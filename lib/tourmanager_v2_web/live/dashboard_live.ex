defmodule TourmanagerV2Web.DashboardLive do
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(TourSwitching.default_assigns())
      |> assign(active_nav: "dashboard", page_title: "Dashboard")
      |> TourSwitching.load_tour_data(socket.assigns[:current_tour])
      |> compute_dashboard_assigns()

    {:ok, socket}
  end

  def handle_event("select_tour", %{"tour-id" => tour_id}, socket) do
    {:noreply, socket} = TourSwitching.handle_event("select_tour", %{"tour-id" => tour_id}, socket)
    {:noreply, compute_dashboard_assigns(socket)}
  end

  def handle_info({:tour_data_changed, tour_id, source_pid}, socket) do
    if source_pid != self() && socket.assigns[:current_tour] && socket.assigns.current_tour.id == tour_id do
      socket =
        socket
        |> TourSwitching.load_tour_data(socket.assigns.current_tour)
        |> compute_dashboard_assigns()

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp compute_dashboard_assigns(socket) do
    stats = socket.assigns[:tour_stats] || %{
      shows_played: 0, shows_total: 0, days_on_road: 0, total_days: 0,
      travel_days: 0, unconfirmed_gigs: 0, start_date: nil, end_date: nil,
      is_travel_today: false
    }
    crew = socket.assigns[:tour_crew] || []

    assign(socket,
      stats: stats,
      gig_tile: build_gig_tile(stats),
      days_tile: build_days_tile(stats),
      crew_cards: build_crew_cards(crew)
    )
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
    >
      <div id="dashboard" class="p-4 md:p-7">
        <div class="flex items-end justify-between mb-5">
          <div>
            <.overline>Management</.overline>
            <.display size={26} class="mt-1.5">
              <%= if @current_tour do %>
                {@current_tour.name}
              <% else %>
                Tour at a glance
              <% end %>
            </.display>
          </div>
        </div>

        <%= if @current_tour do %>
          <%!-- Metric row — 4 tiles --%>
          <div id="metrics-row" class="grid grid-cols-2 md:grid-cols-4 gap-3.5 mb-5">
            <%!-- Tile 1: Gigs --%>
            <div
              class="relative p-[18px] rounded-[var(--radius-md)] tm-halftone tm-halftone--light border-2 border-[var(--ink-900)]"
              style="background: var(--surface-stage); color: var(--paper-100); box-shadow: var(--shadow-hard);"
            >
              <div class="relative z-[2]">
                <div style="font-family: var(--font-mono); font-size: 10px; letter-spacing: 0.16em; text-transform: uppercase; color: var(--brand);">
                  Gigs
                </div>
                <div class="flex items-center gap-2" style="margin-top: 8px;">
                  <div style="font-family: var(--font-display); font-weight: 800; font-size: 40px; letter-spacing: -0.02em; line-height: 1; color: #fff;">
                    {@gig_tile.value}
                  </div>
                  <%= if @stats.is_travel_today && @stats.shows_played > 0 do %>
                    <.signal_chip tone="load" size="sm" variant="tint">TRAVEL DAY</.signal_chip>
                  <% end %>
                </div>
                <div class="mt-1.5 flex items-center gap-2">
                  <span style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-300);">{@gig_tile.sub}</span>
                  <%= if @stats.unconfirmed_gigs > 0 do %>
                    <span
                      class="px-1.5 py-0.5 rounded-[var(--radius-stamp)]"
                      style="background: var(--signal-stop); color: #fff; font-family: var(--font-mono); font-weight: 700; font-size: 9px; letter-spacing: 0.06em;"
                    >{@stats.unconfirmed_gigs} unconfirmed</span>
                  <% end %>
                </div>
              </div>
            </div>

            <%!-- Tile 2: Days --%>
            <div
              class="relative p-[18px] rounded-[var(--radius-md)] border border-[var(--paper-300)]"
              style="background: var(--surface-card); color: var(--ink-700); box-shadow: var(--shadow-sm);"
            >
              <div class="relative z-[2]">
                <div style="font-family: var(--font-mono); font-size: 10px; letter-spacing: 0.16em; text-transform: uppercase; color: var(--ink-400);">
                  Days
                </div>
                <div class="flex items-center gap-2" style="margin-top: 8px;">
                  <div style="font-family: var(--font-display); font-weight: 800; font-size: 40px; letter-spacing: -0.02em; line-height: 1; color: var(--ink-900);">
                    {@days_tile.value}
                  </div>
                  <%= if @stats.is_travel_today && @stats.days_on_road > 0 do %>
                    <.signal_chip tone="load" size="sm" variant="tint">TRAVEL DAY</.signal_chip>
                  <% end %>
                </div>
                <div class="mt-1.5" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">
                  {@days_tile.sub}
                </div>
              </div>
            </div>

            <%!-- Tile 3: Empty --%>
            <div
              class="relative p-[18px] rounded-[var(--radius-md)] border border-[var(--paper-300)]"
              style="background: var(--surface-card); box-shadow: var(--shadow-sm);"
            />

            <%!-- Tile 4: Empty --%>
            <div
              class="relative p-[18px] rounded-[var(--radius-md)] border border-[var(--paper-300)]"
              style="background: var(--surface-card); box-shadow: var(--shadow-sm);"
            />
          </div>

          <div class="grid grid-cols-1 md:grid-cols-[minmax(0,1.3fr)_minmax(0,1fr)] gap-5 items-start">
            <%!-- Crew roster --%>
            <.stamp_card overline_text="Tour crew">
              <%= if @crew_cards == [] do %>
                <div class="py-6 text-center" style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400);">
                  No crew assigned to this tour yet.
                </div>
              <% else %>
                <div class="flex flex-col gap-3">
                  <div :for={c <- @crew_cards} class="flex items-center gap-3">
                    <.pass init={c.init} tone="ink" size={30} />
                    <div class="flex-1">
                      <div class="text-[13.5px] font-semibold text-[var(--ink-900)]">{c.name}</div>
                      <div style="font-family: var(--font-mono); font-size: 9.5px; letter-spacing: 0.06em; color: var(--ink-400); text-transform: uppercase;">{c.role}</div>
                    </div>
                  </div>
                </div>
              <% end %>
            </.stamp_card>

            <%!-- Tour info --%>
            <div class="flex flex-col gap-[18px]">
              <.stamp_card overline_text="Tour details">
                <div class="flex flex-col gap-2.5">
                  <%= if @current_tour.start_date do %>
                    <div class="flex items-center justify-between">
                      <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400);">START</div>
                      <div style="font-family: var(--font-mono); font-size: 13px; font-weight: 700; color: var(--ink-900);">
                        {Calendar.strftime(@current_tour.start_date, "%d %b %Y")}
                      </div>
                    </div>
                  <% end %>
                  <%= if @current_tour.end_date do %>
                    <div class="flex items-center justify-between">
                      <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400);">END</div>
                      <div style="font-family: var(--font-mono); font-size: 13px; font-weight: 700; color: var(--ink-900);">
                        {Calendar.strftime(@current_tour.end_date, "%d %b %Y")}
                      </div>
                    </div>
                  <% end %>
                  <div class="flex items-center justify-between">
                    <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400);">STATUS</div>
                    <.signal_chip
                      tone={cond do
                        @current_tour.status == "active" -> "live"
                        @current_tour.status == "draft" -> "sound"
                        @current_tour.status == "completed" -> "ink"
                        true -> "stop"
                      end}
                      size="sm"
                    >
                      {@current_tour.status}
                    </.signal_chip>
                  </div>
                </div>
              </.stamp_card>
            </div>
          </div>
        <% else %>
          <div class="py-16 text-center">
            <div style="font-family: var(--font-mono); font-size: 13px; color: var(--ink-400); letter-spacing: 0.06em;">
              Select or create a tour to see the dashboard.
            </div>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  defp build_gig_tile(stats) do
    cond do
      stats.shows_played > 0 ->
        %{value: "#{stats.shows_played}", sub: "of #{stats.shows_total} gigs"}

      stats.shows_total > 0 ->
        %{value: "#{stats.shows_total}", sub: "gigs"}

      true ->
        %{value: "0", sub: "gigs"}
    end
  end

  defp build_days_tile(stats) do
    date_range =
      if stats.start_date && stats.end_date do
        "#{Calendar.strftime(stats.start_date, "%d %b")} – #{Calendar.strftime(stats.end_date, "%d %b")}"
      else
        ""
      end

    cond do
      stats.days_on_road > 0 ->
        %{value: "#{stats.days_on_road}", sub: "of #{stats.total_days} days · #{date_range}"}

      stats.total_days > 0 ->
        %{value: "#{stats.total_days}", sub: "days · #{date_range}"}

      true ->
        %{value: "0", sub: "days"}
    end
  end

  defp build_crew_cards(crew) do
    Enum.take(crew, 6)
    |> Enum.map(fn cm ->
      %{name: cm.name, role: cm.role_title, init: initials(cm.name), pass: "CREW", status: "on-site"}
    end)
  end
end
