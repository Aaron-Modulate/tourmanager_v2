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

  def render(assigns) do
    route_entries = assigns[:route_entries] || []
    leg_distances = assigns[:leg_distances] || %{}
    unit = if assigns[:current_user], do: assigns.current_user.distance_unit, else: "km"
    total = assigns[:total_distance] || 0

    today_stop = Enum.find(route_entries, fn r -> r.status == "today" end)
    next_stop = Enum.find(route_entries, fn r -> r.status == "next" end)

    assigns =
      assigns
      |> Map.put(:route_data, route_entries)
      |> Map.put(:leg_distances, leg_distances)
      |> Map.put(:total_distance_val, total)
      |> Map.put(:distance_unit, unit)
      |> Map.put(:today_stop, today_stop)
      |> Map.put(:next_stop, next_stop)

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
            <div class="flex items-center gap-3">
              <div class="text-right" style="font-family: var(--font-mono);">
                <div style="font-size: 10px; letter-spacing: 0.18em; color: var(--ink-400);">TOTAL DISTANCE</div>
                <div style="font-size: 18px; font-weight: 700; color: var(--ink-900);">
                  {TourmanagerV2.GoogleMaps.format_distance(@total_distance_val, @distance_unit)}
                </div>
              </div>
              <%= if @current_tour && @current_user do %>
                <.tm_button variant="secondary" size="sm" icon_name="hero-plus" phx-click="open_add_route">Add</.tm_button>
              <% end %>
            </div>
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

        <%!-- Right: poster map panel + next move --%>
        <div class="flex flex-col gap-[18px] sticky top-0">
          <%= if @route_data != [] do %>
            <div
              class="tm-halftone tm-halftone--light relative rounded-[var(--radius-md)] overflow-hidden border-2 border-[var(--ink-900)] flex flex-col justify-between p-5 min-h-[280px]"
              style="background: var(--surface-stage); box-shadow: var(--shadow-hard);"
            >
              <div class="relative z-[2] flex justify-between items-start">
                <div>
                  <div style="font-family: var(--font-mono); font-size: 10px; letter-spacing: 0.22em; color: var(--brand);">
                    {if @current_tour, do: String.upcase(@current_tour.name), else: "TOUR"}
                  </div>
                  <.display size={28} class="mt-1.5" style="color: #fff;">
                    {Enum.at(@route_data, 0).city} → {Enum.at(@route_data, -1).city}
                  </.display>
                </div>
                <.signal_chip tone="brand" hard>{length(@route_data)} stops</.signal_chip>
              </div>
              <div class="relative z-[2] flex items-center justify-between mt-6">
                <%= for {r, i} <- Enum.with_index(@route_data) do %>
                  <div class="flex flex-col items-center gap-1.5">
                    <span
                      class="w-[11px] h-[11px] rounded-full"
                      style={"background: #{cond do
                        r.status == "today" -> "var(--brand)"
                        r.status == "done" -> "var(--ink-500)"
                        true -> "var(--paper-100)"
                      end};"}
                    />
                    <span style={"font-family: var(--font-mono); font-size: 9px; font-weight: 700; color: #{if r.status == "today", do: "#fff", else: "var(--ink-300)"};"}>
                      {r.code}
                    </span>
                  </div>
                  <div :if={i < length(@route_data) - 1} class="flex-1 h-0.5 bg-[var(--ink-700)] mx-0.5 mb-4" />
                <% end %>
              </div>
            </div>
          <% end %>

          <%!-- Next move with venue photo --%>
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
                    <%= if km = Map.get(@leg_distances, @next_stop.id) do %>
                      · {TourmanagerV2.GoogleMaps.format_distance(km, @distance_unit)}
                    <% end %>
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
              <%!-- Maps link: directions for travel, pin for gigs --%>
              <%= cond do %>
                <% @next_stop.type == "vehicle_travel" && @next_stop.entry.origin && @next_stop.entry.destination -> %>
                  <a
                    href={TourmanagerV2.GoogleMaps.directions_url(@next_stop.entry)}
                    target="_blank"
                    class="flex items-center gap-1.5 mt-3 no-underline transition-colors hover:text-[var(--brand)]"
                    style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400);"
                  >
                    <.icon name="hero-map-pin-mini" class="w-3.5 h-3.5" />
                    OPEN ROUTE IN MAPS
                    <.icon name="hero-arrow-top-right-on-square-mini" class="w-3 h-3" />
                  </a>
                <% @next_stop.entry.place_id -> %>
                  <a
                    href={"https://www.google.com/maps/place/?q=place_id:#{@next_stop.entry.place_id}"}
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

      <%!-- Unified create/edit route modal --%>
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
