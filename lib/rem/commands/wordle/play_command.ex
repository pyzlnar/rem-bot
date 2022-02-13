defmodule Rem.Commands.Wordle.PlayCommand do
  use Rem.Command, type: :session

  alias Rem.Discord.Api
  alias Rem.Queries.WordleQuery
  alias Rem.Sessions.WordleSession

  import Rem.I18n
  import Rem.Commands.Utils

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
      :ok
    else
      error ->
        handle_error(channel_id, error)
        error
    end
  end

  defp handle_played(_user_id, channel_id, %{state: :active} = game) do
    opts = game_to_message_opts(game)
    Api.create_message(channel_id, dgettext("wordle", "board", opts))
  end

  defp handle_played(user_id, channel_id, %{state: :win} = game) do
    WordleSession.kill(user_id)

    opts    = game_to_message_opts(game)
    header  = dgettext("wordle", "board:win")
    content = dgettext("wordle", "board", opts)
    message = dgettext("wordle", "with_header", header: header, content: content)

    Api.create_message(channel_id, message)
  end

  defp handle_played(user_id, channel_id, %{state: :lose} = game) do
    WordleSession.kill(user_id)

    opts    = game_to_message_opts(game)
    header  = dgettext("wordle", "board:lose")
    content = dgettext("wordle", "board", opts)
    message = dgettext("wordle", "with_header", header: header, content: content)

    Api.create_message(channel_id, message)
  end

  defp handle_error(channel_id, {:error, {:invalid_word, attempt}}) do
    Api.create_message(channel_id, dgettext("wordle", "error:invalid_word", attempt: attempt))
  end

  defp handle_error(channel_id, {:error, {:invalid_attempt, attempt}}) do
    Api.create_message(channel_id, dgettext("wordle", "error:invalid_attempt", attempt: attempt))
  end

  defp handle_error(channel_id, error) do
    handle_unknown_error(__MODULE__, channel_id, error)
  end
end
