defmodule Wordle.WordValidator do
  alias Rem.Queries.WordleQuery

  @spec valid?(String.t()) :: boolean

  def valid?(word) do
    valid_format?(word) && word_exists?(word)
  end

  # ---

  defp valid_format?(word) do
    String.match?(word, ~r/\A[a-z]{5}\z/)
  end

  defp word_exists?(word) do
    WordleQuery.word_exists?(word)
  end
end
