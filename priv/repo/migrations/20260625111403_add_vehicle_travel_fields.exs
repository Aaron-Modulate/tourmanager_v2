defmodule TourmanagerV2.Repo.Migrations.AddVehicleTravelFields do
  use Ecto.Migration

  def change do
    alter table(:route_entries) do
      add :origin_place_id, :string
      add :origin_lat, :float
      add :origin_lng, :float
      add :origin_address, :string
      add :dest_place_id, :string
      add :dest_lat, :float
      add :dest_lng, :float
      add :dest_address, :string
      add :travel_duration_seconds, :integer
      add :booking_reference, :string
    end

    execute "UPDATE route_entries SET type = 'vehicle_travel' WHERE type = 'travel'",
            "UPDATE route_entries SET type = 'travel' WHERE type = 'vehicle_travel'"
  end
end
