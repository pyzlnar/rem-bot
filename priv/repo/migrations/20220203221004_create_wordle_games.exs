defmodule Rem.Repo.Migrations.CreateWordleGames do
  use Ecto.Migration

  def up do
    execute "CREATE TYPE wordle_game_evaluation AS ENUM ('absent', 'present', 'correct')"
    execute "CREATE TYPE wordle_game_mode       AS ENUM ('normal', 'hard')"
    execute "CREATE TYPE wordle_game_state      AS ENUM ('active', 'win', 'lose')"

    create table(:wordle_games) do
      add :number,   :integer, null: false
      add :solution, :string,  null: false

      add :mode,  :wordle_game_mode,  default: "normal"
      add :state, :wordle_game_state, default: "active"

      add :attempts,    {:array, :string},                           null: false, default: []
      add :evaluations, {:array, {:array, :wordle_game_evaluation}}, null: false, default: []

      add :discord_user_id, :bigint, null: false

      timestamps()
    end

    create index(:wordle_games, [:number])
    create index(:wordle_games, [:discord_user_id])
  end

  def down do
    drop table(:wordle_games)

    execute "DROP TYPE IF EXISTS wordle_game_evaluation"
    execute "DROP TYPE IF EXISTS wordle_game_mode"
    execute "DROP TYPE IF EXISTS wordle_game_state"
  end
end
