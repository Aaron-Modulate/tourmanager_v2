defmodule TourmanagerV2Web.DaySheetLive do
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  def mount(_params, _session, socket) do
    user = socket.assigns[:current_user]
    tours = socket.assigns[:user_tours] || []
    needs_onboarding = user && tours == [] && !TourmanagerV2.Accounts.User.onboarded?(user)

    tour_form =
      if needs_onboarding do
        TourmanagerV2.Accounts.change_tour() |> Phoenix.Component.to_form()
      end

    socket =
      socket
      |> assign(TourSwitching.default_assigns())
      |> assign(active_nav: "daysheet", active_tab: "show", page_title: "Day Sheet")
      |> assign(:onboarding_tour_form, tour_form)
      |> TourSwitching.load_tour_data(socket.assigns[:current_tour])
      |> compute_daysheet_assigns()

    {:ok, socket}
  end

  def handle_event("select_tour", %{"tour-id" => tour_id}, socket) do
    {:noreply, socket} = TourSwitching.handle_event("select_tour", %{"tour-id" => tour_id}, socket)
    {:noreply, compute_daysheet_assigns(socket)}
  end

  def handle_info({:tour_data_changed, tour_id, source_pid}, socket) do
    if source_pid != self() && socket.assigns[:current_tour] && socket.assigns.current_tour.id == tour_id do
      socket =
        socket
        |> TourSwitching.load_tour_data(socket.assigns.current_tour)
        |> compute_daysheet_assigns()

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  def handle_event("save_event", params, socket) do
    {:noreply, socket} = TourSwitching.handle_event("save_event", params, socket)
    {:noreply, compute_daysheet_assigns(socket)}
  end

  def handle_event("update_event", params, socket) do
    {:noreply, socket} = TourSwitching.handle_event("update_event", params, socket)
    {:noreply, compute_daysheet_assigns(socket)}
  end

  def handle_event("delete_event", params, socket) do
    {:noreply, socket} = TourSwitching.handle_event("delete_event", params, socket)
    {:noreply, compute_daysheet_assigns(socket)}
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
              "load_out" -> "load"
              "catering" -> "ink"
              _ -> "ink"
            end

          %{
            id: e.id,
            time: time,
            label: e.name,
            tone: tone,
            loc: e.location || "",
            done: false,
            flag: e.category in ~w(doors showtime curfew),
            category: e.category
          }
        end)
      else
        if active_entry do
          default_day_events()
        else
          []
        end
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
      crew_count: length(crew),
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
      manage_tour_open={@manage_tour_open}
      manage_tour_form={@manage_tour_form}
    >
      <%!-- Onboarding: show welcome card for new users with no tours --%>
      <%= if @onboarding_tour_form do %>
        <.onboarding_welcome current_user={@current_user} tour_form={@onboarding_tour_form} />
      <% else %>
      <div id="day-sheet" class="p-4 md:p-7 grid grid-cols-1 md:grid-cols-[minmax(0,1.55fr)_minmax(0,1fr)] gap-5 items-start">
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
            <%= if @current_user && TourmanagerV2.Accounts.User.manager?(@current_user) && @current_tour do %>
              <.tm_button variant="secondary" size="sm" icon_name="hero-plus" phx-click="add_event">Add</.tm_button>
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
                event_id={row[:id]}
                is_manager={@current_user && TourmanagerV2.Accounts.User.manager?(@current_user)}
              />
            <% end %>
          </div>

          <%!-- Crew tab --%>
          <div :if={@active_tab == "crew"} id="crew-grid" class="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
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
            <.stamp_card hard overline_text="Next up" padding="18px">
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
            <.stamp_card overline_text="Next up" padding="18px">
              <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400);">
                <%= if @current_tour do %>
                  Nothing scheduled yet.
                <% else %>
                  Select a tour to see what's next.
                <% end %>
              </div>
            </.stamp_card>
          <% end %>
        </div>
      </div>
      <% end %>

      <%!-- Event modal --%>
      <.tm_modal :if={@event_form} id="event-modal" show={@event_modal_open} on_close="close_event_modal">
        <div class="px-6 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);">{if @editing_event, do: "EDIT", else: "NEW"}</div>
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; margin-top: 2px;">{if @editing_event, do: "Edit event", else: "Add event"}</div>
        </div>
        <.form for={@event_form} id="event-form" phx-change="validate_event" phx-submit={if @editing_event, do: "update_event", else: "save_event"} class="px-6 py-5">
          <div class="flex flex-col gap-4">
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">CATEGORY</label>
              <.input field={@event_form[:category]} type="select" options={[{"Load in", "load_in"}, {"Soundcheck", "soundcheck"}, {"Doors", "doors"}, {"Showtime", "showtime"}, {"Curfew", "curfew"}, {"Load out", "load_out"}, {"Catering", "catering"}, {"Travel", "travel"}, {"Other", "other"}]} tabindex="1" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
            </div>
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">NAME</label>
              <.input field={@event_form[:name]} type="text" placeholder="e.g. Soundcheck" tabindex="2" class="w-full px-3 py-2.5 text-[15px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
            </div>
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">START</label>
              <.input field={@event_form[:starts_at]} type="datetime-local" step="60" tabindex="3" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
            </div>
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">END</label>
              <.input field={@event_form[:ends_at]} type="datetime-local" step="60" tabindex="4" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
            </div>
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">LOCATION</label>
              <.input field={@event_form[:location]} type="text" placeholder="e.g. Main stage" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
            </div>
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">NOTES</label>
              <.input field={@event_form[:notes]} type="textarea" rows="2" placeholder="Optional" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none resize-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
            </div>
          </div>
          <div class="flex items-center justify-end gap-3 mt-6 pt-5 border-t border-[var(--paper-300)]">
            <button type="button" phx-click="close_event_modal" class="px-4 py-2.5 rounded-[var(--radius-md)] cursor-pointer hover:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400); border: 1px solid var(--paper-300);">CANCEL</button>
            <button type="submit" class="px-5 py-2.5 rounded-[var(--radius-md)] cursor-pointer" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);">{if @editing_event, do: "SAVE", else: "ADD EVENT"}</button>
          </div>
        </.form>
      </.tm_modal>
    </Layouts.app>
    """
  end

  defp default_day_events do
    [
      %{time: "08:00", label: "Bus call / Travel", tone: "ink", loc: "Hotel lobby", done: false, flag: false},
      %{time: "10:00", label: "Load in", tone: "load", loc: "Stage door", done: false, flag: false},
      %{time: "12:00", label: "Lunch", tone: "ink", loc: "Catering", done: false, flag: false},
      %{time: "14:00", label: "Soundcheck", tone: "sound", loc: "Main stage", done: false, flag: false},
      %{time: "17:00", label: "Dinner", tone: "ink", loc: "Catering", done: false, flag: false},
      %{time: "18:00", label: "Doors", tone: "doors", loc: "FOH", done: false, flag: true},
      %{time: "19:00", label: "Support", tone: "doors", loc: "Main stage", done: false, flag: false},
      %{time: "20:30", label: "Headline", tone: "live", loc: "Main stage", done: false, flag: true},
      %{time: "22:30", label: "Curfew", tone: "stop", loc: "House", done: false, flag: true},
      %{time: "23:00", label: "Load out", tone: "load", loc: "Stage door", done: false, flag: false}
    ]
  end
end
