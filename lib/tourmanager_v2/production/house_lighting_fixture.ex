defmodule TourmanagerV2.Production.HouseLightingFixture do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "house_lighting_fixtures" do
    field :fixture_name, :string
    field :manufacturer, :string
    field :model, :string
    field :quantity, :integer
    field :location, :string
    field :universe, :integer
    field :address_start, :integer
    field :notes, :string

    belongs_to :venue, TourmanagerV2.Production.Venue

    timestamps()
  end

  def changeset(fixture, attrs) do
    fixture
    |> cast(attrs, [:fixture_name, :manufacturer, :model, :quantity, :location,
                    :universe, :address_start, :notes])
    |> validate_required([:fixture_name])
    |> validate_number(:quantity, greater_than_or_equal_to: 1)
    |> validate_number(:universe, greater_than_or_equal_to: 0)
    |> validate_number(:address_start, greater_than_or_equal_to: 1)
  end
end
