defmodule Rem.Repo.Migrations.CreateWordleSolutions do
  use Ecto.Migration

  def change do
    create table(:wordle_solutions) do
      add :number, :integer, null: false
      add :name,   :string,  null: false

      timestamps()
    end

    create index(:wordle_solutions, [:number], unique: true)
    create index(:wordle_solutions, [:name],   using: :gin)
  end
end
