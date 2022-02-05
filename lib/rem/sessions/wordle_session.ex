defmodule Rem.Sessions.WordleSession do
  @moduledoc """
  Manages the session of a wordle game
  """

  use Rem.Session
  alias Rem.Discord.Api

  require Logger
  alias Rem.Commands.WordleCommand
  alias Rem.Queries.WordleQuery
  import Rem.I18n

  @impl true
  def new(user_id, game) do
    with {:ok, %{id: channel_id}} <- Api.create_dm(user_id),
         {:ok, on_timeout}        <- gen_on_timeout(channel_id)
    do
      args = [value: %{game: game, channel_id: channel_id}, on_timeout: on_timeout]
      super(user_id, args)
    end
  end

  @impl true
  def set(user_id, %Rem.Wordle.Game{} = game) do
    with {:ok, update_fn} <- gen_update_fn(game),
         {:ok, value}     <- super(user_id, update_fn),
         do: {:ok, value.game}
  end

  @impl true
  def process(%{author: %{id: user_id}, channel_id: channel_id} = message) do
    with {:ok, state} <- get(user_id),
         true         <- state.channel_id == channel_id
    do
      play(user_id, state, message)
      :ok
    else
      _ -> :noop
    end
  end

  # --- Helpers --- #

  # TODO: gettext
  defp gen_on_timeout(channel_id) do
    {:ok, fn -> Api.create_message(channel_id, "Your session has expired!") end}
  end

  defp gen_update_fn(game) do
    {:ok, fn value -> %{value|game: game} end}
  end

  defp play(user_id, %{channel_id: channel_id, game: game}, %{content: attempt}) do
    with {:ok, game}     <- Rem.Wordle.play(game, attempt),
         {:ok, _record}  <- WordleQuery.update_game(user_id, game),
         {:ok, _session} <- set(user_id, game)
    do
      handle_played(user_id, channel_id, game)
    else
      {:error, :invalid_word} ->
        Api.create_message(channel_id, "'#{attempt}' is not in the word list.")
      error ->
        Logger.warn("[#{__MODULE__} #{inspect error}")
    end
  end

  defp handle_played(_user_id, channel_id, %{state: :active} = game) do
    {board, nrow} = format_board(game)
    Api.create_message(channel_id, gettext("wordle:board", number: game.number, board: board, attempt: nrow))
  end

  defp handle_played(user_id, channel_id, %{state: :win} = game) do
    {board, nrow} = format_board(game)
    kill(user_id)
    Api.create_message(channel_id, gettext("wordle:board", number: game.number, board: board, attempt: nrow))
    Api.create_message(channel_id, "You win!")
  end

  defp handle_played(user_id, channel_id, %{state: :lose} = game) do
    {board, nrow} = format_board(game)
    kill(user_id)
    Api.create_message(channel_id, gettext("wordle:board", number: game.number, board: board, attempt: nrow))
    Api.create_message(channel_id, "Better luck next time.")
  end

  defp format_board(game) do
    board = WordleCommand.game_to_board(game)
    nrow  = length(game.attempts)
    board = if nrow < 6, do: "#{board}\n _  _  _  _  _  _", else: board

    {board, nrow}
  end
end
