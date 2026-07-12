defmodule TourmanagerV2.Repo.Migrations.CreateTourProductionRequirements do
  use Ecto.Migration

  def change do
    create table(:tour_production_requirements, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :minimum_stage_width_m, :float
      add :minimum_stage_depth_m, :float
      add :minimum_trim_height_m, :float
      add :required_three_phase_amps, :integer
      add :required_rigging_points, :integer
      add :required_total_rigging_capacity_kg, :float
      add :notes, :text
      add :tour_id, references(:tours, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:tour_production_requirements, [:tour_id])
  end
end
