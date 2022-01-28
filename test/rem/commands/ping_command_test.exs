defmodule Rem.Commands.PingCommandTest do
  use ExUnit.Case, async: true
  use Injector, inject: [Rem.Discord.Api]

  alias Rem.Commands.PingCommand

  describe "run/2" do
    test "returns a message stating the bot still lives" do

      Rem.Discord.Api
      |> expects(:create_message, fn 123456, "Still alive!" -> :ok end)

      assert :ok = PingCommand.run(%{channel_id: 123456}, "")
    end
  end
end
