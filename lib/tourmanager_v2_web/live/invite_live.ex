defmodule TourmanagerV2Web.InviteLive do
  use TourmanagerV2Web, :live_view

  alias TourmanagerV2.Touring

  def mount(%{"token" => token}, session, socket) do
    user =
      case session do
        %{"user_id" => user_id} when is_binary(user_id) ->
          try do
            TourmanagerV2.Accounts.get_user!(user_id)
          rescue
            _ -> nil
          end

        _ ->
          nil
      end

    case Touring.get_invite_by_token(token) do
      {:ok, invite} ->
        socket =
          socket
          |> assign(:invite, invite)
          |> assign(:current_user, user)
          |> assign(:accepted, false)
          |> assign(:error, nil)
          |> assign(:page_title, "Join #{invite.tour.name}")

        if user do
          case Touring.accept_invite(invite, user) do
            {:ok, _} ->
              {:ok, assign(socket, :accepted, true)}

            {:error, :no_seats} ->
              {:ok, assign(socket, :error, "This tour has no crew seats available. Ask the tour manager to upgrade their plan.")}

            {:error, _} ->
              {:ok, assign(socket, :error, "Could not accept invite.")}
          end
        else
          {:ok, socket}
        end

      {:error, _} ->
        {:ok,
         socket
         |> assign(:invite, nil)
         |> assign(:current_user, user)
         |> assign(:accepted, false)
         |> assign(:error, "This invite link is invalid or has expired.")
         |> assign(:page_title, "Invalid Invite")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center p-6" style="background: var(--paper-100); font-family: var(--font-sans);">
      <div class="w-full max-w-sm">
        <div class="rounded-[var(--radius-xl)] overflow-hidden" style="border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard);">
          <div class="px-6 py-5" style="background: var(--surface-stage);">
            <div class="flex items-center gap-3 mb-4">
              <span class="w-[34px] h-[34px] rounded-[var(--radius-sm)] flex items-center justify-center" style="background: var(--brand); font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff;">T</span>
              <div style="font-family: var(--font-display); font-weight: 800; font-size: 16px; color: #fff;">TOUR MANAGER</div>
            </div>
            <%= if @invite do %>
              <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);">CREW INVITE</div>
              <div style="font-family: var(--font-display); font-weight: 800; font-size: 24px; color: #fff; margin-top: 4px;">{@invite.tour.name}</div>
            <% else %>
              <div style="font-family: var(--font-display); font-weight: 800; font-size: 24px; color: #fff;">Invite</div>
            <% end %>
          </div>

          <div class="px-6 py-6" style="background: var(--surface-card);">
            <%= cond do %>
              <% @error -> %>
                <div class="text-center">
                  <.icon name="hero-exclamation-triangle" class="w-8 h-8 text-[var(--signal-stop)] mx-auto mb-3" />
                  <div style="font-family: var(--font-sans); font-size: 14px; color: var(--ink-700);">{@error}</div>
                </div>

              <% @accepted -> %>
                <div class="text-center">
                  <.icon name="hero-check-circle" class="w-8 h-8 text-[var(--signal-live)] mx-auto mb-3" />
                  <div style="font-family: var(--font-display); font-weight: 700; font-size: 18px; color: var(--ink-900);">You're in</div>
                  <div class="mt-2" style="font-family: var(--font-sans); font-size: 14px; color: var(--ink-400);">
                    You've been added to {@invite.tour.name} as crew.
                  </div>
                  <.link navigate="/app" class="flex items-center justify-center gap-2 mt-5 py-3 rounded-[var(--radius-md)] no-underline" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);">
                    OPEN TOUR MANAGER
                  </.link>
                </div>

              <% !@current_user -> %>
                <div class="text-center">
                  <div style="font-family: var(--font-sans); font-size: 14px; color: var(--ink-700); margin-bottom: 16px;">
                    Sign in to join {@invite.tour.name} as crew.
                  </div>
                  <.link href="/auth/google" class="flex items-center justify-center gap-2 py-3 rounded-[var(--radius-md)] no-underline" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);">
                    <.icon name="hero-globe-alt" class="w-4 h-4" />
                    SIGN IN WITH GOOGLE
                  </.link>
                  <.link href="/auth/microsoft" class="flex items-center justify-center gap-2 mt-3 py-3 rounded-[var(--radius-md)] no-underline" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-500); background: var(--surface-card); border: 1px solid var(--paper-300);">
                    <.icon name="hero-building-office" class="w-4 h-4" />
                    SIGN IN WITH MICROSOFT
                  </.link>
                </div>

              <% true -> %>
                <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400);">Processing...</div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
