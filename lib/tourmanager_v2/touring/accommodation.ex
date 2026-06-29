defmodule TourmanagerV2.Touring.Accommodation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accommodations" do
    field :location, :string
    field :check_in, :date
    field :check_out, :date
    field :booking_reference, :string
    field :notes, :string

    belongs_to :tour, TourmanagerV2.Touring.Tour
    belongs_to :route_entry, TourmanagerV2.Touring.RouteEntry

    timestamps()
  end

  def changeset(accommodation, attrs) do
    accommodation
    |> cast(attrs, [:location, :check_in, :check_out, :booking_reference, :notes])
    |> validate_required([:location, :check_in])
  end
end
