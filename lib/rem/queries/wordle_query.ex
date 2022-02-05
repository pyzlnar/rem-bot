defmodule Rem.Queries.WordleQuery do
  alias Rem.Repo
  alias Rem.Models.Wordle.{Game, Word, Solution}

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

  @spec solutions_length() :: pos_integer
  def solutions_length do
    1 + (Repo.one(from s in Solution, select: max(s.number)) || 0)
  end

  # --- CREATE --- #

  @spec create_game(non_neg_integer, Rem.Wordle.Game.t) :: {:ok, Ecto.Schema.t} | {:error, Ecto.Changeset.t}
  def create_game(user_id, game) do
    Game.insert_changeset(user_id, game)
    |> Repo.insert
  end

  # --- UPDATE --- #

  @spec update_game(non_neg_integer, Rem.Wordle.Game.t) :: {:ok, Ecto.Schema.t} | {:error, Ecto.Changeset.t}
  def update_game(user_id, game) do
    fetch_game(user_id, number: game.number)
    |> Game.update_changeset(game)
    |> Repo.update
  end

  # --- Fragments --- #

  defp game_query(user_id, wheres) do
    wheres = Keyword.merge(wheres, discord_user_id: user_id)

    Game |> where(^wheres)
  end
end
