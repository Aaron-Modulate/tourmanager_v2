defmodule TourmanagerV2.Repo.Migrations.CreateGigs do
  use Ecto.Migration

  def change do
    create table(:gigs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :venue, :string
      add :city, :string
      add :venue_code, :string
      add :capacity, :integer
      add :date, :date, null: false
      add :status, :string, null: false, default: "confirmed"
      add :notes, :string

      add :tour_id, references(:tours, type: :binary_id, on_delete: :delete_all),
        null: false

      add :workspace_id, references(:workspaces, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create index(:gigs, [:tour_id])
    create index(:gigs, [:workspace_id])
    create index(:gigs, [:date])
  end
end
