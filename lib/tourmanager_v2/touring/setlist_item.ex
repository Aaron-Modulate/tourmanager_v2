defmodule TourmanagerV2.Touring.SetlistItem do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "setlist_items" do
    field :position, :integer
    field :title, :string
    field :artist, :string
    field :duration_seconds, :integer
    field :notes, :string

    belongs_to :setlist, TourmanagerV2.Touring.Setlist

    timestamps()
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:position, :title, :artist, :duration_seconds, :notes])
    |> validate_required([:position, :title])
    |> validate_number(:position, greater_than_or_equal_to: 0)
  end
end
