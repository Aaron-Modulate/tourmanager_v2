defmodule TourmanagerV2.Repo.Migrations.CreatePowerServices do
  use Ecto.Migration

  def change do
    create table(:power_services, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :phase_type, :string, null: false, default: "single_phase"
      add :amps, :integer
      add :voltage, :integer
      add :connector_type, :string
      add :location, :string
      add :notes, :text
      add :venue_id, references(:venues, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:power_services, [:venue_id])
    create index(:power_services, [:phase_type])
  end
end
