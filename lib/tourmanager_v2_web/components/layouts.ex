defmodule TourmanagerV2Web.Layouts do
  @moduledoc """
  Tour Manager layouts — app shell with left rail and stage topbar.
  """
  use TourmanagerV2Web, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true

  attr :current_scope, :map,
    default: nil,
    doc: "the current scope"

  attr :active_nav, :string, default: "daysheet", doc: "active navigation item"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div id="app-shell" class="flex h-screen" style="background: var(--paper-100); color: var(--ink-700); font-family: var(--font-sans);">
      <%!-- Left rail --%>
      <aside class="w-[232px] flex-none flex flex-col border-r-2 border-[var(--ink-900)]" style="background: var(--surface-stage); color: var(--paper-100);">
        <%!-- Logo --%>
        <div class="px-[18px] pt-[18px] pb-[14px] border-b border-[var(--ink-700)]">
          <div class="flex items-center gap-2.5">
            <span
              class="w-[34px] h-[34px] rounded-[var(--radius-sm)] flex items-center justify-center"
              style="background: var(--brand); box-shadow: var(--shadow-hard-sm); font-family: var(--font-display); font-weight: 800; font-size: 22px; color: #fff;"
            >T</span>
            <div class="leading-none">
              <div style="font-family: var(--font-display); font-weight: 800; font-size: 16px; letter-spacing: -0.01em;">TOUR MANAGER</div>
              <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.28em; color: var(--brand); margin-top: 3px;">DAY SHEET OS</div>
            </div>
          </div>
        </div>

        <%!-- Tour switcher --%>
        <div class="px-[18px] py-[14px] border-b border-[var(--ink-700)]">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300); margin-bottom: 6px;">CURRENT TOUR</div>
          <div style="font-family: var(--font-display); font-weight: 700; font-size: 18px; letter-spacing: -0.01em; color: #fff;">NOVA RIOT</div>
          <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-300); margin-top: 4px;">DAY 014 / 060</div>
        </div>

        <%!-- Navigation --%>
        <nav class="px-2.5 py-3 flex flex-col gap-0.5 flex-1">
          <.link
            :for={item <- nav_items()}
            navigate={item.path}
            class={[
              "flex items-center gap-3 px-3 py-2.5 rounded-[var(--radius-sm)] no-underline transition-colors",
              if(item.active.(assigns),
                do: "text-white",
                else: if(item.soft, do: "text-[var(--ink-300)]", else: "text-[var(--paper-100)]")
              )
            ]}
            style={"font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; #{if item.active.(assigns), do: "background: var(--brand); box-shadow: var(--shadow-hard-sm);", else: "background: transparent;"}"}
          >
            <.icon name={item.icon} class="w-4 h-4" />
            {item.label}
          </.link>
        </nav>

        <%!-- User --%>
        <div class="px-[18px] py-[14px] border-t border-[var(--ink-700)] flex items-center gap-2.5">
          <span
            class="w-[30px] h-[30px] rounded-[var(--radius-sm)] flex items-center justify-center"
            style="background: var(--ink-700); font-family: var(--font-mono); font-weight: 700; font-size: 12px;"
          >MQ</span>
          <div class="leading-tight">
            <div class="text-[13px] font-semibold text-white">Mara Quinn</div>
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.1em; color: var(--ink-300);">TOUR MANAGER · AAA</div>
          </div>
        </div>
      </aside>

      <%!-- Main column --%>
      <div class="flex-1 flex flex-col min-w-0">
        <%!-- Stage topbar --%>
        <header class="tm-halftone tm-halftone--light flex items-center justify-between px-7 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage); color: var(--paper-100);">
          <div class="relative z-[2]">
            <div style="font-family: var(--font-mono); font-size: 10px; letter-spacing: 0.24em; color: var(--brand);">SAT 25 JUN 2026 · LON-BRX</div>
            <div style="font-family: var(--font-display); font-weight: 800; font-size: 30px; letter-spacing: -0.02em; line-height: 1.02; color: #fff; margin-top: 4px;">Brixton Academy</div>
          </div>
          <div class="relative z-[2] flex items-center gap-5" style="font-family: var(--font-mono);">
            <div :for={{k, v} <- [{"CITY", "London"}, {"CAP", "4,921"}, {"WX", "18° · clear"}, {"CALL", "12:00"}]} class="text-right">
              <div style="font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300);">{k}</div>
              <div style="font-size: 15px; font-weight: 700; color: #fff; margin-top: 2px;">{v}</div>
            </div>
            <.signal_chip tone="live" hard size="lg">T − 5:14</.signal_chip>
          </div>
        </header>

        <main class="flex-1 overflow-auto">
          <.flash_group flash={@flash} />
          {render_slot(@inner_block)}
        </main>
      </div>
    </div>
    """
  end

  defp nav_items do
    [
      %{id: "daysheet", label: "Day sheet", icon: "hero-clipboard-document-list", path: "/", soft: false,
        active: fn assigns -> Map.get(assigns, :active_nav) == "daysheet" end},
      %{id: "routing", label: "Routing", icon: "hero-map", path: "/routing", soft: false,
        active: fn assigns -> Map.get(assigns, :active_nav) == "routing" end},
      %{id: "dashboard", label: "Dashboard", icon: "hero-squares-2x2", path: "/dashboard", soft: false,
        active: fn assigns -> Map.get(assigns, :active_nav) == "dashboard" end},
      %{id: "crew", label: "Crew", icon: "hero-users", path: "#", soft: true,
        active: fn _assigns -> false end},
      %{id: "advance", label: "Advancing", icon: "hero-inbox", path: "#", soft: true,
        active: fn _assigns -> false end},
      %{id: "guestlist", label: "Guest list", icon: "hero-ticket", path: "#", soft: true,
        active: fn _assigns -> false end},
    ]
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
