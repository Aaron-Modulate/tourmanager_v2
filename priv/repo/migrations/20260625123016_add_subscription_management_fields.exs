defmodule TourmanagerV2.Repo.Migrations.AddSubscriptionManagementFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :stripe_price_id, :string
      add :subscription_quantity, :integer
      add :subscription_status, :string
      add :subscription_period_end, :utc_datetime
      add :cancelled_at, :utc_datetime
    end
  end
end
