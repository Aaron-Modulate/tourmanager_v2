defmodule TourmanagerV2.Repo.Migrations.CreateSetlists do
  use Ecto.Migration

  def change do
    create table(:setlists, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tour_id, references(:tours, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :source, :string, null: false, default: "manual"
      add :is_tour_default, :boolean, null: false, default: false
      add :date, :date
      add :file_url, :string
      add :file_type, :string
      add :ocr_status, :string, default: "none"
      add :uploaded_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps()
    end

    create index(:setlists, [:tour_id, :date])
    create index(:setlists, [:tour_id, :is_tour_default])

    create table(:setlist_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :setlist_id, references(:setlists, type: :binary_id, on_delete: :delete_all), null: false
      add :position, :integer, null: false
      add :title, :string, null: false
      add :artist, :string
      add :duration_seconds, :integer
      add :notes, :string

      timestamps()
    end

    create index(:setlist_items, [:setlist_id, :position])
  end
end
