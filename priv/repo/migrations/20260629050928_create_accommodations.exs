defmodule TourmanagerV2.Repo.Migrations.CreateAccommodations do
  use Ecto.Migration

  def change do
    create table(:accommodations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tour_id, references(:tours, type: :binary_id, on_delete: :delete_all), null: false
      add :route_entry_id, references(:route_entries, type: :binary_id, on_delete: :delete_all)
      add :location, :string, null: false
      add :check_in, :date, null: false
      add :check_out, :date
      add :booking_reference, :string
      add :notes, :string

      timestamps()
    end

    create index(:accommodations, [:tour_id])
    create index(:accommodations, [:route_entry_id])
    create index(:accommodations, [:check_in])
  end
end
