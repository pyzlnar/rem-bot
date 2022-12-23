defmodule Rem.Commands.Wordle.StatsCommand do
  use Rem.Command, type: :prefix

  import Rem.I18n
  import Rem.Commands.Utils

  alias Rem.Discord.Api
  alias Rem.Queries.WordleQuery

  @impl true
  def run(%{channel_id: channel_id, author: %{id: user_id}}, _args) do
    with :ok             <- has_games?(user_id),
         {:ok, db_stats} <- get_stats_from_db(user_id),
         {:ok, stats}    <- process_stats(db_stats)
    do
      Api.create_message(channel_id, dgettext("wordle", "stats", stats))
    else
      {:error, :user_has_no_games} ->
        Api.create_message(channel_id, dgettext("wordle", "error:has_no_games"))

      error ->
        handle_unknown_error(__MODULE__, channel_id, error)
    end
  end

  defp has_games?(user_id) do
    if WordleQuery.game_exists?(user_id),
      do:   :ok,
      else: {:error, :user_has_no_games}
  end

  defp get_stats_from_db(user_id) do
    game_stats    = WordleQuery.game_stats(user_id)
    attempt_stats = WordleQuery.attempt_stats(user_id)
    first_attempt = WordleQuery.first_attempt_stats(user_id)

    %{
      game_stats:    game_stats,
      attempt_stats: attempt_stats,
      first_attempt: first_attempt
    }
    |> then(&{:ok, &1})
  end

  defp process_stats(db_stats) do
    %{
      game_stats:    game_stats,
      first_attempt: first_attempt,
      attempt_stats: attempt_stats
    } = db_stats

    []
    |> Keyword.merge(process_game_stats(game_stats))
    |> Keyword.merge(process_guess_distribution(game_stats))
    |> Keyword.merge(process_first_attempts(first_attempt))
    |> Keyword.merge(process_attempts(attempt_stats))
    |> then(&{:ok, &1})
  end

  defp process_game_stats(game_stats) do
    %{win: won, lose: lost} = Enum.group_by(game_stats, & &1.state)

    games_won_count  = Enum.reduce(won,  0, & &1.count + &2)
    games_lost_count = Enum.reduce(lost, 0, & &1.count + &2)

    games_played = games_won_count + games_lost_count

    games_won_per  = (100 * games_won_count / games_played) |> Float.round(2)
    games_lost_per = (100 - games_won_per) |> Float.round(2)

    """
    Total Games Played: #{games_played}

    Games Won: #{games_won_count} (#{games_won_per}%)
    #{percentage_to_bar(games_won_per)}
    Games Lost: #{games_lost_count} (#{games_lost_per}%)
    #{percentage_to_bar(games_lost_per)}
    """
    |> then(&[general_stats: &1])
  end

  defp process_guess_distribution(game_stats) do
    games_won = Enum.filter(game_stats, & &1.state == :win)
    games_won_count = Enum.reduce(games_won,  0, & &1.count + &2)

    tries_with_pers = Enum.map(games_won, fn trie ->
      per = (100 * trie.count / games_won_count) |> Float.round(2)
      Map.put(trie, :per, per)
    end)

    per_sum = Enum.reduce(tries_with_pers, 0, & &1.per + &2)

    tries_with_pers =
      if per_sum == 100 || per_sum == 0 do
        tries_with_pers
      else
        [last | rest] = Enum.reverse(tries_with_pers)
        diff = 100 - per_sum
        nper = (last.per + diff) |> Float.round(2)
        last = %{last|per: nper}
        [last | rest] |> Enum.reverse
      end

    tries_map = Map.new(tries_with_pers, &{&1.tries, &1})

    1..6
    |> Enum.map(fn i ->
      trie = Map.get(tries_map, i, %{count: 0, per: 0})
      bar  = trie.per |> percentage_to_bar |> String.pad_trailing(20, " ")

      "#{i}: #{bar} #{trie.count} (#{trie.per}%)"
    end)
    |> Enum.join("\n")
    |> then(&[guess_distribution: &1])
  end

  defp process_first_attempts(first_attempts) do
    first_attempts
    |> Enum.map(&"- #{&1.attempt}: #{&1.count} #{pluralize("time", &1.count)}")
    |> Enum.join("\n")
    |> then(&[first_attempts: &1])
  end

  defp process_attempts(attempts) do
    attempts
    |> Enum.map(&"- #{&1.attempt}: #{&1.count} #{pluralize("game", &1.count)}")
    |> Enum.join("\n")
    |> then(&[attempts: &1])
  end

  @bar_char "■" # lol
  defp percentage_to_bar(percentage) do
    (percentage * 0.2)
    |> Float.round
    |> trunc
    |> then(&String.duplicate(@bar_char, &1))
  end

  defp pluralize(word, count) when count > 1, do: "#{word}s"
  defp pluralize(word, _), do: word
end
