defmodule Rem.Commands.Wordle.UnknownCommand do
  use Rem.Command, type: :prefix

  import Rem.Commands.Utils

  @impl true
  def run(msg, _args) do
    send_dm(msg, "I'm sorry, I didnt understand what you meant!")
  end
end
