defmodule TourmanagerV2.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :name, :string, null: false
      add :hashed_password, :string, null: false
      add :role, :string, null: false, default: "crew"
      add :plan, :string, null: false, default: "free"

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
