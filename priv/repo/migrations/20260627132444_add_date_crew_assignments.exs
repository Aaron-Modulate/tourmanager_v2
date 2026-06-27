defmodule TourmanagerV2.Repo.Migrations.AddDateCrewAssignments do
  use Ecto.Migration

  def change do
    alter table(:tour_memberships) do
      add :all_dates_default, :boolean, default: true, null: false
    end

    create table(:date_crew_assignments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tour_id, references(:tours, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :date, :date, null: false

      timestamps()
    end

    create unique_index(:date_crew_assignments, [:tour_id, :user_id, :date])
    create index(:date_crew_assignments, [:tour_id, :date])
  end
end
