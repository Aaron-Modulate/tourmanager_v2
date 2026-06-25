defmodule TourmanagerV2.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @roles ~w(manager crew)
  @plans ~w(paid free)
  @providers ~w(google microsoft)

  schema "users" do
    field :email, :string
    field :name, :string
    field :hashed_password, :string
    field :role, :string, default: "crew"
    field :plan, :string, default: "free"
    field :provider, :string
    field :provider_uid, :string
    field :avatar_url, :string
    field :distance_unit, :string, default: "km"
    field :stripe_customer_id, :string
    field :stripe_subscription_id, :string
    field :stripe_price_id, :string
    field :crew_seats, :integer, default: 10
    field :subscription_quantity, :integer
    field :subscription_status, :string
    field :subscription_period_end, :utc_datetime
    field :cancelled_at, :utc_datetime
    field :is_admin, :boolean, default: false
    field :last_login_at, :utc_datetime

    has_many :memberships, TourmanagerV2.Accounts.WorkspaceMembership
    has_many :workspaces, through: [:memberships, :workspace]
    has_many :crew_members, TourmanagerV2.Touring.CrewMember
    has_many :tour_memberships, TourmanagerV2.Touring.TourMembership
    has_many :tours, through: [:tour_memberships, :tour]

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :role, :plan, :avatar_url, :distance_unit,
                    :stripe_customer_id, :stripe_subscription_id, :stripe_price_id,
                    :crew_seats, :subscription_quantity, :subscription_status,
                    :subscription_period_end, :cancelled_at, :is_admin, :last_login_at])
    |> validate_required([:email, :name])
    |> unique_constraint(:email)
    |> validate_inclusion(:role, @roles)
    |> validate_inclusion(:plan, @plans)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
  end

  def oauth_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :provider, :provider_uid, :avatar_url, :distance_unit])
    |> validate_required([:email, :name, :provider, :provider_uid])
    |> unique_constraint(:email)
    |> unique_constraint([:provider, :provider_uid])
    |> validate_inclusion(:provider, @providers)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
  end

  def registration_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> cast(attrs, [:hashed_password])
    |> validate_required([:hashed_password])
    |> validate_length(:hashed_password, min: 12, max: 72)
  end

  def manager?(%__MODULE__{role: "manager"}), do: true
  def manager?(_), do: false

  def subscription_active?(%__MODULE__{subscription_status: "active"}), do: true
  def subscription_active?(_), do: false

  def subscription_cancelling?(%__MODULE__{subscription_status: "cancelling"}), do: true
  def subscription_cancelling?(_), do: false

  def subscribed?(%__MODULE__{plan: "paid"}), do: true
  def subscribed?(_), do: false

  def admin?(%__MODULE__{is_admin: true}), do: true
  def admin?(_), do: false
end
