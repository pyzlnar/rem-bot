defmodule Rem.Commands.Wordle.PlayCommandTest do
  use Rem.DataCase, async: true

  use Injector, inject: [Rem.Discord.Api]

  alias Rem.Repo
  alias Rem.Sessions.Server

  alias Rem.Commands.Wordle.PlayCommand

  describe "should_run?/1" do
    test "returns :ok and the state's value if the session exists and the channel matches" do
      user_id    = make_ref()
      channel_id = 100_000
      message    = %{author: %{id: user_id}, channel_id: channel_id}

      sent_state = %{game: :game, channel_id: channel_id}
      {:ok, pid} = Server.new(user_id, value: sent_state)

      assert {:ok, state} = PlayCommand.should_run?(message)

      assert state.channel_id == 100_000
      assert state.game       == :game

      Process.exit(pid, :kill)
    end

    test "returns :noop if the either there's no session, or channel_id's don't match" do
      user_id    = make_ref()
      message    = %{author: %{id: user_id}, channel_id: 100_00}

      # No session
      assert :noop = PlayCommand.should_run?(message)

      sent_state = %{game: :game, channel_id: 200_000}
      {:ok, pid} = Server.new(user_id, value: sent_state)

      # Channel doesn't match
      assert :noop = PlayCommand.should_run?(message)

      Process.exit(pid, :kill)
    end
  end

  describe "run/2 happy paths" do
    setup do
      user_id    = 100_000
      channel_id = make_ref()
      number     = 23

      insert(:wordle_word, name: "fried")
      insert(:wordle_word, name: "tacos")
      insert(:wordle_game, solution: "tacos", discord_user_id: user_id, number: number)

      message = %{author: %{id: user_id}, channel_id: channel_id}
      game    = Wordle.Game.new(%{solution: "tacos", number: number})

      state = %{game: game}
      {:ok, pid} = Server.new(user_id, value: state)

      on_exit fn ->
        Process.exit(pid, :kill)
      end

      %{message: message, state: state, spid: pid}
    end

    test "moves the game to the next state", %{message: message, state: state, spid: spid} do
      attempt = "fried"
      message = Map.put(message, :content, attempt)
      channel_id = message.channel_id

      Rem.Discord.Api
      |> expects(:create_message, fn ^channel_id, message ->
        assert message =~ ~r/Wordle #{state.game.number}/
      end)

      assert :ok = PlayCommand.run(message, state)

      session = :sys.get_state(spid)
      s_game  = session.value.game

      assert s_game.attempts    == ["fried"]
      assert s_game.evaluations == [~W[absent absent absent absent absent]a]
      assert s_game.state       == :active

      record = Repo.one(Schema.Wordle.Game)
      assert record.attempts    == ["fried"]
      assert record.evaluations == [~W[absent absent absent absent absent]a]
      assert record.state       == :active
    end

    test "ends the game if it's won", %{message: message, state: state, spid: spid} do
      attempt = "tacos"
      message = Map.put(message, :content, attempt)
      channel_id = message.channel_id

      Rem.Discord.Api
      |> expects(:create_message, fn ^channel_id, message ->
        assert message =~ ~r/You win/
        assert message =~ ~r/Wordle #{state.game.number}/
      end)

      assert :ok = PlayCommand.run(message, state)

      record = Repo.one(Schema.Wordle.Game)
      assert record.attempts    == ["tacos"]
      assert record.evaluations == [~W[correct correct correct correct correct]a]
      assert record.state       == :win

      refute Process.alive?(spid)
    end

    test "ends the game if it's lost", %{message: message, state: state, spid: spid} do
      attempt = "fried"
      message = Map.put(message, :content, attempt)
      channel_id = message.channel_id

      attempts    = ~W[fried fried fried fried fried]
      evaluations = [
        ~W[absent absent absent absent absent]a,
        ~W[absent absent absent absent absent]a,
        ~W[absent absent absent absent absent]a,
        ~W[absent absent absent absent absent]a,
        ~W[absent absent absent absent absent]a
      ]

      game = %{state.game|attempts: attempts, evaluations: evaluations}

      Rem.Discord.Api
      |> expects(:create_message, fn ^channel_id, message ->
        assert message =~ ~r/Better luck/
        assert message =~ ~r/Wordle #{state.game.number}/
      end)

      assert :ok = PlayCommand.run(message, %{game: game})

      record = Repo.one(Schema.Wordle.Game)
      assert length(record.attempts)    == 6
      assert length(record.evaluations) == 6
      assert record.state               == :lose

      refute Process.alive?(spid)
    end
  end

  describe "run/2 error cases" do
    test "returns :invalid_word if the word is not in the list" do
      user_id    = 100_000
      channel_id = 123_456
      number     = 23
      attempt    = "fried"

      insert(:wordle_game, solution: "tacos", discord_user_id: user_id, number: number)

      message = %{author: %{id: user_id}, channel_id: channel_id, content: attempt}
      game    = Wordle.Game.new(%{solution: "tacos", number: number})

      {:ok, pid} = Server.new(user_id, value: %{game: game})

      Rem.Discord.Api
      |> expects(:create_message, fn ^channel_id, message ->
        assert message =~ ~r/'#{attempt}' is not in the word list/
      end)

      assert {:error, {:invalid_word, "fried"}} = PlayCommand.run(message, %{game: game})

      Process.exit(pid, :kill)
    end

    test "returns :invalid_attempt if the attempt does not comply with hard mode" do
      user_id    = 100_000
      channel_id = 123_456
      number     = 23
      attempt    = "fried"

      insert(:wordle_word, name: "fried")
      insert(:wordle_game, solution: "tacos", discord_user_id: user_id, number: number)

      attempts = ["tally"]
      evaluations = [~W[correct correct absent absent absent]a]

      message = %{author: %{id: user_id}, channel_id: channel_id, content: attempt}
      game    = Wordle.Game.new(%{solution: "tacos", number: number})
      game    = %{game|attempts: attempts, evaluations: evaluations, mode: :hard}

      {:ok, pid} = Server.new(user_id, value: %{game: game})

      Rem.Discord.Api
      |> expects(:create_message, fn ^channel_id, message ->
        assert message =~ ~r/hard mode/
        assert message =~ ~r/'#{attempt}'/
      end)

      assert {:error, {:invalid_attempt, "fried"}} = PlayCommand.run(message, %{game: game})

      Process.exit(pid, :kill)
    end
  end
end
