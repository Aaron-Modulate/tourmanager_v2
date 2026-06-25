defmodule TourmanagerV2.Repo.Migrations.FixRouteEntriesVenueImageUrlLength do
  use Ecto.Migration

  def change do
    alter table(:route_entries) do
      modify :venue_image_url, :text, from: :string
    end
  end
end
