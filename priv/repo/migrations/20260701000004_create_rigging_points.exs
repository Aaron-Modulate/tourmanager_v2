defmodule TourmanagerV2.Repo.Migrations.CreateRiggingPoints do
  use Ecto.Migration

  def change do
    create table(:rigging_points, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :label, :string, null: false
      add :x_m, :float
      add :y_m, :float
      add :safe_working_load_kg, :float
      add :motor_available, :boolean, default: false
      add :motor_capacity_kg, :float
      add :notes, :text
      add :venue_id, references(:venues, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:rigging_points, [:venue_id])
  end
end
