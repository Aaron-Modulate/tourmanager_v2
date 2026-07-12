defmodule TourmanagerV2.Production.TourProductionRequirement do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tour_production_requirements" do
    field :minimum_stage_width_m, :float
    field :minimum_stage_depth_m, :float
    field :minimum_trim_height_m, :float
    field :required_three_phase_amps, :integer
    field :required_rigging_points, :integer
    field :required_total_rigging_capacity_kg, :float
    field :notes, :string

    belongs_to :tour, TourmanagerV2.Touring.Tour

    timestamps()
  end

  def changeset(requirement, attrs) do
    requirement
    |> cast(attrs, [:minimum_stage_width_m, :minimum_stage_depth_m, :minimum_trim_height_m,
                    :required_three_phase_amps, :required_rigging_points,
                    :required_total_rigging_capacity_kg, :notes])
    |> validate_number(:minimum_stage_width_m, greater_than: 0)
    |> validate_number(:minimum_stage_depth_m, greater_than: 0)
    |> validate_number(:minimum_trim_height_m, greater_than: 0)
    |> validate_number(:required_three_phase_amps, greater_than: 0)
    |> validate_number(:required_rigging_points, greater_than: 0)
    |> validate_number(:required_total_rigging_capacity_kg, greater_than: 0)
    |> unique_constraint(:tour_id)
  end
end
