defmodule TourmanagerV2.Repo.Migrations.AddRouteEntriesAndDistanceUnit do
  use Ecto.Migration

  def change do
    create table(:route_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string, null: false
      add :date, :date, null: false
      add :venue, :string
      add :city, :string
      add :venue_code, :string
      add :origin, :string
      add :destination, :string
      add :notes, :string
      add :distance_km, :integer
      add :venue_image_url, :string
      add :place_id, :string
      add :lat, :float
      add :lng, :float
      add :sort_order, :integer, default: 0

      add :tour_id, references(:tours, type: :binary_id, on_delete: :delete_all), null: false
      add :workspace_id, references(:workspaces, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:route_entries, [:tour_id])
    create index(:route_entries, [:tour_id, :date])

    alter table(:users) do
      add :distance_unit, :string, null: false, default: "km"
    end
  end
end
