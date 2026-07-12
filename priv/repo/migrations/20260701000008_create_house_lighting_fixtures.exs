defmodule TourmanagerV2.Repo.Migrations.CreateHouseLightingFixtures do
  use Ecto.Migration

  def change do
    create table(:house_lighting_fixtures, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :fixture_name, :string, null: false
      add :manufacturer, :string
      add :model, :string
      add :quantity, :integer
      add :location, :string
      add :universe, :integer
      add :address_start, :integer
      add :notes, :text
      add :venue_id, references(:venues, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:house_lighting_fixtures, [:venue_id])
  end
end
