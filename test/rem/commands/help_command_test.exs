defmodule Rem.Commands.HelpCommandTest do
  use ExUnit.Case, async: true

  use Injector, inject: [Rem.Discord.Api]

  alias Rem.Commands.HelpCommand

  describe "run/2" do
    test "returns a message with help of all the commands" do

      Rem.Discord.Api
      |> expects(:create_message, &message_contains_commands?/2)

      assert :ok = HelpCommand.run(%{channel_id: 123456}, [])
    end
  end

  # --- Helpers --- #

  defp message_contains_commands?(123456, message) do
    prefixes =
      Application.get_env(:rem, :prefixes, ["<prefix>"])
      |> Enum.join("|")

    prefixes = "(?:#{prefixes})"

    Application.get_env(:rem, :commands, [])
    |> Enum.each(fn command ->
      assert message =~ ~r/^#{prefixes}#{command}/m
    end)

    {:ok, :whatever}
  end
end
