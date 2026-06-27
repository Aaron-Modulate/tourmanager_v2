defmodule TourmanagerV2Web.ProfileLive do
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  alias TourmanagerV2.Accounts

  def mount(_params, _session, socket) do
    user = socket.assigns[:current_user]

    socket =
      socket
      |> assign(TourSwitching.default_assigns())
      |> assign(active_nav: "profile", page_title: "Edit Profile")
      |> TourSwitching.load_tour_data(socket.assigns[:current_tour])

    socket =
      if user do
        changeset = Accounts.change_profile(user)

        socket
        |> assign(:profile_form, Phoenix.Component.to_form(changeset))
        |> assign(:social_instagram, get_in(user.social_links || %{}, ["instagram"]) || "")
        |> assign(:social_twitter, get_in(user.social_links || %{}, ["twitter"]) || "")
        |> assign(:social_website, get_in(user.social_links || %{}, ["website"]) || "")
        |> assign(:saved, false)
      else
        socket
      end

    {:ok, socket}
  end

  def handle_event("validate_profile", %{"user" => params}, socket) do
    user = socket.assigns.current_user
    changeset = Accounts.change_profile(user, params) |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:profile_form, Phoenix.Component.to_form(changeset))
     |> assign(:saved, false)}
  end

  def handle_event("save_profile", %{"user" => params}, socket) do
    user = socket.assigns.current_user

    social_links = %{
      "instagram" => params["social_instagram"] || "",
      "twitter" => params["social_twitter"] || "",
      "website" => params["social_website"] || ""
    }

    profile_params = Map.put(params, "social_links", social_links)

    case Accounts.update_profile(user, profile_params) do
      {:ok, updated_user} ->
        changeset = Accounts.change_profile(updated_user)

        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> assign(:profile_form, Phoenix.Component.to_form(changeset))
         |> assign(:social_instagram, social_links["instagram"])
         |> assign(:social_twitter, social_links["twitter"])
         |> assign(:social_website, social_links["website"])
         |> assign(:saved, true)}

      {:error, changeset} ->
        {:noreply, assign(socket, :profile_form, Phoenix.Component.to_form(changeset))}
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
      <div id="profile-page" class="p-4 md:p-7 max-w-2xl">
        <div class="mb-6">
          <.overline>Account</.overline>
          <.display size={26} class="mt-1.5">Edit profile</.display>
        </div>

        <%= if @current_user do %>
          <%!-- Avatar header --%>
          <div class="flex items-center gap-4 mb-6 p-4 rounded-[var(--radius-md)] border-2 border-[var(--ink-900)]" style="background: var(--surface-stage); box-shadow: var(--shadow-hard-sm);">
            <%= if @current_user.avatar_url do %>
              <img src={@current_user.avatar_url} class="w-16 h-16 rounded-[var(--radius-md)] object-cover flex-none" referrerpolicy="no-referrer" />
            <% else %>
              <span class="w-16 h-16 rounded-[var(--radius-md)] flex items-center justify-center flex-none" style="background: var(--ink-700); font-family: var(--font-mono); font-weight: 700; font-size: 22px; color: var(--paper-100);">
                {initials(@current_user.name)}
              </span>
            <% end %>
            <div>
              <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff;">{@current_user.name}</div>
              <div style="font-family: var(--font-mono); font-size: 10px; letter-spacing: 0.1em; color: var(--ink-300); margin-top: 2px;">
                {@current_user.email}
              </div>
            </div>
          </div>

          <%!-- Saved indicator --%>
          <div :if={@saved} class="mb-4 px-4 py-2.5 rounded-[var(--radius-md)] flex items-center gap-2" style="background: var(--signal-live-tint); border: 1px solid var(--signal-live);">
            <.icon name="hero-check-circle-mini" class="w-4 h-4 text-[var(--signal-live)]" />
            <span style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; color: var(--signal-live);">Profile saved</span>
          </div>

          <.form for={@profile_form} id="profile-form" phx-change="validate_profile" phx-submit="save_profile">
            <%!-- Identity section --%>
            <div class="rounded-[var(--radius-md)] border border-[var(--paper-300)] overflow-hidden mb-5" style="background: var(--surface-card);">
              <div class="px-5 py-3 border-b border-[var(--paper-300)]" style="background: var(--paper-200);">
                <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">IDENTITY</div>
              </div>
              <div class="p-5 flex flex-col gap-4">
                <div>
                  <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">DISPLAY NAME</label>
                  <.input field={@profile_form[:name]} type="text" placeholder="Your name" class="w-full px-3 py-2.5 text-[15px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
                </div>
                <div>
                  <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">FULL LEGAL NAME</label>
                  <.input field={@profile_form[:legal_name]} type="text" placeholder="As on passport" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
                  <div style="font-family: var(--font-mono); font-size: 9px; color: var(--ink-300); margin-top: 4px;">Used for travel documentation and manifests</div>
                </div>
                <div>
                  <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">ROLE</label>
                  <.input field={@profile_form[:role_title]} type="text" placeholder="e.g. FOH Engineer, Tour Manager, Guitar Tech" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
                </div>
              </div>
            </div>

            <%!-- Travel section --%>
            <div class="rounded-[var(--radius-md)] border border-[var(--paper-300)] overflow-hidden mb-5" style="background: var(--surface-card);">
              <div class="px-5 py-3 border-b border-[var(--paper-300)]" style="background: var(--paper-200);">
                <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">TRAVEL</div>
              </div>
              <div class="p-5 flex flex-col gap-4">
                <div>
                  <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">PASSPORT NUMBER</label>
                  <.input field={@profile_form[:passport_number]} type="text" placeholder="e.g. PA1234567" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
                </div>
                <div>
                  <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">FREQUENT FLYER</label>
                  <.input field={@profile_form[:frequent_flyer]} type="text" placeholder="e.g. QF 12345678" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
                </div>
              </div>
            </div>

            <%!-- Contact section --%>
            <div class="rounded-[var(--radius-md)] border border-[var(--paper-300)] overflow-hidden mb-5" style="background: var(--surface-card);">
              <div class="px-5 py-3 border-b border-[var(--paper-300)]" style="background: var(--paper-200);">
                <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">CONTACT</div>
              </div>
              <div class="p-5 flex flex-col gap-4">
                <div>
                  <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">PHONE</label>
                  <.input field={@profile_form[:phone_number]} type="tel" placeholder="+61 400 000 000" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
                </div>
                <div>
                  <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">INSTAGRAM</label>
                  <input type="text" name="user[social_instagram]" value={@social_instagram} placeholder="@handle" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
                </div>
                <div>
                  <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">X / TWITTER</label>
                  <input type="text" name="user[social_twitter]" value={@social_twitter} placeholder="@handle" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
                </div>
                <div>
                  <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">WEBSITE</label>
                  <input type="text" name="user[social_website]" value={@social_website} placeholder="https://" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
                </div>
              </div>
            </div>

            <div class="flex items-center justify-end gap-3">
              <.link navigate="/app" class="px-4 py-2.5 rounded-[var(--radius-md)] cursor-pointer no-underline hover:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400); border: 1px solid var(--paper-300);">CANCEL</.link>
              <button type="submit" class="px-5 py-2.5 rounded-[var(--radius-md)] cursor-pointer" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);">SAVE PROFILE</button>
            </div>
          </.form>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
