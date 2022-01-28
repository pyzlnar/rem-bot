defmodule Rem.Commands.RepoCommandTest do
  use ExUnit.Case, async: true
  use Injector, inject: [Rem.Discord.Api]

  alias Rem.Commands.RepoCommand

  describe "run/2" do
    test "returns a message linking to the bot's repository" do

      Rem.Discord.Api
      |> expects(:create_message, fn 123456, "https://github.com/pyzlnar/rem-bot" -> :ok end)

      assert :ok = RepoCommand.run(%{channel_id: 123456}, "")
    end
  end
end
