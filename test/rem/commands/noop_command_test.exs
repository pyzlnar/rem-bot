defmodule Rem.Commands.NoopCommandTest do
  use ExUnit.Case, async: true

  alias Rem.Commands.NoopCommand

  describe "should_run?/1" do
    test "returns noop" do
      assert :noop = NoopCommand.should_run?(:message)
    end
  end

  describe "run?/2" do
    test "returns ok" do
      assert :ok = NoopCommand.run(:message, :state)
    end
  end
end
