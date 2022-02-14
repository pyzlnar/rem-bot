defmodule Rem.Commands.PingCommand do
  use Rem.Command, type: :prefix

  import Rem.I18n
  alias Rem.Discord.Api

  @impl true
  def run(%{channel_id: channel_id}, _args),
    do: Api.create_message(channel_id, gettext("response:ping"))
end
