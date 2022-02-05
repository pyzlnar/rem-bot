defmodule Rem.Wordle.Game do
  @attrs ~W[attempts evaluations mode number solution state]a
  defstruct @attrs

  @max_attempts 6

  @type t :: %__MODULE__{
    attempts:    [String.t],
    evaluations: [[:absent | :present | :correct]],
    mode:        :normal | :hard,
    number:      non_neg_integer,
    solution:    String.t,
    state:       :active | :win | :lose
  }

  def attrs, do: @attrs

  def new(%{number: _, solution: _} = attrs) do
    attrs = Map.take(attrs, @attrs)
    %__MODULE__{
      attempts:    [],
      evaluations: [],
      mode:        :normal,
      state:       :active
    }
    |> Map.merge(attrs)
  end

  def play(%__MODULE__{} = game, attempt) do
    game
    |> update_attempts(attempt)
    |> update_state()
  end

  def update_attempts(%__MODULE__{} = game, attempt) do
    evaluation = evaluate_attempt(game, attempt)
    %{game|attempts: [attempt|game.attempts], evaluations: [evaluation|game.evaluations]}
  end

  def evaluate_attempt(%__MODULE__{solution: solution}, attempt) do
    attempt
    |> String.graphemes
    |> Stream.with_index
    |> Enum.map(fn {char, index} ->
      cond do
        String.at(solution, index) == char ->
          :correct
        String.contains?(solution, char) ->
          :present
        true ->
          :absent
      end
    end)
  end

  def update_state(%__MODULE__{} = game) do
    cond do
      hd(game.attempts) == game.solution ->
        %{game|state: :win}
      length(game.attempts) >= @max_attempts  ->
        %{game|state: :lose}
      true ->
        game
    end
  end

  def uses_previous_hints?(%__MODULE__{attempts: []}, _attempt), do: true

  def uses_previous_hints?(%__MODULE__{} = game, attempt) do
    %{attempts: [last_attempt|_], evaluations: [last_evaluation|_]} = game

    last_attempt
    |> String.graphemes
    |> Enum.zip(last_evaluation)
    |> Enum.reject(fn {_char, eval} -> eval == :absent end)
    |> Enum.map(&(elem(&1, 0)))
    |> Enum.all?(&(String.contains?(attempt, &1)))
  end
end
