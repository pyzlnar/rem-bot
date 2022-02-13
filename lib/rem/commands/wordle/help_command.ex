defmodule Rem.Commands.Wordle.HelpCommand do
  use Rem.Command, type: :prefix

  import Rem.I18n
  import Rem.Commands.Utils

  @impl true
  def run(message, _args) do
    header = dgettext("wordle", "help:default_header")
    send_dm(message, dgettext("wordle", "help", header: header, prefix: get_command_prefix()))
  end
end
