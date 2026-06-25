defmodule TourmanagerV2Web.RoutingLive do
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(
        active_nav: "routing",
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
        page_title: "Routing"
      )
      |> load_tour_data(socket.assigns[:current_tour])

    {:ok, socket}
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
    route_entries = assigns[:route_entries] || []
    leg_distances = assigns[:leg_distances] || %{}
    unit = if assigns[:current_user], do: assigns.current_user.distance_unit, else: "km"

    today_stop = Enum.find(route_entries, fn r -> r.status == "today" end)
    next_stop = Enum.find(route_entries, fn r -> r.status == "next" end)

    markers = map_markers(route_entries)

    assigns =
      assigns
      |> Map.put(:route_data, route_entries)
      |> Map.put(:leg_distances, leg_distances)
      |> Map.put(:distance_unit, unit)
      |> Map.put(:today_stop, today_stop)
      |> Map.put(:next_stop, next_stop)
      |> Map.put(:map_markers, markers)

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
      <div id="routing" class="p-7 grid grid-cols-[minmax(0,1fr)_minmax(0,1fr)] gap-5 items-start">
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
                    distance_label={
                      case Map.get(@leg_distances, r.id) do
                        nil -> nil
                        km -> TourmanagerV2.GoogleMaps.format_distance_dual(km)
                      end
                    }
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
          <%!-- Tour map --%>
          <%= if @route_data != [] do %>
            <div
              id="tour-map"
              phx-hook=".TourMap"
              phx-update="ignore"
              data-markers={Jason.encode!(@map_markers)}
              data-api-key={System.get_env("GOOGLE_PLACES_API_KEY")}
              class="rounded-[var(--radius-md)] overflow-hidden border-2 border-[var(--ink-900)]"
              style="height: 360px; background: var(--ink-900); box-shadow: var(--shadow-hard);"
            />
            <script :type={Phoenix.LiveView.ColocatedHook} name=".TourMap">
              export default {
                mounted() {
                  this.loadMap()
                },
                updated() {
                  this.loadMap()
                },
                loadMap() {
                  const apiKey = this.el.dataset.apiKey
                  if (!apiKey) return

                  const loadGoogleMaps = () => {
                    if (window.google && window.google.maps) {
                      this.initMap()
                      return
                    }
                    if (document.querySelector('script[src*="maps.googleapis.com"]')) {
                      const check = setInterval(() => {
                        if (window.google && window.google.maps) {
                          clearInterval(check)
                          this.initMap()
                        }
                      }, 100)
                      return
                    }
                    const script = document.createElement("script")
                    script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}`
                    script.async = true
                    script.defer = true
                    script.onload = () => this.initMap()
                    document.head.appendChild(script)
                  }

                  loadGoogleMaps()
                },
                initMap() {
                  let markers
                  try {
                    markers = JSON.parse(this.el.dataset.markers || "[]")
                  } catch { markers = [] }

                  if (markers.length === 0) return

                  const bounds = new google.maps.LatLngBounds()
                  markers.forEach(m => bounds.extend({lat: m.lat, lng: m.lng}))

                  const map = new google.maps.Map(this.el, {
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

                  map.fitBounds(bounds, 40)

                  const infoWindow = new google.maps.InfoWindow()

                  markers.forEach((m, i) => {
                    const statusColor = m.status === "today" ? "#2B4FF0"
                      : m.status === "done" ? "#574E45"
                      : "#F5F1E8"

                    const marker = new google.maps.Marker({
                      position: {lat: m.lat, lng: m.lng},
                      map,
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

                    marker.addListener("click", () => {
                      infoWindow.setContent(content)
                      infoWindow.open(map, marker)
                    })

                    marker.addListener("mouseover", () => {
                      infoWindow.setContent(content)
                      infoWindow.open(map, marker)
                    })
                  })

                  if (markers.length > 1) {
                    const path = new google.maps.Polyline({
                      path: markers.map(m => ({lat: m.lat, lng: m.lng})),
                      geodesic: true,
                      strokeColor: "#2B4FF0",
                      strokeOpacity: 0.6,
                      strokeWeight: 2
                    })
                    path.setMap(map)
                  }
                }
              }
            </script>
          <% else %>
            <div
              class="rounded-[var(--radius-md)] overflow-hidden border-2 border-[var(--ink-900)] flex items-center justify-center"
              style="height: 360px; background: var(--ink-900); box-shadow: var(--shadow-hard);"
            >
              <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-500); letter-spacing: 0.06em;">
                ADD STOPS TO SEE THE MAP
              </div>
            </div>
          <% end %>

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
