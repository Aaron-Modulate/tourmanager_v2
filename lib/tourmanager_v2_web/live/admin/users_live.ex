defmodule TourmanagerV2Web.Admin.UsersLive do
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  alias TourmanagerV2.Accounts

  def mount(_params, _session, socket) do
    user = socket.assigns[:current_user]

    if user && Accounts.User.admin?(user) do
      users_with_counts = Accounts.list_users_with_tour_counts()

      socket =
        socket
        |> assign(TourSwitching.default_assigns())
        |> assign(
          active_nav: "admin_users",
          billing_seats: user.crew_seats || 10,
          page_title: "Admin · Users",
          admin_users: users_with_counts,
          user_modal_open: false,
          user_form: nil,
          editing_admin_user: nil
        )
        |> TourSwitching.load_tour_data(socket.assigns[:current_tour])

      {:ok, socket}
    else
      {:ok, redirect(socket, to: "/")}
    end
  end

  def handle_event("open_edit_user", %{"id" => id}, socket) do
    target = Accounts.get_user!(id)
    changeset = Accounts.change_user(target)

    {:noreply,
     socket
     |> assign(:user_modal_open, true)
     |> assign(:user_form, Phoenix.Component.to_form(changeset))
     |> assign(:editing_admin_user, target)}
  end

  def handle_event("close_user_modal", _params, socket) do
    {:noreply, assign(socket, :user_modal_open, false)}
  end

  def handle_event("validate_admin_user", %{"user" => params}, socket) do
    changeset =
      Accounts.change_user(socket.assigns.editing_admin_user, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :user_form, Phoenix.Component.to_form(changeset))}
  end

  def handle_event("save_admin_user", %{"user" => params}, socket) do
    case Accounts.update_user(socket.assigns.editing_admin_user, params) do
      {:ok, updated} ->
        admin_users =
          Enum.map(socket.assigns.admin_users, fn entry ->
            if entry.user.id == updated.id, do: %{entry | user: updated}, else: entry
          end)

        {:noreply,
         socket
         |> assign(:user_modal_open, false)
         |> assign(:admin_users, admin_users)
         |> put_flash(:info, "User updated.")}

      {:error, changeset} ->
        {:noreply, assign(socket, :user_form, Phoenix.Component.to_form(changeset))}
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
      <div id="admin-users" class="p-7">
        <div class="mb-5">
          <.overline>Admin</.overline>
          <.display size={26} class="mt-1.5">Users</.display>
        </div>

        <div class="rounded-[var(--radius-md)] border-2 border-[var(--ink-900)]" style="box-shadow: var(--shadow-hard);">
          <%!-- Table header --%>
          <div class="grid grid-cols-[48px_1fr_1fr_160px] gap-4 px-5 py-3 border-b-2 border-[var(--ink-900)] rounded-t-[var(--radius-md)]" style="background: var(--surface-stage);">
            <div></div>
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300);">NAME</div>
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300);">EMAIL</div>
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300);">LAST LOGIN</div>
          </div>

          <%!-- Table rows --%>
          <div :for={%{user: u, tour_count: tc} <- @admin_users} class="relative">
            <%!-- Desktop: hover detail --%>
            <div class="hidden md:block group/user">
              <div class="grid grid-cols-[48px_1fr_1fr_160px] gap-4 px-5 py-3 items-center border-b border-[var(--paper-300)] cursor-pointer transition-colors group-hover/user:bg-[var(--paper-200)]" style="background: var(--surface-card);">
                <div class="relative">
                  <%= if u.avatar_url do %>
                    <img src={u.avatar_url} class="w-9 h-9 rounded-[var(--radius-sm)] object-cover" alt={u.name} referrerpolicy="no-referrer" />
                  <% else %>
                    <span class="w-9 h-9 rounded-[var(--radius-sm)] flex items-center justify-center" style="background: var(--ink-900); color: var(--paper-100); font-family: var(--font-mono); font-weight: 700; font-size: 12px;">{initials(u.name)}</span>
                  <% end %>
                  <span :if={recently_active?(u)} class="absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full border-2 border-[var(--surface-card)]" style="background: var(--signal-live);" />
                </div>
                <div>
                  <div class="text-[14px] font-semibold text-[var(--ink-900)] flex items-center gap-2">
                    {u.name}
                    <span :if={u.is_admin} class="px-1.5 py-0.5 rounded-[var(--radius-stamp)]" style="background: var(--brand); color: #fff; font-family: var(--font-mono); font-weight: 700; font-size: 8px; letter-spacing: 0.1em;">ADMIN</span>
                  </div>
                  <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); margin-top: 1px;">{String.upcase(u.role)} · {String.upcase(u.plan)}</div>
                </div>
                <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-500);">{u.email}</div>
                <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">{if u.last_login_at, do: Calendar.strftime(u.last_login_at, "%d %b %Y %H:%M"), else: "—"}</div>
              </div>
              <%!-- Hover popover --%>
              <div class="absolute left-0 right-0 top-full z-50 pt-1 opacity-0 pointer-events-none group-hover/user:opacity-100 group-hover/user:pointer-events-auto" style="transition: opacity 150ms ease;">
                <div class="mx-5 rounded-[var(--radius-md)] overflow-hidden" style="background: var(--surface-card); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard);">
                  <div class="flex items-center gap-3 px-4 py-3" style="background: var(--surface-stage);">
                    <%= if u.avatar_url do %>
                      <img src={u.avatar_url} class="w-10 h-10 rounded-[var(--radius-sm)] object-cover flex-none" referrerpolicy="no-referrer" />
                    <% else %>
                      <span class="w-10 h-10 rounded-[var(--radius-sm)] flex items-center justify-center flex-none" style="background: var(--ink-700); font-family: var(--font-mono); font-weight: 700; font-size: 14px; color: var(--paper-100);">{initials(u.name)}</span>
                    <% end %>
                    <div>
                      <div style="font-family: var(--font-display); font-weight: 800; font-size: 16px; color: #fff;">{u.name}</div>
                      <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-300);">{u.email}</div>
                    </div>
                  </div>
                  <div class="px-4 py-3 grid grid-cols-3 gap-4">
                    <div>
                      <div style="font-family: var(--font-mono); font-size: 8px; letter-spacing: 0.2em; color: var(--ink-400);">JOINED</div>
                      <div style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; color: var(--ink-900); margin-top: 2px;">{Calendar.strftime(u.inserted_at, "%d %b %Y")}</div>
                    </div>
                    <div>
                      <div style="font-family: var(--font-mono); font-size: 8px; letter-spacing: 0.2em; color: var(--ink-400);">TOURS</div>
                      <div style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; color: var(--ink-900); margin-top: 2px;">{tc}</div>
                    </div>
                    <div>
                      <div style="font-family: var(--font-mono); font-size: 8px; letter-spacing: 0.2em; color: var(--ink-400);">SEATS</div>
                      <div style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; color: var(--ink-900); margin-top: 2px;">{u.crew_seats || 0}</div>
                    </div>
                  </div>
                  <div class="px-4 pb-3 flex items-center gap-2">
                    <.signal_chip tone={if u.plan == "paid", do: "live", else: "ink"} size="sm" variant="tint">{String.upcase(u.plan)}</.signal_chip>
                    <.signal_chip tone={if u.role == "manager", do: "brand", else: "doors"} size="sm" variant="tint">{String.upcase(u.role)}</.signal_chip>
                    <%= if TourmanagerV2.Accounts.User.trial_active?(u) do %>
                      <.signal_chip tone="doors" size="sm" variant="tint">TRIAL</.signal_chip>
                    <% end %>
                  </div>
                  <div class="px-4 pb-3">
                    <button type="button" phx-click="open_edit_user" phx-value-id={u.id} class="w-full flex items-center justify-center gap-1.5 px-3 py-2 rounded-[var(--radius-sm)] cursor-pointer transition-colors hover:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-500); border: 1px solid var(--paper-300);">
                      <.icon name="hero-pencil-mini" class="w-3.5 h-3.5" /> EDIT
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <%!-- Mobile: tap modal --%>
            <div class="md:hidden">
              <label for={"user-modal-#{u.id}"}>
                <div class="grid grid-cols-[48px_1fr] gap-3 px-5 py-3 items-center border-b border-[var(--paper-300)] cursor-pointer active:bg-[var(--paper-200)]" style="background: var(--surface-card);">
                  <div class="relative">
                    <%= if u.avatar_url do %>
                      <img src={u.avatar_url} class="w-9 h-9 rounded-[var(--radius-sm)] object-cover" alt={u.name} referrerpolicy="no-referrer" />
                    <% else %>
                      <span class="w-9 h-9 rounded-[var(--radius-sm)] flex items-center justify-center" style="background: var(--ink-900); color: var(--paper-100); font-family: var(--font-mono); font-weight: 700; font-size: 12px;">{initials(u.name)}</span>
                    <% end %>
                    <span :if={recently_active?(u)} class="absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full border-2 border-[var(--surface-card)]" style="background: var(--signal-live);" />
                  </div>
                  <div>
                    <div class="text-[14px] font-semibold text-[var(--ink-900)] flex items-center gap-2">
                      {u.name}
                      <span :if={u.is_admin} class="px-1.5 py-0.5 rounded-[var(--radius-stamp)]" style="background: var(--brand); color: #fff; font-family: var(--font-mono); font-weight: 700; font-size: 8px; letter-spacing: 0.1em;">ADMIN</span>
                    </div>
                    <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); margin-top: 1px;">{u.email}</div>
                  </div>
                </div>
              </label>
              <input type="checkbox" id={"user-modal-#{u.id}"} class="hidden peer/usermodal" />
              <div class="fixed inset-0 z-50 hidden peer-checked/usermodal:flex items-end justify-center">
                <label for={"user-modal-#{u.id}"} class="absolute inset-0" style="background: rgba(20, 17, 15, 0.55); backdrop-filter: blur(4px);" />
                <div class="relative z-10 w-full max-w-md rounded-t-[var(--radius-xl)] overflow-hidden" style="background: var(--surface-card); border: 2px solid var(--ink-900); border-bottom: none; box-shadow: var(--shadow-hard);">
                  <div class="flex items-center gap-3 px-5 py-4" style="background: var(--surface-stage);">
                    <%= if u.avatar_url do %>
                      <img src={u.avatar_url} class="w-14 h-14 rounded-[var(--radius-md)] object-cover flex-none" referrerpolicy="no-referrer" />
                    <% else %>
                      <span class="w-14 h-14 rounded-[var(--radius-md)] flex items-center justify-center flex-none" style="background: var(--ink-700); font-family: var(--font-mono); font-weight: 700; font-size: 20px; color: var(--paper-100);">{initials(u.name)}</span>
                    <% end %>
                    <div>
                      <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff;">{u.name}</div>
                      <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-300); margin-top: 2px;">{u.email}</div>
                    </div>
                  </div>
                  <div class="px-5 py-4 grid grid-cols-3 gap-4">
                    <div>
                      <div style="font-family: var(--font-mono); font-size: 8px; letter-spacing: 0.2em; color: var(--ink-400);">JOINED</div>
                      <div style="font-family: var(--font-mono); font-size: 13px; font-weight: 700; color: var(--ink-900); margin-top: 2px;">{Calendar.strftime(u.inserted_at, "%d %b %Y")}</div>
                    </div>
                    <div>
                      <div style="font-family: var(--font-mono); font-size: 8px; letter-spacing: 0.2em; color: var(--ink-400);">TOURS</div>
                      <div style="font-family: var(--font-mono); font-size: 13px; font-weight: 700; color: var(--ink-900); margin-top: 2px;">{tc}</div>
                    </div>
                    <div>
                      <div style="font-family: var(--font-mono); font-size: 8px; letter-spacing: 0.2em; color: var(--ink-400);">SEATS</div>
                      <div style="font-family: var(--font-mono); font-size: 13px; font-weight: 700; color: var(--ink-900); margin-top: 2px;">{u.crew_seats || 0}</div>
                    </div>
                  </div>
                  <div class="px-5 pb-2 flex items-center gap-2">
                    <.signal_chip tone={if u.plan == "paid", do: "live", else: "ink"} size="sm" variant="tint">{String.upcase(u.plan)}</.signal_chip>
                    <.signal_chip tone={if u.role == "manager", do: "brand", else: "doors"} size="sm" variant="tint">{String.upcase(u.role)}</.signal_chip>
                    <%= if TourmanagerV2.Accounts.User.trial_active?(u) do %>
                      <.signal_chip tone="doors" size="sm" variant="tint">TRIAL</.signal_chip>
                    <% end %>
                  </div>
                  <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); padding: 0 20px 4px;">
                    Last login: {if u.last_login_at, do: Calendar.strftime(u.last_login_at, "%d %b %Y %H:%M"), else: "Never"}
                  </div>
                  <div class="flex items-center gap-3 mx-5 my-4">
                    <label for={"user-modal-#{u.id}"} class="flex-1 flex items-center justify-center py-2.5 cursor-pointer rounded-[var(--radius-md)]" style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400); border: 1px solid var(--paper-300);">
                      CLOSE
                    </label>
                    <button
                      type="button"
                      phx-click="open_edit_user"
                      phx-value-id={u.id}
                      onclick={"document.getElementById('user-modal-#{u.id}').checked = false"}
                      class="flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-[var(--radius-md)] cursor-pointer"
                      style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900);"
                    >
                      <.icon name="hero-pencil-mini" class="w-3.5 h-3.5" /> EDIT
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%!-- Edit user modal --%>
      <.tm_modal :if={@user_form} id="admin-user-modal" show={@user_modal_open} on_close="close_user_modal">
        <div class="px-6 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand-on-dark);">ADMIN</div>
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; margin-top: 2px;">
            Edit {@editing_admin_user && @editing_admin_user.name}
          </div>
        </div>
        <.form for={@user_form} id="admin-user-form" phx-change="validate_admin_user" phx-submit="save_admin_user" class="px-6 py-5">
          <div class="flex flex-col gap-4">
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">ROLE</label>
                <.input field={@user_form[:role]} type="select" options={[{"Manager", "manager"}, {"Crew", "crew"}]} class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
              </div>
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">PLAN</label>
                <.input field={@user_form[:plan]} type="select" options={[{"Free", "free"}, {"Paid", "paid"}]} class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
              </div>
            </div>
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">CREW SEATS</label>
              <.input field={@user_form[:crew_seats]} type="number" min="0" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
            </div>
            <div class="flex items-center gap-3">
              <.input field={@user_form[:is_admin]} type="checkbox" />
              <label style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-700);">Platform admin</label>
            </div>
          </div>
          <div class="flex items-center justify-end gap-3 mt-6 pt-5 border-t border-[var(--paper-300)]">
            <button type="button" phx-click="close_user_modal" class="px-4 py-2.5 rounded-[var(--radius-md)] cursor-pointer hover:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400); border: 1px solid var(--paper-300);">CANCEL</button>
            <button type="submit" class="px-5 py-2.5 rounded-[var(--radius-md)] cursor-pointer" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);">SAVE</button>
          </div>
        </.form>
      </.tm_modal>
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
