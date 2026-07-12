defmodule TourmanagerV2.Repo.Migrations.CreateProductionDataSuggestions do
  use Ecto.Migration

  def change do
    create table(:production_data_suggestions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :target_type, :string, null: false
      add :target_id, :binary_id
      add :field_name, :string, null: false
      add :current_value, :text
      add :suggested_value, :text, null: false
      add :evidence_note, :text
      add :status, :string, null: false, default: "pending"
      add :rejection_reason, :text
      add :reviewed_at, :utc_datetime
      add :venue_id, references(:venues, type: :binary_id, on_delete: :delete_all), null: false
      add :submitted_by_user_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :reviewed_by_user_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps()
    end

    create index(:production_data_suggestions, [:venue_id])
    create index(:production_data_suggestions, [:status])
    create index(:production_data_suggestions, [:submitted_by_user_id])
    create index(:production_data_suggestions, [:target_type, :target_id, :field_name])
  end
end
