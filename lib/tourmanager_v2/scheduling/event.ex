defmodule TourmanagerV2.Scheduling.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @categories ~w(load_in soundcheck doors showtime curfew load_out catering travel other)

  schema "events" do
    field :name, :string
    field :category, :string
    field :starts_at, :utc_datetime
    field :ends_at, :utc_datetime
    field :location, :string
    field :notes, :string
    field :sort_order, :integer, default: 0

    belongs_to :gig, TourmanagerV2.Touring.Gig
    belongs_to :workspace, TourmanagerV2.Accounts.Workspace

    timestamps()
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:name, :category, :starts_at, :ends_at, :location, :notes, :sort_order])
    |> validate_required([:name, :category, :starts_at])
    |> validate_inclusion(:category, @categories)
    |> validate_time_range()
  end

  defp validate_time_range(changeset) do
    starts_at = get_field(changeset, :starts_at)
    ends_at = get_field(changeset, :ends_at)

    if starts_at && ends_at && DateTime.compare(ends_at, starts_at) == :lt do
      add_error(changeset, :ends_at, "must be after start time")
    else
      changeset
    end
  end
end
