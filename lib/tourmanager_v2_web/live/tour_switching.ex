defmodule TourmanagerV2Web.TourSwitching do
  defmacro __using__(_opts) do
    quote do
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
        form = to_form(changeset)

        {:noreply,
         socket
         |> assign(:new_tour_open, true)
         |> assign(:new_tour_form, form)}
      end

      def handle_event("close_new_tour", _params, socket) do
        {:noreply, assign(socket, :new_tour_open, false)}
      end

      def handle_event("validate_tour", %{"tour" => tour_params}, socket) do
        changeset =
          TourmanagerV2.Accounts.change_tour(%TourmanagerV2.Touring.Tour{}, tour_params)
          |> Map.put(:action, :validate)

        {:noreply, assign(socket, :new_tour_form, to_form(changeset))}
      end

      def handle_event("save_tour", %{"tour" => tour_params}, socket) do
        user = socket.assigns.current_user

        case TourmanagerV2.Accounts.create_tour(user, tour_params) do
          {:ok, tour} ->
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
         |> assign(:add_route_form, to_form(changeset))
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
         |> assign(:add_route_form, to_form(changeset))
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
         |> assign(:add_route_form, to_form(changeset))
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

            source =
              if socket.assigns[:editing_route] && socket.assigns[:editing_route_entry] do
                socket.assigns.editing_route_entry
              else
                %TourmanagerV2.Touring.RouteEntry{}
              end

            changeset = TourmanagerV2.Touring.change_route_entry(source, merged)

            {:noreply,
             socket
             |> assign(:add_route_form, to_form(changeset))
             |> assign(:place_suggestions, [])
             |> assign(:autocomplete_field, nil)}

          _ ->
            {:noreply, assign(socket, :place_suggestions, [])}
        end
      end

      def handle_event("validate_route_entry", %{"route_entry" => params}, socket) do
        source =
          if socket.assigns[:editing_route] && socket.assigns[:editing_route_entry] do
            socket.assigns.editing_route_entry
          else
            %TourmanagerV2.Touring.RouteEntry{}
          end

        changeset =
          TourmanagerV2.Touring.change_route_entry(source, params)
          |> Map.put(:action, :validate)

        {:noreply, assign(socket, :add_route_form, to_form(changeset))}
      end

      def handle_event("save_route_entry", %{"route_entry" => params}, socket) do
        tour = socket.assigns.current_tour

        if tour do
          params = maybe_fetch_travel_time(params)

          case TourmanagerV2.Touring.create_route_entry(tour, tour.workspace_id, params) do
            {:ok, _entry} ->
              {:noreply,
               socket
               |> assign(:add_route_open, false)
               |> assign(:place_suggestions, [])
               |> load_tour_data(tour)}

            {:error, changeset} ->
              {:noreply, assign(socket, :add_route_form, to_form(changeset))}
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
              {:noreply,
               socket
               |> assign(:add_route_open, false)
               |> assign(:editing_route, false)
               |> assign(:place_suggestions, [])
               |> load_tour_data(tour)}

            {:error, changeset} ->
              {:noreply, assign(socket, :add_route_form, to_form(changeset))}
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

      defp load_tour_data(socket, nil) do
        socket
        |> assign(:gigs, [])
        |> assign(:today_gig, nil)
        |> assign(:tour_crew, [])
        |> assign(:events, [])
        |> assign(:route, [])
        |> assign(:route_entries, [])
        |> assign(:leg_distances, %{})
        |> assign(:total_distance, 0)
        |> assign(:today_route_entry, nil)
        |> assign(:next_route_entry, nil)
        |> assign(:headerbar_entry, nil)
        |> assign(:headerbar_is_today, false)
        |> assign(:tour_stats, %{shows_played: 0, shows_total: 0, days_on_road: 0, total_days: 0, travel_days: 0, unconfirmed_gigs: 0, start_date: nil, end_date: nil, is_travel_today: false})
      end

      defp load_tour_data(socket, tour) do
        alias TourmanagerV2.Touring

        gigs = Touring.list_gigs_for_tour(tour.id)
        today_gig = Touring.get_today_gig(tour.id)
        next_gig = Touring.get_next_gig(tour.id)
        active_gig = today_gig || next_gig
        events = Touring.list_events_for_gig(active_gig && active_gig.id)
        crew = Touring.list_crew_for_gig(active_gig && active_gig.id)
        tour_crew = Touring.list_crew_for_tour(tour.id)
        route = Touring.build_route(tour.id)
        stats = Touring.tour_stats(tour.id)

        route_entries = Touring.build_route_with_entries(tour.id)

        leg_distances =
          if length(route_entries) >= 2 do
            Touring.compute_leg_distances(route_entries)
          else
            %{}
          end

        total_distance = leg_distances |> Map.values() |> Enum.sum()

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
        |> assign(:leg_distances, leg_distances)
        |> assign(:total_distance, total_distance)
        |> assign(:today_route_entry, today_re)
        |> assign(:next_route_entry, next_re)
        |> assign(:headerbar_entry, headerbar_entry)
        |> assign(:headerbar_is_today, headerbar_is_today)
        |> assign(:tour_stats, stats)
      end
    end
  end
end
