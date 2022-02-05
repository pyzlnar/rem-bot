defmodule Rem.Models.Wordle.Game do
  use Rem.Schema

  @type t :: %__MODULE__{
    id:              Ecto.UUID.t,
    discord_user_id: non_neg_integer,

    number:      non_neg_integer,
    solution:    String.t,
    mode:        mode,
    state:       state,
    attempts:    [String.t],
    evaluations: [evaluation],

    inserted_at: DateTime.t,
    updated_at:  DateTime.t
  }

  @type evaluation :: [:absent | :present | :correct]
  @type mode       :: :normal | :hard
  @type state      :: :active | :win | :lose

  schema "wordle_games" do
    field :discord_user_id, :integer

    field :number,   :integer,  null: false
    field :solution, :string,   null: false
    field :mode,     Ecto.Enum, default: :normal, values: ~W[normal hard]a
    field :state,    Ecto.Enum, default: :active, values: ~W[active win lose]a

    field :attempts,    {:array, :string},             null: false
    field :evaluations, {:array, {:array, Ecto.Enum}}, null: false, values: ~W[absent present correct]a

    timestamps()
  end

  def new do
    %__MODULE__{}
  end

  def insert_changeset(user_id, %Rem.Wordle.Game{} = game) do
    new()
    |> cast_from_game(game)
    |> put_change(:discord_user_id, user_id)
  end

  def update_changeset(%__MODULE__{} = record, %Rem.Wordle.Game{} = game) do
    record
    |> cast_from_game(game)
  end

  defp cast_from_game(%__MODULE__{} = record, %Rem.Wordle.Game{} = game) do
    cast(
      record,
      Map.from_struct(game),
      ~W[number solution mode state attempts evaluations]a
    )
  end
end
