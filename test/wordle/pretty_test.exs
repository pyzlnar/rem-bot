defmodule Wordle.PrettyTest do
  use ExUnit.Case, async: true

  alias Wordle.{Game, Pretty}

  describe "board_with_info/1" do
    test "returns a keyword list with all the necessary info to print the board" do
      game = %Game{
        attempts:    ~W[tacos board],
        evaluations: [
          ~W[absent  present absent  present present]a,
          ~W[correct present correct absent  absent]a
        ],
        number: 30
      }

      options = Pretty.board_with_info(game)

      refute is_nil(Keyword.get(options, :board))
      refute is_nil(Keyword.get(options, :keyboard))

      assert 2  == Keyword.get(options, :attempt)
      assert 30 == Keyword.get(options, :number)
    end
  end

  describe "game_to_board/1" do
    test "returns a string repesenting the current state of the filled board" do
      game = %Game{
        attempts:    ~W[tacos board],
        evaluations: [
          ~W[absent  present absent  present present]a,
          ~W[correct present correct absent  absent]a
        ]
      }

      [line1, line2] = Pretty.game_to_board(game)

      assert line1 =~ ~r/:gray_t:/
      assert line1 =~ ~r/:yellow_a:/
      assert line1 =~ ~r/:gray_c:/
      assert line1 =~ ~r/:yellow_o:/
      assert line1 =~ ~r/:yellow_s:/

      assert line2 =~ ~r/:green_b:/
      assert line2 =~ ~r/:yellow_o:/
      assert line2 =~ ~r/:green_a:/
      assert line2 =~ ~r/:gray_r:/
      assert line2 =~ ~r/:gray_d:/
    end
  end

  describe "get_blanks/1" do
    test "returns an empty string if attempts over max_attempts" do
      assert [] = Pretty.get_blanks(6)
      assert [] = Pretty.get_blanks(7)
    end

    test "returns a string containing the necessary amount of blanks" do
      arr     = Pretty.get_blanks(2)
      lines   = length(arr)
      squares = Regex.scan(~r/:empty_square:/, Enum.join(arr, "")) |> length

      assert  4 == lines
      assert 20 == squares
    end
  end

  describe "game_to_keyboard/1" do
    test "returns a string containing letters that have been used and how" do
      game = %Game{
        attempts:    ~W[tacos board block],
        evaluations: [
          ~W[absent  present absent  present present]a,
          ~W[correct present correct absent  absent]a,
          ~W[correct absent  present absent  absent]a
        ]
      }

      string = Pretty.game_to_keyboard(game)

      # Letter has not been used
      assert string =~ ~r/:white_z:/

      # Letter was present at a point then correct
      assert string =~ ~r/:green_a:/

      # Letter is in the solution but not right position
      assert string =~ ~r/:yellow_s:/

      # Letter is correct
      assert string =~ ~r/:green_b:/

      # Letter is not in the solution
      assert string =~ ~r/:gray_t:/
    end
  end
end
