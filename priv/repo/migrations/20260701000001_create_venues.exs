defmodule TourmanagerV2.Repo.Migrations.CreateVenues do
  use Ecto.Migration

  def change do
    create table(:venues, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :city, :string
      add :country, :string
      add :capacity, :integer
      add :website, :string
      add :notes, :text
      add :workspace_id, references(:workspaces, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:venues, [:workspace_id])
    create index(:venues, [:name])
  end
end
