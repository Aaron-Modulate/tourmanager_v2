defmodule TourmanagerV2.Repo.Migrations.CreateCrewMembers do
  use Ecto.Migration

  def change do
    create table(:crew_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :role_title, :string, null: false
      add :email, :string
      add :phone, :string
      add :notes, :string

      add :workspace_id, references(:workspaces, type: :binary_id, on_delete: :delete_all),
        null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps()
    end

    create index(:crew_members, [:workspace_id])
    create index(:crew_members, [:user_id])
  end
end
