defmodule TourmanagerV2.Repo.Migrations.CreateGigAssociations do
  use Ecto.Migration

  def change do
    create table(:gig_artists, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :gig_id, references(:gigs, type: :binary_id, on_delete: :delete_all),
        null: false

      add :artist_id, references(:artists, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create index(:gig_artists, [:gig_id])
    create index(:gig_artists, [:artist_id])
    create unique_index(:gig_artists, [:gig_id, :artist_id])

    create table(:gig_crew_members, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :gig_id, references(:gigs, type: :binary_id, on_delete: :delete_all),
        null: false

      add :crew_member_id, references(:crew_members, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create index(:gig_crew_members, [:gig_id])
    create index(:gig_crew_members, [:crew_member_id])
    create unique_index(:gig_crew_members, [:gig_id, :crew_member_id])
  end
end
