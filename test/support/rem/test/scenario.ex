defmodule Rem.Test.Scenario do
  import Rem.Test.Factory

  def insert_wordle_words(words) when is_list(words) do
    words
    |> Enum.map(&[name: &1])
    |> Enum.each(&(insert(:wordle_word, &1)))
  end
end
