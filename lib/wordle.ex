defmodule Wordle do
  @base_date Date.from_iso8601("2021-06-19") |> elem(1)

  alias Rem.Queries.WordleQuery
  alias Wordle.{Game, WordValidator}

  @spec to_valid_id(integer | Date.t) :: {:ok, non_neg_integer } | {:error, reason :: atom}

  def to_valid_id(val \\ pdt_today())

  def to_valid_id(%Date{} = date) do
    date
    |> Date.diff(@base_date)
    |> to_valid_id()
  end

  def to_valid_id(number) when is_integer(number) do
    number
    |> abs()
    |> rem(WordleQuery.solutions_length)
  end

  @spec new(non_neg_integer, list) :: {:ok, Game.t} | {:error, atom}

  def new(number, opts \\ []) when is_integer(number) and number >= 0 do
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
         :ok  <- valid_word?(attempt),
         :ok  <- valid_attempt?(game, attempt),
         game <- update_game(game, attempt)
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

  defp valid_word?(word) do
    if WordValidator.valid?(word),
      do:   :ok,
      else: {:error, {:invalid_word, word}}
  end

  defp valid_attempt?(%Game{mode: :hard} = game, attempt) do
    if Game.uses_previous_hints?(game, attempt),
      do:   :ok,
      else: {:error, {:invalid_attempt, attempt}}
  end

  defp valid_attempt?(_game, _attempt),
    do: :ok

  defp update_game(game, attempt) do
    Game.play(game, attempt)
  end
end
