defmodule TourmanagerV2.Touring.CrewMember do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "crew_members" do
    field :name, :string
    field :role_title, :string
    field :email, :string
    field :phone, :string
    field :notes, :string

    belongs_to :workspace, TourmanagerV2.Accounts.Workspace
    belongs_to :user, TourmanagerV2.Accounts.User
    many_to_many :gigs, TourmanagerV2.Touring.Gig, join_through: "gig_crew_members"

    timestamps()
  end

  def changeset(crew_member, attrs) do
    crew_member
    |> cast(attrs, [:name, :role_title, :email, :phone, :notes])
    |> validate_required([:name, :role_title])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
  end
end
