defmodule TourmanagerV2.Repo.Migrations.CreateProductionDocuments do
  use Ecto.Migration

  def change do
    create table(:production_documents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :document_type, :string, null: false, default: "other"
      add :file_url, :string
      add :original_filename, :string
      add :content_type, :string
      add :file_size, :integer
      add :notes, :text
      # TODO: Add :extracted_metadata :map (jsonb) for future AI extraction of PDFs/CAD files into structured data
      add :uploaded_at, :utc_datetime
      add :venue_id, references(:venues, type: :binary_id, on_delete: :delete_all), null: false
      add :uploaded_by_user_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps()
    end

    create index(:production_documents, [:venue_id])
    create index(:production_documents, [:uploaded_by_user_id])
    create index(:production_documents, [:document_type])
  end
end
