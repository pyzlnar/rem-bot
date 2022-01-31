defmodule Rem.Queries.WordleQuery do
  alias Rem.Repo
  alias Rem.Models.Wordle.{Word, Solution}

  import Ecto.Query

  @spec fetch_solution(non_neg_integer) :: Solution.t() | nil
  def fetch_solution(number) do
    Repo.one(
      from s in Solution,
      select: %{number: s.number, solution: s.name},
      where:  s.number == ^number
    )
  end

  @spec word_exists?(String.t()) :: boolean
  def word_exists?(word) do
    Repo.exists?(
      from w in Word,
      where: w.name == ^word
    )
  end
end
