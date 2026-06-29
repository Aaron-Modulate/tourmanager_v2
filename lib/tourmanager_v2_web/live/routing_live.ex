defmodule TourmanagerV2Web.RoutingLive do
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(TourSwitching.default_assigns())
      |> assign(active_nav: "routing", page_title: "Tour Schedule")
      |> load_and_compute(socket.assigns[:current_tour])

    {:ok, socket}
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
        |> load_and_compute(entry.tour)
      else
        assign(socket, :tour_menu_open, false)
      end

    {:noreply, socket}
  end

  def handle_event("save_route_entry", %{"route_entry" => params} = _full, socket) do
    TourSwitching.handle_event("save_route_entry", %{"route_entry" => params}, socket)
    |> then(fn {:noreply, socket} ->
      {:noreply, compute_route_assigns(socket) |> push_map_markers()}
    end)
  end

  def handle_event("update_route_entry", %{"route_entry" => params}, socket) do
    TourSwitching.handle_event("update_route_entry", %{"route_entry" => params}, socket)
    |> then(fn {:noreply, socket} ->
      {:noreply, compute_route_assigns(socket) |> push_map_markers()}
    end)
  end

  def handle_event("delete_route_inline", %{"id" => id}, socket) do
    entry = TourmanagerV2.Touring.get_route_entry!(id)
    tour = socket.assigns.current_tour

    if entry && tour do
      TourmanagerV2.Touring.delete_route_entry(entry)
      TourmanagerV2.TourBroadcast.broadcast_change(tour.id)
      {:noreply, compute_route_assigns(socket |> TourSwitching.load_tour_data(tour)) |> push_map_markers()}
    else
      {:noreply, socket}
    end
  end

  def handle_event("delete_route_entry", params, socket) do
    TourSwitching.handle_event("delete_route_entry", params, socket)
    |> then(fn {:noreply, socket} ->
      {:noreply, compute_route_assigns(socket) |> push_map_markers()}
    end)
  end

  def handle_info({:tour_data_changed, tour_id, source_pid}, socket) do
    if source_pid != self() && socket.assigns[:current_tour] && socket.assigns.current_tour.id == tour_id do
      {:noreply, load_and_compute(socket, socket.assigns.current_tour)}
    else
      {:noreply, socket}
    end
  end

  defp load_and_compute(socket, tour) do
    socket
    |> TourSwitching.load_tour_data(tour)
    |> compute_route_assigns()
    |> push_map_markers()
  end

  defp compute_route_assigns(socket) do
    route_entries = socket.assigns[:route_entries] || []
    tour = socket.assigns[:current_tour]
    unit = if socket.assigns[:current_user], do: socket.assigns.current_user.distance_unit, else: "km"

    accommodations =
      if tour do
        TourmanagerV2.Touring.list_accommodations_for_tour(tour.id)
      else
        []
      end

    route_data =
      Enum.map(route_entries, fn r ->
        acc = Enum.find(accommodations, fn a -> a.route_entry_id == r.id end)
        Map.put(r, :accommodation, acc)
      end)

    assign(socket,
      route_data: route_data,
      today_stop: Enum.find(route_data, fn r -> r.status == "today" end),
      next_stop: Enum.find(route_data, fn r -> r.status == "next" end),
      distance_unit: unit
    )
  end

  defp push_map_markers(socket) do
    markers = map_markers(socket.assigns[:route_entries] || [])
    push_event(socket, "map_markers", %{markers: markers})
  end

  defp map_markers(route_data) do
    route_data
    |> Enum.filter(fn r -> r.entry.lat && r.entry.lng end)
    |> Enum.map(fn r ->
      %{
        lat: r.entry.lat,
        lng: r.entry.lng,
        label: "D#{String.pad_leading(to_string(r.day), 2, "0")}",
        venue: r.venue,
        city: r.city,
        address: r.address,
        type: r.type,
        status: r.status,
        image_url: r.entry.venue_image_url,
        maps_link: TourmanagerV2.GoogleMaps.search_url(%{venue: r.venue, city: r.city})
      }
    end)
  end

  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      active_nav={@active_nav}
      current_user={@current_user}
      user_tours={@user_tours}
      current_tour={@current_tour}
      current_tour_role={@current_tour_role}
      tour_menu_open={@tour_menu_open}
      settings_open={@settings_open}
      new_tour_open={@new_tour_open}
      new_tour_form={@new_tour_form}
      headerbar_entry={@headerbar_entry}
      headerbar_is_today={@headerbar_is_today}
      billing_seats={@billing_seats}
      billing_error={@billing_error}
      manage_tour_open={@manage_tour_open}
      manage_tour_form={@manage_tour_form}
      calendar_modal_open={@calendar_modal_open}
      calendar_token={@calendar_token}
      calendar_mode={@calendar_mode}
    >
      <%!-- Mobile: next stop at top of page --%>
      <div :if={@next_stop} class="md:hidden p-4 pb-0">
        <.stamp_card hard overline_text="Next stop" padding="18px">
          <img
            :if={@next_stop.entry.venue_image_url}
            src={@next_stop.entry.venue_image_url}
            class="w-full h-28 object-cover rounded-[var(--radius-sm)] mb-3"
            style="border: 1px solid var(--paper-300);"
            loading="lazy"
          />
          <div class="flex items-center gap-3.5">
            <.pass init={@next_stop.code} tone="brand" size={42} />
            <div class="flex-1">
              <.display size={18}>{@next_stop.venue}</.display>
              <div class="mt-1" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">
                {@next_stop.city}
                <%= if @next_stop.travel_duration do %>
                  · {TourmanagerV2.GoogleMaps.format_duration(@next_stop.travel_duration)}
                <% end %>
              </div>
            </div>
            <.signal_chip tone="doors">D{String.pad_leading(to_string(@next_stop.day), 2, "0")}</.signal_chip>
          </div>
        </.stamp_card>
      </div>

      <div id="routing" class="p-4 md:p-7 grid grid-cols-1 md:grid-cols-[minmax(0,1fr)_minmax(0,1fr)] gap-5 items-start">
        <%!-- Left: the road list --%>
        <div>
          <div class="flex items-end justify-between mb-[18px]">
            <div>
              <.overline>Tour schedule</.overline>
              <.display size={26} class="mt-1.5">The road</.display>
            </div>
            <%= if @current_tour && @current_user do %>
              <.tm_button variant="secondary" size="sm" icon_name="hero-plus" phx-click="open_add_route">Add</.tm_button>
            <% end %>
          </div>

          <%= if @route_data == [] do %>
            <div class="py-12 text-center">
              <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400); letter-spacing: 0.06em;">
                <%= if @current_tour do %>
                  No stops on this tour yet. Add gigs, travel days, or off days.
                <% else %>
                  Select or create a tour to see the routing.
                <% end %>
              </div>
            </div>
          <% else %>
            <div class="relative">
              <%= for r <- @route_data do %>
                <div class="group relative">
                  <.route_stop_enhanced
                    day={r.day}
                    date={r.date}
                    city={r.city}
                    venue={r.venue}
                    code={r.code}
                    km={r.km}
                    status={r.status}
                    type={r.type}
                    venue_image_url={r.entry.venue_image_url}
                    travel_duration={r.travel_duration}
                    booking_ref={r.booking_ref}
                    address={r.address}
                    entry_id={r.id}
                    place_id={r.entry.place_id}
                    lat={r.entry.lat}
                    lng={r.entry.lng}
                    origin_address={r.entry.origin_address}
                    dest_address={r.entry.dest_address}
                    directions_url={TourmanagerV2.GoogleMaps.directions_url(r.entry)}
                    distance_label={if(r.type == "vehicle_travel" && r.km > 0, do: TourmanagerV2.GoogleMaps.format_distance(r.km, @distance_unit))}
                    accommodation_name={r.accommodation && r.accommodation.location}
                  />
                  <div class="absolute top-2 right-2 z-10">
                    <.overflow_menu id={"route-menu-#{r.id}"}>
                      <%= if r.type == "gig" && r.raw_date do %>
                        <.link navigate={"/app?date=#{Date.to_iso8601(r.raw_date)}"} class="w-full text-left px-3 py-2 flex items-center gap-2 cursor-pointer transition-colors hover:bg-[var(--paper-200)] no-underline" style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-500);">
                          <.icon name="hero-clipboard-document-list-mini" class="w-3.5 h-3.5" /> DAY SHEET
                        </.link>
                      <% end %>
                      <button type="button" phx-click="edit_route" phx-value-id={r.id} class="w-full text-left px-3 py-2 flex items-center gap-2 cursor-pointer transition-colors hover:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-500);">
                        <.icon name="hero-pencil-mini" class="w-3.5 h-3.5" /> EDIT
                      </button>
                      <button type="button" phx-click="delete_route_inline" phx-value-id={r.id} data-confirm="Delete this stop?" class="w-full text-left px-3 py-2 flex items-center gap-2 cursor-pointer transition-colors hover:bg-[var(--signal-stop-tint)] border-t border-[var(--paper-300)]" style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--signal-stop);">
                        <.icon name="hero-trash-mini" class="w-3.5 h-3.5" /> DELETE
                      </button>
                    </.overflow_menu>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>

          <.onboarding_add_stop_nudge route_count={length(@route_data)} />
        </div>

        <%!-- Right: next stop (desktop) + map --%>
        <div class="flex flex-col gap-[18px] sticky top-0">
          <%!-- Next stop — desktop only (mobile version is above the grid) --%>
          <%= if @next_stop do %>
            <div class="hidden md:block">
              <.stamp_card hard overline_text="Next stop" padding="18px">
                <img
                  :if={@next_stop.entry.venue_image_url}
                  src={@next_stop.entry.venue_image_url}
                  class="w-full h-32 object-cover rounded-[var(--radius-sm)] mb-3"
                  style="border: 1px solid var(--paper-300);"
                  loading="lazy"
                />
                <div class="flex items-center gap-3.5">
                  <.pass init={@next_stop.code} tone="brand" size={46} />
                  <div class="flex-1">
                    <.display size={20}>{@next_stop.venue}</.display>
                    <div class="mt-1" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">
                      {@next_stop.city}
                      <%= if @next_stop.travel_duration do %>
                        · {TourmanagerV2.GoogleMaps.format_duration(@next_stop.travel_duration)}
                      <% end %>
                    </div>
                    <div :if={@next_stop.booking_ref} class="mt-0.5" style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.06em; color: var(--ink-400);">
                      REF: {@next_stop.booking_ref}
                    </div>
                  </div>
                  <.signal_chip tone="doors">D{String.pad_leading(to_string(@next_stop.day), 2, "0")}</.signal_chip>
                </div>
                <%= cond do %>
                  <% @next_stop.type == "vehicle_travel" -> %>
                    <a
                      :if={TourmanagerV2.GoogleMaps.directions_url(@next_stop.entry)}
                      href={TourmanagerV2.GoogleMaps.directions_url(@next_stop.entry)}
                      target="_blank"
                      class="flex items-center gap-1.5 mt-3 no-underline transition-colors hover:text-[var(--brand)]"
                      style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400);"
                    >
                      <.icon name="hero-map-pin-mini" class="w-3.5 h-3.5" />
                      OPEN ROUTE IN MAPS
                      <.icon name="hero-arrow-top-right-on-square-mini" class="w-3 h-3" />
                    </a>
                  <% @next_stop.type == "gig" -> %>
                    <a
                      href={TourmanagerV2.GoogleMaps.search_url(%{venue: @next_stop.venue, city: @next_stop.city})}
                      target="_blank"
                      class="flex items-center gap-1.5 mt-3 no-underline transition-colors hover:text-[var(--brand)]"
                      style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400);"
                    >
                      <.icon name="hero-map-pin-mini" class="w-3.5 h-3.5" />
                      OPEN IN MAPS
                      <.icon name="hero-arrow-top-right-on-square-mini" class="w-3 h-3" />
                    </a>
                  <% true -> %>
                <% end %>
              </.stamp_card>
            </div>
          <% end %>

          <%!-- Map (hidden, but hook still active for marker data) --%>
          <div
            id="tour-map"
            phx-hook=".TourMap"
            data-api-key={System.get_env("GOOGLE_PLACES_API_KEY")}
            class="hidden"
            style="height: 0;"
          />
          <script :type={Phoenix.LiveView.ColocatedHook} name=".TourMap">
            export default {
              mounted() {
                this._markers = []
                this.handleEvent("map_markers", ({markers}) => {
                  this._markers = markers || []
                })
              },
              destroyed() {}
            }
          </script>
        </div>
      </div>

      <.route_entry_modal
        :if={@add_route_form}
        form={@add_route_form}
        show={@add_route_open}
        entry_type={@add_route_type}
        editing={@editing_route}
        place_suggestions={@place_suggestions}
        autocomplete_field={@autocomplete_field}
      />
    </Layouts.app>
    """
  end
end
