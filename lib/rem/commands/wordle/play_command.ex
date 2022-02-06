defmodule Rem.Commands.Wordle.PlayCommand do
  use Rem.Command, type: :session

  alias Rem.Discord.Api
  alias Rem.Queries.WordleQuery
  alias Rem.Sessions.WordleSession

  import Rem.I18n
  import Rem.Commands.Utils

  require Logger

  @impl true
  def should_run?(%{author: %{id: user_id}, channel_id: channel_id}) do
    with {:ok, state} <- WordleSession.get(user_id),
         true         <- state.channel_id == channel_id
    do
      {:ok, state}
    else
      _ -> :noop
    end
  end

  @impl true
  def run(%{author: %{id: user_id}, channel_id: channel_id, content: attempt}, %{game: game}) do
    with {:ok, game}     <- Wordle.play(game, attempt),
         {:ok, _record}  <- WordleQuery.update_game(user_id, game),
         {:ok, _session} <- WordleSession.set(user_id, game)
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
    opts = game_to_message_opts(game)
    Api.create_message(channel_id, gettext("wordle:board", opts))
  end

  defp handle_played(user_id, channel_id, %{state: :win} = game) do
    WordleSession.kill(user_id)

    opts = game_to_message_opts(game)
    Api.create_message(channel_id, gettext("wordle:board", opts))
    Api.create_message(channel_id, "You win!")
  end

  defp handle_played(user_id, channel_id, %{state: :lose} = game) do
    WordleSession.kill(user_id)

    opts = game_to_message_opts(game)
    Api.create_message(channel_id, gettext("wordle:board", opts))
    Api.create_message(channel_id, "Better luck next time.")
  end
end
