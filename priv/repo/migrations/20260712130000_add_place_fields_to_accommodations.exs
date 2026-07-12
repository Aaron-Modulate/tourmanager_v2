defmodule TourmanagerV2.Repo.Migrations.AddPlaceFieldsToAccommodations do
  use Ecto.Migration

  def change do
    alter table(:accommodations) do
      add :place_id, :string
      add :lat, :float
      add :lng, :float
    end
  end
end
