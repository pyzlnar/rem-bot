defmodule Wordle.ValidatorTest do
  use Rem.DataCase, async: true

  alias Wordle.{Game, Validator}

  describe "valid_id?/1" do
    setup do
      insert(:wordle_solution, number: 200, name: "toesy")
      :ok
    end

    test "returns :ok if it's a valid id" do
      assert :ok == Validator.valid_id?(0)
      assert :ok == Validator.valid_id?(200)
    end

    test "returns :error if it's not a valid id" do
      # Not an integer
      assert :error == Validator.valid_id?("200")
      # Negative integer
      assert :error == Validator.valid_id?(-200)
      # Solution not yet in DB
      assert :error == Validator.valid_id?(201)
    end
  end

  describe "valid_word?/1" do
    setup do
      insert(:wordle_word, name: "grasp")
      :ok
    end

    test "returns :ok if it's a valid word" do
      assert :ok == Validator.valid_word?("grasp")
    end

    test "returns error if it's now a valid id" do
      # Invalid format
      assert {:error, {:invalid_word, _}} = Validator.valid_word?("")
      assert {:error, {:invalid_word, _}} = Validator.valid_word?("graspy")
      # Word not in DB
      assert {:error, {:invalid_word, _}} = Validator.valid_word?("bless")
    end
  end

  describe "valid_attempt?/2" do
    setup do
      %Game{
        mode: :normal,
        solution: "stiff",
        attempts: ["tacos"],
        evaluations: [~W[present absent absent absent present]a]
      }
      |> then(&{:ok, %{game: &1}})
    end

    test "returns :ok if it's a valid attempt", %{game: game} do
      assert :ok == Validator.valid_attempt?(game, "tacos")

      game = %{game|mode: :hard}
      assert :ok == Validator.valid_attempt?(game, "trash")
    end

    test "returns error if it's not a valid attempt", %{game: game} do
      game = %{game|mode: :hard}
      assert {:error, {:invalid_attempt, _}} = Validator.valid_attempt?(game, "proud")
    end
  end
end
