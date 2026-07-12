defmodule TourmanagerV2.Repo.Migrations.CreateGuests do
  use Ecto.Migration

  def change do
    create table(:guests, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :plus_ones, :integer, null: false, default: 0
      add :guest_of, :string
      add :notes, :string
      add :checked_in_at, :utc_datetime
      add :date, :date, null: false

      add :tour_id, references(:tours, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:guests, [:tour_id, :date])
  end
end
