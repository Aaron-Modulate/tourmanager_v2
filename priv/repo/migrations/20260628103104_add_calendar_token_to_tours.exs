defmodule TourmanagerV2.Repo.Migrations.AddCalendarTokenToTours do
  use Ecto.Migration

  def change do
    alter table(:tours) do
      add :calendar_token, :string
    end

    create unique_index(:tours, [:calendar_token])
  end
end
