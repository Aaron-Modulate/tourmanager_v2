defmodule TourmanagerV2.Repo.Migrations.CreateTourInvites do
  use Ecto.Migration

  def change do
    create table(:tour_invites, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :token, :string, null: false
      add :role, :string, null: false, default: "crew"
      add :status, :string, null: false, default: "pending"
      add :expires_at, :utc_datetime

      add :tour_id, references(:tours, type: :binary_id, on_delete: :delete_all), null: false
      add :invited_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:tour_invites, [:token])
    create index(:tour_invites, [:tour_id])
  end
end
