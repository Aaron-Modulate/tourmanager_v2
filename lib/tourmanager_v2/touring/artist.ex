defmodule TourmanagerV2.Touring.Artist do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "artists" do
    field :name, :string
    field :genre, :string
    field :notes, :string

    belongs_to :workspace, TourmanagerV2.Accounts.Workspace
    many_to_many :gigs, TourmanagerV2.Touring.Gig, join_through: "gig_artists"

    timestamps()
  end

  def changeset(artist, attrs) do
    artist
    |> cast(attrs, [:name, :genre, :notes])
    |> validate_required([:name])
  end
end
