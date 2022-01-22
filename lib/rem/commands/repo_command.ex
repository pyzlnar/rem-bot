defmodule Rem.Commands.RepoCommand do
  @behaviour Rem.Commands.Command

  alias Nostrum.Api

  @impl true
  def run(%{channel_id: channel_id}, _args_str),
    do: Api.create_message(channel_id, "https://github.com/pyzlnar/rem-bot")
end
