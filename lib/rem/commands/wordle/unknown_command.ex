defmodule Rem.Commands.Wordle.UnknownCommand do
  use Rem.Command, type: :prefix

  import Rem.I18n
  import Rem.Commands.Utils

  @impl true
  def run(msg, _args) do
    header  = dgettext("wordle", "help:unknown_command")
    content = dgettext("wordle", "help", prefix: get_command_prefix())
    message = dgettext("wordle", "with_header", header: header, content: content)
    send_dm(msg, message)
    :ok
  end
end
