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
          admin_tours: tours
        )
        |> TourSwitching.load_tour_data(socket.assigns[:current_tour])

      {:ok, socket}
    else
      {:ok, redirect(socket, to: "/")}
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
    >
      <div id="admin-tours" class="p-7">
        <div class="mb-5">
          <.overline>Admin</.overline>
          <.display size={26} class="mt-1.5">Tours</.display>
        </div>

        <div class="rounded-[var(--radius-md)] border-2 border-[var(--ink-900)] overflow-hidden" style="box-shadow: var(--shadow-hard);">
          <div class="grid grid-cols-[1fr_1fr_120px_120px] gap-4 px-5 py-3 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300);">TOUR</div>
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300);">OWNER</div>
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300);">STATUS</div>
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300);">CREATED</div>
          </div>

          <%= if @admin_tours == [] do %>
            <div class="px-5 py-10 text-center" style="background: var(--surface-card); font-family: var(--font-mono); font-size: 12px; color: var(--ink-400);">
              No tours yet.
            </div>
          <% else %>
            <div :for={%{tour: tour, owner: owner} <- @admin_tours} class="grid grid-cols-[1fr_1fr_120px_120px] gap-4 px-5 py-3 items-center border-b border-[var(--paper-300)] last:border-b-0 transition-colors hover:bg-[var(--paper-200)]" style="background: var(--surface-card);">
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
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
