defmodule Rem.Commands.HelpCommand do
  use Rem.Command, type: :prefix

  import Rem.I18n
  alias Rem.Discord.Api

  @impl true
  def run(%{channel_id: channel_id}, _args) do
    with {:ok, _} <- Api.create_message(channel_id, generate_help_message()),
         do: :ok
  end

  defp generate_help_message do
    prefixes = Application.get_env(:rem, :prefixes, ["<prefix>"])
    gettext("response:help", prefixes: inspect(prefixes), prefix: hd(prefixes))
  end
end
