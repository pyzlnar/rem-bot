defmodule Rem.Test.Factory do
  @moduledoc """
  This module handles ex-machina's factory declaration.
  It is intended for factory declaration _only_, if you want to create cases that
  require insertions or multiple build, write it in Rem.Test.Scenario instead.
  """

  use ExMachina.Ecto,
    repo: Rem.Repo

  # --- Database Models --- #

  def wordle_game_factory do
    %Schema.Wordle.Game{
      discord_user_id: sequence(:discord_user_id, &int/1),
      number:          sequence(:number,          &int/1),
      solution:        sequence(:solution,        &int_to_word/1, start_at: 10_000),
      mode:            :normal,
      state:           :active,
      attempts:        [],
      evaluations:     []
    }
  end

  def wordle_solution_factory do
    %Schema.Wordle.Solution{
      number: sequence(:number, &int/1),
      name:   sequence(:name,   &int_to_word/1, start_at: 10_000)
    }
  end

  def wordle_word_factory do
    %Schema.Wordle.Word{
      name: sequence(:name, &int_to_word/1, start_at: 10_000)
    }
  end

  # --- Virtual Models --- #

  def virtual_game_factory do
    %Wordle.Game{
      number:          sequence(:number,   &int/1),
      solution:        sequence(:solution, &int_to_word/1, start_at: 10_000),
      mode:            :normal,
      state:           :active,
      attempts:        [],
      evaluations:     []
    }
  end

  # --- Helpers --- #

  defp int(int), do: int

  defp int_to_word(int) do
    int
    |> Integer.digits
    |> Enum.map(&(&1 + ?a))
    |> List.to_string
  end
end
