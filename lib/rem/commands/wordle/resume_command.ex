defmodule Rem.Commands.Wordle.ResumeCommand do
  use Rem.Command, type: :prefix

  import Rem.I18n
  import Rem.Commands.Utils

  alias Rem.Queries.WordleQuery
  alias Rem.Sessions.WordleSession

  @impl true
  def run(%{author: %{id: user_id}} = msg, _args) do
    with :ok           <- WordleSession.can_start_session?(user_id),
         {:ok, record} <- fetch_record(user_id),
         {:ok, game}   <- Wordle.from_record(record),
         {:ok, _pid}   <- WordleSession.new(user_id, game)
    do
      opts = game_to_message_opts(game)
      send_dm(msg, dgettext("wordle", "board", opts))
      :ok
    else
      error ->
        handle_error(msg, error)
        error
    end
  end

  # ---

  defp fetch_record(user_id) do
    case WordleQuery.fetch_game(user_id, state: :active) do
      nil    -> {:error, :no_unfinished_game}
      record -> {:ok, record}
    end
  end

  defp handle_error(msg, {:error, :session_already_exists}) do
    send_dm(msg, dgettext("wordle", "error:session_already_exists"))
  end

  defp handle_error(msg, {:error, :no_unfinished_game}) do
    send_dm(msg, dgettext("wordle", "error:no_unfinished_game", prefix: get_command_prefix()))
  end

  defp handle_error(msg, error) do
    handle_unknown_error(__MODULE__, msg, error)
  end
end
