defmodule Rem.Queries.WordleQueryTest do
  use Rem.DataCase, async: true

  alias Rem.Queries.WordleQuery
  alias Schema.Wordle.Game

  describe "fetch_solution/1" do
    test "returns the number and solution of the specified solution'snumber if it exists" do
      insert(:wordle_solution, number: 125, name: "taste")
      assert %{number: 125, solution: "taste"} = WordleQuery.fetch_solution(125)
    end

    test "returns nil otherwise" do
      assert is_nil(WordleQuery.fetch_solution(125))
    end
  end

  describe "fetch_game/1" do
    test "returns the game applying the different options" do
      insert(:wordle_game, discord_user_id: 1234, number: 1, solution: "rebut", state: :active)

      result = WordleQuery.fetch_game(1234, number: 1)
      assert %Game{} = result
      assert result.solution == "rebut"

      result = WordleQuery.fetch_game(1234, number: 1, state: :win)
      assert is_nil(result)
    end
  end

  describe "word_exists?/1" do
    test "returns whether a word exsts or not in the database" do
      insert(:wordle_word, name: "plank")

      assert WordleQuery.word_exists?("plank")
      refute WordleQuery.word_exists?("track")
    end
  end

  describe "game_exists?/1" do
    test "returns whether the game exists applying the different options" do
      insert(:wordle_game, discord_user_id: 1234, number: 1, solution: "rebut", state: :active)

      assert WordleQuery.game_exists?(1234, number: 1)
      refute WordleQuery.game_exists?(1234, number: 1, state: :win)
    end
  end

  describe "solutions_length/0" do
    test "returns the number of inserted solutions" do
      # We actually cheat and get the max number instead cuz it's way faster
      insert(:wordle_solution, number: 2314, name: "shave")

      assert 2315 == WordleQuery.solutions_length
    end

    test "returns 1 if there are no solutions in the database" do
      assert 1 == WordleQuery.solutions_length
    end
  end

  describe "create_game/1" do
    test "inserts a game with the received arguments" do
      user_id = 1234
      game    = build(:virtual_game, number: 1, solution: "rebut")

      result = WordleQuery.create_game(user_id, game)
      assert {:ok, %Game{} = record} = result
      refute is_nil(record.id)
      assert record.number   == 1
      assert record.solution == "rebut"
      assert record.discord_user_id == user_id
    end
  end

  describe "update_game/1" do
    test "updates an existing game" do
      insert(:wordle_game, discord_user_id: 1234, number: 1)
      user_id = 1234
      game    = build(:virtual_game, number: 1, solution: "rebut")

      result = WordleQuery.update_game(user_id, game)
      assert {:ok, %Game{} = record} = result
      refute is_nil(record.id)
      assert record.number   == 1
      assert record.solution == "rebut"
      assert record.discord_user_id == user_id
    end
  end
end
