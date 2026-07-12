defmodule TourmanagerV2.Production.ProductionDocument do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @document_types ~w(tech_pack rigging_plot lighting_plot stage_plot cad photo other)

  schema "production_documents" do
    field :title, :string
    field :document_type, :string, default: "other"
    field :file_url, :string
    field :original_filename, :string
    field :content_type, :string
    field :file_size, :integer
    field :notes, :string
    field :uploaded_at, :utc_datetime

    # TODO: Add :extracted_metadata field (map/jsonb) here when AI extraction is implemented.
    # The extraction service would parse PDFs/CAD files and populate draft rigging_points,
    # power_services, etc. via TourmanagerV2.Production.Documents.extract_metadata/1.

    belongs_to :venue, TourmanagerV2.Production.Venue
    belongs_to :uploaded_by_user, TourmanagerV2.Accounts.User, foreign_key: :uploaded_by_user_id

    timestamps()
  end

  def changeset(doc, attrs) do
    doc
    |> cast(attrs, [:title, :document_type, :file_url, :original_filename, :content_type,
                    :file_size, :notes, :uploaded_at, :uploaded_by_user_id])
    |> validate_required([:title, :document_type])
    |> validate_inclusion(:document_type, @document_types)
  end
end
