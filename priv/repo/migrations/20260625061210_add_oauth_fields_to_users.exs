defmodule TourmanagerV2.Repo.Migrations.AddOauthFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :provider, :string
      add :provider_uid, :string
      add :avatar_url, :string
      modify :hashed_password, :string, null: true
    end

    create unique_index(:users, [:provider, :provider_uid])
  end
end
