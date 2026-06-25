defmodule TourmanagerV2.Repo.Migrations.CreateInvites do
  use Ecto.Migration

  def change do
    create table(:invites, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :token, :string, null: false
      add :role, :string, null: false, default: "crew"
      add :status, :string, null: false, default: "pending"
      add :expires_at, :utc_datetime, null: false

      add :workspace_id, references(:workspaces, type: :binary_id, on_delete: :delete_all),
        null: false

      add :invited_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:invites, [:token])
    create index(:invites, [:workspace_id])
    create index(:invites, [:email, :workspace_id])
  end
end
