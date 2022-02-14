defmodule Rem.Commands.NoopCommand do
  use Rem.Command, type: :session

  @impl true
  def should_run?(_message),
    do: :noop

  @impl true
  def run(_message, _state),
    do: :ok
end
