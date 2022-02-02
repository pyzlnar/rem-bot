defmodule Rem.Repo.Migrations.CreateWordleWords do
  use Ecto.Migration

  def change do
    create table(:wordle_words) do
      add :name, :string, null: false

      timestamps()
    end

    create index(:wordle_words, [:name], using: :gin)
  end
end
