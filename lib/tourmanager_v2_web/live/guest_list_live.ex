defmodule TourmanagerV2Web.GuestListLive do
  @moduledoc "Per-date guest list for the current tour, with its own date selector."
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  alias TourmanagerV2.Touring
  alias TourmanagerV2.Touring.Guest

  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(TourSwitching.default_assigns())
      |> assign(
        active_nav: "guestlist",
        page_title: "Guest List",
        guest_modal_open: false,
        guest_form: nil,
        editing_guest: nil,
        selected_date: nil
      )
      |> TourSwitching.load_tour_data(socket.assigns[:current_tour])
      |> init_selected_date(params["date"])
      |> load_guests()

    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    if params["date"] do
      case Date.from_iso8601(params["date"]) do
        {:ok, date} -> {:noreply, socket |> assign(:selected_date, date) |> load_guests()}
        _ -> {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("select_tour", %{"tour-id" => tour_id}, socket) do
    {:noreply, socket} = TourSwitching.handle_event("select_tour", %{"tour-id" => tour_id}, socket)
    {:noreply, socket |> init_selected_date(nil) |> load_guests()}
  end

  def handle_event("select_date", %{"date" => date_str}, socket) do
    case Date.from_iso8601(date_str) do
      {:ok, date} -> {:noreply, socket |> assign(:selected_date, date) |> load_guests()}
      _ -> {:noreply, socket}
    end
  end

  def handle_event("open_add_guest", _params, socket) do
    changeset = Touring.change_guest()

    {:noreply,
     socket
     |> assign(:guest_modal_open, true)
     |> assign(:guest_form, Phoenix.Component.to_form(changeset))
     |> assign(:editing_guest, nil)}
  end

  def handle_event("edit_guest", %{"id" => id}, socket) do
    guest = Touring.get_guest!(id)
    changeset = Touring.change_guest(guest)

    {:noreply,
     socket
     |> assign(:guest_modal_open, true)
     |> assign(:guest_form, Phoenix.Component.to_form(changeset))
     |> assign(:editing_guest, guest)}
  end

  def handle_event("close_guest_modal", _params, socket) do
    {:noreply, assign(socket, :guest_modal_open, false)}
  end

  def handle_event("validate_guest", %{"guest" => params}, socket) do
    source = socket.assigns[:editing_guest] || %Guest{}

    changeset =
      Touring.change_guest(source, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :guest_form, Phoenix.Component.to_form(changeset))}
  end

  def handle_event("save_guest", %{"guest" => params}, socket) do
    tour = socket.assigns[:current_tour]
    date = socket.assigns[:selected_date]
    editing = socket.assigns[:editing_guest]

    result =
      cond do
        editing -> Touring.update_guest(editing, params)
        tour && date -> Touring.create_guest(tour.id, date, params)
        true -> {:error, :no_tour}
      end

    case result do
      {:ok, _guest} ->
        {:noreply,
         socket
         |> assign(:guest_modal_open, false)
         |> load_guests()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :guest_form, Phoenix.Component.to_form(changeset))}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("toggle_guest_checkin", %{"id" => id}, socket) do
    id
    |> Touring.get_guest!()
    |> Touring.toggle_guest_checkin()

    {:noreply, load_guests(socket)}
  end

  def handle_event("delete_guest", %{"id" => id}, socket) do
    id
    |> Touring.get_guest!()
    |> Touring.delete_guest()

    {:noreply, load_guests(socket)}
  end

  defp init_selected_date(socket, date_param) do
    case date_param && Date.from_iso8601(date_param) do
      {:ok, date} -> assign(socket, :selected_date, date)
      _ -> set_default_date(socket)
    end
  end

  defp set_default_date(socket) do
    route_entries = socket.assigns[:route_entries] || []

    dated_entries =
      route_entries
      |> Enum.filter(& &1.raw_date)
      |> Enum.sort_by(& &1.raw_date, Date)

    date =
      cond do
        socket.assigns[:today_route_entry] -> socket.assigns.today_route_entry.date
        socket.assigns[:next_route_entry] -> socket.assigns.next_route_entry.date
        dated_entries != [] -> List.first(dated_entries).raw_date
        true -> Date.utc_today()
      end

    assign(socket, :selected_date, date)
  end

  defp load_guests(socket) do
    tour = socket.assigns[:current_tour]
    date = socket.assigns[:selected_date]
    route_entries = socket.assigns[:route_entries] || []
    today = Date.utc_today()

    tour_dates =
      route_entries
      |> Enum.filter(& &1.raw_date)
      |> Enum.map(fn r ->
        %{
          date: r.raw_date,
          label: Calendar.strftime(r.raw_date, "%a %d %b"),
          venue: r.venue,
          city: r.city,
          past: Date.compare(r.raw_date, today) == :lt,
          selected: date && Date.compare(r.raw_date, date) == :eq
        }
      end)
      |> Enum.uniq_by(& &1.date)
      |> Enum.sort_by(& &1.date, Date)

    date_guests =
      if tour && date do
        Touring.list_guests_for_date(tour.id, date)
      else
        []
      end

    socket
    |> assign(:tour_dates, tour_dates)
    |> assign(:date_guests, date_guests)
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
      <div id="guest-list-page" class="p-4 md:p-7 max-w-3xl">
        <div class="flex items-center justify-between mb-5">
          <div>
            <.drilldown_breadcrumb current_label="GUEST LIST" />
            <%!-- Date dropdown --%>
            <%= if @current_tour && @tour_dates != [] do %>
              <details class="group/date-dd mt-1.5 relative">
                <summary class="flex items-center gap-2 cursor-pointer list-none" style="list-style: none;">
                  <.display size={26}>
                    {if @selected_date, do: Calendar.strftime(@selected_date, "%A %d %b"), else: "Select a date"}
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
              <.display size={26} class="mt-1.5">Guest list</.display>
            <% end %>
          </div>
          <%= if @current_tour && @current_user && TourmanagerV2.Accounts.User.manager?(@current_user) && @selected_date do %>
            <.tm_button variant="primary" size="sm" icon_name="hero-user-plus" phx-click="open_add_guest">Add</.tm_button>
          <% end %>
        </div>

        <%= if !@current_tour do %>
          <div class="py-16 text-center">
            <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400); letter-spacing: 0.06em;">
              Select a tour to manage guests.
            </div>
          </div>
        <% else %>
          <%= if @tour_dates == [] do %>
            <div class="py-16 text-center">
              <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400); letter-spacing: 0.06em;">
                No dates on this tour yet. Add a date on the
                <.link navigate="/routing" class="no-underline" style="color: var(--brand); font-weight: 700;">tour schedule</.link> to get started.
              </div>
            </div>
          <% else %>
            <%= if @date_guests == [] do %>
              <div class="py-16 text-center rounded-[var(--radius-md)] border-2 border-dashed border-[var(--paper-300)]">
                <.icon name="hero-ticket" class="w-10 h-10 text-[var(--ink-300)] mx-auto mb-3" />
                <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400); letter-spacing: 0.06em;">
                  No guests on the list for this date.
                </div>
              </div>
            <% else %>
              <div class="flex flex-col gap-2">
                <div :for={g <- @date_guests} class="flex items-center gap-3 p-3 rounded-[var(--radius-md)] border border-[var(--paper-300)]" style="background: var(--surface-card);">
                  <button
                    type="button"
                    phx-click="toggle_guest_checkin"
                    phx-value-id={g.id}
                    class="w-8 h-8 rounded-[var(--radius-sm)] flex items-center justify-center flex-none cursor-pointer transition-colors"
                    style={if g.checked_in_at, do: "background: var(--signal-live); color: #fff;", else: "background: var(--paper-200); border: 1px solid var(--paper-300); color: var(--ink-300);"}
                    title={if g.checked_in_at, do: "Checked in — tap to undo", else: "Tap to check in"}
                  >
                    <.icon name="hero-check-mini" class="w-4 h-4" />
                  </button>
                  <div class="flex-1 min-w-0">
                    <div class="text-[14px] font-semibold text-[var(--ink-900)] truncate">
                      {g.name}<span :if={g.plus_ones > 0} style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; color: var(--ink-400);"> +{g.plus_ones}</span>
                    </div>
                    <div :if={g.guest_of || g.notes} style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); margin-top: 1px;">
                      {[if(g.guest_of, do: "Guest of #{g.guest_of}"), g.notes] |> Enum.reject(&is_nil/1) |> Enum.join(" · ")}
                    </div>
                  </div>
                  <.signal_chip :if={g.checked_in_at} tone="live" size="sm" variant="tint">IN</.signal_chip>
                  <%= if @current_user && TourmanagerV2.Accounts.User.manager?(@current_user) do %>
                    <div class="flex items-center gap-1 flex-none">
                      <button type="button" phx-click="edit_guest" phx-value-id={g.id} class="p-1.5 rounded-[var(--radius-sm)] cursor-pointer transition-colors hover:bg-[var(--paper-200)]" title="Edit">
                        <.icon name="hero-pencil-mini" class="w-4 h-4 text-[var(--ink-400)]" />
                      </button>
                      <button
                        type="button"
                        phx-click="delete_guest"
                        phx-value-id={g.id}
                        data-confirm={"Remove #{g.name} from the list?"}
                        class="p-1.5 rounded-[var(--radius-sm)] cursor-pointer transition-colors hover:bg-[var(--signal-stop-tint)]"
                        title="Remove"
                      >
                        <.icon name="hero-trash-mini" class="w-4 h-4 text-[var(--signal-stop)]" />
                      </button>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          <% end %>
        <% end %>
      </div>

      <%!-- Guest modal --%>
      <.tm_modal :if={@guest_form} id="guest-modal" show={@guest_modal_open} on_close="close_guest_modal">
        <div class="px-6 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand-on-dark);">GUEST LIST</div>
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; margin-top: 2px;">
            {if @editing_guest, do: "Edit guest", else: "Add guest"} — {if @selected_date, do: Calendar.strftime(@selected_date, "%d %b %Y"), else: ""}
          </div>
        </div>
        <.form for={@guest_form} id="guest-form" phx-change="validate_guest" phx-submit="save_guest" class="px-6 py-5">
          <div class="flex flex-col gap-4">
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">NAME</label>
              <.input field={@guest_form[:name]} type="text" placeholder="Guest name" class="w-full px-3 py-2.5 text-[15px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
            </div>
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">+GUESTS</label>
                <.input field={@guest_form[:plus_ones]} type="number" min="0" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
              </div>
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">GUEST OF</label>
                <.input field={@guest_form[:guest_of]} type="text" placeholder="e.g. crew member" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
              </div>
            </div>
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">NOTES</label>
              <.input field={@guest_form[:notes]} type="text" placeholder="Optional" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
            </div>
          </div>
          <div class="flex items-center justify-end gap-3 mt-6 pt-5 border-t border-[var(--paper-300)]">
            <button type="button" phx-click="close_guest_modal" class="px-4 py-2.5 rounded-[var(--radius-md)] cursor-pointer hover:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400); border: 1px solid var(--paper-300);">CANCEL</button>
            <button type="submit" class="px-5 py-2.5 rounded-[var(--radius-md)] cursor-pointer" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);">{if @editing_guest, do: "SAVE", else: "ADD GUEST"}</button>
          </div>
        </.form>
      </.tm_modal>
    </Layouts.app>
    """
  end
end
