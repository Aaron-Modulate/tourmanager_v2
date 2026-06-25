defmodule TourmanagerV2.Accounts.Invite do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ~w(pending accepted expired revoked)

  schema "invites" do
    field :email, :string
    field :token, :string
    field :role, :string, default: "crew"
    field :status, :string, default: "pending"
    field :expires_at, :utc_datetime

    belongs_to :workspace, TourmanagerV2.Accounts.Workspace
    belongs_to :invited_by, TourmanagerV2.Accounts.User, foreign_key: :invited_by_id

    timestamps()
  end

  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [:email, :role, :status, :expires_at])
    |> validate_required([:email, :role, :expires_at])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:role, ~w(admin member))
    |> put_token()
    |> unique_constraint(:token)
  end

  defp put_token(changeset) do
    if get_field(changeset, :token) do
      changeset
    else
      put_change(changeset, :token, Base.url_encode64(:crypto.strong_rand_bytes(32)))
    end
  end
end
