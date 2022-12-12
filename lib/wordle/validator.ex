defmodule Wordle.Validator do
  alias Rem.Queries.WordleQuery
  alias Wordle.Game

  import Wordle, only: [is_wordle_id?: 1]

  @spec valid_id?(Wordle.wordle_id | Date.t) :: :ok | :error

  def valid_id?(id) when is_wordle_id?(id) do
    if id <= WordleQuery.last_saved_solution,
      do: :ok,
      else: :error
  end

  def valid_id?(_) do
    :error
  end

  @spec valid_word?(String.t) ::
    :ok | {:error, {:invalid_word, String.t}}

  def valid_word?(word) do
    with true <- valid_word_format?(word),
         true <- word_exists?(word)
    do
      :ok
    else
      _ ->
        {:error, {:invalid_word, word}}
    end
  end

  @spec valid_attempt?(Game.t, String.t) ::
    :ok | {:error, {:invalid_attempt, String.t}}

  def valid_attempt?(%Game{mode: :hard} = game, attempt) do
    if Game.uses_previous_hints?(game, attempt),
      do:   :ok,
      else: {:error, {:invalid_attempt, attempt}}
  end

  def valid_attempt?(_game, _attempt),
    do: :ok

  # ---

  defp valid_word_format?(word) do
    String.match?(word, ~r/\A[a-z]{5}\z/)
  end

  defp word_exists?(word) do
    WordleQuery.word_exists?(word)
  end
end
