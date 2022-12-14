defmodule Rem.Commands.Wordle.StartCommandTest do
  use Rem.DataCase, async: true

  use Injector, inject: [Rem.Discord.Api]

  alias Rem.Repo
  alias Rem.Sessions.Server

  alias Rem.Commands.Wordle.StartCommand

  setup do
    user_id = 123_456_789
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
    test "starts a game with default arguments", %{user_id: user_id, message: message} do
      number = Wordle.default_id
      insert(:wordle_solution, number: number, name: "perky")

      Rem.Discord.Api
      |> expects(:create_message, fn :channel_id, message ->
        assert message =~ ~r/Wordle #{number}/
      end)

      assert :ok = StartCommand.run(message, [])

      assert record = Repo.one(Schema.Wordle.Game)
      assert record.mode     == :normal
      assert record.number   == number
      assert record.solution == "perky"
      assert record.state    == :active

      assert [{pid, _}] = Registry.lookup(Server.registry, user_id)
      assert state = :sys.get_state(pid)

      assert state.handler             == Rem.Commands.Wordle.PlayCommand
      assert state.value.channel_id    == :channel_id
      assert state.value.game.mode     == :normal
      assert state.value.game.number   == number
      assert state.value.game.solution == "perky"
    end

    test "starts a game in hard mode", %{message: message, user_id: user_id} do
      number = Wordle.default_id
      insert(:wordle_solution, number: number, name: "perky")

      Rem.Discord.Api
      |> expects(:create_message, fn :channel_id, message ->
        assert message =~ ~r/Wordle #{number}/
      end)

      assert :ok = StartCommand.run(message, ["hard"])

      assert record = Repo.one(Schema.Wordle.Game)
      assert record.number == number
      assert record.state  == :active
      assert record.mode   == :hard

      assert [{pid, _}] = Registry.lookup(Server.registry, user_id)
      assert state = :sys.get_state(pid)

      assert state.handler           == Rem.Commands.Wordle.PlayCommand
      assert state.value.channel_id  == :channel_id
      assert state.value.game.mode   == :hard
      assert state.value.game.number == number
    end

    test "starts a game with a specific numeric id", %{message: message, user_id: user_id} do
      number = 120
      insert(:wordle_solution, number: number, name: "perky")

      Rem.Discord.Api
      |> expects(:create_message, fn :channel_id, message ->
        assert message =~ ~r/Wordle #{number}/
      end)

      assert :ok = StartCommand.run(message, ["normal", "#{number}"])

      assert record = Repo.one(Schema.Wordle.Game)
      assert record.mode     == :normal
      assert record.number   == number
      assert record.solution == "perky"
      assert record.state    == :active

      assert [{pid, _}] = Registry.lookup(Server.registry, user_id)
      assert state = :sys.get_state(pid)

      assert state.handler             == Rem.Commands.Wordle.PlayCommand
      assert state.value.channel_id    == :channel_id
      assert state.value.game.mode     == :normal
      assert state.value.game.number   == number
      assert state.value.game.solution == "perky"
    end

    test "starts a game with a specific date", %{message: message, user_id: user_id} do
      {:ok, date} = Date.new(2022, 01, 01)
      number      = Wordle.date_to_id(date)
      insert(:wordle_solution, number: number, name: "perky")

      Rem.Discord.Api
      |> expects(:create_message, fn :channel_id, message ->
        assert message =~ ~r/Wordle #{number}/
      end)

      assert :ok = StartCommand.run(message, ["hard", Date.to_iso8601(date)])

      assert record = Repo.one(Schema.Wordle.Game)
      assert record.number == number
      assert record.state  == :active
      assert record.mode   == :hard

      assert [{pid, _}] = Registry.lookup(Server.registry, user_id)
      assert state = :sys.get_state(pid)

      assert state.handler           == Rem.Commands.Wordle.PlayCommand
      assert state.value.channel_id  == :channel_id
      assert state.value.game.mode   == :hard
      assert state.value.game.number == number
    end
  end

  describe "error cases" do
    test "args are not in the correct format", %{message: message} do
      Rem.Discord.Api
      |> expects(:create_message, fn :channel_id, message ->
        assert message =~ ~r/You can see the accepted arguments here/
      end)

      assert {:error, :invalid_arg_format} = StartCommand.run(message, ["weird", "args"])
    end

    test "user already has a session", %{message: message, user_id: user_id} do
      {:ok, _pid} = Rem.Sessions.WordleSession.new(user_id, nil)

      Rem.Discord.Api
      |> expects(:create_message, fn :channel_id, message ->
        assert message =~ ~r/We are already playing a game!/
      end)

      assert {:error, :session_already_exists} = StartCommand.run(message, [])
    end

    test "user left an unfinished game", %{message: message, user_id: user_id} do
      insert(:wordle_game, discord_user_id: user_id, state: :active)

      Rem.Discord.Api
      |> expects(:create_message, fn :channel_id, message ->
        assert message =~ ~r/we have an unfinished game/
      end)

      assert {:error, :has_unfinished_game} = StartCommand.run(message, [])
    end

    test "user already played requested game", %{message: message, user_id: user_id} do
      insert(:wordle_game, discord_user_id: user_id, state: :win, number: 20)

      Rem.Discord.Api
      |> expects(:create_message, fn :channel_id, message ->
        assert message =~ ~r/we already played this game/
      end)

      assert {:error, {:has_played_game, _number}} = StartCommand.run(message, ["normal", "20"])
    end
  end
end
