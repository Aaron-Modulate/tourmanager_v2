defmodule TourmanagerV2.Touring.DateCrewAssignment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "date_crew_assignments" do
    field :date, :date

    belongs_to :tour, TourmanagerV2.Touring.Tour
    belongs_to :user, TourmanagerV2.Accounts.User

    timestamps()
  end

  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:date])
    |> validate_required([:date])
    |> unique_constraint([:tour_id, :user_id, :date])
  end
end
