defmodule Rem.WordleTest do
  use Rem.DataCase, async: true

  alias Rem.Wordle

  describe "happy path games" do
    test "starts a game by date, plays and wins a game" do
      insert(:wordle_solution, number: 223, name: "perky")
      insert_wordle_words(~W[husky moder perky])

      {:ok, date} = Date.new(2022, 01, 28)

      assert {:ok, %Wordle.Game{} = game} = Wordle.new(date)
      assert []      = game.attempts
      assert []      = game.evaluations
      assert :active = game.state

      assert {:ok, game} = Wordle.play(game, "husky")
      assert ["husky"|_]                                   = game.attempts
      assert [~W[absent absent absent correct correct]a|_] = game.evaluations
      assert :active                                       = game.state

      assert {:ok, game} = Wordle.play(game, "moder")
      assert ["moder"|_]                                   = game.attempts
      assert [~W[absent absent absent present present]a|_] = game.evaluations
      assert :active                                       = game.state

      assert {:ok, game} = Wordle.play(game, "perky")
      assert ["perky"|_]                                      = game.attempts
      assert [~W[correct correct correct correct correct]a|_] = game.evaluations
      assert :win                                             = game.state

      assert 3 == length(game.attempts)
      assert 3 == length(game.evaluations)
    end

    test "starts a game by number, plays and looses" do
      insert(:wordle_solution, number: 2, name: "sissy")
      insert_wordle_words(~W[plans shake truck stink foils sinky])

      assert {:ok, %Wordle.Game{} = game} = Wordle.new(2)

      assert {:ok, game} = Wordle.play(game, "plans")
      assert {:ok, game} = Wordle.play(game, "shake")
      assert {:ok, game} = Wordle.play(game, "truck")
      assert {:ok, game} = Wordle.play(game, "stink")
      assert {:ok, game} = Wordle.play(game, "foils")
      assert {:ok, game} = Wordle.play(game, "sinky")

      assert :lose = game.state
      assert 6 == length(game.attempts)
      assert 6 == length(game.evaluations)
    end

    test "starts a game in hard mode, and wins" do
      insert(:wordle_solution, number: 229, name: "shard")
      insert_wordle_words(~W[prime roast snark shard])

      assert {:ok, %Wordle.Game{} = game} = Wordle.new(229, hard: true)

      assert {:ok, game} = Wordle.play(game, "prime")
      assert {:ok, game} = Wordle.play(game, "roast")
      assert {:ok, game} = Wordle.play(game, "snark")
      assert {:ok, game} = Wordle.play(game, "shard")

      assert :win  = game.state
      assert :hard = game.mode
      assert 4 == length(game.attempts)
      assert 4 == length(game.evaluations)
    end
  end

  describe "unhappy paths" do
    test "returns :invalid_number when the solution for said date/number is not in the DB" do
      insert(:wordle_solution, number: 0, name: "cigar")

      {:ok, date} = Date.new(2022, 01, 28)
      assert {:error, :invalid_number} = Wordle.new(1)
      assert {:error, :invalid_number} = Wordle.new(1, hard: true)
      assert {:error, :invalid_number} = Wordle.new(date)
    end

    test "returns :invalid_word if the provided word is not in the correct format, or not in the DB" do
      insert(:wordle_solution, number: 0, name: "cigar")

      {:ok, game} = Wordle.new(0)

      # We insert the words to ensure they fail on the regex
      invalid_words = ~W[w/sym shrt longerthanfive]
      insert_wordle_words(invalid_words)

      for word <- invalid_words do
        assert {:error, :invalid_word} = Wordle.play(game, word)
      end

      # Correct format but not in DB
      assert {:error, :invalid_word} = Wordle.play(game, "abcde")
    end

    test "returns :invalid_attempt for hard mode game when the attempt doesn't use all previous hints" do
      insert(:wordle_solution, number: 0, name: "cigar")
      insert_wordle_words(~W[cigar trope blast])

      {:ok, game} = Wordle.new(0)
      {:ok, game} = Wordle.play(game, "trope")
      assert {:ok, _} = Wordle.play(game, "blast")

      {:ok, game} = Wordle.new(0, hard: true)
      {:ok, game} = Wordle.play(game, "trope")
      assert {:error, :invalid_attempt} = Wordle.play(game, "blast")
    end

    test "returnes :game_already_over when trying to play in a game that is already finished" do
      insert(:wordle_solution, number: 0, name: "cigar")
      insert_wordle_words(~W[cigar blast])

      {:ok, game} = Wordle.new(0)
      {:ok, game} = Wordle.play(game, "cigar")
      assert {:error, :game_already_over} = Wordle.play(game, "blast")
    end
  end
end
