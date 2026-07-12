defmodule TourmanagerV2.Production.RiggingPoint do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "rigging_points" do
    field :label, :string
    field :x_m, :float
    field :y_m, :float
    field :safe_working_load_kg, :float
    field :motor_available, :boolean, default: false
    field :motor_capacity_kg, :float
    field :notes, :string

    belongs_to :venue, TourmanagerV2.Production.Venue

    timestamps()
  end

  def changeset(point, attrs) do
    point
    |> cast(attrs, [:label, :x_m, :y_m, :safe_working_load_kg, :motor_available, :motor_capacity_kg, :notes])
    |> validate_required([:label])
    |> validate_number(:safe_working_load_kg, greater_than: 0)
    |> validate_number(:motor_capacity_kg, greater_than: 0)
  end
end
