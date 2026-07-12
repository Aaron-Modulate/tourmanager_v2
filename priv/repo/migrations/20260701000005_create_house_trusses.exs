defmodule TourmanagerV2.Repo.Migrations.CreateHouseTrusses do
  use Ecto.Migration

  def change do
    create table(:house_trusses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :position, :string, null: false, default: "other"
      add :length_m, :float
      add :trim_height_m, :float
      add :max_load_kg, :float
      add :notes, :text
      add :venue_id, references(:venues, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:house_trusses, [:venue_id])
  end
end
