defmodule TourmanagerV2Web.Admin.ToursLive do
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  alias TourmanagerV2.Accounts

  def mount(_params, _session, socket) do
    user = socket.assigns[:current_user]

    if user && Accounts.User.admin?(user) do
      tours = Accounts.list_all_tours()

      socket =
        socket
        |> assign(TourSwitching.default_assigns())
        |> assign(
          active_nav: "admin_tours",
          page_title: "Admin · Tours",
          admin_tours: tours,
          tour_modal_open: false,
          tour_form: nil,
          editing_tour: nil
        )
        |> TourSwitching.load_tour_data(socket.assigns[:current_tour])

      {:ok, socket}
    else
      {:ok, redirect(socket, to: "/")}
    end
  end

  def handle_event("open_edit_tour", %{"id" => id}, socket) do
    tour = Enum.find_value(socket.assigns.admin_tours, fn %{tour: t} -> t.id == id && t end)
    changeset = Accounts.change_tour(tour)

    {:noreply,
     socket
     |> assign(:tour_modal_open, true)
     |> assign(:tour_form, Phoenix.Component.to_form(changeset))
     |> assign(:editing_tour, tour)}
  end

  def handle_event("close_tour_modal", _params, socket) do
    {:noreply, assign(socket, :tour_modal_open, false)}
  end

  def handle_event("validate_tour", %{"tour" => params}, socket) do
    changeset =
      Accounts.change_tour(socket.assigns.editing_tour, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :tour_form, Phoenix.Component.to_form(changeset))}
  end

  def handle_event("save_tour", %{"tour" => params}, socket) do
    case Accounts.update_tour(socket.assigns.editing_tour, params) do
      {:ok, updated} ->
        TourmanagerV2.TourBroadcast.broadcast_change(updated.id)

        admin_tours =
          Enum.map(socket.assigns.admin_tours, fn entry ->
            if entry.tour.id == updated.id, do: %{entry | tour: updated}, else: entry
          end)

        {:noreply,
         socket
         |> assign(:tour_modal_open, false)
         |> assign(:admin_tours, admin_tours)
         |> put_flash(:info, "Tour updated.")}

      {:error, changeset} ->
        {:noreply, assign(socket, :tour_form, Phoenix.Component.to_form(changeset))}
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
      <div id="admin-tours" class="p-7">
        <div class="mb-5">
          <.overline>Admin</.overline>
          <.display size={26} class="mt-1.5">Tours</.display>
        </div>

        <div class="rounded-[var(--radius-md)] border-2 border-[var(--ink-900)] overflow-hidden" style="box-shadow: var(--shadow-hard);">
          <div class="grid grid-cols-[1fr_1fr_120px_120px_40px] gap-4 px-5 py-3 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300);">TOUR</div>
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300);">OWNER</div>
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300);">STATUS</div>
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300);">CREATED</div>
            <div></div>
          </div>

          <%= if @admin_tours == [] do %>
            <div class="px-5 py-10 text-center" style="background: var(--surface-card); font-family: var(--font-mono); font-size: 12px; color: var(--ink-400);">
              No tours yet.
            </div>
          <% else %>
            <div :for={%{tour: tour, owner: owner} <- @admin_tours} class="grid grid-cols-[1fr_1fr_120px_120px_40px] gap-4 px-5 py-3 items-center border-b border-[var(--paper-300)] last:border-b-0 transition-colors hover:bg-[var(--paper-200)]" style="background: var(--surface-card);">
              <div>
                <div class="text-[14px] font-semibold text-[var(--ink-900)]">{tour.name}</div>
                <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); margin-top: 1px;">
                  <%= if tour.start_date && tour.end_date do %>
                    {Calendar.strftime(tour.start_date, "%d %b")} – {Calendar.strftime(tour.end_date, "%d %b %Y")}
                  <% end %>
                </div>
              </div>

              <div>
                <%= if owner do %>
                  <div class="flex items-center gap-2">
                    <%= if owner.avatar_url do %>
                      <img src={owner.avatar_url} class="w-6 h-6 rounded-[var(--radius-sm)] object-cover flex-none" referrerpolicy="no-referrer" />
                    <% else %>
                      <span class="w-6 h-6 rounded-[var(--radius-sm)] flex items-center justify-center flex-none" style="background: var(--ink-900); color: var(--paper-100); font-family: var(--font-mono); font-weight: 700; font-size: 9px;">{initials(owner.name)}</span>
                    <% end %>
                    <div>
                      <div class="text-[13px] font-semibold text-[var(--ink-900)]">{owner.name}</div>
                      <div style="font-family: var(--font-mono); font-size: 9px; color: var(--ink-400);">{owner.email}</div>
                    </div>
                  </div>
                <% else %>
                  <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-300);">—</div>
                <% end %>
              </div>

              <div>
                <.signal_chip
                  tone={cond do
                    tour.status == "active" -> "live"
                    tour.status == "draft" -> "sound"
                    tour.status == "completed" -> "ink"
                    true -> "stop"
                  end}
                  size="sm"
                >
                  {tour.status || "draft"}
                </.signal_chip>
              </div>

              <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">
                {Calendar.strftime(tour.inserted_at, "%d %b %Y")}
              </div>

              <div>
                <button type="button" phx-click="open_edit_tour" phx-value-id={tour.id} class="p-1.5 rounded-[var(--radius-sm)] cursor-pointer transition-colors hover:bg-[var(--paper-200)]" title="Edit">
                  <.icon name="hero-pencil-mini" class="w-4 h-4 text-[var(--ink-400)]" />
                </button>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <%!-- Edit tour modal --%>
      <.tm_modal :if={@tour_form} id="admin-tour-modal" show={@tour_modal_open} on_close="close_tour_modal">
        <div class="px-6 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand-on-dark);">ADMIN</div>
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; margin-top: 2px;">Edit tour</div>
        </div>
        <.form for={@tour_form} id="admin-tour-form" phx-change="validate_tour" phx-submit="save_tour" class="px-6 py-5">
          <div class="flex flex-col gap-4">
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">NAME</label>
              <.input field={@tour_form[:name]} type="text" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
            </div>
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">START DATE</label>
                <.input field={@tour_form[:start_date]} type="date" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
              </div>
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">END DATE</label>
                <.input field={@tour_form[:end_date]} type="date" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
              </div>
            </div>
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">STATUS</label>
              <.input field={@tour_form[:status]} type="select" options={[{"Draft", "draft"}, {"Active", "active"}, {"Completed", "completed"}, {"Cancelled", "cancelled"}]} class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
            </div>
          </div>
          <div class="flex items-center justify-end gap-3 mt-6 pt-5 border-t border-[var(--paper-300)]">
            <button type="button" phx-click="close_tour_modal" class="px-4 py-2.5 rounded-[var(--radius-md)] cursor-pointer hover:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400); border: 1px solid var(--paper-300);">CANCEL</button>
            <button type="submit" class="px-5 py-2.5 rounded-[var(--radius-md)] cursor-pointer" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);">SAVE</button>
          </div>
        </.form>
      </.tm_modal>
    </Layouts.app>
    """
  end
end
