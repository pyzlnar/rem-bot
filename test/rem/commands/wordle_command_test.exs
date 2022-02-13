defmodule Rem.Commands.WordleCommandTest do
  use Rem.DataCase, async: true

  alias Rem.Commands.WordleCommand
  use Injector, inject: [Rem.Discord.Api]

  setup do
    Rem.Discord.Api
    |> stubs(:create_dm, fn _ -> {:ok, %{id: :channel_id}} end)

    Rem.Discord.Api
    |> stubs(:create_message, fn _, _ -> {:ok, :message} end)
  end

  describe "wordle" do
    test "runs the help command" do
      Rem.Discord.Api
      |> expects(:create_message, fn _channel_id, message ->
        assert message =~ "wordle help"
        assert message =~ "wordle play"

        {:ok, :whatever}
      end)

      message = %{author: %{id: make_ref()}, content: "wordle"}
      assert :ok = WordleCommand.run(message, [])
    end
  end

  describe "wordle help" do
    test "runs the help command" do
      Rem.Discord.Api
      |> expects(:create_message, fn _channel_id, message ->
        assert message =~ "wordle help"
        assert message =~ "wordle play"

        {:ok, :whatever}
      end)

      message = %{author: %{id: make_ref()}, content: "wordle help"}
      assert :ok = WordleCommand.run(message, ["help"])
    end
  end

  describe "wordle play" do
    test "runs the start command" do
      message = %{author: %{id: 123456}, content: "wordle play"}
      assert {:error, {:invalid_number, _}} = WordleCommand.run(message, ["play"])
    end
  end

  describe "wordle resume" do
    test "runs the resume command" do
      message = %{author: %{id: 123456}, content: "wordle resume"}
      assert {:error, :no_unfinished_game} = WordleCommand.run(message, ["resume"])
    end
  end

  describe "wordle something_else" do
    test "runs the unkonwn command" do
      Rem.Discord.Api
      |> expects(:create_message, fn :channel_id, message ->
        assert message =~ ~r/didn't understand/
      end)

      message = %{author: %{id: 123456}, content: "wordle something_else"}
      assert :ok = WordleCommand.run(message, ["something_else"])
    end
  end
end
