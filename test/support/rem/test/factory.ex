defmodule Rem.Test.Factory do
  @moduledoc """
  This module handles ex-machina's factory declaration.
  It is intended for factory declaration _only_, if you want to create cases that
  require insertions or multiple build, write it in Rem.Test.Scenario instead.
  """

  use ExMachina.Ecto,
    repo: Rem.Repo

  alias Rem.Models

  def wordle_solution_factory do
    %Models.Wordle.Solution{
      number: sequence(:number, Enum.to_list(0..2314)),
      name:   sequence(:name, &number_to_string/1, start_at: 10_000)
    }
  end

  def wordle_word_factory do
    %Models.Wordle.Word{
      name: sequence(:name, &number_to_string/1, start_at: 10_000)
    }
  end

  # --- Helpers --- #

  defp number_to_string(number) do
    number
    |> Integer.digits
    |> Enum.map(&(&1 + ?a))
    |> List.to_string
  end
end
