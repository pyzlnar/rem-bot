defmodule Rem.Commands.Wordle.ResumeCommand do
  use Rem.Command, type: :prefix

  import Rem.I18n
  import Rem.Commands.Utils

  alias Rem.Queries.WordleQuery
  alias Rem.Sessions.WordleSession

  # TODO errors to message

  @impl true
  def run(%{author: %{id: user_id}} = msg, _args) do
    with :ok                            <- WordleSession.can_start_session?(user_id),
         record when not is_nil(record) <- WordleQuery.fetch_game(user_id, state: :active),
         {:ok, game}                    <- Wordle.from_record(record),
         {:ok, _game}                   <- WordleSession.new(user_id, game)
    do
      opts = game_to_message_opts(game)
      send_dm(msg, gettext("wordle:board", opts))
    end
  end
end
