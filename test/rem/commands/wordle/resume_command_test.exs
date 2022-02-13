defmodule Rem.Commands.Wordle.ResumeCommandTest do
  use Rem.DataCase, async: true

  use Injector, inject: [Rem.Discord.Api]

  alias Rem.Sessions.Server
  alias Rem.Commands.Wordle.ResumeCommand

  setup do
    user_id = 123_456_790
    message = %{author: %{id: user_id}}
    insert(:wordle_solution, number: 100_000)

    Rem.Discord.Api
    |> stubs(:create_dm, fn _ -> {:ok, %{id: :channel_id}} end)

    on_exit fn ->
      case Registry.lookup(Server.registry, user_id) do
        [{pid, _}] -> Process.exit(pid, :kill)
        _          -> :noop
      end
    end

    %{user_id: user_id, message: message}
  end

  describe "happy paths" do
    test "resumes a game that was not finished by the user", %{message: message, user_id: user_id} do
      insert(:wordle_game, discord_user_id: user_id, state: :active, mode: :hard, number: 24, solution: "tacos")

      Rem.Discord.Api
      |> expects(:create_message, fn :channel_id, message ->
        assert message =~ ~r/Wordle 24/
      end)

      assert :ok = ResumeCommand.run(message, [])

      assert [{pid, _}] = Registry.lookup(Server.registry, user_id)
      assert state = :sys.get_state(pid)

      assert state.handler             == Rem.Commands.Wordle.PlayCommand
      assert state.value.channel_id    == :channel_id
      assert state.value.game.mode     == :hard
      assert state.value.game.number   == 24
      assert state.value.game.solution == "tacos"
    end
  end

  describe "error cases" do
    test "user already has a session", %{message: message, user_id: user_id} do
      {:ok, _pid} = Rem.Sessions.WordleSession.new(user_id, nil)

      Rem.Discord.Api
      |> expects(:create_message, fn :channel_id, message ->
        assert message =~ ~r/We are already playing a game!/
      end)

      assert {:error, :session_already_exists} = ResumeCommand.run(message, [])
    end

    test "user has no unfinished game", %{message: message} do
      Rem.Discord.Api
      |> expects(:create_message, fn :channel_id, message ->
        assert message =~ ~r/we don't have an unfinished game/
      end)

      assert {:error, :no_unfinished_game} = ResumeCommand.run(message, [])
    end
  end
end
