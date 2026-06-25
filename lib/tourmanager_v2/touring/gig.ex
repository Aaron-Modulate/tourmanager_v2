defmodule TourmanagerV2.Touring.Gig do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ~w(confirmed tentative cancelled postponed)

  schema "gigs" do
    field :name, :string
    field :venue, :string
    field :city, :string
    field :venue_code, :string
    field :capacity, :integer
    field :date, :date
    field :status, :string, default: "confirmed"
    field :notes, :string

    belongs_to :tour, TourmanagerV2.Touring.Tour
    belongs_to :workspace, TourmanagerV2.Accounts.Workspace
    has_many :events, TourmanagerV2.Scheduling.Event
    many_to_many :artists, TourmanagerV2.Touring.Artist, join_through: "gig_artists"
    many_to_many :crew_members, TourmanagerV2.Touring.CrewMember, join_through: "gig_crew_members"

    timestamps()
  end

  def changeset(gig, attrs) do
    gig
    |> cast(attrs, [:name, :venue, :city, :venue_code, :capacity, :date, :status, :notes])
    |> validate_required([:name, :date])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:capacity, greater_than: 0)
  end
end
