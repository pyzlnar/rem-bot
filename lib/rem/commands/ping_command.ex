defmodule Rem.Commands.PingCommand do
  @behaviour Rem.Commands.Command

  alias Nostrum.Api

  @impl true
  def run(%{channel_id: channel_id}, _args_str),
    do: Api.create_message(channel_id, "Still alive!")
end
