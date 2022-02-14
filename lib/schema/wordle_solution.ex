defmodule Schema.Wordle.Solution do
  use Rem.Schema

  schema "wordle_solutions" do
    field :name,   :string
    field :number, :integer

    timestamps()
  end
end
