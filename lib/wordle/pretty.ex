defmodule Wordle.Pretty do
  @max_attempts 6
  @word_length  5

  @keyboard [
    ~W[q w e r t y u i o p],
     ~W[a s d f g h j k l],
      ~W[z x c v b n m]
  ]

  alias Wordle.{Emoji, Game}

  def board_with_info(%Game{} = game) do
    nrow = length(game.attempts)

    plays  = game_to_board(game)
    blanks = get_blanks(nrow)

    board =
      blanks ++ plays
      |> Enum.reverse
      |> Enum.join("\n")

    keyboard = game_to_keyboard(game)

    [board: board, attempt: nrow, number: game.number, keyboard: keyboard]
  end

  def game_to_board(game) do
    Stream.zip(game.attempts, game.evaluations)
    |> Stream.map(fn {attempt, evaluation} ->
      attempt
      |> String.graphemes
      |> Enum.zip(evaluation)
      |> Enum.map(&Emoji.from_evaluation/1)
      |> Enum.join("")
    end)
    |> Enum.to_list
  end

  def get_blanks(n_attempts) when n_attempts >= @max_attempts, do: []

  def get_blanks(n_attempts) do
    n_attempts..(@max_attempts - 1)
    |> Enum.map(fn _ ->
      Emoji.empty_square
      |> List.duplicate(@word_length)
      |> Enum.join("")
    end)
  end

  def game_to_keyboard(game) do
    map = game_to_keyboard_map(game)

    @keyboard
    |> Stream.with_index
    |> Stream.map(fn {row, index} ->
      row
      |> Enum.map(&(Emoji.from_evaluation({&1, map[&1]})))
      |> Enum.join("")
      |> String.replace_prefix("", String.pad_leading("", index * 2, " "))
    end)
    |> Enum.join("\n")
    |> String.replace_prefix("", "\n\n")
  end

  defp game_to_keyboard_map(game) do
    Stream.zip(game.attempts, game.evaluations)
    |> Enum.reduce(%{}, fn {attempt, evaluation}, map ->
      attempt
      |> String.graphemes
      |> Enum.zip(evaluation)
      |> Enum.reduce(map, fn {letter, eval}, map ->
        case {map[letter], eval} do
          {nil, _}             -> Map.put(map, letter, eval)
          {:absent, _}         -> Map.put(map, letter, eval)
          {:present, :correct} -> Map.put(map, letter, eval)
          _                    -> map
        end
      end)
    end)
  end
end
