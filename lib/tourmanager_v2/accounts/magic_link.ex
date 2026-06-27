defmodule TourmanagerV2.Accounts.MagicLink do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @token_validity_minutes 15

  schema "magic_links" do
    field :email, :string
    field :token_hash, :string
    field :expires_at, :utc_datetime
    field :used_at, :utc_datetime

    timestamps()
  end

  def changeset(magic_link, attrs) do
    magic_link
    |> cast(attrs, [:email, :token_hash, :expires_at])
    |> validate_required([:email, :token_hash, :expires_at])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> unique_constraint(:token_hash)
  end

  def token_validity_minutes, do: @token_validity_minutes
end
