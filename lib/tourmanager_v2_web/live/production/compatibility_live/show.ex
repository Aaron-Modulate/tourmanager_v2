defmodule TourmanagerV2Web.CompatibilityLive.Show do
  @moduledoc "Tour vs venue compatibility checker."
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  alias TourmanagerV2.Production.{Compatibility, Profiles}
  alias TourmanagerV2.Accounts

  def mount(params, _session, socket) do
    user = socket.assigns.current_user

    all_venues = Profiles.list_all_venues()
    all_tours = if user, do: Accounts.list_tours_for_user(user.id), else: []

    venue_id = params["venue_id"]
    tour_id = params["tour_id"] || (socket.assigns[:current_tour] && socket.assigns.current_tour.id)

    {result, selected_venue, selected_tour} =
      if venue_id && tour_id do
        venue = Enum.find(all_venues, fn v -> v.id == venue_id end)
        tour_entry = Enum.find(all_tours, fn %{tour: t} -> t.id == tour_id end)
        tour = tour_entry && tour_entry.tour

        result = if venue && tour, do: Compatibility.check(venue_id, tour_id), else: nil
        {result, venue, tour}
      else
        {nil, nil, nil}
      end

    socket =
      socket
      |> assign(TourSwitching.default_assigns())
      |> assign(
        active_nav: "production",
        page_title: "Compatibility Check",
        all_venues: all_venues,
        all_tours: all_tours,
        selected_venue: selected_venue,
        selected_tour: selected_tour,
        selected_venue_id: venue_id || "",
        selected_tour_id: tour_id || "",
        result: result
      )
      |> TourSwitching.load_tour_data(socket.assigns[:current_tour])

    {:ok, socket}
  end

  def handle_event("select_venue", %{"venue_id" => venue_id}, socket) do
    socket = assign(socket, :selected_venue_id, venue_id)
    {:noreply, maybe_run_check(socket)}
  end

  def handle_event("select_tour", %{"tour_id" => tour_id}, socket) do
    socket = assign(socket, :selected_tour_id, tour_id)
    {:noreply, maybe_run_check(socket)}
  end

  # Catch-all for TourSwitching's header tour selector
  def handle_event("select_tour", %{"tour-id" => _} = params, socket) do
    TourmanagerV2Web.TourSwitching.handle_event("select_tour", params, socket)
  end

  defp maybe_run_check(socket) do
    venue_id = socket.assigns.selected_venue_id
    tour_id = socket.assigns.selected_tour_id

    if venue_id != "" and tour_id != "" do
      all_venues = socket.assigns.all_venues
      all_tours = socket.assigns.all_tours

      venue = Enum.find(all_venues, fn v -> v.id == venue_id end)
      tour_entry = Enum.find(all_tours, fn %{tour: t} -> t.id == tour_id end)
      tour = tour_entry && tour_entry.tour

      result = if venue && tour, do: Compatibility.check(venue_id, tour_id), else: nil

      socket
      |> assign(:selected_venue, venue)
      |> assign(:selected_tour, tour)
      |> assign(:result, result)
    else
      socket
    end
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
      <div class="p-4 md:p-7 max-w-4xl">
        <div class="mb-6">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);">PRODUCTION</div>
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 26px; letter-spacing: -0.01em; color: var(--ink-900); margin-top: 4px;">Compatibility Check</div>
        </div>

        <%!-- Selectors --%>
        <div class="grid md:grid-cols-2 gap-4 mb-6">
          <div class="p-4 rounded-[var(--radius-md)] border border-[var(--paper-300)]" style="background: var(--surface-card);">
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); margin-bottom: 8px;">VENUE</div>
            <select
              phx-change="select_venue"
              name="venue_id"
              class="w-full px-3 py-2.5 rounded-[var(--radius-md)] border border-[var(--paper-300)] text-[12px] outline-none"
              style="background: var(--paper-200); color: var(--ink-900); font-family: var(--font-mono);"
            >
              <option value="">Select a venue…</option>
              <option :for={v <- @all_venues} value={v.id} selected={v.id == @selected_venue_id}>{v.name}{if v.city, do: " — #{v.city}", else: ""}</option>
            </select>
          </div>
          <div class="p-4 rounded-[var(--radius-md)] border border-[var(--paper-300)]" style="background: var(--surface-card);">
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); margin-bottom: 8px;">TOUR</div>
            <select
              phx-change="select_tour"
              name="tour_id"
              class="w-full px-3 py-2.5 rounded-[var(--radius-md)] border border-[var(--paper-300)] text-[12px] outline-none"
              style="background: var(--paper-200); color: var(--ink-900); font-family: var(--font-mono);"
            >
              <option value="">Select a tour…</option>
              <option :for={%{tour: t} <- @all_tours} value={t.id} selected={t.id == @selected_tour_id}>{t.name}</option>
            </select>
          </div>
        </div>

        <%!-- No selection yet --%>
        <%= if is_nil(@result) do %>
          <div class="py-16 text-center rounded-[var(--radius-md)] border-2 border-dashed border-[var(--paper-300)]">
            <.icon name="hero-scale" class="w-10 h-10 text-[var(--ink-300)] mx-auto mb-3" />
            <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400); letter-spacing: 0.06em;">
              Select a venue and tour above to check compatibility.
            </div>
          </div>
        <% else %>
          <%!-- Overall score --%>
          <div class="mb-5 p-5 rounded-[var(--radius-md)] border-2 border-[var(--ink-900)] flex items-center gap-5" style={"background: #{overall_bg(@result.overall_status)};"}>
            <div class="text-center flex-none">
              <div style={"font-family: var(--font-display); font-weight: 800; font-size: 48px; line-height: 1; color: #{overall_color(@result.overall_status)};"}>
                {@result.percentage_score}
              </div>
              <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">SCORE</div>
            </div>
            <div>
              <div style={"font-family: var(--font-display); font-weight: 800; font-size: 22px; color: #{overall_color(@result.overall_status)};"}>
                {overall_label(@result.overall_status)}
              </div>
              <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-500); margin-top: 4px;">
                {@selected_venue.name} × {@selected_tour.name}
              </div>
            </div>
          </div>

          <%!-- Check results --%>
          <div class="flex flex-col gap-2">
            <div :for={check <- @result.checks} class={["flex items-start gap-3 p-4 rounded-[var(--radius-md)] border", check_border(check.status)]} style={"background: #{check_bg(check.status)};"}>
              <div class="flex-none mt-0.5">
                <.icon name={check_icon(check.status)} class={"w-4 h-4 #{check_icon_class(check.status)}"} />
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-center justify-between gap-2 flex-wrap">
                  <div style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; color: var(--ink-900);">{check.requirement}</div>
                  <.signal_chip tone={check_tone(check.status)} size="sm" variant="tint">
                    {String.upcase(to_string(check.status))}
                  </.signal_chip>
                </div>
                <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-500); margin-top: 4px;">{check.message}</div>
                <%= if check.venue_value do %>
                  <div class="mt-2" style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.1em; color: var(--ink-400);">
                    VENUE: <span style="color: var(--ink-700);">{check.venue_value}</span>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp overall_label(:compatible), do: "Compatible"
  defp overall_label(:incompatible), do: "Incompatible"
  defp overall_label(:warning), do: "Needs Review"
  defp overall_label(:unknown), do: "Unknown"

  defp overall_color(:compatible), do: "var(--signal-live)"
  defp overall_color(:incompatible), do: "var(--signal-stop)"
  defp overall_color(:warning), do: "var(--signal-doors)"
  defp overall_color(:unknown), do: "var(--ink-400)"

  defp overall_bg(:compatible), do: "var(--signal-live-tint)"
  defp overall_bg(:incompatible), do: "var(--signal-stop-tint)"
  defp overall_bg(:warning), do: "var(--signal-doors-tint)"
  defp overall_bg(:unknown), do: "var(--paper-200)"

  defp check_border(:pass), do: "border-[var(--signal-live)]"
  defp check_border(:fail), do: "border-[var(--signal-stop)]"
  defp check_border(:unknown), do: "border-[var(--paper-300)]"

  defp check_bg(:pass), do: "var(--signal-live-tint)"
  defp check_bg(:fail), do: "var(--signal-stop-tint)"
  defp check_bg(:unknown), do: "var(--paper-200)"

  defp check_icon(:pass), do: "hero-check-circle-mini"
  defp check_icon(:fail), do: "hero-x-circle-mini"
  defp check_icon(:unknown), do: "hero-question-mark-circle-mini"

  defp check_icon_class(:pass), do: "text-[var(--signal-live)]"
  defp check_icon_class(:fail), do: "text-[var(--signal-stop)]"
  defp check_icon_class(:unknown), do: "text-[var(--ink-400)]"

  defp check_tone(:pass), do: "live"
  defp check_tone(:fail), do: "stop"
  defp check_tone(:unknown), do: "ink"
end
