defmodule Rem.Commands.RepoCommand do
  @behaviour Rem.Commands.Command

  import Rem.I18n
  alias Rem.Discord.Api

  @impl true
  def run(%{channel_id: channel_id}, _args_str),
    do: Api.create_message(channel_id, gettext("response:repo"))
end
