defmodule Rem.Consumer do
  use Nostrum.Consumer
  use Rem.Consumer.Meta

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, %{content: content} = message, _ws_state}) do
    with {:ok, rest}          <- extract_prefix(content),
         {:ok, cmd, args_str} <- extract_command(rest),
         do: run_command(cmd, message, args_str)
  end

  def handle_event(_other),
    do: :noop

  # --- Helpers --- #

  defp run_command(command, message, args_str),
    do: apply(command, :run, [message, args_str])
end
