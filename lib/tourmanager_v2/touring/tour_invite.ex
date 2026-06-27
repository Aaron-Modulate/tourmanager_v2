defmodule TourmanagerV2.Touring.TourInvite do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ~w(pending accepted revoked)

  schema "tour_invites" do
    field :token, :string
    field :role, :string, default: "crew"
    field :status, :string, default: "pending"
    field :expires_at, :utc_datetime

    belongs_to :tour, TourmanagerV2.Touring.Tour
    belongs_to :invited_by, TourmanagerV2.Accounts.User, foreign_key: :invited_by_id

    timestamps()
  end

  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [:role, :status, :expires_at])
    |> validate_required([:role])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:role, ~w(manager crew))
    |> put_token()
  end

  defp put_token(changeset) do
    if get_field(changeset, :token) do
      changeset
    else
      put_change(changeset, :token, Base.url_encode64(:crypto.strong_rand_bytes(32)))
    end
  end
end
