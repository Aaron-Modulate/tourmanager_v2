defmodule TourmanagerV2.Repo.Migrations.CreateVenueProductionProfiles do
  use Ecto.Migration

  def change do
    create table(:venue_production_profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_status, :string, null: false, default: "draft"
      add :stage_width_m, :float
      add :stage_depth_m, :float
      add :stage_height_m, :float
      add :trim_height_m, :float
      add :notes, :text
      add :last_verified_at, :utc_datetime
      add :venue_id, references(:venues, type: :binary_id, on_delete: :delete_all), null: false
      add :verified_by_user_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:venue_production_profiles, [:venue_id])
    create index(:venue_production_profiles, [:profile_status])
    create index(:venue_production_profiles, [:verified_by_user_id])
  end
end
