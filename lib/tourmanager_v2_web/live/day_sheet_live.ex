defmodule TourmanagerV2Web.DaySheetLive do
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(TourSwitching.default_assigns())
      |> assign(active_nav: "daysheet", active_tab: "show", page_title: "Day Sheet")
      |> TourSwitching.load_tour_data(socket.assigns[:current_tour])
      |> compute_daysheet_assigns()

    {:ok, socket}
  end

  def handle_event("select_tour", %{"tour-id" => tour_id}, socket) do
    {:noreply, socket} = TourSwitching.handle_event("select_tour", %{"tour-id" => tour_id}, socket)
    {:noreply, compute_daysheet_assigns(socket)}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  defp compute_daysheet_assigns(socket) do
    today_re = socket.assigns[:today_route_entry]
    next_re = socket.assigns[:next_route_entry]
    today_gig = socket.assigns[:today_gig]
    events = socket.assigns[:events] || []
    crew = socket.assigns[:tour_crew] || []

    active_entry = next_re || today_re || today_gig

    run_of_show =
      if events != [] do
        Enum.map(events, fn e ->
          time = if e.starts_at, do: Calendar.strftime(e.starts_at, "%H:%M"), else: "--:--"

          tone =
            case e.category do
              "load_in" -> "load"
              "soundcheck" -> "sound"
              "doors" -> "doors"
              "showtime" -> "live"
              "curfew" -> "stop"
              _ -> "ink"
            end

          %{
            time: time,
            label: e.name,
            tone: tone,
            loc: e.location || "",
            done: false,
            flag: e.category in ~w(doors showtime curfew)
          }
        end)
      else
        []
      end

    crew_cards =
      Enum.map(crew, fn cm ->
        %{
          name: cm.name,
          role: cm.role_title,
          init: initials(cm.name),
          pass: "CREW",
          status: "on-site"
        }
      end)

    assign(socket,
      run_of_show_data: run_of_show,
      crew_cards: crew_cards,
      active_entry: active_entry,
      active_gig: today_gig
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
    >
      <div id="day-sheet" class="p-7 grid grid-cols-[minmax(0,1.55fr)_minmax(0,1fr)] gap-5 items-start">
        <%!-- Left: run of show --%>
        <div>
          <div class="flex items-center justify-between mb-3.5">
            <div>
              <.overline>Run of show</.overline>
              <.display size={26} class="mt-1.5">
                <%= cond do %>
                  <% @active_entry && Map.has_key?(@active_entry, :date) && @active_entry.date -> %>
                    {Calendar.strftime(@active_entry.date, "%A %d %b")}
                  <% @active_gig && @active_gig.date -> %>
                    {Calendar.strftime(@active_gig.date, "%A %d %b")}
                  <% true -> %>
                    Schedule
                <% end %>
              </.display>
            </div>
            <%= if @current_user && TourmanagerV2.Accounts.User.manager?(@current_user) do %>
              <.tm_button variant="secondary" size="sm" icon_name="hero-plus">Add</.tm_button>
            <% end %>
          </div>

          <.tab_bar
            tabs={[
              %{value: "show", label: "Schedule", count: length(@run_of_show_data)},
              %{value: "crew", label: "Crew", count: length(@crew_cards)},
              %{value: "notes", label: "Notes"}
            ]}
            active={@active_tab}
            class="mb-4"
          />

          <%!-- Schedule tab --%>
          <div :if={@active_tab == "show"} id="schedule-list" class="flex flex-col">
            <%= if @run_of_show_data == [] do %>
              <div class="py-12 text-center">
                <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400); letter-spacing: 0.06em;">
                  <%= if @current_tour do %>
                    No upcoming events scheduled. Add gigs and events to this tour.
                  <% else %>
                    Select or create a tour to see the day sheet.
                  <% end %>
                </div>
              </div>
            <% else %>
              <.schedule_row
                :for={row <- @run_of_show_data}
                time={row.time}
                label={row.label}
                tone={row.tone}
                loc={row.loc}
                done={row.done}
                flag={row.flag}
              />
            <% end %>
          </div>

          <%!-- Crew tab --%>
          <div :if={@active_tab == "crew"} id="crew-grid" class="grid grid-cols-2 gap-2.5">
            <%= if @crew_cards == [] do %>
              <div class="col-span-2 py-12 text-center">
                <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400); letter-spacing: 0.06em;">
                  No crew assigned yet.
                </div>
              </div>
            <% else %>
              <.crew_card
                :for={c <- @crew_cards}
                name={c.name}
                role={c.role}
                init={c.init}
                pass_level={c.pass}
                status={c.status}
              />
            <% end %>
          </div>

          <%!-- Notes tab --%>
          <div :if={@active_tab == "notes"} id="notes-panel">
            <.stamp_card overline_text="Production notes" halftone>
              <div class="text-[15px] leading-relaxed text-[var(--ink-700)]">
                <%= cond do %>
                  <% @active_entry && Map.has_key?(@active_entry, :notes) && @active_entry.notes -> %>
                    {@active_entry.notes}
                  <% @active_gig && @active_gig.notes -> %>
                    {@active_gig.notes}
                  <% true -> %>
                    No production notes.
                <% end %>
              </div>
            </.stamp_card>
          </div>
        </div>

        <%!-- Right column --%>
        <div class="flex flex-col gap-[18px]">
          <%= if @active_entry do %>
            <.stamp_card hard overline_text="Next gig" padding="18px">
              <div>
                <.display size={22}>{@active_entry.venue || @active_entry.city || "Upcoming"}</.display>
                <div class="mt-1.5" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">
                  {@active_entry.city || ""}
                  <%= if @active_entry.date do %>
                    · {Calendar.strftime(@active_entry.date, "%d %b")}
                  <% end %>
                </div>
              </div>
            </.stamp_card>
          <% else %>
            <.stamp_card overline_text="No upcoming gigs" padding="18px">
              <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400);">
                <%= if @current_tour do %>
                  No gigs scheduled on this tour.
                <% else %>
                  Select a tour to see gig details.
                <% end %>
              </div>
            </.stamp_card>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
