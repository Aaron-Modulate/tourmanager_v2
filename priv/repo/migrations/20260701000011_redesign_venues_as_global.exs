defmodule TourmanagerV2.Repo.Migrations.RedesignVenuesAsGlobal do
  use Ecto.Migration

  def up do
    # Truncate all production data — seed data only at this stage
    execute "TRUNCATE TABLE production_data_suggestions, production_documents, house_lighting_fixtures, loading_accesses, power_services, house_trusses, rigging_points, venue_production_profiles, venues RESTART IDENTITY CASCADE"

    alter table(:venues) do
      remove :workspace_id
      add :google_place_id, :string
      add :formatted_address, :string
      add :lat, :float
      add :lng, :float
    end

    drop_if_exists index(:venues, [:workspace_id])
    create unique_index(:venues, [:google_place_id])
  end

  def down do
    alter table(:venues) do
      remove :google_place_id
      remove :formatted_address
      remove :lat
      remove :lng
      add :workspace_id, references(:workspaces, type: :binary_id, on_delete: :delete_all)
    end

    drop_if_exists unique_index(:venues, [:google_place_id])
    create index(:venues, [:workspace_id])
  end
end
