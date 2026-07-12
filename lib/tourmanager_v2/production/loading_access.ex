defmodule TourmanagerV2.Production.LoadingAccess do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "loading_accesses" do
    field :dock_available, :boolean, default: false
    field :truck_access_notes, :string
    field :max_vehicle_height_m, :float
    field :lift_available, :boolean, default: false
    field :parking_notes, :string
    field :notes, :string

    belongs_to :venue, TourmanagerV2.Production.Venue

    timestamps()
  end

  def changeset(access, attrs) do
    access
    |> cast(attrs, [:dock_available, :truck_access_notes, :max_vehicle_height_m,
                    :lift_available, :parking_notes, :notes])
    |> validate_number(:max_vehicle_height_m, greater_than: 0)
    |> unique_constraint(:venue_id)
  end
end
