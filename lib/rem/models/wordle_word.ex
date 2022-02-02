defmodule Rem.Models.Wordle.Word do
  use Rem.Schema

  schema "wordle_words" do
    field :name, :string

    timestamps()
  end
end
