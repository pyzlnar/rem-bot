defmodule Wordle.GameTest do
  use ExUnit.Case, async: true

  alias Wordle.Game

  describe "new/1" do
    test "creates a new game with default attributes" do
      args = %{number: 1, solution: "rebut"}
      game = Game.new(args)

      assert game.attempts    == []
      assert game.evaluations == []
      assert game.mode        == :normal
      assert game.number      == 1
      assert game.solution    == "rebut"
      assert game.state       == :active
    end

    test "creates a new game overriding attributes" do
      args = %{number: 1, solution: "rebut", attempts: ["tacos"], invalid_key: :key, mode: :hard}
      game = Game.new(args)

      assert game.attempts    == ["tacos"]
      assert game.evaluations == []
      assert game.mode        == :hard
      assert game.number      == 1
      assert game.solution    == "rebut"
      assert game.state       == :active
    end
  end

  describe "play/2" do
    test "takes the game to the next state" do
      game = %Game{attempts: [], evaluations: [], solution: "tacos", state: :active}
      game = Game.play(game, "blank")

      assert game.state    == :active
      assert game.attempts == ["blank"]
    end

    test "ends the game with correct solution" do
      game = %Game{attempts: [], evaluations: [], solution: "tacos"}
      game = Game.play(game, "tacos")

      assert game.state    == :win
      assert game.attempts == ["tacos"]
    end

    test "ends the game when max attempts are reached" do
      attempts = ~W[dream solar shark flunk query]
      game     = %Game{attempts: attempts, evaluations: [], solution: "tacos"}
      game     = Game.play(game, "other")

      assert game.state    == :lose
      assert game.attempts == ~W[other dream solar shark flunk query]
    end
  end

  describe "evaluate_attempt/2" do
    test "returns an array with the evaluation" do
      game = %Game{solution: "tacos"}

      assert ~W[correct correct correct correct correct]a == Game.evaluate_attempt(game, "tacos")
      assert ~W[absent  absent  absent  absent  absent ]a == Game.evaluate_attempt(game, "drunk")
      assert ~W[present present present present present]a == Game.evaluate_attempt(game, "sotac")
      assert ~W[absent  absent  present absent  correct]a == Game.evaluate_attempt(game, "grams")
    end
  end

  describe "uses_previous_hints/2" do
    test "returns true if there are no attempts" do
      game = %Game{attempts: [], evaluations: []}

      assert Game.uses_previous_hints?(game, "blank")
    end

    test "returns true only if the current attempt uses all previous hints" do
      game = %Game{attempts: ["roast"], evaluations: [~W[present absent correct present absent]a]}

      # Uses all
      assert Game.uses_previous_hints?(game, "snark")

      # Uses only correct
      refute Game.uses_previous_hints?(game, "plain")

      # Uses only present
      refute Game.uses_previous_hints?(game, "siren")

      # Uses none
      refute Game.uses_previous_hints?(game, "abbey")
    end
  end
end
