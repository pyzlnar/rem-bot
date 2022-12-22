defmodule Rem.Commands.Wordle.StatsCommandTest do
  use Rem.DataCase, async: true

  use Injector, inject: [Rem.Discord.Api]

  alias Rem.Commands.Wordle.StatsCommand

  describe "run/2" do
    setup do
      user_id = 954_213
      message = %{channel_id: :channel_id, author: %{id: user_id}}
      insert_stats_scenario(user_id)

      {:ok, %{user_id: user_id, message: message}}
    end

    test "sends a message with your stats", ctx do
      %{message: message} = ctx

      Rem.Discord.Api
      |> expects(:create_message, fn :channel_id, message ->
        assert message =~ ~r/^Total Games Played: 6/m
        assert message =~ ~r/^Games Won: 4 \(66.67%\)/m
        assert message =~ ~r/^Games Lost: 2 \(33.33%\)/m

        assert message =~ ~r/^1: \s{20} 0 \(0%\)/m
        assert message =~ ~r/^2: \s{20} 0 \(0%\)/m
        assert message =~ ~r/^3: ■{10}\s{10} 2 \(50.0%\)/mu
        assert message =~ ~r/^4: ■{5}\s{15} 1 \(25.0%\)/mu
        assert message =~ ~r/^5: \s{20} 0 \(0%\)/m
        assert message =~ ~r/^6: ■{5}\s{15} 1 \(25.0%\)/mu

        assert message =~ ~r/^- six: 3 times/m
        assert message =~ ~r/^- three: 2 times/m
        assert message =~ ~r/^- four: 1 time/m

        assert message =~ ~r/^- one: 6 games/m
        assert message =~ ~r/^- three: 6 games/m
        assert message =~ ~r/^- two: 6 games/m
        assert message =~ ~r/^- four: 4 games/m
        assert message =~ ~r/^- five: 3 games/m
        :ok
      end)

      assert :ok = StatsCommand.run(message, [])
    end

    test "sends a message if the user has played no games" do
      message = %{channel_id: :channel_id, author: %{id: -1}}

      Rem.Discord.Api
      |> expects(:create_message, fn :channel_id, message ->
        assert message == "You have not played any games yet!"
        :ok
      end)

      assert :ok = StatsCommand.run(message, [])
    end
  end
end
