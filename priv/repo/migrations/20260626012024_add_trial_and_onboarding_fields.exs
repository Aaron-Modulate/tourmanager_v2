defmodule TourmanagerV2.Repo.Migrations.AddTrialAndOnboardingFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :trial_started_at, :utc_datetime
      add :trial_ends_at, :utc_datetime
      add :onboarding_completed_at, :utc_datetime
    end
  end
end
