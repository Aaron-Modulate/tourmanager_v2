defmodule TourmanagerV2Web.DaySheetLive do
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  def mount(params, _session, socket) do
    user = socket.assigns[:current_user]
    tours = socket.assigns[:user_tours] || []
    needs_onboarding = user && tours == [] && !TourmanagerV2.Accounts.User.onboarded?(user)

    {tour_form, profile_form, onboarding_step} =
      if needs_onboarding do
        tour_f = TourmanagerV2.Accounts.change_tour() |> Phoenix.Component.to_form()
        profile_f = TourmanagerV2.Accounts.change_profile(user) |> Phoenix.Component.to_form()
        {tour_f, profile_f, "profile"}
      else
        {nil, nil, nil}
      end

    initial_date = params["date"]

    socket =
      socket
      |> assign(TourSwitching.default_assigns())
      |> assign(active_nav: "daysheet", active_tab: "show", page_title: "Day Sheet")
      |> assign(:onboarding_tour_form, tour_form)
      |> assign(:onboarding_profile_form, profile_form)
      |> assign(:onboarding_step, onboarding_step)
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
        |> reload_selected_date()

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  def handle_event("validate_onboarding_profile", %{"user" => params}, socket) do
    user = socket.assigns.current_user
    changeset = TourmanagerV2.Accounts.change_profile(user, params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, :onboarding_profile_form, Phoenix.Component.to_form(changeset))}
  end

  def handle_event("save_onboarding_profile", %{"user" => params}, socket) do
    user = socket.assigns.current_user

    case TourmanagerV2.Accounts.update_profile(user, params) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> assign(:onboarding_step, "tour")}

      {:error, changeset} ->
        {:noreply, assign(socket, :onboarding_profile_form, Phoenix.Component.to_form(changeset))}
    end
  end

  def handle_event("skip_onboarding_profile", _params, socket) do
    {:noreply, assign(socket, :onboarding_step, "tour")}
  end

  def handle_event("save_event", params, socket) do
    {:noreply, socket} = TourSwitching.handle_event("save_event", params, socket)
    {:noreply, reload_selected_date(socket)}
  end

  def handle_event("update_event", params, socket) do
    {:noreply, socket} = TourSwitching.handle_event("update_event", params, socket)
    {:noreply, reload_selected_date(socket)}
  end

  def handle_event("delete_event", params, socket) do
    {:noreply, socket} = TourSwitching.handle_event("delete_event", params, socket)
    {:noreply, reload_selected_date(socket)}
  end

  def handle_event("add_crew_to_date", %{"user-id" => user_id}, socket) do
    tour = socket.assigns.current_tour
    date = socket.assigns[:selected_date]

    if tour && date do
      TourmanagerV2.Touring.assign_crew_to_date(tour.id, user_id, date)
      TourmanagerV2.TourBroadcast.broadcast_change(tour.id)
      {:noreply, reload_selected_date(socket)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("remove_crew_from_date", %{"user-id" => user_id}, socket) do
    tour = socket.assigns.current_tour
    date = socket.assigns[:selected_date]

    if tour && date do
      TourmanagerV2.Touring.remove_crew_from_date(tour.id, user_id, date)
      TourmanagerV2.TourBroadcast.broadcast_change(tour.id)
      {:noreply, reload_selected_date(socket)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("reorder_items", %{"ids" => ids}, socket) do
    date_setlists = socket.assigns[:date_setlists] || []

    setlist = Enum.find(date_setlists, fn sl ->
      Enum.any?(sl.items, fn item -> item.id in ids end)
    end)

    if setlist do
      TourmanagerV2.Touring.reorder_setlist_items(setlist.id, ids)
      {:noreply, reload_selected_date(socket)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("toggle_add_setlist", _params, socket) do
    {:noreply, assign(socket, :add_setlist_open, !socket.assigns[:add_setlist_open])}
  end

  def handle_event("assign_setlist_to_date", %{"id" => setlist_id}, socket) do
    tour = socket.assigns.current_tour
    date = socket.assigns[:selected_date]

    if tour && date do
      setlist = TourmanagerV2.Touring.get_setlist!(setlist_id)

      TourmanagerV2.Touring.create_setlist(tour.id, socket.assigns.current_user.id, %{
        "name" => setlist.name,
        "date" => date,
        "source" => "manual"
      })
      |> case do
        {:ok, new_setlist} ->
          Enum.each(setlist.items, fn item ->
            TourmanagerV2.Touring.add_setlist_item(new_setlist.id, %{
              "title" => item.title,
              "artist" => item.artist,
              "position" => item.position,
              "duration_seconds" => item.duration_seconds,
              "notes" => item.notes
            })
          end)

          TourmanagerV2.TourBroadcast.broadcast_change(tour.id)

          {:noreply,
           socket
           |> assign(:add_setlist_open, false)
           |> reload_selected_date()}

        _ ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("remove_date_setlist", %{"id" => id}, socket) do
    tour = socket.assigns.current_tour
    setlist = TourmanagerV2.Touring.get_setlist!(id)

    if tour && setlist.date do
      TourmanagerV2.Touring.delete_setlist(setlist)
      TourmanagerV2.TourBroadcast.broadcast_change(tour.id)
      {:noreply, reload_selected_date(socket)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("toggle_add_crew", _params, socket) do
    {:noreply, assign(socket, :add_crew_open, !socket.assigns[:add_crew_open])}
  end

  def handle_event("insert_standard_day", params, socket) do
    {:noreply, socket} = handle_insert_standard_day(params, socket)
    {:noreply, reload_selected_date(socket)}
  end

  defp reload_selected_date(socket) do
    date = socket.assigns[:selected_date]

    if date do
      socket
      |> load_events_for_date(date)
      |> compute_daysheet_assigns()
    else
      compute_daysheet_assigns(socket)
    end
  end

  defp handle_insert_standard_day(_params, socket) do
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

        TourmanagerV2.TourBroadcast.broadcast_change(tour.id)
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

    tour = socket.assigns[:current_tour]

    date_crew =
      if tour && selected_date do
        TourmanagerV2.Touring.list_crew_for_date(tour.id, selected_date)
      else
        []
      end

    crew_cards =
      Enum.map(date_crew, fn %{user: member, membership: membership} ->
        %{
          id: member.id,
          name: member.name,
          email: member.email,
          role: membership.role,
          role_title: member.role_title,
          init: initials(member.name),
          avatar_url: member.avatar_url,
          phone_number: member.phone_number,
          social_links: member.social_links || %{},
          pass: String.upcase(membership.role),
          status: "on-site",
          all_dates: membership.all_dates_default
        }
      end)

    all_tour_members =
      if tour do
        TourmanagerV2.Touring.list_tour_memberships(tour.id)
      else
        []
      end

    available_to_add =
      Enum.reject(all_tour_members, fn %{user: u} ->
        Enum.any?(date_crew, fn %{user: dc} -> dc.id == u.id end)
      end)

    selected_stop = Enum.find(tour_dates, fn d -> d.selected end)

    display_stop_name =
      cond do
        selected_stop && selected_stop.venue -> selected_stop.venue
        selected_stop && selected_stop.city -> selected_stop.city
        true -> "Day sheet"
      end

    {date_setlists, date_setlist_source} =
      if tour && selected_date do
        TourmanagerV2.Touring.resolve_setlists_for_date(tour.id, selected_date)
      else
        {[], :none}
      end

    all_tour_setlists =
      if tour do
        TourmanagerV2.Touring.list_setlists_for_tour(tour.id)
      else
        []
      end

    assignable_setlists =
      Enum.reject(all_tour_setlists, fn sl ->
        Enum.any?(date_setlists, fn ds -> ds.id == sl.id end)
      end)

    assign(socket,
      run_of_show_data: run_of_show,
      crew_cards: crew_cards,
      crew_count: length(date_crew),
      active_entry: active_entry,
      active_gig: today_gig,
      tour_dates: tour_dates,
      display_date: selected_date,
      display_stop_name: display_stop_name,
      display_stop_venue: (selected_stop && selected_stop.venue) || "",
      display_stop_city: (selected_stop && selected_stop.city) || "",
      available_to_add: available_to_add,
      add_crew_open: socket.assigns[:add_crew_open] || false,
      date_setlists: date_setlists,
      date_setlist_source: date_setlist_source,
      assignable_setlists: assignable_setlists,
      add_setlist_open: socket.assigns[:add_setlist_open] || false
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
      calendar_modal_open={@calendar_modal_open}
      calendar_token={@calendar_token}
      calendar_mode={@calendar_mode}
    >
      <%!-- Onboarding: show welcome card for new users with no tours --%>
      <%= if @onboarding_tour_form do %>
        <.onboarding_welcome
          current_user={@current_user}
          tour_form={@onboarding_tour_form}
          profile_form={@onboarding_profile_form}
          onboarding_step={@onboarding_step}
        />
      <% else %>
      <div id="day-sheet" class="p-4 md:p-7 grid grid-cols-1 md:grid-cols-[minmax(0,1.55fr)_minmax(0,1fr)] gap-5 items-start">
        <%!-- Left: run of show --%>
        <div>
          <div class="flex items-center justify-between mb-3.5">
            <div>
              <.overline>{@display_stop_name}</.overline>
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
              %{value: "setlist", label: "Setlist", count: length(@date_setlists)},
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
          <div :if={@active_tab == "crew"} id="crew-list">
            <%= if @crew_cards == [] && !@add_crew_open do %>
              <div class="py-12 text-center">
                <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400); letter-spacing: 0.06em;">
                  No crew assigned to this date.
                </div>
                <%= if @current_tour && @current_user && TourmanagerV2.Accounts.User.manager?(@current_user) do %>
                  <button
                    type="button"
                    phx-click="toggle_add_crew"
                    class="mt-4 px-5 py-2.5 rounded-[var(--radius-md)] cursor-pointer inline-flex items-center gap-2"
                    style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);"
                  >
                    <.icon name="hero-user-plus" class="w-4 h-4" />
                    ADD CREW
                  </button>
                <% end %>
              </div>
            <% else %>
              <%!-- Assigned crew list --%>
              <div class="flex flex-col gap-2">
                <div
                  :for={c <- @crew_cards}
                  class="relative"
                >
                  <%!-- Desktop: hover-triggered profile popover --%>
                  <div class="hidden md:block group/crew">
                    <div
                      class="flex items-center gap-3 p-3 rounded-[var(--radius-md)] border border-[var(--paper-300)] transition-colors cursor-pointer group-hover/crew:bg-[var(--paper-200)]"
                      style="background: var(--surface-card);"
                    >
                      <%= if c.avatar_url do %>
                        <img src={c.avatar_url} class="w-9 h-9 rounded-[var(--radius-sm)] object-cover flex-none transition-all group-hover/crew:ring-2 group-hover/crew:ring-[var(--brand)]" referrerpolicy="no-referrer" />
                      <% else %>
                        <span class="w-9 h-9 rounded-[var(--radius-sm)] flex items-center justify-center flex-none transition-all group-hover/crew:ring-2 group-hover/crew:ring-[var(--brand)]" style="background: var(--ink-900); color: var(--paper-100); font-family: var(--font-mono); font-weight: 700; font-size: 13px;">
                          {c.init}
                        </span>
                      <% end %>
                      <div class="flex-1 min-w-0">
                        <div class="text-[14px] font-semibold text-[var(--ink-900)] truncate">{c.name}</div>
                        <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); margin-top: 1px;">
                          {c.role_title || c.email}
                        </div>
                      </div>
                      <.signal_chip tone={if c.role == "manager", do: "brand", else: "live"} size="sm" variant="tint">{String.upcase(c.role)}</.signal_chip>
                      <%= if c.all_dates do %>
                        <span style="font-family: var(--font-mono); font-size: 9px; color: var(--ink-300); letter-spacing: 0.06em;">ALL DATES</span>
                      <% end %>
                      <%= if @current_user && TourmanagerV2.Accounts.User.manager?(@current_user) && c.id != @current_user.id && !c.all_dates do %>
                        <button type="button" phx-click="remove_crew_from_date" phx-value-user-id={c.id} data-confirm={"Remove #{c.name} from this date?"} class="p-1.5 rounded-[var(--radius-sm)] cursor-pointer transition-colors hover:bg-[var(--signal-stop-tint)]" title="Remove from this date">
                          <.icon name="hero-x-mark-mini" class="w-4 h-4 text-[var(--signal-stop)]" />
                        </button>
                      <% end %>
                    </div>

                    <%!-- Desktop hover popover --%>
                    <div class="absolute left-0 right-0 top-full z-50 pt-1 opacity-0 pointer-events-none group-hover/crew:opacity-100 group-hover/crew:pointer-events-auto" style="transition: opacity 150ms ease;">
                      <div class="rounded-[var(--radius-md)] overflow-hidden" style="background: var(--surface-card); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard);">
                        <%!-- Header --%>
                        <div class="flex items-center gap-3 px-4 py-3" style="background: var(--surface-stage);">
                          <%= if c.avatar_url do %>
                            <img src={c.avatar_url} class="w-11 h-11 rounded-[var(--radius-sm)] object-cover flex-none" referrerpolicy="no-referrer" />
                          <% else %>
                            <span class="w-11 h-11 rounded-[var(--radius-sm)] flex items-center justify-center flex-none" style="background: var(--ink-700); font-family: var(--font-mono); font-weight: 700; font-size: 16px; color: var(--paper-100);">
                              {c.init}
                            </span>
                          <% end %>
                          <div class="flex-1 min-w-0">
                            <div style="font-family: var(--font-display); font-weight: 800; font-size: 16px; color: #fff;">{c.name}</div>
                            <div :if={c.role_title} style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-300); margin-top: 2px;">{c.role_title}</div>
                          </div>
                          <.signal_chip tone={if c.role == "manager", do: "brand", else: "live"} size="sm">{String.upcase(c.role)}</.signal_chip>
                        </div>

                        <%!-- Actions --%>
                        <div class="px-4 py-3 flex flex-col gap-1">
                          <a :if={c.phone_number} href={"tel:#{c.phone_number}"} onclick={"return confirm('Call #{c.name}?')"} class="flex items-center gap-2.5 px-2 py-2 rounded-[var(--radius-sm)] no-underline transition-colors hover:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-700);">
                            <.icon name="hero-phone-mini" class="w-3.5 h-3.5 text-[var(--brand)]" />
                            {c.phone_number}
                          </a>
                          <a href={"mailto:#{c.email}"} onclick={"return confirm('Email #{c.name}?')"} class="flex items-center gap-2.5 px-2 py-2 rounded-[var(--radius-sm)] no-underline transition-colors hover:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-700);">
                            <.icon name="hero-envelope-mini" class="w-3.5 h-3.5 text-[var(--brand)]" />
                            {c.email}
                          </a>
                          <%= if c.social_links["instagram"] && c.social_links["instagram"] != "" do %>
                            <a href={"https://instagram.com/#{String.trim_leading(c.social_links["instagram"], "@")}"} target="_blank" onclick={"return confirm('Open #{c.name}\\'s Instagram?')"} class="flex items-center gap-2.5 px-2 py-2 rounded-[var(--radius-sm)] no-underline transition-colors hover:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-700);">
                              <.icon name="hero-camera-mini" class="w-3.5 h-3.5 text-[var(--brand)]" />
                              {c.social_links["instagram"]}
                            </a>
                          <% end %>
                          <%= if c.social_links["twitter"] && c.social_links["twitter"] != "" do %>
                            <a href={"https://x.com/#{String.trim_leading(c.social_links["twitter"], "@")}"} target="_blank" onclick={"return confirm('Open #{c.name}\\'s X profile?')"} class="flex items-center gap-2.5 px-2 py-2 rounded-[var(--radius-sm)] no-underline transition-colors hover:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-700);">
                              <.icon name="hero-chat-bubble-left-mini" class="w-3.5 h-3.5 text-[var(--brand)]" />
                              {c.social_links["twitter"]}
                            </a>
                          <% end %>
                          <%= if c.social_links["website"] && c.social_links["website"] != "" do %>
                            <a href={c.social_links["website"]} target="_blank" onclick={"return confirm('Open #{c.name}\\'s website?')"} class="flex items-center gap-2.5 px-2 py-2 rounded-[var(--radius-sm)] no-underline transition-colors hover:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-700);">
                              <.icon name="hero-globe-alt-mini" class="w-3.5 h-3.5 text-[var(--brand)]" />
                              {c.social_links["website"]}
                            </a>
                          <% end %>
                          <div :if={!c.phone_number && map_size(c.social_links) == 0} class="px-2 py-2" style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-300);">
                            No contact details added yet.
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <%!-- Mobile: tap-triggered bottom sheet --%>
                  <div class="md:hidden">
                    <label for={"crew-modal-#{c.id}"}>
                      <div
                        class="flex items-center gap-3 p-3 rounded-[var(--radius-md)] border border-[var(--paper-300)] cursor-pointer active:bg-[var(--paper-200)]"
                        style="background: var(--surface-card);"
                      >
                        <%= if c.avatar_url do %>
                          <img src={c.avatar_url} class="w-9 h-9 rounded-[var(--radius-sm)] object-cover flex-none" referrerpolicy="no-referrer" />
                        <% else %>
                          <span class="w-9 h-9 rounded-[var(--radius-sm)] flex items-center justify-center flex-none" style="background: var(--ink-900); color: var(--paper-100); font-family: var(--font-mono); font-weight: 700; font-size: 13px;">
                            {c.init}
                          </span>
                        <% end %>
                        <div class="flex-1 min-w-0">
                          <div class="text-[14px] font-semibold text-[var(--ink-900)] truncate">{c.name}</div>
                          <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); margin-top: 1px;">{c.role_title || c.email}</div>
                        </div>
                        <.signal_chip tone={if c.role == "manager", do: "brand", else: "live"} size="sm" variant="tint">{String.upcase(c.role)}</.signal_chip>
                      </div>
                    </label>
                    <input type="checkbox" id={"crew-modal-#{c.id}"} class="hidden peer/crewmodal" />
                    <div class="fixed inset-0 z-50 hidden peer-checked/crewmodal:flex items-end justify-center">
                      <label for={"crew-modal-#{c.id}"} class="absolute inset-0" style="background: rgba(20, 17, 15, 0.55); backdrop-filter: blur(4px);" />
                      <div class="relative z-10 w-full max-w-md rounded-t-[var(--radius-xl)] overflow-hidden" style="background: var(--surface-card); border: 2px solid var(--ink-900); border-bottom: none; box-shadow: var(--shadow-hard);">
                        <%!-- Header --%>
                        <div class="flex items-center gap-3 px-5 py-4" style="background: var(--surface-stage);">
                          <%= if c.avatar_url do %>
                            <img src={c.avatar_url} class="w-14 h-14 rounded-[var(--radius-md)] object-cover flex-none" referrerpolicy="no-referrer" />
                          <% else %>
                            <span class="w-14 h-14 rounded-[var(--radius-md)] flex items-center justify-center flex-none" style="background: var(--ink-700); font-family: var(--font-mono); font-weight: 700; font-size: 20px; color: var(--paper-100);">
                              {c.init}
                            </span>
                          <% end %>
                          <div class="flex-1">
                            <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff;">{c.name}</div>
                            <div :if={c.role_title} style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-300); margin-top: 2px;">{c.role_title}</div>
                          </div>
                          <.signal_chip tone={if c.role == "manager", do: "brand", else: "live"} size="sm">{String.upcase(c.role)}</.signal_chip>
                        </div>

                        <%!-- Actions --%>
                        <div class="px-5 py-4 flex flex-col gap-1">
                          <a :if={c.phone_number} href={"tel:#{c.phone_number}"} onclick={"return confirm('Call #{c.name}?')"} class="flex items-center gap-3 px-3 py-3 rounded-[var(--radius-md)] no-underline transition-colors active:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 13px; color: var(--ink-700); border: 1px solid var(--paper-300);">
                            <.icon name="hero-phone" class="w-5 h-5 text-[var(--brand)]" />
                            {c.phone_number}
                          </a>
                          <a href={"mailto:#{c.email}"} onclick={"return confirm('Email #{c.name}?')"} class="flex items-center gap-3 px-3 py-3 rounded-[var(--radius-md)] no-underline transition-colors active:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 13px; color: var(--ink-700); border: 1px solid var(--paper-300);">
                            <.icon name="hero-envelope" class="w-5 h-5 text-[var(--brand)]" />
                            {c.email}
                          </a>
                          <%= if c.social_links["instagram"] && c.social_links["instagram"] != "" do %>
                            <a href={"https://instagram.com/#{String.trim_leading(c.social_links["instagram"], "@")}"} target="_blank" onclick={"return confirm('Open #{c.name}\\'s Instagram?')"} class="flex items-center gap-3 px-3 py-3 rounded-[var(--radius-md)] no-underline transition-colors active:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 13px; color: var(--ink-700); border: 1px solid var(--paper-300);">
                              <.icon name="hero-camera" class="w-5 h-5 text-[var(--brand)]" />
                              {c.social_links["instagram"]}
                            </a>
                          <% end %>
                          <%= if c.social_links["twitter"] && c.social_links["twitter"] != "" do %>
                            <a href={"https://x.com/#{String.trim_leading(c.social_links["twitter"], "@")}"} target="_blank" onclick={"return confirm('Open #{c.name}\\'s X profile?')"} class="flex items-center gap-3 px-3 py-3 rounded-[var(--radius-md)] no-underline transition-colors active:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 13px; color: var(--ink-700); border: 1px solid var(--paper-300);">
                              <.icon name="hero-chat-bubble-left" class="w-5 h-5 text-[var(--brand)]" />
                              {c.social_links["twitter"]}
                            </a>
                          <% end %>
                          <%= if c.social_links["website"] && c.social_links["website"] != "" do %>
                            <a href={c.social_links["website"]} target="_blank" onclick={"return confirm('Open #{c.name}\\'s website?')"} class="flex items-center gap-3 px-3 py-3 rounded-[var(--radius-md)] no-underline transition-colors active:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 13px; color: var(--ink-700); border: 1px solid var(--paper-300);">
                              <.icon name="hero-globe-alt" class="w-5 h-5 text-[var(--brand)]" />
                              {c.social_links["website"]}
                            </a>
                          <% end %>
                          <div :if={!c.phone_number && map_size(c.social_links) == 0} class="px-3 py-3 text-center" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-300);">
                            No contact details added yet.
                          </div>
                        </div>

                        <label for={"crew-modal-#{c.id}"} class="flex items-center justify-center mx-5 mb-5 py-2.5 cursor-pointer rounded-[var(--radius-md)]" style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400); border: 1px solid var(--paper-300);">
                          CLOSE
                        </label>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <%!-- Add crew button --%>
              <%= if @current_tour && @current_user && TourmanagerV2.Accounts.User.manager?(@current_user) do %>
                <button
                  type="button"
                  phx-click="toggle_add_crew"
                  class="mt-3 w-full py-2.5 rounded-[var(--radius-md)] cursor-pointer flex items-center justify-center gap-2 transition-colors hover:bg-[var(--paper-200)]"
                  style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400); border: 1px dashed var(--paper-300);"
                >
                  <.icon name="hero-user-plus-mini" class="w-3.5 h-3.5" />
                  {if @add_crew_open, do: "CLOSE", else: "ADD CREW TO THIS DATE"}
                </button>
              <% end %>
            <% end %>

            <%!-- Add crew dropdown --%>
            <%= if @add_crew_open do %>
              <div class="mt-3 rounded-[var(--radius-md)] border border-[var(--paper-300)] overflow-hidden" style="background: var(--surface-card);">
                <div class="px-4 py-2.5 border-b border-[var(--paper-300)]" style="background: var(--paper-200);">
                  <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">TOUR MEMBERS</div>
                </div>
                <%= if @available_to_add == [] do %>
                  <div class="px-4 py-6 text-center" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">
                    All tour members are already assigned to this date.
                  </div>
                <% else %>
                  <div
                    :for={%{user: member, membership: _m} <- @available_to_add}
                    class="flex items-center gap-3 px-4 py-2.5 cursor-pointer transition-colors hover:bg-[var(--paper-200)] border-b border-[var(--paper-300)] last:border-b-0"
                    phx-click="add_crew_to_date"
                    phx-value-user-id={member.id}
                  >
                    <%= if member.avatar_url do %>
                      <img src={member.avatar_url} class="w-7 h-7 rounded-[var(--radius-sm)] object-cover flex-none" referrerpolicy="no-referrer" />
                    <% else %>
                      <span class="w-7 h-7 rounded-[var(--radius-sm)] flex items-center justify-center flex-none" style="background: var(--ink-900); color: var(--paper-100); font-family: var(--font-mono); font-weight: 700; font-size: 11px;">
                        {initials(member.name)}
                      </span>
                    <% end %>
                    <div class="flex-1 min-w-0">
                      <div class="text-[13px] font-semibold text-[var(--ink-900)] truncate">{member.name}</div>
                    </div>
                    <.icon name="hero-plus-mini" class="w-4 h-4 text-[var(--brand)]" />
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <%!-- Setlist tab --%>
          <div :if={@active_tab == "setlist"} id="setlist-panel">
            <%= if @date_setlists == [] do %>
              <div class="py-12 text-center">
                <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400); letter-spacing: 0.06em;">
                  No setlist for this date.
                </div>
                <%= if @current_tour && @current_user && TourmanagerV2.Accounts.User.manager?(@current_user) do %>
                  <button type="button" phx-click="toggle_add_setlist" class="mt-4 px-5 py-2.5 rounded-[var(--radius-md)] cursor-pointer inline-flex items-center gap-2" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);">
                    <.icon name="hero-musical-note" class="w-4 h-4" /> ADD SET LIST
                  </button>
                <% end %>
              </div>
            <% else %>
              <div :if={@date_setlist_source == :tour_default} class="flex items-center gap-2 mb-3 px-3 py-2 rounded-[var(--radius-sm)]" style="background: var(--paper-200);">
                <.icon name="hero-information-circle-mini" class="w-3.5 h-3.5 text-[var(--ink-300)]" />
                <span style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400);">Using tour default setlist</span>
              </div>
              <div :for={sl <- @date_setlists} class="mb-5 last:mb-0">
                <div class="flex items-center justify-between mb-2">
                  <div style="font-family: var(--font-display); font-weight: 700; font-size: 16px; color: var(--ink-900);">{sl.name}</div>
                  <div class="flex items-center gap-2">
                    <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400);">{length(sl.items)} songs</div>
                    <%= if sl.date && @current_user && TourmanagerV2.Accounts.User.manager?(@current_user) do %>
                      <button type="button" phx-click="remove_date_setlist" phx-value-id={sl.id} data-confirm="Remove this setlist from this date?" class="p-1 rounded-[var(--radius-sm)] cursor-pointer hover:bg-[var(--signal-stop-tint)]">
                        <.icon name="hero-x-mark-mini" class="w-3.5 h-3.5 text-[var(--signal-stop)]" />
                      </button>
                    <% end %>
                  </div>
                </div>
                <%= if sl.file_url && sl.file_type in ~w(jpg jpeg png heic) do %>
                  <img src={sl.file_url} class="w-full rounded-[var(--radius-md)] border border-[var(--paper-300)] mb-3 max-h-[300px] object-contain" style="background: var(--paper-200);" />
                <% end %>
                <%= if sl.items != [] do %>
                  <div class="rounded-[var(--radius-md)] border border-[var(--paper-300)]" style="background: var(--surface-card);">
                    <div id={"daysheet-setlist-#{sl.id}"} phx-hook=".SortableList" phx-update="ignore">
                      <div :for={item <- sl.items} id={"ds-item-#{item.id}"} data-id={item.id} class="flex items-center gap-3 px-4 py-2.5 border-b border-[var(--paper-300)]" style="background: var(--surface-card);">
                        <%= if @current_user && TourmanagerV2.Accounts.User.manager?(@current_user) do %>
                          <div class="flex-none cursor-grab active:cursor-grabbing drag-handle touch-none" style="color: var(--ink-300);">
                            <.icon name="hero-bars-2-mini" class="w-4 h-4" />
                          </div>
                        <% end %>
                        <div class="w-5 text-right flex-none setlist-position" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; color: var(--ink-300);">
                          {item.position + 1}
                        </div>
                        <div class="flex-1 min-w-0">
                          <div class="text-[13px] font-semibold text-[var(--ink-900)] truncate">{item.title}</div>
                          <div :if={item.notes} style="font-family: var(--font-mono); font-size: 9px; color: var(--ink-400); margin-top: 1px;">{item.notes}</div>
                        </div>
                        <div :if={item.duration_seconds} style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">
                          {div(item.duration_seconds, 60)}:{rem(item.duration_seconds, 60) |> Integer.to_string() |> String.pad_leading(2, "0")}
                        </div>
                      </div>
                    </div>
                    <%!-- Runtime total --%>
                    <% total_seconds = Enum.reduce(sl.items, 0, fn item, acc -> acc + (item.duration_seconds || 0) end) %>
                    <div class="flex items-center gap-3 px-4 py-2.5" style="background: var(--paper-200); border-top: 2px solid var(--paper-300);">
                      <div class="w-6 flex-none" />
                      <div class="flex-1" style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-500);">
                        RUNTIME
                      </div>
                      <div style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; color: var(--ink-700);">
                        {div(total_seconds, 3600)}:{div(rem(total_seconds, 3600), 60) |> Integer.to_string() |> String.pad_leading(2, "0")}:{rem(total_seconds, 60) |> Integer.to_string() |> String.pad_leading(2, "0")}
                      </div>
                    </div>
                  </div>
                <% end %>

                <%!-- Generate PDF --%>
                <div class="mt-3">
                  <a
                    href={"/setlist/#{sl.id}/print?mode=stage&tour=#{@current_tour && @current_tour.id}&date=#{@display_date && Date.to_iso8601(@display_date)}"}
                    target="_blank"
                    class="inline-flex items-center gap-2 px-3 py-2 rounded-[var(--radius-md)] no-underline transition-colors hover:bg-[var(--paper-200)]"
                    style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400); border: 1px solid var(--paper-300);"
                  >
                    <.icon name="hero-printer-mini" class="w-3.5 h-3.5" /> GENERATE PDF
                  </a>
                </div>
              </div>

              <%!-- Add another setlist button --%>
              <%= if @current_tour && @current_user && TourmanagerV2.Accounts.User.manager?(@current_user) do %>
                <button type="button" phx-click="toggle_add_setlist" class="mt-2 w-full py-2.5 rounded-[var(--radius-md)] cursor-pointer flex items-center justify-center gap-2 transition-colors hover:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400); border: 1px dashed var(--paper-300);">
                  <.icon name="hero-plus-mini" class="w-3.5 h-3.5" />
                  {if @add_setlist_open, do: "CLOSE", else: "ADD SET LIST"}
                </button>
              <% end %>
            <% end %>

            <%!-- Add setlist picker --%>
            <%= if @add_setlist_open do %>
              <div class="mt-3 rounded-[var(--radius-md)] border border-[var(--paper-300)] overflow-hidden" style="background: var(--surface-card);">
                <div class="px-4 py-2.5 border-b border-[var(--paper-300)]" style="background: var(--paper-200);">
                  <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">TOUR SETLISTS</div>
                </div>
                <%= if @assignable_setlists == [] do %>
                  <div class="px-4 py-6 text-center" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">
                    No setlists available.
                    <.link navigate="/setlists" class="no-underline" style="color: var(--brand);"> Create one</.link>
                  </div>
                <% else %>
                  <div
                    :for={sl <- @assignable_setlists}
                    class="flex items-center gap-3 px-4 py-2.5 cursor-pointer transition-colors hover:bg-[var(--paper-200)] border-b border-[var(--paper-300)] last:border-b-0"
                    phx-click="assign_setlist_to_date"
                    phx-value-id={sl.id}
                  >
                    <div class="w-8 h-8 rounded-[var(--radius-sm)] flex items-center justify-center flex-none" style={"background: #{if sl.is_tour_default, do: "var(--brand)", else: "var(--paper-200)"};"}>
                      <.icon name="hero-musical-note-mini" class={["w-4 h-4", if(sl.is_tour_default, do: "text-white", else: "text-[var(--ink-400)]")]} />
                    </div>
                    <div class="flex-1 min-w-0">
                      <div class="text-[13px] font-semibold text-[var(--ink-900)] truncate">{sl.name}</div>
                      <div style="font-family: var(--font-mono); font-size: 9px; color: var(--ink-400);">{length(sl.items)} songs</div>
                    </div>
                    <.icon name="hero-plus-mini" class="w-4 h-4 text-[var(--brand)]" />
                  </div>
                <% end %>
              </div>
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

end
