defmodule TourmanagerV2.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :category, :string, null: false
      add :starts_at, :utc_datetime, null: false
      add :ends_at, :utc_datetime
      add :location, :string
      add :notes, :string
      add :sort_order, :integer, null: false, default: 0

      add :gig_id, references(:gigs, type: :binary_id, on_delete: :delete_all),
        null: false

      add :workspace_id, references(:workspaces, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create index(:events, [:gig_id])
    create index(:events, [:workspace_id])
    create index(:events, [:gig_id, :sort_order])
  end
end
