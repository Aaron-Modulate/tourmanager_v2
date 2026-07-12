defmodule TourmanagerV2.Production.ProductionDataSuggestion do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @target_types ~w(profile rigging_point truss power loading lighting_fixture document)
  @statuses ~w(pending accepted rejected)

  schema "production_data_suggestions" do
    field :target_type, :string
    field :target_id, :binary_id
    field :field_name, :string
    field :current_value, :string
    field :suggested_value, :string
    field :evidence_note, :string
    field :status, :string, default: "pending"
    field :rejection_reason, :string
    field :reviewed_at, :utc_datetime

    belongs_to :venue, TourmanagerV2.Production.Venue
    belongs_to :submitted_by_user, TourmanagerV2.Accounts.User, foreign_key: :submitted_by_user_id
    belongs_to :reviewed_by_user, TourmanagerV2.Accounts.User, foreign_key: :reviewed_by_user_id

    timestamps()
  end

  def changeset(suggestion, attrs) do
    suggestion
    |> cast(attrs, [:target_type, :target_id, :field_name, :current_value, :suggested_value,
                    :evidence_note, :submitted_by_user_id])
    |> validate_required([:target_type, :field_name, :suggested_value])
    |> validate_inclusion(:target_type, @target_types)
    |> validate_inclusion(:status, @statuses)
  end

  def review_changeset(suggestion, attrs) do
    suggestion
    |> cast(attrs, [:status, :rejection_reason, :reviewed_at, :reviewed_by_user_id])
    |> validate_required([:status, :reviewed_at, :reviewed_by_user_id])
    |> validate_inclusion(:status, @statuses)
  end
end
