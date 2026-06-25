defmodule TourmanagerV2.Repo.Migrations.CreateTourMemberships do
  use Ecto.Migration

  def change do
    create table(:tour_memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :role, :string, null: false, default: "crew"

      add :tour_id, references(:tours, type: :binary_id, on_delete: :delete_all),
        null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create index(:tour_memberships, [:tour_id])
    create index(:tour_memberships, [:user_id])
    create unique_index(:tour_memberships, [:tour_id, :user_id])
  end
end
