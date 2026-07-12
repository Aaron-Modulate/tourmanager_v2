defmodule TourmanagerV2.Touring.Guest do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "guests" do
    field :name, :string
    field :plus_ones, :integer, default: 0
    field :guest_of, :string
    field :notes, :string
    field :checked_in_at, :utc_datetime
    field :date, :date

    belongs_to :tour, TourmanagerV2.Touring.Tour

    timestamps()
  end

  def changeset(guest, attrs) do
    guest
    |> cast(attrs, [:name, :plus_ones, :guest_of, :notes, :checked_in_at, :date])
    |> validate_required([:name, :date])
    |> validate_number(:plus_ones, greater_than_or_equal_to: 0)
  end
end
