defmodule Rem.Commands.Command do
  @moduledoc """
  A command processes a command/request done to the bot.
  All commands end in *Command for the sake of clarity.
  """

  alias Nostrum.Struct.Message

  # NOTE: With only one method behavior may seem like an overkill...
  @callback run(Message.t, String.t) :: :ok | :error
end
