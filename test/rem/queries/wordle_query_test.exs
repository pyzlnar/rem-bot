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

    test "raises an error if multiple records are found" do
      insert(:wordle_game, discord_user_id: 1234, number: 0, solution: "cigar", state: :active)
      insert(:wordle_game, discord_user_id: 1234, number: 1, solution: "rebut", state: :active)

      assert_raise Ecto.MultipleResultsError, fn -> WordleQuery.fetch_game(1234) end
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

      assert WordleQuery.game_exists?(1234)
      assert WordleQuery.game_exists?(1234, number: 1)
      refute WordleQuery.game_exists?(1234, number: 1, state: :win)
    end
  end

  describe "last_saved_solution/0" do
    test "returns the number of the last inserted solution" do
      insert(:wordle_solution, number: 2314, name: "shave")

      assert 2314 == WordleQuery.last_saved_solution
    end

    test "returns 0 if there are no solutions in the database" do
      assert 0 == WordleQuery.last_saved_solution
    end
  end

  describe "game_stats/1" do
    test "returns stats concerning the number of completed games of an user" do
      user_id = 1234
      insert_stats_scenario(user_id)

      expected = [
        %{state: :win,  tries: 3, count: 2},
        %{state: :win,  tries: 4, count: 1},
        %{state: :win,  tries: 6, count: 1},
        %{state: :lose, tries: 6, count: 2}
      ]

      assert expected == WordleQuery.game_stats(user_id)
    end
  end

  describe "attempt_stats/1" do
    test "returns stats concerning the attempts used for a given user" do
      user_id = 1234
      insert_stats_scenario(user_id)

      expected = [
        %{attempt: "one",   count: 6},
        %{attempt: "three", count: 6},
        %{attempt: "two",   count: 6},
        %{attempt: "four",  count: 4},
        %{attempt: "five",  count: 3}
      ]

      assert expected == WordleQuery.attempt_stats(user_id)
    end
  end

  describe "first_attempt_stats/1" do
    test "returns stats concerning the attempts used for a given user" do
      user_id = 1234
      insert_stats_scenario(user_id)

      # Friendly reminder: Attempts order is inversed in DB
      expected = [
        %{attempt: "six",   count: 3},
        %{attempt: "three", count: 2},
        %{attempt: "four",  count: 1}
      ]

      assert expected == WordleQuery.first_attempt_stats(user_id)
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
