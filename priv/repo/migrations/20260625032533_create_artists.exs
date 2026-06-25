defmodule TourmanagerV2.Repo.Migrations.CreateArtists do
  use Ecto.Migration

  def change do
    create table(:artists, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :genre, :string
      add :notes, :string

      add :workspace_id, references(:workspaces, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create index(:artists, [:workspace_id])
  end
end
