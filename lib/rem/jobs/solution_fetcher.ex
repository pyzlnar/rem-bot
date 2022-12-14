defmodule Rem.Jobs.SolutionFetcher do
  use Oban.Worker, queue: :cron

  require Logger

  alias Rem.{Clients, Repo}
  alias Rem.Queries.WordleQuery

  @max_solutions_fetched_per_second 10

  @impl Oban.Worker
  def perform(_) do
    with {:ok, range}      <- get_missing_solutions_range(),
         {:ok, solutions}  <- get_solutions(range),
         {:ok, changesets} <- create_changesets(solutions),
         :ok               <- insert_solutions(changesets)
    do
      :ok
    else
      {:halt, :solutions_up_to_date} ->
        :ok

      error ->
        Logger.error "[#{__MODULE__}] Error: #{inspect(error, pretty: true)}"
        error
    end
  end

  defp get_missing_solutions_range do
    from = WordleQuery.last_saved_solution
    to   = Wordle.date_to_id(Date.utc_today)

    if from < to do
      {:ok, (from + 1)..to}
    else
      {:halt, :solutions_up_to_date}
    end
  end

  defp get_solutions(range) do
    range
    |> Stream.chunk_every(@max_solutions_fetched_per_second)
    |> Enum.flat_map(fn chunk ->
      chunk
      |> Enum.map(fn wordle_id ->
        {:ok, solution} = fetch_solution(wordle_id)
        {wordle_id, solution}
      end)
      |> tap(fn _ -> Process.sleep(1000) end)
    end)
    |> then(&{:ok, &1})
  end

  defp fetch_solution(wordle_id) do
    wordle_id
    |> Wordle.id_to_date
    |> Clients.Nytimes.fetch_solution
  end

  defp create_changesets(solutions) do
    solutions
    |> Enum.map(fn {number, name} ->
      %{
        name:        name,
        number:      number,
        inserted_at: {:placeholder, :now},
        updated_at:  {:placeholder, :now}
      }
    end)
    |> then(&{:ok, &1})
  end

  defp insert_solutions(changesets) do
    Repo.insert_all(
      Schema.Wordle.Solution,
      changesets,
      on_conflict:     {:replace, [:name, :updated_at]},
      conflict_target: :number,
      placeholders:    %{now: DateTime.utc_now}
    )
    |> then(fn
      {0, _} -> {:error, :none_inserted}
      {_, _} -> :ok
    end)
  end
end
