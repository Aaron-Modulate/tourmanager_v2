defmodule TourmanagerV2Web.Layouts do
  @moduledoc """
  Tour Manager layouts — app shell with left rail, mobile drawers, and stage topbar.
  """
  use TourmanagerV2Web, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true
  attr :current_scope, :map, default: nil, doc: "the current scope"
  attr :current_user, :map, default: nil
  attr :user_tours, :list, default: []
  attr :current_tour, :map, default: nil
  attr :current_tour_role, :string, default: nil
  attr :active_nav, :string, default: "daysheet", doc: "active navigation item"
  attr :tour_menu_open, :boolean, default: false
  attr :settings_open, :boolean, default: false
  attr :new_tour_open, :boolean, default: false
  attr :new_tour_form, :map, default: nil
  attr :headerbar_entry, :map, default: nil
  attr :headerbar_is_today, :boolean, default: false
  attr :billing_seats, :integer, default: 10
  attr :billing_error, :string, default: nil
  attr :manage_tour_open, :boolean, default: false
  attr :manage_tour_form, :map, default: nil
  attr :calendar_modal_open, :boolean, default: false
  attr :calendar_token, :string, default: nil
  attr :calendar_mode, :string, default: "subscribe"

  slot :inner_block, required: true

  def app(assigns) do
    today = Date.utc_today()
    today_str = Calendar.strftime(today, "%a %d %b %Y") |> String.upcase()

    headerbar_entry = assigns[:headerbar_entry]
    headerbar_is_today = assigns[:headerbar_is_today] || false

    {days_away_label, days_away_tone} =
      cond do
        headerbar_entry && headerbar_entry.date ->
          days = Date.diff(headerbar_entry.date, today)

          cond do
            days == 0 -> {"TODAY", "live"}
            days == 1 -> {"TOMORROW", "doors"}
            days > 1 -> {"IN #{days} DAYS", "doors"}
            true -> {"#{abs(days)}D AGO", "ink"}
          end

        true ->
          {nil, nil}
      end

    headerbar_nav_url =
      if headerbar_entry && headerbar_entry.date do
        "/app?date=#{Date.to_iso8601(headerbar_entry.date)}"
      else
        "/app"
      end

    assigns =
      assigns
      |> Map.put(:today_str, today_str)
      |> Map.put(:days_away_label, days_away_label)
      |> Map.put(:days_away_tone, days_away_tone)
      |> Map.put(:headerbar_nav_url, headerbar_nav_url)

    ~H"""
    <div id="app-shell" class="flex flex-col md:flex-row h-screen" style="background: var(--paper-100); color: var(--ink-700); font-family: var(--font-sans);">
      <%!-- ============================================ --%>
      <%!-- MOBILE: Fixed header with stop info --%>
      <%!-- ============================================ --%>
      <div class="md:hidden flex-none">
        <%!-- Top bar: hamburger + stop info + info pane toggle --%>
        <div class="flex items-center gap-2 px-3 py-2.5 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage); color: var(--paper-100);">
          <%!-- Left: hamburger opens tour/nav drawer --%>
          <label for="mobile-left-drawer" class="cursor-pointer p-1.5 -ml-1 rounded-[var(--radius-sm)] active:bg-[var(--ink-700)]">
            <.icon name="hero-bars-3" class="w-5 h-5 text-[var(--paper-100)]" />
          </label>

          <%!-- Center: venue + date + days away — tap to open day sheet --%>
          <.link navigate={@headerbar_nav_url} class="flex-1 min-w-0 no-underline">
            <%= if @headerbar_entry && @headerbar_entry.date do %>
              <div class="flex items-center gap-1.5">
                <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.16em; color: var(--brand-on-dark);">
                  {headerbar_date(@headerbar_entry)}
                </div>
                <.signal_chip tone={@days_away_tone} size="sm">{@days_away_label}</.signal_chip>
              </div>
              <div class="truncate" style="font-family: var(--font-display); font-weight: 800; font-size: 18px; letter-spacing: -0.01em; color: #fff; margin-top: 1px;">
                {@headerbar_entry.venue || @headerbar_entry.origin || "Upcoming"}
                <span :if={@headerbar_entry.city} style="font-weight: 400; font-size: 13px; color: var(--ink-300); margin-left: 4px;">
                  {@headerbar_entry.city}
                </span>
              </div>
            <% else %>
              <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.16em; color: var(--brand-on-dark);">{@today_str}</div>
              <div class="truncate" style="font-family: var(--font-display); font-weight: 800; font-size: 18px; letter-spacing: -0.01em; color: #fff; margin-top: 1px;">
                {if @current_tour, do: @current_tour.name, else: "Tour Manager"}
              </div>
            <% end %>
          </.link>

          <%!-- Right: info pane toggle + settings --%>
          <div class="flex items-center gap-1">
            <label for="mobile-right-drawer" class="cursor-pointer p-1.5 rounded-[var(--radius-sm)] active:bg-[var(--ink-700)]">
              <.icon name="hero-information-circle" class="w-5 h-5 text-[var(--ink-300)]" />
            </label>
            <%= if @current_user do %>
              <div class="relative">
                <input type="checkbox" id="mobile-avatar-menu" class="hidden peer/avatar" />
                <label for="mobile-avatar-menu" class="cursor-pointer p-0.5 block">
                  <%= if @current_user.avatar_url do %>
                    <img src={@current_user.avatar_url} class="w-7 h-7 rounded-[var(--radius-sm)] object-cover" referrerpolicy="no-referrer" />
                  <% else %>
                    <span class="w-7 h-7 rounded-[var(--radius-sm)] flex items-center justify-center" style="background: var(--ink-700); font-family: var(--font-mono); font-weight: 700; font-size: 10px;">{initials(@current_user.name)}</span>
                  <% end %>
                </label>
                <div class="absolute right-0 top-full mt-2 hidden peer-checked/avatar:block z-50 rounded-[var(--radius-md)] overflow-hidden" style="background: var(--ink-700); border: 1px solid var(--ink-500); box-shadow: var(--shadow-hard); min-width: 160px;">
                  <.link navigate="/profile" class="w-full text-left px-4 py-2.5 flex items-center gap-2.5 cursor-pointer transition-colors hover:bg-[var(--ink-500)] no-underline" style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--paper-100);">
                    <.icon name="hero-user-mini" class="w-3.5 h-3.5" /> EDIT PROFILE
                  </.link>
                  <button type="button" phx-click="open_settings" class="w-full text-left px-4 py-2.5 flex items-center gap-2.5 cursor-pointer transition-colors hover:bg-[var(--ink-500)] border-t border-[var(--ink-500)]" style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--paper-100);">
                    <.icon name="hero-cog-6-tooth-mini" class="w-3.5 h-3.5" /> SETTINGS
                  </button>
                </div>
                <label for="mobile-avatar-menu" class="fixed inset-0 z-40 hidden peer-checked/avatar:block" />
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <%!-- ============================================ --%>
      <%!-- MOBILE: Left drawer — tour switcher + nav --%>
      <%!-- ============================================ --%>
      <input type="checkbox" id="mobile-left-drawer" class="hidden peer/left" />
      <div class="fixed inset-0 z-50 hidden peer-checked/left:flex md:hidden">
        <label for="mobile-left-drawer" class="absolute inset-0" style="background: rgba(20, 17, 15, 0.55); backdrop-filter: blur(4px);" />
        <aside class="relative z-10 w-[280px] h-full flex flex-col overflow-y-auto" style="background: var(--surface-stage); color: var(--paper-100);">
          <%!-- Drawer header --%>
          <div class="flex items-center justify-between px-[18px] pt-[18px] pb-[14px] border-b border-[var(--ink-700)]">
            <div class="flex items-center gap-2.5">
              <span class="w-[34px] h-[34px] rounded-[var(--radius-sm)] flex items-center justify-center" style="background: var(--brand); box-shadow: var(--shadow-hard-sm); font-family: var(--font-display); font-weight: 800; font-size: 22px; color: #fff;">T</span>
              <div class="leading-none">
                <div style="font-family: var(--font-display); font-weight: 800; font-size: 16px; letter-spacing: -0.01em;">TOUR MANAGER</div>
                <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.28em; color: var(--brand-on-dark); margin-top: 3px;">DAY SHEET OS</div>
              </div>
            </div>
            <label for="mobile-left-drawer" class="cursor-pointer p-1">
              <.icon name="hero-x-mark" class="w-5 h-5 text-[var(--ink-300)]" />
            </label>
          </div>

          <%!-- Tour switcher dropdown --%>
          <div class="px-[18px] py-[14px] border-b border-[var(--ink-700)]">
            <%= if @current_tour do %>
              <details class="group/tour-dd">
                <summary class="flex items-center justify-between cursor-pointer list-none" style="list-style: none;">
                  <div class="min-w-0">
                    <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300);">CURRENT TOUR</div>
                    <div class="truncate" style="font-family: var(--font-display); font-weight: 700; font-size: 16px; letter-spacing: -0.01em; color: #fff; margin-top: 4px;">
                      {String.upcase(@current_tour.name)}
                    </div>
                  </div>
                  <.icon name="hero-chevron-down" class="w-4 h-4 text-[var(--ink-300)] flex-none transition-transform group-open/tour-dd:rotate-180" />
                </summary>

                <div class="mt-3 flex flex-col gap-1">
                  <button
                    :for={%{tour: tour, role: role} <- @user_tours}
                    type="button"
                    phx-click="select_tour"
                    phx-value-tour-id={tour.id}
                    class={[
                      "w-full text-left px-3 py-2.5 rounded-[var(--radius-sm)] flex items-center justify-between cursor-pointer transition-colors",
                      if(@current_tour && tour.id == @current_tour.id, do: "bg-[var(--brand)]", else: "active:bg-[var(--ink-500)]")
                    ]}
                  >
                    <div>
                      <div style="font-family: var(--font-display); font-weight: 700; font-size: 13px; color: #fff;">{tour.name}</div>
                      <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.1em; color: var(--ink-300); margin-top: 1px;">{String.upcase(role)}</div>
                    </div>
                    <.icon :if={@current_tour && tour.id == @current_tour.id} name="hero-check" class="w-4 h-4 text-white" />
                  </button>

                  <%!-- Create new tour --%>
                  <button
                    :if={@current_user}
                    type="button"
                    phx-click="new_tour"
                    class="w-full text-left px-3 py-2.5 rounded-[var(--radius-sm)] flex items-center gap-2 cursor-pointer transition-colors active:bg-[var(--ink-500)]"
                    style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-300);"
                  >
                    <.icon name="hero-plus-mini" class="w-3.5 h-3.5" />
                    NEW TOUR
                  </button>

                  <%!-- Manage tour --%>
                  <button
                    :if={@current_tour_role == "manager"}
                    type="button"
                    phx-click="open_manage_tour"
                    class="w-full text-left px-3 py-2.5 rounded-[var(--radius-sm)] flex items-center gap-2 cursor-pointer transition-colors active:bg-[var(--ink-500)] mt-1 border-t border-[var(--ink-700)] pt-2"
                    style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-300);"
                  >
                    <.icon name="hero-cog-6-tooth-mini" class="w-3.5 h-3.5" />
                    MANAGE TOUR
                  </button>
                </div>
              </details>
            <% else %>
              <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300);">CURRENT TOUR</div>
              <div class="mt-2" style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400);">No tours yet</div>
              <button
                :if={@current_user}
                type="button"
                phx-click="new_tour"
                class="w-full text-left px-3 py-2.5 mt-2 rounded-[var(--radius-sm)] flex items-center gap-2 cursor-pointer transition-colors active:bg-[var(--ink-500)]"
                style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-300);"
              >
                <.icon name="hero-plus-mini" class="w-3.5 h-3.5" />
                CREATE TOUR
              </button>
            <% end %>
          </div>

          <%!-- Navigation --%>
          <nav class="px-2.5 py-3 flex flex-col gap-1 flex-1">
            <div :for={section <- nav_sections(@current_user)} class="flex flex-col gap-0.5">
              <div class="px-3 pt-3 pb-1 first:pt-0" style="font-family: var(--font-mono); font-size: 9px; font-weight: 700; letter-spacing: 0.24em; color: var(--ink-300);">
                {String.upcase(section.title)}
              </div>
              <label :for={item <- section.items} for="mobile-left-drawer">
                <.link
                  navigate={item.path}
                  class={[
                    "flex items-center gap-3 px-3 py-3 rounded-[var(--radius-sm)] no-underline transition-colors",
                    if(item.active.(assigns), do: "text-white", else: if(item.soft, do: "text-[var(--ink-300)]", else: "text-[var(--paper-100)]"))
                  ]}
                  style={"font-family: var(--font-mono); font-size: 13px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; #{if item.active.(assigns), do: "background: var(--brand); box-shadow: var(--shadow-hard-sm);", else: "background: transparent;"}"}
                >
                  <.icon name={item.icon} class="w-5 h-5" />
                  {item.label}
                  <span :if={Map.get(item, :admin)} class="px-1 py-0.5 rounded-[var(--radius-stamp)] ml-auto" style="background: var(--signal-stop); color: #fff; font-size: 7px; letter-spacing: 0.1em; line-height: 1;">ADMIN</span>
                </.link>
              </label>
            </div>
          </nav>

          <%!-- User --%>
          <div class="px-[18px] py-[14px] border-t border-[var(--ink-700)]">
            <%= if @current_user do %>
              <label for="mobile-left-drawer">
                <button type="button" phx-click="open_settings" class="flex items-center gap-2.5 w-full cursor-pointer rounded-[var(--radius-sm)] px-1 py-1">
                  <%= if @current_user.avatar_url do %>
                    <img src={@current_user.avatar_url} class="w-[30px] h-[30px] rounded-[var(--radius-sm)] object-cover flex-none" referrerpolicy="no-referrer" />
                  <% else %>
                    <span class="w-[30px] h-[30px] rounded-[var(--radius-sm)] flex items-center justify-center flex-none" style="background: var(--ink-700); font-family: var(--font-mono); font-weight: 700; font-size: 12px;">{initials(@current_user.name)}</span>
                  <% end %>
                  <div class="flex-1 min-w-0 leading-tight text-left">
                    <div class="text-[13px] font-semibold text-white truncate">{@current_user.name}</div>
                    <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.1em; color: var(--ink-300);">{String.upcase(@current_user.role)} · {String.upcase(@current_user.plan)}</div>
                  </div>
                </button>
              </label>
            <% else %>
              <div class="flex flex-col gap-2">
                <.link href="/auth/google" class="flex items-center gap-2.5 px-3 py-3 rounded-[var(--radius-sm)] no-underline" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: var(--paper-100);">
                  <.icon name="hero-globe-alt" class="w-5 h-5" /> SIGN IN WITH GOOGLE
                </.link>
                <.link href="/auth/microsoft" class="flex items-center gap-2.5 px-3 py-3 rounded-[var(--radius-sm)] no-underline" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: var(--paper-100);">
                  <.icon name="hero-building-office" class="w-5 h-5" /> SIGN IN WITH MICROSOFT
                </.link>
              </div>
            <% end %>
          </div>
        </aside>
      </div>

      <%!-- ============================================ --%>
      <%!-- MOBILE: Right drawer — contextual info pane --%>
      <%!-- ============================================ --%>
      <input type="checkbox" id="mobile-right-drawer" class="hidden peer/right" />
      <div class="fixed inset-0 z-50 hidden peer-checked/right:flex md:hidden flex-row-reverse">
        <label for="mobile-right-drawer" class="absolute inset-0" style="background: rgba(20, 17, 15, 0.55); backdrop-filter: blur(4px);" />
        <aside class="relative z-10 w-[300px] h-full flex flex-col overflow-y-auto" style="background: var(--surface-card); border-left: 2px solid var(--ink-900); box-shadow: -3px 0 0 var(--ink-900);">
          <div class="flex items-center justify-between px-4 py-3 border-b border-[var(--paper-300)]">
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">INFO</div>
            <label for="mobile-right-drawer" class="cursor-pointer p-1">
              <.icon name="hero-x-mark" class="w-5 h-5 text-[var(--ink-400)]" />
            </label>
          </div>
          <div class="p-4 flex flex-col gap-4">
            <%!-- Headerbar info rendered as card in info pane --%>
            <%= if @headerbar_entry do %>
              <div class="rounded-[var(--radius-md)] p-4 border-2 border-[var(--ink-900)]" style="background: var(--surface-stage); box-shadow: var(--shadow-hard-sm);">
                <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand-on-dark); margin-bottom: 4px;">
                  {if @headerbar_is_today, do: "TODAY", else: "NEXT"}
                </div>
                <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; letter-spacing: -0.01em;">
                  {@headerbar_entry.venue || @headerbar_entry.origin || "Upcoming"}
                </div>
                <div :if={@headerbar_entry.city} style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-300); margin-top: 4px;">
                  {@headerbar_entry.city}
                </div>
                <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); margin-top: 6px;">
                  {headerbar_date(@headerbar_entry)}
                </div>
              </div>
            <% end %>

            <%!-- Current tour details --%>
            <%= if @current_tour do %>
              <div class="rounded-[var(--radius-md)] p-4 border border-[var(--paper-300)]" style="background: var(--surface-card);">
                <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); margin-bottom: 6px;">TOUR</div>
                <div style="font-family: var(--font-display); font-weight: 700; font-size: 16px; color: var(--ink-900);">{@current_tour.name}</div>
                <%= if @current_tour.start_date && @current_tour.end_date do %>
                  <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); margin-top: 4px;">
                    {Calendar.strftime(@current_tour.start_date, "%d %b")} – {Calendar.strftime(@current_tour.end_date, "%d %b %Y")}
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </aside>
      </div>

      <%!-- ============================================ --%>
      <%!-- DESKTOP: Left rail (unchanged, hidden on mobile) --%>
      <%!-- ============================================ --%>
      <aside class="hidden md:flex w-[232px] flex-none flex-col border-r-2 border-[var(--ink-900)]" style="background: var(--surface-stage); color: var(--paper-100);">
        <.link navigate={@headerbar_nav_url} class="block px-[18px] pt-[18px] pb-[14px] border-b border-[var(--ink-700)] no-underline transition-colors hover:bg-[var(--ink-700)]">
          <div class="flex items-center gap-2.5">
            <span class="w-[34px] h-[34px] rounded-[var(--radius-sm)] flex items-center justify-center" style="background: var(--brand); box-shadow: var(--shadow-hard-sm); font-family: var(--font-display); font-weight: 800; font-size: 22px; color: #fff;">T</span>
            <div class="leading-none">
              <div style="font-family: var(--font-display); font-weight: 800; font-size: 16px; letter-spacing: -0.01em;">TOUR MANAGER</div>
              <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.28em; color: var(--brand-on-dark); margin-top: 3px;">DAY SHEET OS</div>
            </div>
          </div>
        </.link>

        <div class="px-[18px] py-[14px] border-b border-[var(--ink-700)]">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300); margin-bottom: 6px;">CURRENT TOUR</div>
          <%= if @current_tour do %>
            <div id="tour-switcher" class="relative" phx-click-away="close_tour_menu">
              <button id="tour-switcher-btn" type="button" phx-click="toggle_tour_menu" class="w-full text-left flex items-center justify-between gap-2 cursor-pointer group">
                <div>
                  <div style="font-family: var(--font-display); font-weight: 700; font-size: 18px; letter-spacing: -0.01em; color: #fff;">{String.upcase(@current_tour.name)}</div>
                  <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-300); margin-top: 4px;">{String.upcase(@current_tour_role || "crew")}</div>
                </div>
                <.icon name="hero-chevron-down" class="w-4 h-4 text-[var(--ink-300)] group-hover:text-white transition-colors" />
              </button>
              <div :if={assigns[:tour_menu_open]} id="tour-menu" class="absolute left-0 right-0 top-full mt-2 rounded-[var(--radius-md)] overflow-hidden z-50" style="background: var(--ink-700); border: 1px solid var(--ink-500); box-shadow: var(--shadow-hard);">
                <button :for={%{tour: tour, role: role} <- @user_tours} type="button" phx-click="select_tour" phx-value-tour-id={tour.id} class={["w-full text-left px-4 py-3 flex items-center justify-between cursor-pointer transition-colors", if(tour.id == @current_tour.id, do: "bg-[var(--brand)]", else: "hover:bg-[var(--ink-500)]")]}>
                  <div>
                    <div style="font-family: var(--font-display); font-weight: 700; font-size: 14px; color: #fff;">{tour.name}</div>
                    <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.1em; color: var(--ink-300); margin-top: 2px;">{String.upcase(role)}</div>
                  </div>
                  <.icon :if={tour.id == @current_tour.id} name="hero-check" class="w-4 h-4 text-white" />
                </button>
                <div class="border-t border-[var(--ink-500)]">
                  <button :if={@current_user} type="button" phx-click="new_tour" class="w-full text-left px-4 py-2.5 flex items-center gap-2 cursor-pointer transition-colors hover:bg-[var(--ink-500)]" style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-300);">
                    <.icon name="hero-plus-mini" class="w-3.5 h-3.5" />
                    NEW TOUR
                  </button>
                  <button :if={@current_tour_role == "manager"} type="button" phx-click="open_manage_tour" class="w-full text-left px-4 py-2.5 flex items-center gap-2 cursor-pointer transition-colors hover:bg-[var(--ink-500)]" style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-300);">
                    <.icon name="hero-cog-6-tooth-mini" class="w-3.5 h-3.5" />
                    MANAGE TOUR
                  </button>
                  <button :if={@current_tour} type="button" phx-click="open_calendar" class="w-full text-left px-4 py-2.5 flex items-center gap-2 cursor-pointer transition-colors hover:bg-[var(--ink-500)]" style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-300);">
                    <.icon name="hero-calendar-days-mini" class="w-3.5 h-3.5" />
                    SUBSCRIBE TO CALENDAR
                  </button>
                </div>
              </div>
            </div>
          <% else %>
            <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400); margin-bottom: 8px;">No tours yet</div>
            <button :if={@current_user} type="button" phx-click="new_tour" class="w-full text-left px-3 py-2.5 rounded-[var(--radius-sm)] flex items-center gap-2 cursor-pointer transition-colors hover:bg-[var(--ink-500)]" style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-300);">
              <.icon name="hero-plus-mini" class="w-3.5 h-3.5" />
              NEW TOUR
            </button>
          <% end %>
        </div>

        <nav class="px-2.5 py-3 flex flex-col gap-1 flex-1">
          <div :for={section <- nav_sections(@current_user)} class="flex flex-col gap-0.5">
            <div class="px-3 pt-3 pb-1 first:pt-0" style="font-family: var(--font-mono); font-size: 9px; font-weight: 700; letter-spacing: 0.24em; color: var(--ink-300);">
              {String.upcase(section.title)}
            </div>
            <.link :for={item <- section.items} navigate={item.path} class={["flex items-center gap-3 px-3 py-2.5 rounded-[var(--radius-sm)] no-underline transition-colors", if(item.active.(assigns), do: "text-white", else: if(item.soft, do: "text-[var(--ink-300)]", else: "text-[var(--paper-100)]"))]} style={"font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; #{if item.active.(assigns), do: "background: var(--brand); box-shadow: var(--shadow-hard-sm);", else: "background: transparent;"}"}>
              <.icon name={item.icon} class="w-4 h-4" />
              {item.label}
              <span :if={Map.get(item, :admin)} class="px-1 py-0.5 rounded-[var(--radius-stamp)] ml-auto" style="background: var(--signal-stop); color: #fff; font-size: 7px; letter-spacing: 0.1em; line-height: 1;">ADMIN</span>
            </.link>
          </div>
        </nav>

        <div class="px-[18px] py-[14px] border-t border-[var(--ink-700)]">
          <%= if @current_user do %>
            <div class="relative group/avatar">
              <button type="button" class="flex items-center gap-2.5 w-full cursor-pointer rounded-[var(--radius-sm)] -mx-1 px-1 py-1 transition-colors hover:bg-[var(--ink-700)]">
                <%= if @current_user.avatar_url do %>
                  <img src={@current_user.avatar_url} class="w-[30px] h-[30px] rounded-[var(--radius-sm)] object-cover flex-none" alt={@current_user.name} referrerpolicy="no-referrer" />
                <% else %>
                  <span class="w-[30px] h-[30px] rounded-[var(--radius-sm)] flex items-center justify-center flex-none" style="background: var(--ink-700); font-family: var(--font-mono); font-weight: 700; font-size: 12px;">{initials(@current_user.name)}</span>
                <% end %>
                <div class="flex-1 min-w-0 leading-tight text-left">
                  <div class="text-[13px] font-semibold text-white truncate">{@current_user.name}</div>
                  <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.1em; color: var(--ink-300);">{String.upcase(@current_user.role)} · {String.upcase(@current_user.plan)}</div>
                </div>
              </button>
              <div class="absolute left-0 right-0 bottom-full z-50 pb-2 opacity-0 pointer-events-none group-hover/avatar:opacity-100 group-hover/avatar:pointer-events-auto" style="transition: opacity 150ms ease;">
                <div class="rounded-[var(--radius-md)] overflow-hidden" style="background: var(--ink-700); border: 1px solid var(--ink-500); box-shadow: var(--shadow-hard);">
                  <.link navigate="/profile" class="w-full text-left px-4 py-2.5 flex items-center gap-2.5 cursor-pointer transition-colors hover:bg-[var(--ink-500)] no-underline" style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--paper-100);">
                    <.icon name="hero-user-mini" class="w-3.5 h-3.5" /> EDIT PROFILE
                  </.link>
                  <button type="button" phx-click="open_settings" class="w-full text-left px-4 py-2.5 flex items-center gap-2.5 cursor-pointer transition-colors hover:bg-[var(--ink-500)] border-t border-[var(--ink-500)]" style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--paper-100);">
                    <.icon name="hero-cog-6-tooth-mini" class="w-3.5 h-3.5" /> SETTINGS
                  </button>
                </div>
              </div>
            </div>
          <% else %>
            <div class="flex flex-col gap-2">
              <.link href="/auth/google" class="flex items-center gap-2.5 px-3 py-2 rounded-[var(--radius-sm)] no-underline transition-colors hover:bg-[var(--ink-700)]" style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--paper-100);">
                <.icon name="hero-globe-alt" class="w-4 h-4" /> SIGN IN WITH GOOGLE
              </.link>
              <.link href="/auth/microsoft" class="flex items-center gap-2.5 px-3 py-2 rounded-[var(--radius-sm)] no-underline transition-colors hover:bg-[var(--ink-700)]" style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--paper-100);">
                <.icon name="hero-building-office" class="w-4 h-4" /> SIGN IN WITH MICROSOFT
              </.link>
            </div>
          <% end %>
        </div>
      </aside>

      <%!-- ============================================ --%>
      <%!-- Main content column --%>
      <%!-- ============================================ --%>
      <div class="flex-1 flex flex-col min-w-0">
        <%!-- Desktop stage topbar (hidden on mobile) --%>
        <header class="hidden md:flex tm-halftone tm-halftone--light items-center px-7 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage); color: var(--paper-100);">
          <.link navigate={@headerbar_nav_url} class="relative z-[2] no-underline flex items-center gap-5 flex-1 min-w-0">
            <%= if @headerbar_entry && @headerbar_entry.date do %>
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2">
                  <div style="font-family: var(--font-mono); font-size: 10px; letter-spacing: 0.24em; color: var(--brand-on-dark);">
                    {headerbar_date(@headerbar_entry)} · {headerbar_code(@headerbar_entry)}
                  </div>
                </div>
                <div class="flex items-center gap-3 mt-1">
                  <div class="truncate" style="font-family: var(--font-display); font-weight: 800; font-size: 30px; letter-spacing: -0.02em; line-height: 1.02; color: #fff;">
                    {@headerbar_entry.venue || @headerbar_entry.origin || "Upcoming"}
                  </div>
                  <span :if={@headerbar_entry.city} style="font-family: var(--font-mono); font-size: 13px; color: var(--ink-300); white-space: nowrap;">
                    {@headerbar_entry.city}
                  </span>
                </div>
              </div>
              <.signal_chip tone={@days_away_tone} hard size="lg">{@days_away_label}</.signal_chip>
            <% else %>
              <div class="flex-1 min-w-0">
                <div style="font-family: var(--font-mono); font-size: 10px; letter-spacing: 0.24em; color: var(--brand-on-dark);">{@today_str}</div>
                <div style="font-family: var(--font-display); font-weight: 800; font-size: 30px; letter-spacing: -0.02em; line-height: 1.02; color: #fff; margin-top: 4px;">
                  {if @current_tour, do: @current_tour.name, else: "Tour Manager"}
                </div>
              </div>
            <% end %>
          </.link>
        </header>

        <main class="flex-1 overflow-y-auto overflow-x-hidden">
          <.trial_banner :if={@current_user} current_user={@current_user} />
          <.trial_expired_banner :if={@current_user} current_user={@current_user} />
          <.flash_group flash={@flash} />
          {render_slot(@inner_block)}
        </main>
      </div>

      <.settings_modal :if={@current_user} current_user={@current_user} show={@settings_open} billing_seats={@billing_seats} billing_error={@billing_error} />
      <.new_tour_modal :if={@new_tour_form} form={@new_tour_form} show={@new_tour_open} />
      <.manage_tour_modal :if={@manage_tour_form} form={@manage_tour_form} show={@manage_tour_open} />
      <.calendar_modal :if={@current_tour} show={@calendar_modal_open} calendar_token={@calendar_token} calendar_mode={@calendar_mode} current_tour={@current_tour} />
    </div>
    """
  end

  defp headerbar_date(entry) do
    if entry.date do
      Calendar.strftime(entry.date, "%a %d %b %Y") |> String.upcase()
    else
      "TBD"
    end
  end

  defp headerbar_code(entry) do
    entry.venue_code || String.slice(entry.city || "—", 0, 3) |> String.upcase()
  end

  defp headerbar_countdown(entry) do
    if entry.date do
      days = Date.diff(entry.date, Date.utc_today())

      cond do
        days == 1 -> "TOMORROW"
        days > 1 -> "IN #{days}D"
        true -> "TODAY"
      end
    else
      "TBD"
    end
  end

  # Nav is grouped to mirror the tour workflow, with RUN (day-of-show, the most
  # frequently used section) surfaced first, then ADVANCE and REVIEW. Admin tools
  # get their own trailing section.
  defp nav_sections(user) do
    advance = [
      %{id: "routing", label: "Tour schedule", icon: "hero-map", path: "/routing", soft: false,
        active: fn assigns -> Map.get(assigns, :active_nav) == "routing" end},
      %{id: "crew", label: "Crew", icon: "hero-users", path: "/crew", soft: false,
        active: fn assigns -> Map.get(assigns, :active_nav) == "crew" end},
      %{id: "setlists", label: "Setlists", icon: "hero-musical-note", path: "/setlists", soft: false,
        active: fn assigns -> Map.get(assigns, :active_nav) == "setlists" end},
      %{id: "guestlist", label: "Guest list", icon: "hero-ticket", path: "/guests", soft: false,
        active: fn assigns -> Map.get(assigns, :active_nav) == "guestlist" end},
      %{id: "production", label: "Production", icon: "hero-building-library", path: "/production/venues", soft: false,
        active: fn assigns -> Map.get(assigns, :active_nav) == "production" end},
      %{id: "accommodation", label: "Accommodation", icon: "hero-building-office-2", path: "/accommodation", soft: false,
        active: fn assigns -> Map.get(assigns, :active_nav) == "accommodation" end},
    ]

    review = [
      %{id: "dashboard", label: "Overview", icon: "hero-squares-2x2", path: "/dashboard", soft: false,
        active: fn assigns -> Map.get(assigns, :active_nav) == "dashboard" end},
    ]

    run = [
      %{id: "daysheet", label: "Day sheet", icon: "hero-clipboard-document-list", path: "/app", soft: false,
        active: fn assigns -> Map.get(assigns, :active_nav) == "daysheet" end},
    ]

    sections = [
      %{title: "Run", items: run},
      %{title: "Advance", items: advance},
      %{title: "Review", items: review}
    ]

    if user && TourmanagerV2.Accounts.User.admin?(user) do
      admin = [
        %{id: "admin_tours", label: "Tours", icon: "hero-map", path: "/admin/tours", soft: false, admin: true,
          active: fn assigns -> Map.get(assigns, :active_nav) == "admin_tours" end},
        %{id: "admin_users", label: "Users", icon: "hero-user-group", path: "/admin/users", soft: false, admin: true,
          active: fn assigns -> Map.get(assigns, :active_nav) == "admin_users" end},
        %{id: "admin_jobs", label: "Jobs", icon: "hero-bolt", path: "/admin/jobs", soft: false, admin: true,
          active: fn assigns -> Map.get(assigns, :active_nav) == "admin_jobs" end},
      ]

      sections ++ [%{title: "Admin", items: admin}]
    else
      sections
    end
  end

  @doc """
  Shows the flash group with standard titles and content.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end
end
