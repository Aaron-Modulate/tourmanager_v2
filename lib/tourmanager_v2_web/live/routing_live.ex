defmodule TourmanagerV2Web.RoutingLive do
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(TourSwitching.default_assigns())
      |> assign(active_nav: "routing", page_title: "Routing")
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

  def handle_event("delete_route_entry", params, socket) do
    TourSwitching.handle_event("delete_route_entry", params, socket)
    |> then(fn {:noreply, socket} ->
      {:noreply, compute_route_assigns(socket) |> push_map_markers()}
    end)
  end

  defp load_and_compute(socket, tour) do
    socket
    |> TourSwitching.load_tour_data(tour)
    |> compute_route_assigns()
    |> push_map_markers()
  end

  defp compute_route_assigns(socket) do
    route_entries = socket.assigns[:route_entries] || []
    unit = if socket.assigns[:current_user], do: socket.assigns.current_user.distance_unit, else: "km"

    assign(socket,
      route_data: route_entries,
      today_stop: Enum.find(route_entries, fn r -> r.status == "today" end),
      next_stop: Enum.find(route_entries, fn r -> r.status == "next" end),
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
    >
      <div id="routing" class="p-4 md:p-7 grid grid-cols-1 md:grid-cols-[minmax(0,1fr)_minmax(0,1fr)] gap-5 items-start">
        <%!-- Left: the road list --%>
        <div>
          <div class="flex items-end justify-between mb-[18px]">
            <div>
              <.overline>Routing</.overline>
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
            <div class="relative pl-2">
              <div class="absolute left-[35px] top-3 bottom-3 w-0.5 bg-[var(--paper-300)]" />
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
                    distance_label={if r.km > 0, do: TourmanagerV2.GoogleMaps.format_distance_dual(r.km)}
                  />
                  <button
                    type="button"
                    phx-click="edit_route"
                    phx-value-id={r.id}
                    class="absolute top-2 right-2 w-7 h-7 flex items-center justify-center rounded-[var(--radius-sm)] cursor-pointer opacity-0 group-hover:opacity-100 transition-opacity"
                    style="background: var(--surface-card); border: 1px solid var(--paper-300); box-shadow: var(--shadow-sm);"
                    title="Edit stop"
                  >
                    <.icon name="hero-pencil-mini" class="w-3.5 h-3.5 text-[var(--ink-400)]" />
                  </button>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>

        <%!-- Right: interactive map + next move --%>
        <div class="flex flex-col gap-[18px] sticky top-0">
          <%!-- Tour map — always present, lazy-loaded via IntersectionObserver --%>
          <div
            id="tour-map"
            phx-hook=".TourMap"
            data-api-key={System.get_env("GOOGLE_PLACES_API_KEY")}
            class="rounded-[var(--radius-md)] overflow-hidden border-2 border-[var(--ink-900)]"
            style="height: 360px; background: var(--ink-900); box-shadow: var(--shadow-hard);"
          >
            <%= if @route_data == [] do %>
              <div class="flex items-center justify-center h-full">
                <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-500); letter-spacing: 0.06em;">
                  ADD STOPS TO SEE THE MAP
                </div>
              </div>
            <% end %>
          </div>
          <script :type={Phoenix.LiveView.ColocatedHook} name=".TourMap">
            export default {
              mounted() {
                this._markers = []
                this._mapInstance = null
                this._gMarkers = []
                this._polyline = null
                this._infoWindow = null
                this._apiLoaded = false
                this._visible = false

                this.handleEvent("map_markers", ({markers}) => {
                  this._markers = markers || []
                  if (this._visible && this._apiLoaded) this.renderMap()
                })

                this.observer = new IntersectionObserver(([entry]) => {
                  if (entry.isIntersecting && !this._visible) {
                    this._visible = true
                    this.loadApi()
                  }
                }, { threshold: 0.1 })
                this.observer.observe(this.el)
              },

              destroyed() {
                if (this.observer) this.observer.disconnect()
                this.clearMap()
              },

              loadApi() {
                const apiKey = this.el.dataset.apiKey
                if (!apiKey) return

                if (window.google && window.google.maps) {
                  this._apiLoaded = true
                  this.renderMap()
                  return
                }

                if (document.querySelector('script[src*="maps.googleapis.com"]')) {
                  const check = setInterval(() => {
                    if (window.google && window.google.maps) {
                      clearInterval(check)
                      this._apiLoaded = true
                      this.renderMap()
                    }
                  }, 100)
                  return
                }

                const script = document.createElement("script")
                script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}`
                script.async = true
                script.defer = true
                script.onload = () => {
                  this._apiLoaded = true
                  this.renderMap()
                }
                document.head.appendChild(script)
              },

              clearMap() {
                if (this._gMarkers) this._gMarkers.forEach(m => m.setMap(null))
                if (this._polyline) this._polyline.setMap(null)
                if (this._infoWindow) this._infoWindow.close()
                this._gMarkers = []
                this._polyline = null
              },

              renderMap() {
                const markers = this._markers
                if (!markers.length) return

                this.clearMap()

                const bounds = new google.maps.LatLngBounds()
                markers.forEach(m => bounds.extend({lat: m.lat, lng: m.lng}))

                if (!this._mapInstance) {
                  this._mapInstance = new google.maps.Map(this.el, {
                    center: bounds.getCenter(),
                    zoom: 6,
                    disableDefaultUI: true,
                    zoomControl: true,
                    styles: [
                      {elementType: "geometry", stylers: [{color: "#14110F"}]},
                      {elementType: "labels.text.fill", stylers: [{color: "#A89E92"}]},
                      {elementType: "labels.text.stroke", stylers: [{color: "#14110F"}]},
                      {featureType: "road", elementType: "geometry", stylers: [{color: "#2A2520"}]},
                      {featureType: "water", elementType: "geometry", stylers: [{color: "#1E1A17"}]},
                      {featureType: "poi", stylers: [{visibility: "off"}]},
                      {featureType: "transit", stylers: [{visibility: "off"}]}
                    ]
                  })
                  this._infoWindow = new google.maps.InfoWindow()
                }

                this._mapInstance.fitBounds(bounds, 40)

                markers.forEach(m => {
                  const statusColor = m.status === "today" ? "#2B4FF0"
                    : m.status === "done" ? "#574E45"
                    : "#F5F1E8"

                  const gm = new google.maps.Marker({
                    position: {lat: m.lat, lng: m.lng},
                    map: this._mapInstance,
                    label: {
                      text: m.label,
                      color: m.status === "done" ? "#A89E92" : "#14110F",
                      fontFamily: "'Space Mono', monospace",
                      fontWeight: "700",
                      fontSize: "10px"
                    },
                    icon: {
                      path: google.maps.SymbolPath.CIRCLE,
                      scale: 16,
                      fillColor: statusColor,
                      fillOpacity: 1,
                      strokeColor: "#14110F",
                      strokeWeight: 2
                    }
                  })
                  this._gMarkers.push(gm)

                  const imgHtml = m.image_url
                    ? `<img src="${m.image_url}" style="width:100%;height:100px;object-fit:cover;border-radius:4px 4px 0 0;" />`
                    : ""

                  const mapsLink = m.maps_link
                    ? `<a href="${m.maps_link}" target="_blank" style="font-family:'Space Mono',monospace;font-size:10px;font-weight:700;letter-spacing:0.06em;color:#837A6F;text-decoration:none;display:flex;align-items:center;gap:4px;margin-top:8px;">OPEN IN GOOGLE ↗</a>`
                    : ""

                  const content = `
                    <div style="width:220px;background:#FBF9F3;border:2px solid #14110F;border-radius:8px;overflow:hidden;box-shadow:3px 3px 0 #14110F;font-family:'Archivo',sans-serif;">
                      ${imgHtml}
                      <div style="padding:10px;">
                        <div style="font-family:'Bricolage Grotesque',sans-serif;font-weight:700;font-size:14px;color:#14110F;">${m.venue || "Stop"}</div>
                        <div style="font-family:'Space Mono',monospace;font-size:10px;color:#837A6F;margin-top:3px;">${m.city || ""}</div>
                        ${m.address ? `<div style="font-family:'Space Mono',monospace;font-size:9px;color:#A89E92;margin-top:2px;">${m.address}</div>` : ""}
                        ${mapsLink}
                      </div>
                    </div>
                  `

                  gm.addListener("click", () => {
                    this._infoWindow.setContent(content)
                    this._infoWindow.open(this._mapInstance, gm)
                  })

                  gm.addListener("mouseover", () => {
                    this._infoWindow.setContent(content)
                    this._infoWindow.open(this._mapInstance, gm)
                  })
                })

                if (markers.length > 1) {
                  this._polyline = new google.maps.Polyline({
                    path: markers.map(m => ({lat: m.lat, lng: m.lng})),
                    geodesic: true,
                    strokeColor: "#2B4FF0",
                    strokeOpacity: 0.6,
                    strokeWeight: 2
                  })
                  this._polyline.setMap(this._mapInstance)
                }
              }
            }
          </script>

          <%!-- Next move --%>
          <%= if @next_stop do %>
            <.stamp_card hard overline_text="Next move" padding="18px">
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
          <% end %>

          <%!-- Onboarding nudge to add second stop --%>
          <.onboarding_add_stop_nudge route_count={length(@route_data)} />
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
