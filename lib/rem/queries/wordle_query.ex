defmodule Rem.Queries.WordleQuery do
  alias Rem.Repo
  alias Schema.Wordle.{Game, Word, Solution}

  import Ecto.Query

  # --- GET --- #

  @spec fetch_solution(non_neg_integer) :: Solution.t | nil
  def fetch_solution(number) do
    Repo.one(
      from s in Solution,
      select: %{number: s.number, solution: s.name},
      where:  s.number == ^number
    )
  end

  @spec fetch_game(non_neg_integer, list) :: Game.t | nil
  def fetch_game(user_id, wheres \\ []) do
    game_query(user_id, wheres)
    |> Repo.one
  end

  @spec word_exists?(String.t) :: boolean
  def word_exists?(word) do
    Repo.exists?(
      from w in Word,
      where: w.name == ^word
    )
  end

  @spec game_exists?(non_neg_integer, list) :: boolean
  def game_exists?(user_id, wheres \\ []) do
    game_query(user_id, wheres)
    |> Repo.exists?
  end

  @spec last_saved_solution() :: pos_integer
  def last_saved_solution do
    (Repo.one(from s in Solution, select: max(s.number)) || 0)
  end

  @type game_stat :: %{
    state: :win | :lose,
    tries: non_neg_integer,
    count: non_neg_integer
  }

  @spec game_stats(non_neg_integer) :: [game_stat]
  def game_stats(user_id) do
    sub =
      from g in completed_games(user_id),
      select: %{
        state: g.state,
        tries: fragment("array_length(?.attempts, 1)", g)
      }

    Repo.all(
      from g in subquery(sub),
      group_by: [g.state, g.tries],
      order_by: [asc: g.state, asc: g.tries],
      select: %{
        state: g.state,
        tries: g.tries,
        count: count(g.tries)
      }
    )
  end

  @type attempt_count :: %{attempt: String.t, count: non_neg_integer}

  @spec attempt_stats(non_neg_integer) :: [attempt_count]
  def attempt_stats(user_id) do
    user_id
    |> completed_games
    |> select([q], %{attempt: fragment("unnest(?.attempts)", q)})
    |> get_attempt_counts
    |> limit(5)
    |> Repo.all
  end

  @spec attempt_stats(non_neg_integer) :: [attempt_count]
  def first_attempt_stats(user_id) do
    user_id
    |> completed_games
    |> select([g], %{attempt: fragment("?.attempts[array_upper(?.attempts, 1)]", g, g)})
    |> get_attempt_counts
    |> limit(3)
    |> Repo.all
  end

  # --- CREATE --- #

  @spec create_game(non_neg_integer, Wordle.Game.t) :: {:ok, Ecto.Schema.t} | {:error, Ecto.Changeset.t}
  def create_game(user_id, game) do
    Game.insert_changeset(user_id, game)
    |> Repo.insert
  end

  # --- UPDATE --- #

  @spec update_game(non_neg_integer, Wordle.Game.t) :: {:ok, Ecto.Schema.t} | {:error, Ecto.Changeset.t}
  def update_game(user_id, game) do
    fetch_game(user_id, number: game.number)
    |> Game.update_changeset(game)
    |> Repo.update
  end

  # --- Fragments --- #

  defp game_query(user_id, wheres \\ []) do
    wheres = Keyword.merge(wheres, discord_user_id: user_id)

    Game |> where(^wheres)
  end

  defp completed_games(user_id) do
    user_id
    |> game_query
    |> where([g], g.state in [:win, :lose])
  end

  defp get_attempt_counts(query) do
    from q in subquery(query),
    group_by: [q.attempt],
    order_by: [desc: count(q.attempt), asc: q.attempt],
    select:   %{attempt: q.attempt, count: count(q.attempt)}
  end
end
