defmodule Wordle.Emoji do
  @external_resource :code.priv_dir(:rem) |> Path.join("wordle/gray_emojis.txt")
  @external_resource :code.priv_dir(:rem) |> Path.join("wordle/yellow_emojis.txt")
  @external_resource :code.priv_dir(:rem) |> Path.join("wordle/green_emojis.txt")
  @external_resource :code.priv_dir(:rem) |> Path.join("wordle/white_emojis.txt")

  letters = ?a..?z |> Enum.to_list |> List.to_string |> String.graphemes

  # NOTE: Reminder that cumulative attributes add on head, so this has to be in reverse order of above
  evaluations = [nil, :correct, :present, :absent]

  for {file, evaluation} <- Enum.zip(@external_resource, evaluations) do
    file
    |> File.stream!
    |> Stream.zip(letters)
    |> Enum.each(fn {line, letter} ->
      def from_evaluation({unquote(letter), unquote(evaluation)}),
        do: unquote(String.trim(line))
    end)
  end

  def empty_square,
    do: "<:empty_square:942522970507714590>"
end
