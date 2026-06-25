defmodule TourmanagerV2.Repo.Migrations.AddStripeBillingFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :stripe_customer_id, :string
      add :stripe_subscription_id, :string
      add :crew_seats, :integer, null: false, default: 10
    end

    create unique_index(:users, [:stripe_customer_id])
  end
end
