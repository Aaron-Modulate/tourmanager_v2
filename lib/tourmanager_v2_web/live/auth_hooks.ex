defmodule TourmanagerV2Web.AuthHooks do
  import Phoenix.Component
  alias TourmanagerV2.Accounts
  alias TourmanagerV2.Accounts.User

  def on_mount(:default, _params, session, socket) do
    user =
      case session do
        %{"user_id" => user_id} when is_binary(user_id) ->
          try do
            Accounts.get_user!(user_id)
          rescue
            Ecto.NoResultsError -> nil
          end

        _ ->
          nil
      end

    user = maybe_expire_trial(user)

    tours = if user, do: Accounts.list_tours_for_user(user.id), else: []

    connect_tour_id =
      if Phoenix.LiveView.connected?(socket) do
        Phoenix.LiveView.get_connect_params(socket)["current_tour_id"]
      end

    current_tour_id =
      case connect_tour_id do
        id when is_binary(id) and id != "" -> id
        _ -> session["current_tour_id"]
      end

    current_tour_entry =
      if current_tour_id do
        Enum.find(tours, fn %{tour: t} -> t.id == current_tour_id end)
      end

    current_tour_entry = current_tour_entry || List.first(tours)

    detect_unit = session["detect_distance_unit"] == true

    socket =
      socket
      |> assign(:current_user, user)
      |> assign(:user_tours, tours)
      |> assign(:current_tour, current_tour_entry && current_tour_entry.tour)
      |> assign(:current_tour_role, current_tour_entry && current_tour_entry.role)

    if user do
      socket =
        if detect_unit and Phoenix.LiveView.connected?(socket) do
          Phoenix.LiveView.push_event(socket, "detect_distance_unit", %{})
        else
          socket
        end

      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: "/")}
    end
  end

  defp maybe_expire_trial(nil), do: nil

  defp maybe_expire_trial(%User{} = user) do
    if User.trial_expired?(user) && User.manager?(user) && !User.subscribed?(user) do
      case Accounts.expire_trial(user) do
        {:ok, updated} -> updated
        _ -> user
      end
    else
      user
    end
  end
end
