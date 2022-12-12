defmodule Wordle do
  alias Rem.Queries.WordleQuery
  alias Wordle.{Game, Validator}

  @base_date Date.from_iso8601("2021-06-19") |> elem(1)

  @type wordle_id :: non_neg_integer

  defguard is_wordle_id?(id) when is_integer(id) and id >= 0

  @spec date_to_id(Date.t) :: wordle_id

  def date_to_id(date) do
    Date.diff(date, @base_date)
  end

  @spec id_to_date(wordle_id) :: Date.t

  def id_to_date(id) when is_wordle_id?(id) do
    Date.add(@base_date, id)
  end

  @spec default_id() :: wordle_id

  def default_id do
    date_to_id(pdt_today())
  end

  @spec new(non_neg_integer, list) :: {:ok, Game.t} | {:error, atom}

  def new(number, opts \\ []) when is_wordle_id?(number) do
    case WordleQuery.fetch_solution(number) do
      %{number: _, solution: _} = args ->
        args =
          if Keyword.get(opts, :hard),
            do:   Map.put(args, :mode, :hard),
            else: args

        {:ok, Game.new(args)}
      _ ->
        {:error, {:invalid_number, number}}
    end
  end

  @spec from_record(Schema.Wordle.Game.t) :: {:ok, Game.t}

  def from_record(%Schema.Wordle.Game{} = record) do
    {:ok, Game.new(record)}
  end

  @spec play(Game.t, String.t) :: {:ok, Game.t} | {:error, atom}

  def play(%Game{state: :active} = game, attempt) do
    with attempt = String.downcase(attempt),
         :ok  <- Validator.valid_word?(attempt),
         :ok  <- Validator.valid_attempt?(game, attempt),
         game <- Game.play(game, attempt)
    do
      {:ok, game}
    else
      {:error, status} = error when is_atom(status) ->
        error
      {:error, {status, _info}} = error when is_atom(status) ->
        error
      _ ->
        {:error, :unknown_error}
    end
  end

  def play(%Game{}, _attempt) do
    {:error, :game_already_over}
  end

  # ----

  # Returns todays time in PDT
  # We could use timezones for more accuricy, but really the goal is to not change the date beforehand
  # for an entire continent
  defp pdt_today do
    DateTime.utc_now
    |> DateTime.add(-7 * 3600, :second)
    |> DateTime.to_date
  end
end
