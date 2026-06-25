defmodule TourmanagerV2Web.Admin.UsersLive do
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  alias TourmanagerV2.Accounts

  def mount(_params, _session, socket) do
    user = socket.assigns[:current_user]

    if user && Accounts.User.admin?(user) do
      users = Accounts.list_users()

      socket =
        socket
        |> assign(TourSwitching.default_assigns())
        |> assign(
          active_nav: "admin_users",
          billing_seats: user.crew_seats || 10,
          page_title: "Admin · Users",
          admin_users: users
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
    >
      <div id="admin-users" class="p-7">
        <div class="mb-5">
          <.overline>Admin</.overline>
          <.display size={26} class="mt-1.5">Users</.display>
        </div>

        <div class="rounded-[var(--radius-md)] border-2 border-[var(--ink-900)] overflow-hidden" style="box-shadow: var(--shadow-hard);">
          <%!-- Table header --%>
          <div class="grid grid-cols-[48px_1fr_1fr_160px] gap-4 px-5 py-3 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
            <div></div>
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300);">NAME</div>
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300);">EMAIL</div>
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300);">LAST LOGIN</div>
          </div>

          <%!-- Table rows --%>
          <div :for={u <- @admin_users} class="grid grid-cols-[48px_1fr_1fr_160px] gap-4 px-5 py-3 items-center border-b border-[var(--paper-300)] last:border-b-0 transition-colors hover:bg-[var(--paper-200)]" style="background: var(--surface-card);">
            <%!-- Avatar with active dot --%>
            <div class="relative">
              <%= if u.avatar_url do %>
                <img
                  src={u.avatar_url}
                  class="w-9 h-9 rounded-[var(--radius-sm)] object-cover"
                  alt={u.name}
                  referrerpolicy="no-referrer"
                />
              <% else %>
                <span
                  class="w-9 h-9 rounded-[var(--radius-sm)] flex items-center justify-center"
                  style="background: var(--ink-900); color: var(--paper-100); font-family: var(--font-mono); font-weight: 700; font-size: 12px;"
                >{initials(u.name)}</span>
              <% end %>
              <span
                :if={recently_active?(u)}
                class="absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full border-2 border-[var(--surface-card)]"
                style="background: var(--signal-live);"
              />
            </div>

            <%!-- Name --%>
            <div>
              <div class="text-[14px] font-semibold text-[var(--ink-900)] flex items-center gap-2">
                {u.name}
                <span
                  :if={u.is_admin}
                  class="px-1.5 py-0.5 rounded-[var(--radius-stamp)]"
                  style="background: var(--brand); color: #fff; font-family: var(--font-mono); font-weight: 700; font-size: 8px; letter-spacing: 0.1em;"
                >ADMIN</span>
              </div>
              <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); margin-top: 1px;">
                {String.upcase(u.role)} · {String.upcase(u.plan)}
              </div>
            </div>

            <%!-- Email --%>
            <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-500);">
              {u.email}
            </div>

            <%!-- Last login --%>
            <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">
              {if u.last_login_at, do: Calendar.strftime(u.last_login_at, "%d %b %Y %H:%M"), else: "—"}
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end


  defp recently_active?(user) do
    case user.last_login_at do
      nil -> false
      ts -> DateTime.diff(DateTime.utc_now(), ts, :minute) < 30
    end
  end
end
