defmodule TourmanagerV2.Repo.Migrations.CreateTours do
  use Ecto.Migration

  def change do
    create table(:tours, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :string
      add :start_date, :date
      add :end_date, :date
      add :status, :string, null: false, default: "draft"

      add :workspace_id, references(:workspaces, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create index(:tours, [:workspace_id])
  end
end
