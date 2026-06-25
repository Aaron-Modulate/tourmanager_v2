defmodule TourmanagerV2.Accounts.Workspace do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "workspaces" do
    field :name, :string
    field :slug, :string

    has_many :memberships, TourmanagerV2.Accounts.WorkspaceMembership
    has_many :users, through: [:memberships, :user]
    has_many :invites, TourmanagerV2.Accounts.Invite
    has_many :tours, TourmanagerV2.Touring.Tour
    has_many :artists, TourmanagerV2.Touring.Artist
    has_many :crew_members, TourmanagerV2.Touring.CrewMember
    has_many :gigs, TourmanagerV2.Touring.Gig
    has_many :events, TourmanagerV2.Scheduling.Event

    timestamps()
  end

  def changeset(workspace, attrs) do
    workspace
    |> cast(attrs, [:name, :slug])
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug)
    |> validate_format(:slug, ~r/^[a-z0-9\-]+$/)
  end
end
