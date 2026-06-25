defmodule TourmanagerV2.Accounts.WorkspaceMembership do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @roles ~w(owner admin member)

  schema "workspace_memberships" do
    field :role, :string, default: "member"

    belongs_to :workspace, TourmanagerV2.Accounts.Workspace
    belongs_to :user, TourmanagerV2.Accounts.User

    timestamps()
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:role])
    |> validate_required([:role])
    |> validate_inclusion(:role, @roles)
    |> unique_constraint([:workspace_id, :user_id])
  end
end
