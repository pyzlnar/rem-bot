defmodule Rem.Commands.Utils do
  @moduledoc """
  Library with common helpers for diverse commands
  """

  alias Rem.Discord.Api

  @spec send_dm(map, String.t) :: :ok
  def send_dm(%{author: %{id: user_id}}, message) do
    with {:ok, %{id: channel_id}} <- Api.create_dm(user_id),
         {:ok, _}                 <- Api.create_message(channel_id, message),
         do: :ok
  end

  def game_to_message_opts(game) do
    board = game_to_board(game)
    nrow  = length(game.attempts)

    board =
      if nrow < 6,
        do: "#{board}\n _  _  _  _  _ ",
        else: board

    [board: board, attempt: nrow, number: game.number]
  end

  # TODO: This can be prettier...
  defp game_to_board(game) do
    Stream.zip(game.attempts, game.evaluations)
    |> Stream.map(fn {attempt, evaluation} ->
      attempt
      |> String.graphemes
      |> Enum.zip(evaluation)
      |> Enum.map(fn
        {char, :absent}  -> "-#{char}-"
        {char, :present} -> "~#{char}~"
        {char, :correct} -> "[#{char}]"
      end)
      |> Enum.join(" ")
    end)
    |> Enum.reverse
    |> Enum.join("\n")
  end
end
