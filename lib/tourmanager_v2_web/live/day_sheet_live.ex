defmodule TourmanagerV2Web.DaySheetLive do
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  def mount(params, _session, socket) do
    user = socket.assigns[:current_user]
    tours = socket.assigns[:user_tours] || []
    needs_onboarding = user && tours == [] && !TourmanagerV2.Accounts.User.onboarded?(user)

    tour_form =
      if needs_onboarding do
        TourmanagerV2.Accounts.change_tour() |> Phoenix.Component.to_form()
      end

    initial_date = params["date"]

    socket =
      socket
      |> assign(TourSwitching.default_assigns())
      |> assign(active_nav: "daysheet", active_tab: "show", page_title: "Day Sheet")
      |> assign(:onboarding_tour_form, tour_form)
      |> assign(:selected_date, nil)
      |> TourSwitching.load_tour_data(socket.assigns[:current_tour])
      |> init_selected_date(initial_date)
      |> compute_daysheet_assigns()

    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    if params["date"] do
      case Date.from_iso8601(params["date"]) do
        {:ok, date} ->
          {:noreply,
           socket
           |> assign(:selected_date, date)
           |> load_events_for_date(date)
           |> compute_daysheet_assigns()}

        _ ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("select_tour", %{"tour-id" => tour_id}, socket) do
    {:noreply, socket} = TourSwitching.handle_event("select_tour", %{"tour-id" => tour_id}, socket)

    socket =
      socket
      |> assign(:selected_date, nil)
      |> init_selected_date(nil)
      |> compute_daysheet_assigns()

    {:noreply, socket}
  end

  def handle_event("select_date", %{"date" => date_str}, socket) do
    case Date.from_iso8601(date_str) do
      {:ok, date} ->
        {:noreply,
         socket
         |> assign(:selected_date, date)
         |> load_events_for_date(date)
         |> compute_daysheet_assigns()}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("view_header_gig", _params, socket) do
    next_re = socket.assigns[:next_route_entry]

    if next_re && next_re.date do
      {:noreply,
       socket
       |> assign(:selected_date, next_re.date)
       |> load_events_for_date(next_re.date)
       |> compute_daysheet_assigns()}
    else
      {:noreply, socket}
    end
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

  def handle_event("insert_standard_day", _params, socket) do
    tour = socket.assigns.current_tour
    selected_date = socket.assigns[:selected_date] || Date.utc_today()

    if tour do
      gig = socket.assigns[:today_gig] || ensure_gig(tour, selected_date)

      if gig do
        standard_events()
        |> Enum.each(fn {time, name, category, location} ->
          starts_at = DateTime.new!(selected_date, time)
          ends_at = DateTime.add(starts_at, 3600, :second)

          TourmanagerV2.Touring.create_event(gig, tour.workspace_id, %{
            "name" => name,
            "category" => category,
            "location" => location,
            "starts_at" => starts_at,
            "ends_at" => ends_at
          })
        end)

        socket =
          socket
          |> load_events_for_date(selected_date)
          |> compute_daysheet_assigns()

        {:noreply, socket}
      else
        {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  defp ensure_gig(tour, date) do
    case TourmanagerV2.Touring.get_gig_for_date(tour.id, date) do
      nil ->
        case TourmanagerV2.Repo.insert(
               %TourmanagerV2.Touring.Gig{tour_id: tour.id, workspace_id: tour.workspace_id}
               |> TourmanagerV2.Touring.Gig.changeset(%{name: "Show", date: date})
             ) do
          {:ok, gig} -> gig
          _ -> nil
        end

      gig ->
        gig
    end
  end

  defp standard_events do
    [
      {~T[08:00:00], "Bus call / Travel", "travel", "Hotel lobby"},
      {~T[10:00:00], "Load in", "load_in", "Stage door"},
      {~T[12:00:00], "Lunch", "catering", "Catering"},
      {~T[14:00:00], "Soundcheck", "soundcheck", "Main stage"},
      {~T[17:00:00], "Dinner", "catering", "Catering"},
      {~T[18:00:00], "Doors", "doors", "FOH"},
      {~T[19:00:00], "Support", "showtime", "Main stage"},
      {~T[20:30:00], "Headline", "showtime", "Main stage"},
      {~T[22:30:00], "Curfew", "curfew", "House"},
      {~T[23:00:00], "Load out", "load_out", "Stage door"}
    ]
  end

  defp init_selected_date(socket, date_param) do
    cond do
      date_param ->
        case Date.from_iso8601(date_param) do
          {:ok, date} ->
            socket
            |> assign(:selected_date, date)
            |> load_events_for_date(date)

          _ ->
            set_default_date(socket)
        end

      true ->
        set_default_date(socket)
    end
  end

  defp set_default_date(socket) do
    date =
      cond do
        socket.assigns[:next_route_entry] && socket.assigns.next_route_entry.date ->
          socket.assigns.next_route_entry.date

        socket.assigns[:today_route_entry] && socket.assigns.today_route_entry.date ->
          socket.assigns.today_route_entry.date

        socket.assigns[:today_gig] && socket.assigns.today_gig.date ->
          socket.assigns.today_gig.date

        true ->
          Date.utc_today()
      end

    socket
    |> assign(:selected_date, date)
    |> load_events_for_date(date)
  end

  defp load_events_for_date(socket, date) do
    tour = socket.assigns[:current_tour]

    if tour do
      gig = TourmanagerV2.Touring.get_gig_for_date(tour.id, date)
      events = if gig, do: TourmanagerV2.Touring.list_events_for_gig(gig.id), else: []

      socket
      |> assign(:today_gig, gig)
      |> assign(:events, events)
    else
      socket
    end
  end

  defp compute_daysheet_assigns(socket) do
    selected_date = socket.assigns[:selected_date]
    today_gig = socket.assigns[:today_gig]
    events = socket.assigns[:events] || []
    crew = socket.assigns[:tour_crew] || []
    route_entries = socket.assigns[:route_entries] || []
    today = Date.utc_today()

    active_entry =
      cond do
        today_gig -> today_gig
        socket.assigns[:next_route_entry] -> socket.assigns[:next_route_entry]
        socket.assigns[:today_route_entry] -> socket.assigns[:today_route_entry]
        true -> nil
      end

    tour_dates =
      route_entries
      |> Enum.filter(fn r -> r.raw_date end)
      |> Enum.map(fn r ->
        %{
          date: r.raw_date,
          label: Calendar.strftime(r.raw_date, "%a %d %b"),
          venue: r.venue,
          city: r.city,
          type: r.type,
          past: Date.compare(r.raw_date, today) == :lt,
          selected: selected_date && Date.compare(r.raw_date, selected_date) == :eq
        }
      end)
      |> Enum.uniq_by(fn d -> d.date end)

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
      crew_count: length(crew),
      active_entry: active_entry,
      active_gig: today_gig,
      tour_dates: tour_dates,
      display_date: selected_date
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
              <%!-- Date dropdown --%>
              <%= if @current_tour && @tour_dates != [] do %>
                <details class="group/date-dd mt-1.5 relative">
                  <summary class="flex items-center gap-2 cursor-pointer list-none" style="list-style: none;">
                    <.display size={26}>
                      {if @display_date, do: Calendar.strftime(@display_date, "%A %d %b"), else: "Schedule"}
                    </.display>
                    <.icon name="hero-chevron-down" class="w-4 h-4 text-[var(--ink-400)] transition-transform group-open/date-dd:rotate-180" />
                  </summary>
                  <div class="absolute left-0 top-full mt-2 z-50 rounded-[var(--radius-md)] overflow-hidden max-h-[300px] overflow-y-auto" style="background: var(--surface-card); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard); min-width: 240px;">
                    <button
                      :for={d <- @tour_dates}
                      type="button"
                      phx-click="select_date"
                      phx-value-date={Date.to_iso8601(d.date)}
                      class={[
                        "w-full text-left px-4 py-2.5 flex items-center justify-between cursor-pointer transition-colors border-b border-[var(--paper-300)] last:border-b-0",
                        if(d.selected, do: "bg-[var(--marker-050)]", else: "hover:bg-[var(--paper-200)]")
                      ]}
                    >
                      <div>
                        <div class={["text-[13px] font-semibold", if(d.past, do: "text-[var(--ink-300)]", else: "text-[var(--ink-900)]")]}>
                          {d.label}
                        </div>
                        <div style={"font-family: var(--font-mono); font-size: 10px; color: #{if d.past, do: "var(--ink-300)", else: "var(--ink-400)"}; margin-top: 1px;"}>
                          {d.venue} · {d.city}
                        </div>
                      </div>
                      <div class="flex items-center gap-2">
                        <.signal_chip :if={d.past} tone="ink" size="sm" variant="tint">PAST</.signal_chip>
                        <.icon :if={d.selected} name="hero-check" class="w-4 h-4 text-[var(--brand)]" />
                      </div>
                    </button>
                  </div>
                </details>
              <% else %>
                <.display size={26} class="mt-1.5">Schedule</.display>
              <% end %>
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
                    No events scheduled for this date.
                  <% else %>
                    Select or create a tour to see the day sheet.
                  <% end %>
                </div>
                <%= if @current_tour && @current_user && TourmanagerV2.Accounts.User.manager?(@current_user) do %>
                  <button
                    type="button"
                    phx-click="insert_standard_day"
                    class="mt-4 px-5 py-2.5 rounded-[var(--radius-md)] cursor-pointer transition-all inline-flex items-center gap-2"
                    style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);"
                  >
                    <.icon name="hero-calendar-days" class="w-4 h-4" />
                    ADD STANDARD DAY
                  </button>
                <% end %>
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
                  <% @active_gig && @active_gig.notes -> %>
                    {@active_gig.notes}
                  <% @active_entry && Map.has_key?(@active_entry, :notes) && @active_entry.notes -> %>
                    {@active_entry.notes}
                  <% true -> %>
                    No production notes.
                <% end %>
              </div>
            </.stamp_card>
          </div>
        </div>

        <%!-- Right column --%>
        <div class="flex flex-col gap-[18px]">
          <%!-- Next up — clickable to jump to that date --%>
          <%= if @headerbar_entry do %>
            <button type="button" phx-click="view_header_gig" class="w-full text-left cursor-pointer">
              <.stamp_card hard overline_text="Next up" padding="18px">
                <div>
                  <.display size={22}>{@headerbar_entry.venue || @headerbar_entry.city || "Upcoming"}</.display>
                  <div class="mt-1.5" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">
                    {@headerbar_entry.city || ""}
                    <%= if @headerbar_entry.date do %>
                      · {Calendar.strftime(@headerbar_entry.date, "%d %b")}
                    <% end %>
                  </div>
                </div>
              </.stamp_card>
            </button>
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
              <.input field={@event_form[:location]} type="text" placeholder="e.g. Main stage" tabindex="5" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
            </div>
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">NOTES</label>
              <.input field={@event_form[:notes]} type="textarea" rows="2" placeholder="Optional" tabindex="6" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none resize-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
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
