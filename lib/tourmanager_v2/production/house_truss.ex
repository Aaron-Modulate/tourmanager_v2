defmodule TourmanagerV2.Production.HouseTruss do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @positions ~w(foh midstage upstage side ground_support other)

  schema "house_trusses" do
    field :name, :string
    field :position, :string, default: "other"
    field :length_m, :float
    field :trim_height_m, :float
    field :max_load_kg, :float
    field :notes, :string

    belongs_to :venue, TourmanagerV2.Production.Venue

    timestamps()
  end

  def changeset(truss, attrs) do
    truss
    |> cast(attrs, [:name, :position, :length_m, :trim_height_m, :max_load_kg, :notes])
    |> validate_required([:name])
    |> validate_inclusion(:position, @positions)
    |> validate_number(:length_m, greater_than: 0)
    |> validate_number(:trim_height_m, greater_than: 0)
    |> validate_number(:max_load_kg, greater_than: 0)
  end
end
