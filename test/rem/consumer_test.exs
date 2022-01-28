defmodule Rem.ConsumerTest do
  use ExUnit.Case, async: true

  alias Rem.Consumer

  describe "extract_prefix/1" do
    test "removes the prefix and returns the rest of the string"  do
      assert {:ok, "ping"}            = Consumer.extract_prefix("!ping")
      assert {:ok, "unknown_command"} = Consumer.extract_prefix("!unknown_command")
      assert {:ok, "ping other args"} = Consumer.extract_prefix("!ping other args")
      assert {:ok, "ping with space"} = Consumer.extract_prefix("! ping with space")
    end

    test "returns {:ok, rest} for all valid prefixes" do
      Application.get_env(:rem, :prefixes, [])
      |> Enum.each(fn prefix ->
        assert {:ok, _rest} = Consumer.extract_prefix(prefix <> "command")
      end)
    end

    test "returns error for unknown prefixes" do
      assert :error = Consumer.extract_prefix("no_prefix ping")
    end
  end

  describe "extract_command/1" do
    test "removes the command and returns the command and a string with the remaining args" do
      assert {:ok, Rem.Commands.PingCommand, ""}           = Consumer.extract_command("ping")
      assert {:ok, Rem.Commands.PingCommand, "other args"} = Consumer.extract_command("ping other args")
    end

    test "returns {:ok, rest} for all valid commands" do
      Application.get_env(:rem, :commands, [])
      |> Enum.each(fn command ->
        assert {:ok, _command, _args} = Consumer.extract_command(command <> "other args")
      end)
    end

    test "returns error for unknown commands" do
      assert :error = Consumer.extract_command("unknown_command")
    end
  end
end
