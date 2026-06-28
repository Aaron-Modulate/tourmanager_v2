defmodule TourmanagerV2.Touring.Tour do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ~w(draft active completed cancelled)

  schema "tours" do
    field :name, :string
    field :description, :string
    field :start_date, :date
    field :end_date, :date
    field :status, :string, default: "draft"
    field :calendar_token, :string

    belongs_to :workspace, TourmanagerV2.Accounts.Workspace
    has_many :gigs, TourmanagerV2.Touring.Gig
    has_many :tour_memberships, TourmanagerV2.Touring.TourMembership
    has_many :members, through: [:tour_memberships, :user]

    timestamps()
  end

  def changeset(tour, attrs) do
    tour
    |> cast(attrs, [:name, :description, :start_date, :end_date, :status])
    |> validate_required([:name])
    |> validate_inclusion(:status, @statuses)
    |> validate_date_range()
  end

  defp validate_date_range(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if start_date && end_date && Date.compare(end_date, start_date) == :lt do
      add_error(changeset, :end_date, "must be on or after start date")
    else
      changeset
    end
  end
end
