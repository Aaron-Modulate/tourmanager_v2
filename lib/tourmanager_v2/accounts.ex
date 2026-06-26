defmodule TourmanagerV2.Accounts do
  import Ecto.Query
  alias TourmanagerV2.Repo
  alias TourmanagerV2.Accounts.User
  alias TourmanagerV2.Touring.{Tour, TourMembership}

  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_provider(provider, uid) do
    Repo.get_by(User, provider: to_string(provider), provider_uid: to_string(uid))
  end

  def find_or_create_oauth_user(auth) do
    provider = to_string(auth.provider)
    uid = to_string(auth.uid)

    case get_user_by_provider(provider, uid) do
      nil ->
        attrs = %{
          email: auth.info.email,
          name: auth.info.name || auth.info.email,
          provider: provider,
          provider_uid: uid,
          avatar_url: auth.info.image
        }

        now = DateTime.utc_now()
        trial_end = DateTime.add(now, 7, :day)

        case %User{} |> User.oauth_changeset(attrs) |> Repo.insert() do
          {:ok, user} ->
            {:ok, updated} =
              user
              |> User.changeset(%{
                role: "manager",
                trial_started_at: now,
                trial_ends_at: trial_end
              })
              |> Repo.update()

            {:ok, Map.put(updated, :new_user, true)}

          error ->
            error
        end

      user ->
        user
        |> User.changeset(%{avatar_url: auth.info.image, name: auth.info.name || user.name})
        |> Repo.update()
    end
  end

  def list_tours_for_user(user_id) do
    Tour
    |> join(:inner, [t], tm in TourMembership, on: tm.tour_id == t.id and tm.user_id == ^user_id)
    |> select([t, tm], %{tour: t, role: tm.role})
    |> order_by([t], asc: t.name)
    |> Repo.all()
  end

  def get_tour_membership(tour_id, user_id) do
    Repo.get_by(TourMembership, tour_id: tour_id, user_id: user_id)
  end

  def update_user_plan(%User{} = user, plan) when plan in ~w(free paid) do
    role = if plan == "paid", do: "manager", else: "crew"

    user
    |> User.changeset(%{plan: plan, role: role})
    |> Repo.update()
  end

  def create_tour(%User{} = user, attrs) do
    alias TourmanagerV2.Accounts.{Workspace, WorkspaceMembership}

    TourmanagerV2.Repo.transaction(fn ->
      workspace =
        case Repo.one(from w in Workspace,
               join: wm in WorkspaceMembership, on: wm.workspace_id == w.id,
               where: wm.user_id == ^user.id,
               limit: 1) do
          nil ->
            slug = user.email |> String.split("@") |> List.first() |> String.downcase() |> String.replace(~r/[^a-z0-9\-]/, "-")

            %Workspace{}
            |> Workspace.changeset(%{name: "#{user.name}'s workspace", slug: slug})
            |> Repo.insert!()

          ws -> ws
        end

      unless Repo.get_by(WorkspaceMembership, workspace_id: workspace.id, user_id: user.id) do
        %WorkspaceMembership{workspace_id: workspace.id, user_id: user.id}
        |> WorkspaceMembership.changeset(%{role: "owner"})
        |> Repo.insert!()
      end

      tour =
        %Tour{workspace_id: workspace.id}
        |> Tour.changeset(attrs)
        |> Repo.insert!()

      %TourMembership{tour_id: tour.id, user_id: user.id}
      |> TourMembership.changeset(%{role: "manager"})
      |> Repo.insert!()

      tour
    end)
  end

  def change_tour(tour \\ %Tour{}, attrs \\ %{}) do
    Tour.changeset(tour, attrs)
  end

  def complete_onboarding(%User{} = user) do
    user
    |> User.changeset(%{onboarding_completed_at: DateTime.utc_now()})
    |> Repo.update()
  end

  def expire_trial(%User{} = user) do
    if User.trial_expired?(user) && !User.subscribed?(user) do
      user
      |> User.changeset(%{role: "crew"})
      |> Repo.update()
    else
      {:ok, user}
    end
  end

  def update_distance_unit(%User{} = user, unit) when unit in ~w(km mi) do
    user
    |> User.changeset(%{distance_unit: unit})
    |> Repo.update()
  end

  def list_users do
    User
    |> order_by(asc: :name)
    |> Repo.all()
  end

  def update_last_login(%User{} = user) do
    user
    |> User.changeset(%{last_login_at: DateTime.utc_now()})
    |> Repo.update()
  end

  def user_role_in_tour(tour_id, user_id) do
    TourMembership
    |> where(tour_id: ^tour_id, user_id: ^user_id)
    |> select([tm], tm.role)
    |> Repo.one()
  end
end
