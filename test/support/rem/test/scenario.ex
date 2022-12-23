defmodule Rem.Test.Scenario do
  import Rem.Test.Factory

  def insert_wordle_words(words) when is_list(words) do
    words
    |> Enum.map(&[name: &1])
    |> Enum.each(&(insert(:wordle_word, &1)))
  end

  def insert_stats_scenario(user_id \\ 1234) do
    insert(:wordle_game, discord_user_id: user_id, state: :active)
    insert(:wordle_game, discord_user_id: user_id, state: :win,  attempts: ~W[one two three])
    insert(:wordle_game, discord_user_id: user_id, state: :win,  attempts: ~W[one two three])
    insert(:wordle_game, discord_user_id: user_id, state: :win,  attempts: ~W[one two three four])
    insert(:wordle_game, discord_user_id: user_id, state: :win,  attempts: ~W[one two three four five six])
    insert(:wordle_game, discord_user_id: user_id, state: :lose, attempts: ~W[one two three four five six])
    insert(:wordle_game, discord_user_id: user_id, state: :lose, attempts: ~W[one two three four five six])
  end
end
