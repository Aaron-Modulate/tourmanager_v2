defmodule TourmanagerV2.Repo.Migrations.AddUserProfileFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :legal_name, :string
      add :passport_number, :string
      add :phone_number, :string
      add :frequent_flyer, :string
      add :social_links, :map, default: %{}
      add :role_title, :string
    end
  end
end
