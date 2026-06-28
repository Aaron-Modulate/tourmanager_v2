defmodule TourmanagerV2Web.CrewLive do
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  alias TourmanagerV2.Touring
  alias TourmanagerV2.Accounts.User

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(TourSwitching.default_assigns())
      |> assign(active_nav: "crew", page_title: "Crew",
               invite_modal_open: false, invite_mode: "link", invite_token: nil)
      |> TourSwitching.load_tour_data(socket.assigns[:current_tour])
      |> load_crew_data()

    {:ok, socket}
  end

  def handle_event("select_tour", %{"tour-id" => tour_id}, socket) do
    {:noreply, socket} = TourSwitching.handle_event("select_tour", %{"tour-id" => tour_id}, socket)
    {:noreply, load_crew_data(socket)}
  end

  def handle_event("open_invite", _params, socket) do
    tour = socket.assigns.current_tour
    user = socket.assigns.current_user

    if tour && user && User.manager?(user) do
      remaining = Touring.crew_seats_remaining(tour.id)

      if remaining > 0 do
        case Touring.get_or_create_active_invite(tour, user) do
          {:ok, invite} ->
            {:noreply,
             socket
             |> assign(:invite_modal_open, true)
             |> assign(:invite_token, invite.token)
             |> assign(:invite_mode, "link")}

          _ ->
            {:noreply, socket}
        end
      else
        {:noreply,
         socket
         |> assign(:invite_modal_open, false)
         |> Phoenix.LiveView.put_flash(:error, "No crew seats remaining. Upgrade your plan to add more.")}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("close_invite", _params, socket) do
    {:noreply, assign(socket, :invite_modal_open, false)}
  end

  def handle_event("set_invite_mode", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, :invite_mode, mode)}
  end

  def handle_event("remove_crew", %{"user-id" => user_id}, socket) do
    tour = socket.assigns.current_tour

    if tour do
      Touring.remove_crew_from_tour(tour.id, user_id)
      TourmanagerV2.TourBroadcast.broadcast_change(tour.id)
      {:noreply, load_crew_data(socket)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:tour_data_changed, tour_id, source_pid}, socket) do
    if source_pid != self() && socket.assigns[:current_tour] && socket.assigns.current_tour.id == tour_id do
      socket =
        socket
        |> TourSwitching.load_tour_data(socket.assigns.current_tour)
        |> load_crew_data()

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("promote_member", %{"user-id" => user_id}, socket) do
    tour = socket.assigns.current_tour

    if tour do
      case Touring.promote_to_manager(tour.id, user_id) do
        {:ok, _} ->
          TourmanagerV2.TourBroadcast.broadcast_change(tour.id)
          {:noreply, load_crew_data(socket)}
        {:error, :not_subscribed} ->
          {:noreply, Phoenix.LiveView.put_flash(socket, :error, "This member needs a manager subscription before they can be promoted.")}
        _ -> {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("toggle_all_dates", %{"user-id" => user_id}, socket) do
    tour = socket.assigns.current_tour

    if tour do
      case Touring.toggle_all_dates_default(tour.id, user_id) do
        {:ok, _} ->
          TourmanagerV2.TourBroadcast.broadcast_change(tour.id)
          {:noreply, load_crew_data(socket)}
        _ -> {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("demote_member", %{"user-id" => user_id}, socket) do
    tour = socket.assigns.current_tour

    if tour do
      case Touring.demote_to_crew(tour.id, user_id) do
        {:ok, _} ->
          TourmanagerV2.TourBroadcast.broadcast_change(tour.id)
          {:noreply, load_crew_data(socket)}
        {:error, :no_seats} ->
          {:noreply, Phoenix.LiveView.put_flash(socket, :error, "No crew seats available. Cannot demote to crew.")}
        _ -> {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  defp load_crew_data(socket) do
    tour = socket.assigns[:current_tour]

    if tour do
      all_members = Touring.list_tour_memberships(tour.id)
      crew_count = Enum.count(all_members, fn %{membership: m} -> m.role == "crew" end)
      total_seats = Touring.total_seats_on_tour(tour.id)
      remaining = Touring.crew_seats_remaining(tour.id)

      assign(socket,
        tour_members: all_members,
        crew_count: crew_count,
        crew_seats_total: total_seats,
        crew_seats_remaining: remaining
      )
    else
      assign(socket,
        tour_members: [],
        crew_count: 0,
        crew_seats_total: 0,
        crew_seats_remaining: 0
      )
    end
  end

  defp invite_url(token) do
    TourmanagerV2Web.Endpoint.url() <> "/invite/#{token}"
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
      <div id="crew-page" class="p-4 md:p-7 max-w-3xl">
        <div class="flex items-end justify-between mb-5">
          <div>
            <.overline>Crew</.overline>
            <.display size={26} class="mt-1.5">Your people</.display>
          </div>
          <%= if @current_tour && @current_user && TourmanagerV2.Accounts.User.manager?(@current_user) do %>
            <.tm_button variant="primary" size="sm" icon_name="hero-user-plus" phx-click="open_invite">Invite</.tm_button>
          <% end %>
        </div>

        <%!-- Seat counter --%>
        <%= if @current_tour do %>
          <div class="flex items-center gap-3 mb-5 px-4 py-3 rounded-[var(--radius-md)] border border-[var(--paper-300)]" style="background: var(--surface-card);">
            <.icon name="hero-users" class="w-4 h-4 text-[var(--ink-400)]" />
            <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-500);">
              {@crew_count} of {@crew_seats_total} crew seats used
            </div>
            <div class="flex-1" />
            <div
              class="px-2 py-0.5 rounded-[var(--radius-stamp)]"
              style={"font-family: var(--font-mono); font-size: 9px; font-weight: 700; letter-spacing: 0.1em; color: #{if @crew_seats_remaining == 0, do: "var(--signal-stop)", else: "var(--signal-live)"}; background: #{if @crew_seats_remaining == 0, do: "var(--signal-stop-tint)", else: "var(--signal-live-tint)"};"}
            >
              {@crew_seats_remaining} REMAINING
            </div>
          </div>
        <% end %>

        <%!-- Member list --%>
        <%= if !@current_tour do %>
          <div class="py-16 text-center">
            <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400); letter-spacing: 0.06em;">
              Select a tour to manage crew.
            </div>
          </div>
        <% else %>
          <%= if @tour_members == [] do %>
            <div class="py-16 text-center">
              <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400); letter-spacing: 0.06em;">
                No members on this tour yet. Invite your first crew member.
              </div>
            </div>
          <% else %>
            <div class="flex flex-col gap-2">
              <div
                :for={%{membership: membership, user: member} <- @tour_members}
                class="flex items-center gap-3 p-3 rounded-[var(--radius-md)] border border-[var(--paper-300)] transition-colors hover:bg-[var(--paper-200)]"
                style="background: var(--surface-card);"
              >
                <%= if member.avatar_url do %>
                  <img src={member.avatar_url} class="w-10 h-10 rounded-[var(--radius-sm)] object-cover flex-none" referrerpolicy="no-referrer" />
                <% else %>
                  <span class="w-10 h-10 rounded-[var(--radius-sm)] flex items-center justify-center flex-none" style="background: var(--ink-900); color: var(--paper-100); font-family: var(--font-mono); font-weight: 700; font-size: 14px;">
                    {initials(member.name)}
                  </span>
                <% end %>
                <div class="flex-1 min-w-0">
                  <div class="text-[14px] font-semibold text-[var(--ink-900)] truncate">{member.name}</div>
                  <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); margin-top: 1px;">
                    {member.email}
                    <%= if membership.role == "manager" && TourmanagerV2.Accounts.User.subscribed?(member) do %>
                      <span style="color: var(--ink-300);"> · +{member.crew_seats} seats</span>
                    <% end %>
                  </div>
                </div>
                <.signal_chip
                  tone={if membership.role == "manager", do: "brand", else: "live"}
                  size="sm"
                  variant="tint"
                >{String.upcase(membership.role)}</.signal_chip>

                <%!-- All dates toggle --%>
                <%= if @current_user && TourmanagerV2.Accounts.User.manager?(@current_user) && member.id != @current_user.id do %>
                  <button
                    type="button"
                    phx-click="toggle_all_dates"
                    phx-value-user-id={member.id}
                    class="flex items-center gap-1.5 px-2 py-1 rounded-[var(--radius-sm)] cursor-pointer transition-colors hover:bg-[var(--paper-200)]"
                    title={if membership.all_dates_default, do: "On all dates — click to remove", else: "Per-date only — click to add to all"}
                  >
                    <div
                      class="w-7 h-4 rounded-full relative transition-colors"
                      style={"background: #{if membership.all_dates_default, do: "var(--brand)", else: "var(--paper-300)"}; border: 1px solid #{if membership.all_dates_default, do: "var(--brand)", else: "var(--ink-300)"};"}
                    >
                      <div
                        class="absolute top-0.5 w-2.5 h-2.5 rounded-full transition-all"
                        style={"background: #fff; #{if membership.all_dates_default, do: "left: 14px;", else: "left: 2px;"}"}
                      />
                    </div>
                    <span style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.06em; color: var(--ink-400);">
                      {if membership.all_dates_default, do: "ALL", else: "PER DATE"}
                    </span>
                  </button>
                <% end %>

                <%!-- Manager actions (only for tour managers, not on themselves) --%>
                <%= if @current_user && TourmanagerV2.Accounts.User.manager?(@current_user) && member.id != @current_user.id do %>
                  <div class="relative group/actions">
                    <button type="button" class="p-1.5 rounded-[var(--radius-sm)] cursor-pointer transition-colors hover:bg-[var(--paper-200)]">
                      <.icon name="hero-ellipsis-vertical-mini" class="w-4 h-4 text-[var(--ink-300)]" />
                    </button>
                    <div class="absolute right-0 top-full mt-1 hidden group-hover/actions:block z-50 rounded-[var(--radius-md)] overflow-hidden" style="background: var(--surface-card); border: 1px solid var(--paper-300); box-shadow: var(--shadow-hard); min-width: 150px;">
                      <%= if membership.role == "crew" && TourmanagerV2.Accounts.User.subscribed?(member) do %>
                        <button
                          type="button"
                          phx-click="promote_member"
                          phx-value-user-id={member.id}
                          class="w-full text-left px-3 py-2 flex items-center gap-2 cursor-pointer transition-colors hover:bg-[var(--paper-200)]"
                          style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-500);"
                        >
                          <.icon name="hero-arrow-up-mini" class="w-3.5 h-3.5" />
                          PROMOTE
                        </button>
                      <% end %>
                      <%= if membership.role == "manager" do %>
                        <button
                          type="button"
                          phx-click="demote_member"
                          phx-value-user-id={member.id}
                          data-confirm={"Demote #{member.name} to crew? This will use a crew seat."}
                          class="w-full text-left px-3 py-2 flex items-center gap-2 cursor-pointer transition-colors hover:bg-[var(--paper-200)]"
                          style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-500);"
                        >
                          <.icon name="hero-arrow-down-mini" class="w-3.5 h-3.5" />
                          DEMOTE
                        </button>
                      <% end %>
                      <button
                        type="button"
                        phx-click="remove_crew"
                        phx-value-user-id={member.id}
                        data-confirm={"Remove #{member.name} from this tour?"}
                        class="w-full text-left px-3 py-2 flex items-center gap-2 cursor-pointer transition-colors hover:bg-[var(--signal-stop-tint)] border-t border-[var(--paper-300)]"
                        style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--signal-stop);"
                      >
                        <.icon name="hero-trash-mini" class="w-3.5 h-3.5" />
                        REMOVE
                      </button>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>

      <%!-- Invite modal --%>
      <.tm_modal id="invite-modal" show={@invite_modal_open} on_close="close_invite">
        <div class="px-6 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);">INVITE</div>
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; margin-top: 2px;">Add crew member</div>
        </div>

        <%!-- Mode switcher --%>
        <div class="px-6 pt-5 pb-3">
          <div class="flex gap-2">
            <button
              :for={{mode, icon, label} <- [{"link", "hero-link", "Link"}, {"qr", "hero-qr-code", "QR Code"}, {"email", "hero-envelope", "Email"}]}
              type="button"
              phx-click="set_invite_mode"
              phx-value-mode={mode}
              class={[
                "flex-1 flex items-center justify-center gap-2 py-2.5 rounded-[var(--radius-md)] cursor-pointer transition-all",
                if(@invite_mode == mode, do: "border-2 border-[var(--brand)]", else: "border border-[var(--paper-300)] hover:border-[var(--ink-400)]")
              ]}
              style={"font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; background: #{if @invite_mode == mode, do: "var(--marker-050)", else: "var(--surface-card)"}; color: #{if @invite_mode == mode, do: "var(--brand)", else: "var(--ink-500)"};"}
            >
              <.icon name={icon} class="w-4 h-4" />
              {label}
            </button>
          </div>
        </div>

        <div class="px-6 pb-6">
          <%!-- Link mode --%>
          <div :if={@invite_mode == "link" && @invite_token} class="mt-2">
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); margin-bottom: 8px;">INVITE LINK</div>
            <div class="flex gap-2">
              <input
                type="text"
                readonly
                value={invite_url(@invite_token)}
                id="invite-link-input"
                class="flex-1 px-3 py-2.5 text-[12px] rounded-[var(--radius-md)] border border-[var(--paper-300)] outline-none"
                style="background: var(--paper-200); color: var(--ink-700); font-family: var(--font-mono);"
              />
              <button
                type="button"
                phx-click={Phoenix.LiveView.JS.dispatch("phx:copy", to: "#invite-link-input")}
                class="px-4 py-2.5 rounded-[var(--radius-md)] cursor-pointer transition-all flex items-center gap-1.5"
                style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);"
              >
                <.icon name="hero-clipboard-document" class="w-4 h-4" />
                COPY
              </button>
            </div>
            <div class="mt-3" style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400);">
              Share this link with a crew member. They'll be added to this tour when they sign in.
            </div>
          </div>

          <%!-- QR Code mode --%>
          <div :if={@invite_mode == "qr" && @invite_token} class="mt-2">
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); margin-bottom: 8px;">SCAN TO JOIN</div>
            <div class="flex justify-center p-6 rounded-[var(--radius-md)] border border-[var(--paper-300)]" style="background: #fff;">
              <img
                src={"https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=#{URI.encode(invite_url(@invite_token))}"}
                class="w-[200px] h-[200px]"
                alt="Invite QR code"
              />
            </div>
            <div class="mt-3 text-center" style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400);">
              Crew member scans this with their phone camera to join.
            </div>
          </div>

          <%!-- Email mode (placeholder) --%>
          <div :if={@invite_mode == "email"} class="mt-2">
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); margin-bottom: 8px;">EMAIL INVITE</div>
            <div class="py-8 text-center rounded-[var(--radius-md)] border border-[var(--paper-300)]" style="background: var(--paper-200);">
              <.icon name="hero-envelope" class="w-8 h-8 text-[var(--ink-300)] mx-auto mb-2" />
              <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">
                Email invites coming soon. Use the link or QR code for now.
              </div>
            </div>
          </div>
        </div>
      </.tm_modal>
    </Layouts.app>
    """
  end
end
