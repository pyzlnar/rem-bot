defmodule Rem.Commands.Wordle.HelpCommandTest do
  use ExUnit.Case, async: true

  use Injector, inject: [Rem.Discord.Api]

  alias Rem.Commands.Wordle.HelpCommand

  describe "run/2" do
    test "returns a message with help of all the commands" do

      Rem.Discord.Api
      |> expects(:create_dm, &create_dm/1)
      Rem.Discord.Api
      |> expects(:create_message, &create_message/2)

      assert :ok = HelpCommand.run(%{author: %{id: :user_id}}, [])
    end
  end

  # --- Helpers --- #

  defp create_dm(:user_id) do
    {:ok, %{id: :channel_id}}
  end

  defp create_message(:channel_id, message) do
    assert message =~ ~r/wordle help/
    assert message =~ ~r/wordle play/
    assert message =~ ~r/wordle resume/

    :ok
  end
end
