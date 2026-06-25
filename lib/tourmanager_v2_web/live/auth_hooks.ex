defmodule TourmanagerV2Web.AuthHooks do
  import Phoenix.Component
  alias TourmanagerV2.Accounts

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

    socket =
      if detect_unit and Phoenix.LiveView.connected?(socket) do
        Phoenix.LiveView.push_event(socket, "detect_distance_unit", %{})
      else
        socket
      end

    {:cont, socket}
  end
end
