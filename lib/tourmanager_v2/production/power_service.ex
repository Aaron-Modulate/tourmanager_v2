defmodule TourmanagerV2.Production.PowerService do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @phase_types ~w(single_phase three_phase)

  schema "power_services" do
    field :name, :string
    field :phase_type, :string, default: "single_phase"
    field :amps, :integer
    field :voltage, :integer
    field :connector_type, :string
    field :location, :string
    field :notes, :string

    belongs_to :venue, TourmanagerV2.Production.Venue

    timestamps()
  end

  def changeset(service, attrs) do
    service
    |> cast(attrs, [:name, :phase_type, :amps, :voltage, :connector_type, :location, :notes])
    |> validate_required([:name, :phase_type])
    |> validate_inclusion(:phase_type, @phase_types)
    |> validate_number(:amps, greater_than: 0)
    |> validate_number(:voltage, greater_than: 0)
  end
end
