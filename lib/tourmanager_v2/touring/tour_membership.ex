defmodule TourmanagerV2.Touring.TourMembership do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @roles ~w(manager crew)

  schema "tour_memberships" do
    field :role, :string, default: "crew"
    field :all_dates_default, :boolean, default: true

    belongs_to :tour, TourmanagerV2.Touring.Tour
    belongs_to :user, TourmanagerV2.Accounts.User

    timestamps()
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:role, :all_dates_default])
    |> validate_required([:role])
    |> validate_inclusion(:role, @roles)
    |> unique_constraint([:tour_id, :user_id])
  end
end
