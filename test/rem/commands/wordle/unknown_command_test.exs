defmodule Rem.Commands.Wordle.UnknownCommandTest do
  use ExUnit.Case, async: true

  use Injector, inject: [Rem.Discord.Api]

  alias Rem.Commands.Wordle.UnknownCommand

  describe "run/2" do
    test "it just display the help message stating it doesn't know what the user meant" do
      Rem.Discord.Api
      |> stubs(:create_dm, fn _user_id -> {:ok, %{id: :channel_id}} end)

      Rem.Discord.Api
      |> expects(:create_message, fn :channel_id, message ->

        assert message =~ ~r/didn't understand/
        assert message =~ ~r/wordle help/
        assert message =~ ~r/wordle play/
      end)

      assert :ok = UnknownCommand.run(%{author: %{id: :user_id}}, [])
    end
  end
end
