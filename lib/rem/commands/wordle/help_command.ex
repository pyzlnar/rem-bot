defmodule Rem.Commands.Wordle.HelpCommand do
  use Rem.Command, type: :prefix

  import Rem.I18n
  import Rem.Commands.Utils

  @impl true
  def run(message, _args) do
    prefix = Application.get_env(:rem, :prefixes, ["<prefix>"]) |> hd

    send_dm(message, gettext("wordle:help", prefix: prefix))
  end
end
