defmodule TourmanagerV2.Production.VenueProductionProfile do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ~w(draft published needs_review)

  schema "venue_production_profiles" do
    field :profile_status, :string, default: "draft"
    field :stage_width_m, :float
    field :stage_depth_m, :float
    field :stage_height_m, :float
    field :trim_height_m, :float
    field :notes, :string
    field :last_verified_at, :utc_datetime

    belongs_to :venue, TourmanagerV2.Production.Venue
    belongs_to :verified_by_user, TourmanagerV2.Accounts.User, foreign_key: :verified_by_user_id

    timestamps()
  end

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:profile_status, :stage_width_m, :stage_depth_m, :stage_height_m,
                    :trim_height_m, :notes, :last_verified_at, :verified_by_user_id])
    |> validate_inclusion(:profile_status, @statuses)
    |> validate_number(:stage_width_m, greater_than: 0)
    |> validate_number(:stage_depth_m, greater_than: 0)
    |> validate_number(:stage_height_m, greater_than: 0)
    |> validate_number(:trim_height_m, greater_than: 0)
    |> unique_constraint(:venue_id)
  end
end
