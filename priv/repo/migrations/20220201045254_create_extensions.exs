defmodule Rem.Repo.Migrations.CreateExtensions do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
    execute "CREATE EXTENSION IF NOT EXISTS btree_gin;"
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
  end

  def down do
    :noop
  end
end
