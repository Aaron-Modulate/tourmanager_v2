defmodule TourmanagerV2.Repo.Migrations.CreateLoadingAccesses do
  use Ecto.Migration

  def change do
    create table(:loading_accesses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :dock_available, :boolean, default: false
      add :truck_access_notes, :text
      add :max_vehicle_height_m, :float
      add :lift_available, :boolean, default: false
      add :parking_notes, :text
      add :notes, :text
      add :venue_id, references(:venues, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:loading_accesses, [:venue_id])
  end
end
