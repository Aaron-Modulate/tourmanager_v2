defmodule TourmanagerV2Web.TourSwitching do
  @moduledoc """
  Shared event handling and data loading for all LiveViews.
  Consumed via `use TourmanagerV2Web.TourSwitching` which injects
  a catch-all `handle_event/3` that delegates to this module's functions.
  """

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [push_event: 3, redirect: 2]

  alias TourmanagerV2.TourBroadcast

  def default_assigns do
    %{
      tour_menu_open: false,
      settings_open: false,
      billing_seats: 10,
      billing_error: nil,
      new_tour_open: false,
      new_tour_form: nil,
      add_route_open: false,
      add_route_type: "gig",
      add_route_form: nil,
      place_suggestions: [],
      autocomplete_field: nil,
      editing_route: false,
      editing_route_entry: nil,
      manage_tour_open: false,
      manage_tour_form: nil,
      event_modal_open: false,
      event_form: nil,
      editing_event: nil
    }
  end

  defmacro __using__(_opts) do
    quote do
      @before_compile TourmanagerV2Web.TourSwitching
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def handle_event(event, params, socket) do
        TourmanagerV2Web.TourSwitching.handle_event(event, params, socket)
      end

      def handle_info({:tour_data_changed, tour_id, source_pid}, socket) do
        if source_pid != self() && socket.assigns[:current_tour] && socket.assigns.current_tour.id == tour_id do
          {:noreply, TourmanagerV2Web.TourSwitching.load_tour_data(socket, socket.assigns.current_tour)}
        else
          {:noreply, socket}
        end
      end
    end
  end

  def handle_event("toggle_tour_menu", _params, socket) do
    {:noreply, assign(socket, :tour_menu_open, !socket.assigns.tour_menu_open)}
  end

  def handle_event("close_tour_menu", _params, socket) do
    {:noreply, assign(socket, :tour_menu_open, false)}
  end

  def handle_event("select_tour", %{"tour-id" => tour_id}, socket) do
    entry = Enum.find(socket.assigns.user_tours, fn %{tour: t} -> t.id == tour_id end)

    socket =
      if entry do
        socket
        |> assign(:current_tour, entry.tour)
        |> assign(:current_tour_role, entry.role)
        |> assign(:tour_menu_open, false)
        |> push_event("persist_tour", %{tour_id: tour_id})
        |> load_tour_data(entry.tour)
      else
        assign(socket, :tour_menu_open, false)
      end

    {:noreply, socket}
  end

  def handle_event("new_tour", _params, socket) do
    changeset = TourmanagerV2.Accounts.change_tour()

    {:noreply,
     socket
     |> assign(:new_tour_open, true)
     |> assign(:new_tour_form, Phoenix.Component.to_form(changeset))}
  end

  def handle_event("close_new_tour", _params, socket) do
    {:noreply, assign(socket, :new_tour_open, false)}
  end

  def handle_event("validate_tour", %{"tour" => tour_params}, socket) do
    changeset =
      TourmanagerV2.Accounts.change_tour(%TourmanagerV2.Touring.Tour{}, tour_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :new_tour_form, Phoenix.Component.to_form(changeset))}
  end

  def handle_event("save_tour", %{"tour" => tour_params}, socket) do
    user = socket.assigns.current_user

    case TourmanagerV2.Accounts.create_tour(user, tour_params) do
      {:ok, tour} ->
        TourBroadcast.broadcast_change(tour.id)
        tours = TourmanagerV2.Accounts.list_tours_for_user(user.id)
        entry = Enum.find(tours, fn %{tour: t} -> t.id == tour.id end)

        {:noreply,
         socket
         |> assign(:new_tour_open, false)
         |> assign(:user_tours, tours)
         |> assign(:current_tour, tour)
         |> assign(:current_tour_role, entry && entry.role)
         |> push_event("persist_tour", %{tour_id: tour.id})
         |> load_tour_data(tour)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  def handle_event("open_add_route", _params, socket) do
    changeset = TourmanagerV2.Touring.change_route_entry(%TourmanagerV2.Touring.RouteEntry{}, %{type: "gig"})

    {:noreply,
     socket
     |> assign(:add_route_open, true)
     |> assign(:add_route_type, "gig")
     |> assign(:add_route_form, Phoenix.Component.to_form(changeset))
     |> assign(:place_suggestions, [])
     |> assign(:autocomplete_field, nil)
     |> assign(:editing_route, false)}
  end

  def handle_event("close_add_route", _params, socket) do
    {:noreply,
     socket
     |> assign(:add_route_open, false)
     |> assign(:place_suggestions, [])}
  end

  def handle_event("edit_route", %{"id" => id}, socket) do
    entry = TourmanagerV2.Touring.get_route_entry!(id)
    changeset = TourmanagerV2.Touring.change_route_entry(entry, %{})

    {:noreply,
     socket
     |> assign(:add_route_open, true)
     |> assign(:add_route_type, entry.type)
     |> assign(:add_route_form, Phoenix.Component.to_form(changeset))
     |> assign(:place_suggestions, [])
     |> assign(:editing_route, true)
     |> assign(:editing_route_entry, entry)}
  end

  def handle_event("close_edit_route", _params, socket) do
    {:noreply,
     socket
     |> assign(:add_route_open, false)
     |> assign(:editing_route, false)
     |> assign(:place_suggestions, [])}
  end

  def handle_event("set_route_type", %{"type" => type}, socket) do
    changeset = TourmanagerV2.Touring.change_route_entry(%TourmanagerV2.Touring.RouteEntry{}, %{type: type})

    {:noreply,
     socket
     |> assign(:add_route_type, type)
     |> assign(:add_route_form, Phoenix.Component.to_form(changeset))
     |> assign(:place_suggestions, [])}
  end

  def handle_event("place_autocomplete", %{"value" => query, "field" => field}, socket) when byte_size(query) >= 3 do
    case TourmanagerV2.GoogleMaps.autocomplete(query) do
      {:ok, suggestions} ->
        {:noreply,
         socket
         |> assign(:place_suggestions, suggestions)
         |> assign(:autocomplete_field, field)}

      _ ->
        {:noreply, assign(socket, :place_suggestions, [])}
    end
  end

  def handle_event("place_autocomplete", %{"value" => query}, socket) when byte_size(query) >= 3 do
    case TourmanagerV2.GoogleMaps.autocomplete(query) do
      {:ok, suggestions} ->
        {:noreply,
         socket
         |> assign(:place_suggestions, suggestions)
         |> assign(:autocomplete_field, "venue")}

      _ ->
        {:noreply, assign(socket, :place_suggestions, [])}
    end
  end

  def handle_event("place_autocomplete", _params, socket) do
    {:noreply, assign(socket, :place_suggestions, [])}
  end

  def handle_event("select_place", %{"place-id" => place_id, "field" => field}, socket) do
    handle_place_selection(socket, place_id, field)
  end

  def handle_event("select_place", %{"place-id" => place_id}, socket) do
    handle_place_selection(socket, place_id, "venue")
  end

  def handle_event("validate_route_entry", %{"route_entry" => params}, socket) do
    source = editing_source(socket)

    changeset =
      TourmanagerV2.Touring.change_route_entry(source, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :add_route_form, Phoenix.Component.to_form(changeset))}
  end

  def handle_event("save_route_entry", %{"route_entry" => params}, socket) do
    tour = socket.assigns.current_tour

    if tour do
      params = maybe_fetch_travel_time(params)

      case TourmanagerV2.Touring.create_route_entry(tour, tour.workspace_id, params) do
        {:ok, _entry} ->
          TourBroadcast.broadcast_change(tour.id)

          {:noreply,
           socket
           |> assign(:add_route_open, false)
           |> assign(:place_suggestions, [])
           |> load_tour_data(tour)}

        {:error, changeset} ->
          {:noreply, assign(socket, :add_route_form, Phoenix.Component.to_form(changeset))}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("update_route_entry", %{"route_entry" => params}, socket) do
    entry = socket.assigns[:editing_route_entry]
    tour = socket.assigns.current_tour

    if entry && tour do
      params = maybe_fetch_travel_time(params)

      case TourmanagerV2.Touring.update_route_entry(entry, params) do
        {:ok, _updated} ->
          TourBroadcast.broadcast_change(tour.id)

          {:noreply,
           socket
           |> assign(:add_route_open, false)
           |> assign(:editing_route, false)
           |> assign(:place_suggestions, [])
           |> load_tour_data(tour)}

        {:error, changeset} ->
          {:noreply, assign(socket, :add_route_form, Phoenix.Component.to_form(changeset))}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("delete_route_entry", _params, socket) do
    entry = socket.assigns[:editing_route_entry]
    tour = socket.assigns.current_tour

    if entry && tour do
      TourmanagerV2.Touring.delete_route_entry(entry)
      TourBroadcast.broadcast_change(tour.id)

      {:noreply,
       socket
       |> assign(:add_route_open, false)
       |> assign(:editing_route, false)
       |> assign(:place_suggestions, [])
       |> load_tour_data(tour)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("toggle_distance_unit", _params, socket) do
    user = socket.assigns.current_user

    if user do
      new_unit = if user.distance_unit == "km", do: "mi", else: "km"

      case TourmanagerV2.Accounts.update_distance_unit(user, new_unit) do
        {:ok, updated_user} ->
          {:noreply, assign(socket, :current_user, updated_user)}

        _ ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("open_settings", _params, socket) do
    user = socket.assigns.current_user
    seats = if user, do: user.crew_seats || 10, else: 10

    {:noreply,
     socket
     |> assign(:settings_open, true)
     |> assign(:billing_seats, seats)
     |> assign(:billing_error, nil)}
  end

  def handle_event("close_settings", _params, socket) do
    {:noreply, assign(socket, :settings_open, false)}
  end

  def handle_event("select_plan", %{"plan" => plan}, socket) do
    user = socket.assigns.current_user

    case TourmanagerV2.Accounts.update_user_plan(user, plan) do
      {:ok, updated_user} ->
        {:noreply, assign(socket, :current_user, updated_user)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_event("increment_seats", _params, socket) do
    seats = (socket.assigns[:billing_seats] || 10) + 1
    {:noreply, assign(socket, :billing_seats, seats)}
  end

  def handle_event("decrement_seats", _params, socket) do
    seats = max((socket.assigns[:billing_seats] || 10) - 1, 10)
    {:noreply, assign(socket, :billing_seats, seats)}
  end

  def handle_event("subscribe", _params, socket) do
    user = socket.assigns.current_user
    seats = socket.assigns[:billing_seats] || 10

    case TourmanagerV2.Billing.create_checkout_session(user, seats) do
      {:ok, %{url: url}} ->
        {:noreply, redirect(socket, external: url)}

      {:error, reason} ->
        msg =
          cond do
            is_binary(reason) -> reason
            is_map(reason) -> get_in(reason, ["error", "message"]) || inspect(reason)
            true -> "Payment failed. Try again."
          end

        {:noreply, assign(socket, :billing_error, msg)}
    end
  end

  def handle_event("cancel_subscription", _params, socket) do
    user = socket.assigns.current_user

    case TourmanagerV2.Billing.cancel_subscription(user) do
      :ok ->
        updated_user =
          user
          |> TourmanagerV2.Accounts.User.changeset(%{
            subscription_status: "cancelling",
            cancelled_at: DateTime.utc_now()
          })
          |> TourmanagerV2.Repo.update!()

        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> assign(:billing_error, nil)}

      {:error, reason} ->
        msg = if is_binary(reason), do: reason, else: "Could not cancel. Contact support."
        {:noreply, assign(socket, :billing_error, msg)}
    end
  end

  def handle_event("create_first_tour", %{"tour" => tour_params}, socket) do
    user = socket.assigns.current_user

    case TourmanagerV2.Accounts.create_tour(user, tour_params) do
      {:ok, tour} ->
        TourBroadcast.broadcast_change(tour.id)
        tours = TourmanagerV2.Accounts.list_tours_for_user(user.id)
        entry = Enum.find(tours, fn %{tour: t} -> t.id == tour.id end)

        {:noreply,
         socket
         |> assign(:user_tours, tours)
         |> assign(:current_tour, tour)
         |> assign(:current_tour_role, entry && entry.role)
         |> push_event("persist_tour", %{tour_id: tour.id})
         |> Phoenix.LiveView.push_navigate(to: "/routing")}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  def handle_event("open_manage_tour", _params, socket) do
    tour = socket.assigns.current_tour

    if tour do
      changeset = TourmanagerV2.Accounts.change_tour(tour, %{})

      {:noreply,
       socket
       |> assign(:manage_tour_open, true)
       |> assign(:manage_tour_form, Phoenix.Component.to_form(changeset))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("close_manage_tour", _params, socket) do
    {:noreply, assign(socket, :manage_tour_open, false)}
  end

  def handle_event("validate_manage_tour", %{"tour" => params}, socket) do
    tour = socket.assigns.current_tour

    changeset =
      TourmanagerV2.Accounts.change_tour(tour, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :manage_tour_form, Phoenix.Component.to_form(changeset))}
  end

  def handle_event("save_manage_tour", %{"tour" => params}, socket) do
    tour = socket.assigns.current_tour

    if tour do
      case TourmanagerV2.Repo.get!(TourmanagerV2.Touring.Tour, tour.id)
           |> TourmanagerV2.Touring.Tour.changeset(params)
           |> TourmanagerV2.Repo.update() do
        {:ok, updated_tour} ->
          TourBroadcast.broadcast_change(updated_tour.id)
          tours = TourmanagerV2.Accounts.list_tours_for_user(socket.assigns.current_user.id)

          {:noreply,
           socket
           |> assign(:current_tour, updated_tour)
           |> assign(:user_tours, tours)
           |> assign(:manage_tour_open, false)}

        {:error, changeset} ->
          {:noreply, assign(socket, :manage_tour_form, Phoenix.Component.to_form(changeset))}
      end
    else
      {:noreply, socket}
    end
  end

  # --- Event management ---

  def handle_event("add_event", _params, socket) do
    active_date =
      cond do
        socket.assigns[:selected_date] ->
          socket.assigns[:selected_date]

        socket.assigns[:today_route_entry] && socket.assigns.today_route_entry.date ->
          socket.assigns.today_route_entry.date

        socket.assigns[:next_route_entry] && socket.assigns.next_route_entry.date ->
          socket.assigns.next_route_entry.date

        socket.assigns[:today_gig] && socket.assigns.today_gig.date ->
          socket.assigns.today_gig.date

        true ->
          Date.utc_today()
      end

    default_start = DateTime.new!(active_date, ~T[12:00:00])
    default_end = DateTime.add(default_start, 3600, :second)

    changeset = TourmanagerV2.Touring.change_event(%TourmanagerV2.Scheduling.Event{}, %{
      starts_at: default_start,
      ends_at: default_end,
      category: "other",
      name: "Other"
    })

    {:noreply,
     socket
     |> assign(:event_modal_open, true)
     |> assign(:event_form, Phoenix.Component.to_form(changeset))
     |> assign(:editing_event, nil)}
  end

  def handle_event("edit_event", %{"id" => id}, socket) do
    event = TourmanagerV2.Touring.get_event!(id)
    changeset = TourmanagerV2.Touring.change_event(event, %{})
    {:noreply, assign(socket, :event_modal_open, true) |> assign(:event_form, Phoenix.Component.to_form(changeset)) |> assign(:editing_event, event)}
  end

  def handle_event("close_event_modal", _params, socket) do
    {:noreply, assign(socket, :event_modal_open, false)}
  end

  @category_labels %{
    "load_in" => "Load in", "soundcheck" => "Soundcheck", "doors" => "Doors",
    "showtime" => "Showtime", "curfew" => "Curfew", "load_out" => "Load out",
    "catering" => "Catering", "travel" => "Travel", "other" => "Other"
  }

  def handle_event("validate_event", %{"event" => params}, socket) do
    source = socket.assigns[:editing_event] || %TourmanagerV2.Scheduling.Event{}

    params =
      if is_nil(socket.assigns[:editing_event]) do
        category = params["category"]
        current_name = params["name"] || ""
        old_category_name = Map.get(@category_labels, Ecto.Changeset.get_field(
          TourmanagerV2.Touring.change_event(source, %{}), :category
        ) || "", "")

        if current_name == "" || current_name == old_category_name || Enum.member?(Map.values(@category_labels), current_name) do
          Map.put(params, "name", Map.get(@category_labels, category, current_name))
        else
          params
        end
      else
        params
      end

    changeset = TourmanagerV2.Touring.change_event(source, params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, :event_form, Phoenix.Component.to_form(changeset))}
  end

  def handle_event("save_event", %{"event" => params}, socket) do
    tour = socket.assigns.current_tour

    if tour do
      gig = socket.assigns[:today_gig] || ensure_gig_for_tour(tour, socket)

      if gig do
        case TourmanagerV2.Touring.create_event(gig, tour.workspace_id, params) do
          {:ok, _event} ->
            TourBroadcast.broadcast_change(tour.id)

            {:noreply,
             socket
             |> assign(:event_modal_open, false)
             |> load_tour_data(tour)}

          {:error, changeset} ->
            {:noreply, assign(socket, :event_form, Phoenix.Component.to_form(changeset))}
        end
      else
        {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("update_event", %{"event" => params}, socket) do
    event = socket.assigns[:editing_event]
    tour = socket.assigns.current_tour

    if event && tour do
      case TourmanagerV2.Touring.update_event(event, params) do
        {:ok, _updated} ->
          TourBroadcast.broadcast_change(tour.id)

          {:noreply,
           socket
           |> assign(:event_modal_open, false)
           |> assign(:editing_event, nil)
           |> load_tour_data(tour)}

        {:error, changeset} ->
          {:noreply, assign(socket, :event_form, Phoenix.Component.to_form(changeset))}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("delete_event", %{"id" => id}, socket) do
    tour = socket.assigns.current_tour

    if tour do
      event = TourmanagerV2.Touring.get_event!(id)
      TourmanagerV2.Touring.delete_event(event)
      TourBroadcast.broadcast_change(tour.id)
      {:noreply, load_tour_data(socket, tour)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("delete_tour", _params, socket) do
    user = socket.assigns.current_user
    tour = socket.assigns.current_tour

    if user && tour do
      case TourmanagerV2.Accounts.delete_tour(user, tour.id) do
        {:ok, _deleted} ->
          TourBroadcast.broadcast_change(tour.id)
          tours = TourmanagerV2.Accounts.list_tours_for_user(user.id)
          next_entry = List.first(tours)

          socket =
            socket
            |> assign(:user_tours, tours)
            |> assign(:tour_menu_open, false)

          socket =
            if next_entry do
              socket
              |> assign(:current_tour, next_entry.tour)
              |> assign(:current_tour_role, next_entry.role)
              |> push_event("persist_tour", %{tour_id: next_entry.tour.id})
              |> load_tour_data(next_entry.tour)
            else
              socket
              |> assign(:current_tour, nil)
              |> assign(:current_tour_role, nil)
              |> load_tour_data(nil)
            end

          {:noreply, socket}

        {:error, :unauthorized} ->
          {:noreply, socket}

        {:error, _reason} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("complete_onboarding", _params, socket) do
    user = socket.assigns.current_user

    case TourmanagerV2.Accounts.complete_onboarding(user) do
      {:ok, updated} ->
        {:noreply, assign(socket, :current_user, updated)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # --- Data loading ---

  def load_tour_data(socket, nil) do
    old_tour = socket.assigns[:current_tour]
    if old_tour, do: TourBroadcast.unsubscribe(old_tour.id)
    socket
    |> assign(:gigs, [])
    |> assign(:today_gig, nil)
    |> assign(:tour_crew, [])
    |> assign(:events, [])
    |> assign(:route, [])
    |> assign(:route_entries, [])
    |> assign(:today_route_entry, nil)
    |> assign(:next_route_entry, nil)
    |> assign(:headerbar_entry, nil)
    |> assign(:headerbar_is_today, false)
    |> assign(:tour_stats, %{shows_played: 0, shows_total: 0, days_on_road: 0, total_days: 0, travel_days: 0, unconfirmed_gigs: 0, start_date: nil, end_date: nil, is_travel_today: false})
  end

  def load_tour_data(socket, tour) do
    old_tour = socket.assigns[:current_tour]
    if old_tour && old_tour.id != tour.id, do: TourBroadcast.unsubscribe(old_tour.id)
    TourBroadcast.subscribe(tour.id)

    alias TourmanagerV2.Touring

    gigs = Touring.list_gigs_for_tour(tour.id)
    today_gig = Touring.get_today_gig(tour.id)
    next_gig = Touring.get_next_gig(tour.id)
    active_gig = today_gig || next_gig
    events = Touring.list_events_for_gig(active_gig && active_gig.id)
    tour_crew = Touring.list_crew_for_tour(tour.id)
    route = Touring.build_route(tour.id)
    stats = Touring.tour_stats(tour.id)

    route_entries = Touring.build_route_with_entries(tour.id)

    today_re = Touring.get_today_route_entry(tour.id)
    next_re = Touring.get_next_route_entry(tour.id)

    {headerbar_entry, headerbar_is_today} =
      cond do
        today_re -> {today_re, true}
        next_re -> {next_re, false}
        true -> {nil, false}
      end

    socket
    |> assign(:gigs, gigs)
    |> assign(:today_gig, active_gig)
    |> assign(:tour_crew, tour_crew)
    |> assign(:events, events)
    |> assign(:route, route)
    |> assign(:route_entries, route_entries)
    |> assign(:today_route_entry, today_re)
    |> assign(:next_route_entry, next_re)
    |> assign(:headerbar_entry, headerbar_entry)
    |> assign(:headerbar_is_today, headerbar_is_today)
    |> assign(:tour_stats, stats)
  end

  # --- Private helpers ---

  defp handle_place_selection(socket, place_id, field) do
    case TourmanagerV2.GoogleMaps.place_details(place_id) do
      {:ok, place} ->
        image_url =
          if place.photo_ref do
            TourmanagerV2.GoogleMaps.photo_url(place.photo_ref)
          else
            TourmanagerV2.GoogleMaps.venue_image_url("#{place.lat},#{place.lng}")
          end

        city = extract_city(place.address)

        current_params =
          if socket.assigns[:add_route_form] do
            socket.assigns.add_route_form.params || %{}
          else
            %{}
          end

        field_updates =
          case field do
            "origin" ->
              %{
                "origin" => place.name,
                "origin_place_id" => place.place_id,
                "origin_lat" => place.lat && to_string(place.lat),
                "origin_lng" => place.lng && to_string(place.lng),
                "origin_address" => place.address
              }

            "destination" ->
              %{
                "destination" => place.name,
                "dest_place_id" => place.place_id,
                "dest_lat" => place.lat && to_string(place.lat),
                "dest_lng" => place.lng && to_string(place.lng),
                "dest_address" => place.address
              }

            _ ->
              %{
                "venue" => place.name,
                "city" => city,
                "place_id" => place.place_id,
                "lat" => place.lat && to_string(place.lat),
                "lng" => place.lng && to_string(place.lng),
                "venue_image_url" => image_url
              }
          end

        merged = Map.merge(current_params, Map.put(field_updates, "type", socket.assigns.add_route_type))
        source = editing_source(socket)
        changeset = TourmanagerV2.Touring.change_route_entry(source, merged)

        {:noreply,
         socket
         |> assign(:add_route_form, Phoenix.Component.to_form(changeset))
         |> assign(:place_suggestions, [])
         |> assign(:autocomplete_field, nil)}

      _ ->
        {:noreply, assign(socket, :place_suggestions, [])}
    end
  end

  defp editing_source(socket) do
    if socket.assigns[:editing_route] && socket.assigns[:editing_route_entry] do
      socket.assigns.editing_route_entry
    else
      %TourmanagerV2.Touring.RouteEntry{}
    end
  end

  defp maybe_fetch_travel_time(%{"type" => "vehicle_travel", "origin" => origin, "destination" => dest} = params)
       when is_binary(origin) and origin != "" and is_binary(dest) and dest != "" do
    case TourmanagerV2.GoogleMaps.distance_between(origin, dest) do
      {:ok, %{km: km, duration_seconds: dur}} ->
        params
        |> Map.put("distance_km", to_string(km))
        |> Map.put("travel_duration_seconds", dur && to_string(dur))

      _ ->
        params
    end
  end

  defp maybe_fetch_travel_time(params), do: params

  defp extract_city(address) when is_binary(address) do
    parts = String.split(address, ",") |> Enum.map(&String.trim/1)

    case length(parts) do
      n when n >= 3 -> Enum.at(parts, -3)
      n when n >= 2 -> Enum.at(parts, 0)
      _ -> address
    end
  end

  defp extract_city(_), do: nil

  defp ensure_gig_for_tour(tour, socket) do
    date = socket.assigns[:selected_date]
    active_entry = socket.assigns[:today_route_entry] || socket.assigns[:next_route_entry]

    {date, name} =
      cond do
        date -> {date, "Show"}
        active_entry -> {active_entry.date || Date.utc_today(), active_entry.venue || active_entry.city || "Show"}
        true -> {Date.utc_today(), "Show"}
      end

    existing = TourmanagerV2.Touring.get_gig_for_date(tour.id, date)

    if existing do
      existing
    else
      case TourmanagerV2.Repo.insert(
             %TourmanagerV2.Touring.Gig{tour_id: tour.id, workspace_id: tour.workspace_id}
             |> TourmanagerV2.Touring.Gig.changeset(%{name: name, date: date})
           ) do
        {:ok, gig} -> gig
        _ -> nil
      end
    end
  end
end
