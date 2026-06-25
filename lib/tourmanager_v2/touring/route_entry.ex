defmodule TourmanagerV2.Touring.RouteEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @types ~w(gig vehicle_travel off_day)

  schema "route_entries" do
    field :type, :string
    field :date, :date
    field :venue, :string
    field :city, :string
    field :venue_code, :string
    field :origin, :string
    field :destination, :string
    field :notes, :string
    field :distance_km, :integer
    field :venue_image_url, :string
    field :place_id, :string
    field :lat, :float
    field :lng, :float
    field :sort_order, :integer, default: 0
    field :origin_place_id, :string
    field :origin_lat, :float
    field :origin_lng, :float
    field :origin_address, :string
    field :dest_place_id, :string
    field :dest_lat, :float
    field :dest_lng, :float
    field :dest_address, :string
    field :travel_duration_seconds, :integer
    field :booking_reference, :string

    belongs_to :tour, TourmanagerV2.Touring.Tour
    belongs_to :workspace, TourmanagerV2.Accounts.Workspace

    timestamps()
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [
      :type, :date, :venue, :city, :venue_code, :origin, :destination,
      :notes, :distance_km, :venue_image_url, :place_id, :lat, :lng, :sort_order,
      :origin_place_id, :origin_lat, :origin_lng, :origin_address,
      :dest_place_id, :dest_lat, :dest_lng, :dest_address,
      :travel_duration_seconds, :booking_reference
    ])
    |> validate_required([:type, :date])
    |> validate_inclusion(:type, @types)
    |> validate_by_type()
  end

  defp validate_by_type(changeset) do
    case get_field(changeset, :type) do
      "gig" ->
        validate_required(changeset, [:venue, :city])

      "vehicle_travel" ->
        validate_required(changeset, [:origin, :destination])

      _ ->
        changeset
    end
  end

  def vehicle_travel?(%__MODULE__{type: "vehicle_travel"}), do: true
  def vehicle_travel?(_), do: false

  def gig?(%__MODULE__{type: "gig"}), do: true
  def gig?(_), do: false
end
