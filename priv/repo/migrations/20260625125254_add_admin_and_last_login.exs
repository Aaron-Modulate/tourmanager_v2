defmodule TourmanagerV2.Repo.Migrations.AddAdminAndLastLogin do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_admin, :boolean, null: false, default: false
      add :last_login_at, :utc_datetime
    end

    create table(:admin_jobs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :cron_expression, :string, null: false, default: "0 */6 * * *"
      add :enabled, :boolean, null: false, default: true
      add :last_run_at, :utc_datetime
      add :last_result, :text

      timestamps()
    end

    create unique_index(:admin_jobs, [:name])

    execute "UPDATE users SET is_admin = true WHERE email = 'aaronkprictor@gmail.com'",
            "UPDATE users SET is_admin = false WHERE email = 'aaronkprictor@gmail.com'"
  end
end
