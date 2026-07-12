defmodule TourmanagerV2.Production.Venue do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "venues" do
    field :name, :string
    field :google_place_id, :string
    field :formatted_address, :string
    field :city, :string
    field :country, :string
    field :lat, :float
    field :lng, :float
    field :capacity, :integer
    field :website, :string
    field :notes, :string

    has_one :production_profile, TourmanagerV2.Production.VenueProductionProfile
    has_many :rigging_points, TourmanagerV2.Production.RiggingPoint
    has_many :house_trusses, TourmanagerV2.Production.HouseTruss
    has_many :power_services, TourmanagerV2.Production.PowerService
    has_one :loading_access, TourmanagerV2.Production.LoadingAccess
    has_many :lighting_fixtures, TourmanagerV2.Production.HouseLightingFixture
    has_many :production_documents, TourmanagerV2.Production.ProductionDocument

    timestamps()
  end

  def changeset(venue, attrs) do
    venue
    |> cast(attrs, [:name, :google_place_id, :formatted_address, :city, :country, :lat, :lng,
                    :capacity, :website, :notes])
    |> validate_required([:name])
    |> unique_constraint(:google_place_id)
  end
end
