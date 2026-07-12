defmodule TourmanagerV2Web.TourComponents do
  @moduledoc """
  Shared UI components for the Tour Manager design system.
  """
  use Phoenix.Component

  import TourmanagerV2Web.CoreComponents, only: [icon: 1, input: 1]
  import TourmanagerV2Web.TextHelpers

  attr :size, :integer, default: 28
  attr :class, :string, default: nil
  attr :style, :string, default: nil
  slot :inner_block, required: true

  def display(assigns) do
    ~H"""
    <div
      class={[@class]}
      style={"font-family: var(--font-display); font-weight: 800; font-size: #{@size}px; letter-spacing: -0.02em; line-height: 1.02; color: var(--ink-900);#{if @style, do: " #{@style}", else: ""}"}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :style, :string, default: nil
  slot :inner_block, required: true

  def overline(assigns) do
    ~H"""
    <div
      class={[@class]}
      style={"font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.2em; text-transform: uppercase; color: var(--ink-400);#{if @style, do: " #{@style}", else: ""}"}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Section eyebrow for every Advance-section page: a small tappable "back to
  parent" segment followed by the current context, sitting above a page's
  large `.display` title — mirrors an iOS nav bar's back button + large-title
  pattern rather than a full desktop-style breadcrumb trail (only ever one
  level back).

  Pass `navigate` for a routed parent (a real back destination), or
  `on_click` for a same-page state toggle (e.g. closing an inline detail
  view). Omit both (and `back_label`) for a top-level page with no parent to
  go back to — it renders just `current_label` in the same brand-colored
  eyebrow style, so every Advance page shares one consistent header treatment.
  """
  attr :back_label, :string, default: nil
  attr :navigate, :string, default: nil
  attr :on_click, :string, default: nil
  attr :current_label, :string, required: true

  def drilldown_breadcrumb(assigns) do
    ~H"""
    <div class="flex items-center gap-2 mb-1">
      <%= if @back_label do %>
        <.link
          :if={@navigate}
          navigate={@navigate}
          class="inline-flex items-center py-1.5 -my-1.5 -ml-1 pl-1"
          style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand); text-decoration: none;"
        >{@back_label}</.link>
        <button
          :if={@on_click}
          type="button"
          phx-click={@on_click}
          class="inline-flex items-center py-1.5 -my-1.5 -ml-1 pl-1 cursor-pointer bg-transparent border-0"
          style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);"
        >{@back_label}</button>
        <.icon name="hero-chevron-right-mini" class="w-3 h-3 text-[var(--ink-300)] flex-none" />
        <span style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">{@current_label}</span>
      <% else %>
        <span style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);">{@current_label}</span>
      <% end %>
    </div>
    """
  end

  attr :init, :string, required: true
  attr :tone, :string, default: "ink"
  attr :size, :integer, default: 36

  def pass(assigns) do
    ~H"""
    <span
      class="inline-flex items-center justify-center flex-none"
      style={"width: #{@size}px; height: #{@size}px; border-radius: var(--radius-sm); background: #{if @tone == "brand", do: "var(--brand)", else: "var(--ink-900)"}; color: var(--paper-100); font-family: var(--font-mono); font-weight: 700; font-size: #{trunc(@size * 0.34)}px; letter-spacing: 0.02em; box-shadow: var(--shadow-hard-sm);"}
    >
      {@init}
    </span>
    """
  end

  attr :tone, :string, required: true
  attr :hard, :boolean, default: false
  attr :dot, :boolean, default: false
  attr :size, :string, default: "md"
  attr :variant, :string, default: "solid"
  slot :inner_block, required: true

  def signal_chip(assigns) do
    tone_color = signal_color(assigns.tone)
    tint_color = signal_tint_color(assigns.tone)

    assigns =
      assigns
      |> assign(:tone_color, tone_color)
      |> assign(:tint_color, tint_color)

    ~H"""
    <span
      class="inline-flex items-center gap-1.5 uppercase"
      style={"font-family: var(--font-mono); font-weight: 700; letter-spacing: 0.06em; font-size: #{if @size == "sm", do: "10px", else: "11px"}; padding: #{if @size == "sm", do: "3px 7px", else: "4px 10px"}; border-radius: var(--radius-stamp); background: #{if @variant == "tint", do: @tint_color, else: @tone_color}; color: #{if @variant == "tint", do: @tone_color, else: "#fff"}; #{if @hard, do: "box-shadow: var(--shadow-hard-sm);", else: ""}"}
    >
      <span :if={@dot} style={"width: 6px; height: 6px; border-radius: 50%; background: #{if @variant == "tint", do: @tone_color, else: "#fff"};"}></span>
      {render_slot(@inner_block)}
    </span>
    """
  end

  defp signal_color("load"), do: "var(--signal-load)"
  defp signal_color("sound"), do: "var(--signal-sound)"
  defp signal_color("doors"), do: "var(--signal-doors)"
  defp signal_color("live"), do: "var(--signal-live)"
  defp signal_color("stop"), do: "var(--signal-stop)"
  defp signal_color("brand"), do: "var(--brand)"
  defp signal_color("ink"), do: "var(--ink-500)"
  defp signal_color(_), do: "var(--ink-500)"

  defp signal_tint_color("load"), do: "var(--signal-load-tint)"
  defp signal_tint_color("sound"), do: "var(--signal-sound-tint)"
  defp signal_tint_color("doors"), do: "var(--signal-doors-tint)"
  defp signal_tint_color("live"), do: "var(--signal-live-tint)"
  defp signal_tint_color("stop"), do: "var(--signal-stop-tint)"
  defp signal_tint_color(_), do: "var(--paper-200)"

  attr :overline_text, :string, default: nil
  attr :hard, :boolean, default: false
  attr :halftone, :boolean, default: false
  attr :padding, :string, default: "20px"
  slot :inner_block, required: true

  def stamp_card(assigns) do
    ~H"""
    <div
      class={[@halftone && "tm-halftone"]}
      style={"position: relative; padding: #{@padding}; border-radius: var(--radius-md); background: var(--surface-card); border: #{if @hard, do: "2px solid var(--ink-900)", else: "1px solid var(--paper-300)"}; #{if @hard, do: "box-shadow: var(--shadow-hard);", else: "box-shadow: var(--shadow-sm);"}"}
    >
      <div :if={@overline_text} style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.2em; text-transform: uppercase; color: var(--ink-400); margin-bottom: 14px;">
        {@overline_text}
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :tabs, :list, required: true
  attr :active, :string, required: true
  attr :class, :string, default: nil

  def tab_bar(assigns) do
    ~H"""
    <div
      class={[
        "flex gap-1 overflow-x-auto border-b-2 border-[var(--paper-300)] pb-0",
        "[-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden",
        @class
      ]}
      role="tablist"
    >
      <button
        :for={tab <- @tabs}
        type="button"
        role="tab"
        phx-click="switch_tab"
        phx-value-tab={tab.value}
        title={tab.label}
        aria-label={tab.label}
        class={[
          "px-4 py-2.5 -mb-[2px] border-b-2 cursor-pointer transition-colors shrink-0 flex items-center gap-1.5",
          if(tab.value == @active,
            do: "border-[var(--brand)] text-[var(--ink-900)]",
            else: "border-transparent text-[var(--ink-400)] hover:text-[var(--ink-700)]"
          )
        ]}
      >
        <.icon name={tab.icon} class="w-5 h-5" />
        <span
          :if={Map.has_key?(tab, :count)}
          class={[
            "px-1.5 py-0.5 rounded text-[10px]",
            if(tab.value == @active,
              do: "bg-[var(--brand)] text-white",
              else: "bg-[var(--paper-200)] text-[var(--ink-400)]"
            )
          ]}
          style="font-family: var(--font-mono); font-weight: 700;"
        >
          {tab.count}
        </span>
      </button>
    </div>
    """
  end

  attr :variant, :string, default: "primary"
  attr :size, :string, default: "md"
  attr :block, :boolean, default: false
  attr :icon_name, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(phx-click phx-target phx-value-id disabled id)
  slot :inner_block, required: true

  def tm_button(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        "inline-flex items-center justify-center gap-2 cursor-pointer font-bold uppercase tracking-wider transition-all",
        if(@block, do: "w-full", else: ""),
        if(@size == "sm", do: "px-3 py-1.5 text-[11px]", else: "px-5 py-2.5 text-[12px]"),
        @class
      ]}
      style={"font-family: var(--font-mono); letter-spacing: 0.06em; border-radius: var(--radius-md); #{button_style(@variant)}"}
      {@rest}
    >
      <.icon :if={@icon_name} name={@icon_name} class="w-4 h-4" />
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp button_style("primary"),
    do:
      "background: var(--brand); color: #fff; border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);"

  defp button_style("secondary"),
    do:
      "background: var(--surface-card); color: var(--ink-900); border: 1px solid var(--paper-300);"

  defp button_style("stage"),
    do:
      "background: var(--ink-700); color: var(--paper-100); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);"

  defp button_style("ghost"),
    do: "background: transparent; color: var(--ink-500); border: 1px solid var(--paper-300);"

  attr :id, :string, required: true
  slot :inner_block, required: true

  def overflow_menu(assigns) do
    ~H"""
    <div class="relative">
      <input type="checkbox" id={@id} class="hidden peer/menu" />
      <label for={@id} class="p-1.5 rounded-[var(--radius-sm)] cursor-pointer transition-colors hover:bg-[var(--paper-200)] block">
        <.icon name="hero-ellipsis-vertical-mini" class="w-4 h-4 text-[var(--ink-300)]" />
      </label>
      <div class="absolute right-0 top-full mt-1 hidden peer-checked/menu:block z-50 rounded-[var(--radius-md)] overflow-hidden" style="background: var(--surface-card); border: 1px solid var(--paper-300); box-shadow: var(--shadow-hard); min-width: 130px;">
        {render_slot(@inner_block)}
      </div>
      <label :if={true} for={@id} class="fixed inset-0 z-40 hidden peer-checked/menu:block" />
    </div>
    """
  end

  attr :time, :string, required: true
  attr :label, :string, required: true
  attr :tone, :string, required: true
  attr :loc, :string, required: true
  attr :done, :boolean, default: false
  attr :flag, :boolean, default: false
  attr :event_id, :string, default: nil
  attr :is_manager, :boolean, default: false
  attr :notes, :string, default: nil

  def schedule_row(assigns) do
    ~H"""
    <div
      class={["group/row grid grid-cols-[64px_14px_1fr_auto] gap-3.5 items-center px-3 py-2.5 rounded-[var(--radius-sm)] relative", if(@flag, do: "bg-[var(--surface-card)] border border-[var(--paper-300)]", else: "border border-transparent hover:bg-[var(--paper-200)] transition-colors")]}
      style={if @done, do: "opacity: 0.5;", else: ""}
    >
      <div style="font-family: var(--font-mono); font-weight: 700; font-size: 16px; color: var(--ink-900); letter-spacing: -0.01em;">
        {@time}
      </div>
      <div
        class="w-2.5 h-2.5 rounded-full justify-self-center"
        style={"background: var(--signal-#{if @tone == "ink", do: "load", else: @tone}); opacity: #{if @tone == "ink", do: "0.25", else: "1"};"}
      />
      <div class="flex-1 min-w-0">
        <div class={["text-[15px] font-semibold text-[var(--ink-900)]", if(@done, do: "line-through", else: "")]}>
          {@label}
        </div>
        <%= if @notes && @notes != "" do %>
          <div class="mt-0.5" style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); font-style: italic;">
            {@notes}
          </div>
        <% else %>
          <div class="flex items-center gap-1.5 mt-0.5" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">
            <.icon name="hero-map-pin-mini" class="w-3 h-3" /> {@loc}
          </div>
        <% end %>
      </div>
      <div class="flex items-center gap-2">
        <.signal_chip :if={@flag} tone={@tone} hard>
          {cond do
            @tone == "live" -> "Key"
            @tone == "stop" -> "Hard"
            true -> "Flag"
          end}
        </.signal_chip>
        <%= if @is_manager && @event_id do %>
          <.overflow_menu id={"event-menu-#{@event_id}"}>
            <button type="button" phx-click="edit_event" phx-value-id={@event_id} class="w-full text-left px-3 py-2 flex items-center gap-2 cursor-pointer transition-colors hover:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-500);">
              <.icon name="hero-pencil-mini" class="w-3.5 h-3.5" /> EDIT
            </button>
            <button type="button" phx-click="delete_event" phx-value-id={@event_id} data-confirm="Delete this event?" class="w-full text-left px-3 py-2 flex items-center gap-2 cursor-pointer transition-colors hover:bg-[var(--signal-stop-tint)] border-t border-[var(--paper-300)]" style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--signal-stop);">
              <.icon name="hero-trash-mini" class="w-3.5 h-3.5" /> DELETE
            </button>
          </.overflow_menu>
        <% end %>
      </div>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :role, :string, required: true
  attr :init, :string, required: true
  attr :pass_level, :string, required: true
  attr :status, :string, required: true

  def crew_card(assigns) do
    ~H"""
    <div class="flex items-center gap-3 p-3 border border-[var(--paper-300)] rounded-[var(--radius-md)] bg-[var(--surface-card)]">
      <.pass init={@init} tone={if @pass_level == "AAA", do: "brand", else: "ink"} />
      <div class="flex-1 min-w-0">
        <div class="text-sm font-semibold text-[var(--ink-900)]">{@name}</div>
        <div style="font-family: var(--font-mono); font-size: 10px; letter-spacing: 0.06em; color: var(--ink-400); text-transform: uppercase;">
          {@role} · {@pass_level}
        </div>
      </div>
      <.signal_chip
        tone={cond do
          @status == "on-site" -> "live"
          @status == "travel" -> "load"
          true -> "sound"
        end}
        variant="tint"
        size="sm"
        dot
      >
        {@status}
      </.signal_chip>
    </div>
    """
  end

  attr :text, :string, required: true
  attr :tone, :string, required: true
  attr :meta, :string, required: true

  def alert_card(assigns) do
    ~H"""
    <div
      class="flex gap-3 p-3 bg-[var(--surface-card)] border border-[var(--paper-300)] rounded-[var(--radius-sm)]"
      style={"border-left: 3px solid var(--signal-#{@tone});"}
    >
      <div class="flex-1">
        <div class="text-[13.5px] leading-[1.45] text-[var(--ink-700)]">{@text}</div>
        <div class="mt-1.5" style="font-family: var(--font-mono); font-size: 10px; letter-spacing: 0.1em; color: var(--ink-400);">
          {@meta}
        </div>
      </div>
    </div>
    """
  end

  defp route_tone("today"), do: "live"
  defp route_tone("next"), do: "doors"
  defp route_tone("upcoming"), do: "load"
  defp route_tone("hold"), do: "load"
  defp route_tone(_), do: "load"

  defp venue_maps_link(venue, city, address, lat, lng) do
    cond do
      is_binary(address) && address != "" -> "https://www.google.com/maps/search/#{URI.encode(address)}"
      is_binary(venue) && is_binary(city) -> "https://www.google.com/maps/search/#{URI.encode("#{venue}, #{city}")}"
      is_number(lat) && is_number(lng) -> "https://www.google.com/maps/search/#{lat},#{lng}"
      true -> "#"
    end
  end

  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :sub, :string, required: true
  attr :featured, :boolean, default: false

  def metric_card(assigns) do
    ~H"""
    <div
      class={["relative p-[18px] rounded-[var(--radius-md)]", if(@featured, do: "tm-halftone tm-halftone--light border-2 border-[var(--ink-900)]", else: "border border-[var(--paper-300)]")]}
      style={"background: #{if @featured, do: "var(--surface-stage)", else: "var(--surface-card)"}; color: #{if @featured, do: "var(--paper-100)", else: "var(--ink-700)"}; #{if @featured, do: "box-shadow: var(--shadow-hard);", else: "box-shadow: var(--shadow-sm);"}"}
    >
      <div class="relative z-[2]">
        <div style={"font-family: var(--font-mono); font-size: 10px; letter-spacing: 0.16em; text-transform: uppercase; color: #{if @featured, do: "var(--brand)", else: "var(--ink-400)"}"}>
          {@label}
        </div>
        <div style={"font-family: var(--font-display); font-weight: 800; font-size: 40px; letter-spacing: -0.02em; line-height: 1; margin-top: 8px; color: #{if @featured, do: "#fff", else: "var(--ink-900)"}"}>
          {@value}
        </div>
        <div class="mt-1.5" style={"font-family: var(--font-mono); font-size: 11px; color: #{if @featured, do: "var(--ink-300)", else: "var(--ink-400)"}"}>
          {@sub}
        </div>
      </div>
    </div>
    """
  end

  attr :city, :string, required: true
  attr :code, :string, required: true
  attr :pct, :integer, required: true
  attr :tone, :string, required: true
  attr :open, :integer, required: true

  def advance_row(assigns) do
    ~H"""
    <div>
      <div class="flex items-center justify-between mb-2">
        <div class="flex items-center gap-2.5">
          <.pass init={@code} tone="ink" size={32} />
          <div>
            <div class="text-[15px] font-semibold text-[var(--ink-900)]">{@city}</div>
            <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400);">
              {@open} OPEN ITEM{if @open > 1, do: "S", else: ""}
            </div>
          </div>
        </div>
        <div class="flex items-center gap-2.5">
          <span style="font-family: var(--font-mono); font-weight: 700; font-size: 14px; color: var(--ink-900);">
            {@pct}%
          </span>
          <.signal_chip tone={@tone} size="sm" dot>
            {cond do
              @pct >= 85 -> "ready"
              @pct >= 50 -> "pending"
              true -> "at risk"
            end}
          </.signal_chip>
        </div>
      </div>
      <div class="h-2.5 bg-[var(--paper-200)] rounded-[var(--radius-stamp)] overflow-hidden border border-[var(--paper-300)]">
        <div class="h-full" style={"width: #{@pct}%; background: var(--signal-#{@tone});"} />
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_close, :string, default: "close_modal"
  slot :inner_block, required: true

  def tm_modal(assigns) do
    ~H"""
    <div
      :if={@show}
      id={@id}
      class="fixed inset-0 z-50 flex items-center justify-center"
      phx-window-keydown={@on_close}
      phx-key="Escape"
    >
      <div
        class="absolute inset-0"
        style="background: rgba(20, 17, 15, 0.55); backdrop-filter: blur(4px);"
        phx-click={@on_close}
      />
      <div
        class="relative z-10 w-full max-w-[480px] mx-4 rounded-[var(--radius-xl)] overflow-x-hidden overflow-y-auto"
        style="background: var(--surface-card); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard); max-height: calc(100vh - 2rem); max-height: calc(100dvh - 2rem);"
        role="dialog"
        aria-modal="true"
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :current_user, :map, required: true
  attr :show, :boolean, default: false
  attr :billing_seats, :integer, default: 10
  attr :billing_error, :string, default: nil

  def settings_modal(assigns) do
    billing = TourmanagerV2.Billing.price_breakdown(assigns.billing_seats)
    assigns = assign(assigns, :billing, billing)

    ~H"""
    <.tm_modal id="settings-modal" show={@show} on_close="close_settings">
      <%!-- Header --%>
      <div class="flex items-center justify-between px-6 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
        <div>
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand-on-dark);">SETTINGS</div>
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; margin-top: 2px;">Your account</div>
        </div>
        <button
          type="button"
          phx-click="close_settings"
          class="w-8 h-8 flex items-center justify-center rounded-[var(--radius-sm)] cursor-pointer transition-colors hover:bg-[var(--ink-700)]"
          aria-label="Close settings"
        >
          <.icon name="hero-x-mark" class="w-5 h-5 text-[var(--ink-300)]" />
        </button>
      </div>

      <%!-- User info --%>
      <div class="px-6 py-5 border-b border-[var(--paper-300)]">
        <div class="flex items-center gap-3">
          <%= if @current_user.avatar_url do %>
            <img
              src={@current_user.avatar_url}
              class="w-10 h-10 rounded-[var(--radius-md)] object-cover"
              alt={@current_user.name}
              referrerpolicy="no-referrer"
            />
          <% else %>
            <span
              class="w-10 h-10 rounded-[var(--radius-md)] flex items-center justify-center"
              style="background: var(--ink-900); color: var(--paper-100); font-family: var(--font-mono); font-weight: 700; font-size: 14px;"
            >{initials(@current_user.name)}</span>
          <% end %>
          <div>
            <div class="text-[15px] font-semibold text-[var(--ink-900)]">{@current_user.name}</div>
            <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">{@current_user.email}</div>
          </div>
        </div>
      </div>

      <%!-- Crew seats + billing --%>
      <div class="px-6 py-5 border-b border-[var(--paper-300)]">
        <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); margin-bottom: 12px;">CREW SEATS</div>

        <div class="flex items-center justify-between mb-4">
          <div>
            <div style="font-family: var(--font-display); font-weight: 700; font-size: 15px; color: var(--ink-900);">1 manager + {@billing_seats} crew</div>
            <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400); margin-top: 2px;">Base plan includes 10 seats</div>
          </div>
          <div class="flex items-center gap-0">
            <button
              type="button"
              phx-click="decrement_seats"
              disabled={@billing_seats <= 10}
              class={[
                "w-9 h-9 flex items-center justify-center rounded-l-[var(--radius-md)] cursor-pointer transition-colors border border-r-0",
                if(@billing_seats <= 10, do: "opacity-30 cursor-not-allowed", else: "hover:bg-[var(--paper-200)]")
              ]}
              style="border-color: var(--paper-300); background: var(--surface-card);"
            >
              <.icon name="hero-minus-mini" class="w-4 h-4 text-[var(--ink-500)]" />
            </button>
            <div
              class="w-14 h-9 flex items-center justify-center border-y"
              style="border-color: var(--paper-300); background: var(--surface-card); font-family: var(--font-mono); font-weight: 700; font-size: 16px; color: var(--ink-900);"
            >
              {@billing_seats}
            </div>
            <button
              type="button"
              phx-click="increment_seats"
              class="w-9 h-9 flex items-center justify-center rounded-r-[var(--radius-md)] cursor-pointer transition-colors border border-l-0 hover:bg-[var(--paper-200)]"
              style="border-color: var(--paper-300); background: var(--surface-card);"
            >
              <.icon name="hero-plus-mini" class="w-4 h-4 text-[var(--ink-500)]" />
            </button>
          </div>
        </div>

        <%!-- Pricing breakdown --%>
        <div class="rounded-[var(--radius-md)] p-4 border border-[var(--paper-300)]" style="background: var(--paper-200);">
          <div class="flex items-center justify-between mb-1.5">
            <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-500);">Base plan (1 mgr + 10 crew)</div>
            <div style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; color: var(--ink-700);">{@billing.base}</div>
          </div>
          <%= if @billing.extra_seats > 0 do %>
            <div class="flex items-center justify-between mb-1.5">
              <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-500);">{@billing.extra_seats} extra seat{if @billing.extra_seats != 1, do: "s", else: ""} × {@billing.extra_per_seat}</div>
              <div style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; color: var(--ink-700);">{@billing.extra_cost}</div>
            </div>
          <% end %>
          <div class="flex items-center justify-between pt-2 mt-2 border-t border-[var(--paper-300)]">
            <div style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; color: var(--ink-900);">MONTHLY TOTAL</div>
            <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: var(--ink-900);">{@billing.total}</div>
          </div>
        </div>

        <%!-- Error --%>
        <div
          :if={@billing_error}
          class="mt-3 px-3 py-2 rounded-[var(--radius-sm)]"
          style="background: var(--signal-stop-tint); border: 1px solid var(--signal-stop); font-family: var(--font-mono); font-size: 11px; color: var(--signal-stop);"
        >
          {@billing_error}
        </div>

        <%!-- Subscribe button --%>
        <button
          type="button"
          phx-click="subscribe"
          class="w-full mt-4 px-5 py-3 rounded-[var(--radius-md)] cursor-pointer transition-all flex items-center justify-center gap-2"
          style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);"
        >
          <.icon name="hero-credit-card-mini" class="w-4 h-4" />
          <%= if @current_user.plan == "paid" do %>
            UPDATE PLAN
          <% else %>
            SUBSCRIBE · {@billing.total}/MO
          <% end %>
        </button>

        <%!-- Admin test plan controls --%>
        <%= if TourmanagerV2.Accounts.User.admin?(@current_user) do %>
          <div class="mt-3 p-3 rounded-[var(--radius-md)] border border-dashed border-[var(--signal-stop)]" style="background: var(--signal-stop-tint);">
            <div class="flex items-center gap-2 mb-2">
              <span class="px-1.5 py-0.5 rounded-[var(--radius-stamp)]" style="background: var(--signal-stop); color: #fff; font-family: var(--font-mono); font-weight: 700; font-size: 7px; letter-spacing: 0.1em;">ADMIN</span>
              <div style="font-family: var(--font-mono); font-size: 9px; color: var(--ink-500); letter-spacing: 0.06em;">TEST PLAN CONTROLS</div>
            </div>
            <div class="flex gap-2">
              <button
                type="button"
                phx-click="admin_test_subscribe"
                class="flex-1 py-2 rounded-[var(--radius-sm)] cursor-pointer flex items-center justify-center gap-1.5 transition-colors hover:bg-[var(--paper-200)]"
                style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--signal-live); border: 1px solid var(--signal-live);"
              >
                <.icon name="hero-bolt-mini" class="w-3.5 h-3.5" />
                ACTIVATE
              </button>
              <button
                type="button"
                phx-click="admin_deactivate_plan"
                data-confirm="Deactivate test plan?"
                class="flex-1 py-2 rounded-[var(--radius-sm)] cursor-pointer flex items-center justify-center gap-1.5 transition-colors hover:bg-[var(--paper-200)]"
                style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400); border: 1px solid var(--paper-300);"
              >
                <.icon name="hero-x-mark-mini" class="w-3.5 h-3.5" />
                DEACTIVATE
              </button>
            </div>
          </div>
        <% end %>
      </div>

      <%!-- Current plan status + cancellation --%>
      <%= if @current_user.plan == "paid" do %>
        <div class="px-6 py-4 border-b border-[var(--paper-300)]">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-2">
              <%= if @current_user.subscription_status == "cancelling" do %>
                <span
                  class="px-2 py-0.5 rounded-[var(--radius-stamp)]"
                  style="background: var(--signal-sound); color: #fff; font-family: var(--font-mono); font-weight: 700; font-size: 9px; letter-spacing: 0.1em;"
                >CANCELLING</span>
              <% else %>
                <span
                  class="px-2 py-0.5 rounded-[var(--radius-stamp)]"
                  style="background: var(--signal-live); color: #fff; font-family: var(--font-mono); font-weight: 700; font-size: 9px; letter-spacing: 0.1em;"
                >ACTIVE</span>
              <% end %>
              <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-500);">
                Manager plan · {@current_user.crew_seats || 10} seats
              </div>
            </div>
          </div>

          <%= if @current_user.subscription_status == "cancelling" && @current_user.subscription_period_end do %>
            <div class="mt-3 px-3 py-2 rounded-[var(--radius-sm)]" style="background: var(--signal-sound-tint); border: 1px solid var(--signal-sound);">
              <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-700);">
                Your plan remains active until {Calendar.strftime(@current_user.subscription_period_end, "%d %b %Y")}. You can resubscribe at any time.
              </div>
            </div>
          <% end %>

          <%= if @current_user.subscription_status == "active" && @current_user.stripe_subscription_id do %>
            <div class="mt-3">
              <button
                type="button"
                phx-click="cancel_subscription"
                data-confirm="Cancel your subscription? You'll keep access until the end of this billing cycle."
                class="px-3 py-1.5 rounded-[var(--radius-sm)] cursor-pointer transition-colors hover:bg-[var(--signal-stop-tint)]"
                style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--signal-stop); background: transparent; border: 1px solid var(--signal-stop);"
              >CANCEL SUBSCRIPTION</button>
            </div>
          <% end %>
        </div>
      <% end %>

      <%!-- Distance unit preference --%>
      <div class="px-6 py-4 border-b border-[var(--paper-300)]">
        <div class="flex items-center justify-between">
          <div>
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); margin-bottom: 4px;">DISTANCE UNIT</div>
            <div class="text-[13px] text-[var(--ink-500)]">Used for routing distances</div>
          </div>
          <button
            type="button"
            phx-click="toggle_distance_unit"
            class="flex items-center gap-2 px-3 py-2 rounded-[var(--radius-md)] cursor-pointer transition-all"
            style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; background: var(--ink-900); color: var(--paper-100); box-shadow: var(--shadow-hard-sm);"
          >
            {String.upcase(@current_user.distance_unit)}
            <.icon name="hero-arrows-right-left-mini" class="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      <%!-- Footer --%>
      <div class="px-6 py-4 border-t border-[var(--paper-300)] flex items-center justify-between">
        <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400);">
          {String.upcase(@current_user.role)} · {String.upcase(@current_user.plan)} PLAN
        </div>
        <.link
          href="/auth/sign_out"
          method="delete"
          class="flex items-center gap-1.5 px-3 py-1.5 rounded-[var(--radius-sm)] no-underline transition-colors hover:bg-[var(--paper-200)]"
          style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400);"
        >
          <.icon name="hero-arrow-right-on-rectangle-mini" class="w-3.5 h-3.5" />
          SIGN OUT
        </.link>
      </div>
    </.tm_modal>
    """
  end

  attr :form, :map, required: true
  attr :show, :boolean, default: false

  def new_tour_modal(assigns) do
    ~H"""
    <.tm_modal id="new-tour-modal" show={@show} on_close="close_new_tour">
      <%!-- Header --%>
      <div class="flex items-center justify-between px-6 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
        <div>
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand-on-dark);">NEW</div>
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; margin-top: 2px;">Create tour</div>
        </div>
        <button
          type="button"
          phx-click="close_new_tour"
          class="w-8 h-8 flex items-center justify-center rounded-[var(--radius-sm)] cursor-pointer transition-colors hover:bg-[var(--ink-700)]"
          aria-label="Close"
        >
          <.icon name="hero-x-mark" class="w-5 h-5 text-[var(--ink-300)]" />
        </button>
      </div>

      <%!-- Form --%>
      <.form for={@form} id="new-tour-form" phx-change="validate_tour" phx-submit="save_tour" class="px-6 py-5">
        <div class="flex flex-col gap-4">
          <div>
            <label
              for={@form[:name].id}
              style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;"
            >TOUR NAME</label>
            <.input
              field={@form[:name]}
              type="text"
              placeholder="e.g. Nova Riot UK Run 2026"
              class="w-full px-3 py-2.5 text-[15px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none transition-colors"
              style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);"
            />
          </div>

          <div>
            <label
              for={@form[:description].id}
              style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;"
            >DESCRIPTION</label>
            <.input
              field={@form[:description]}
              type="textarea"
              placeholder="Optional notes about this tour"
              rows="3"
              class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none transition-colors resize-none"
              style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);"
            />
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label
                for={@form[:start_date].id}
                style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;"
              >START DATE</label>
              <.input
                field={@form[:start_date]}
                type="date"
                class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none transition-colors"
                style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);"
              />
            </div>
            <div>
              <label
                for={@form[:end_date].id}
                style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;"
              >END DATE</label>
              <.input
                field={@form[:end_date]}
                type="date"
                class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none transition-colors"
                style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);"
              />
            </div>
          </div>
        </div>

        <%!-- Footer --%>
        <div class="flex items-center justify-end gap-3 mt-6 pt-5 border-t border-[var(--paper-300)]">
          <button
            type="button"
            phx-click="close_new_tour"
            class="px-4 py-2.5 rounded-[var(--radius-md)] cursor-pointer transition-colors hover:bg-[var(--paper-200)]"
            style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400); background: var(--surface-card); border: 1px solid var(--paper-300);"
          >CANCEL</button>
          <button
            type="submit"
            id="save-tour-btn"
            class="px-5 py-2.5 rounded-[var(--radius-md)] cursor-pointer transition-all"
            style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);"
          >CREATE TOUR</button>
        </div>
      </.form>
    </.tm_modal>
    """
  end

  attr :form, :map, required: true
  attr :show, :boolean, default: false

  def manage_tour_modal(assigns) do
    ~H"""
    <.tm_modal id="manage-tour-modal" show={@show} on_close="close_manage_tour">
      <div class="flex items-center justify-between px-6 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
        <div>
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand-on-dark);">MANAGE</div>
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; margin-top: 2px;">Edit tour</div>
        </div>
        <button type="button" phx-click="close_manage_tour" class="w-8 h-8 flex items-center justify-center rounded-[var(--radius-sm)] cursor-pointer transition-colors hover:bg-[var(--ink-700)]" aria-label="Close">
          <.icon name="hero-x-mark" class="w-5 h-5 text-[var(--ink-300)]" />
        </button>
      </div>

      <.form for={@form} id="manage-tour-form" phx-change="validate_manage_tour" phx-submit="save_manage_tour" class="px-6 py-5">
        <div class="flex flex-col gap-4">
          <div>
            <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">TOUR NAME</label>
            <.input field={@form[:name]} type="text" class="w-full px-3 py-2.5 text-[15px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none transition-colors" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">START DATE</label>
              <.input field={@form[:start_date]} type="date" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none transition-colors" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
            </div>
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">END DATE</label>
              <.input field={@form[:end_date]} type="date" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none transition-colors" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
            </div>
          </div>

          <div>
            <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">STATUS</label>
            <.input field={@form[:status]} type="select" options={[{"Draft", "draft"}, {"Active", "active"}, {"Completed", "completed"}, {"Cancelled", "cancelled"}]} class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none transition-colors" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
          </div>
        </div>

        <div class="flex items-center justify-between mt-6 pt-5 border-t border-[var(--paper-300)]">
          <button
            type="button"
            phx-click="delete_tour"
            data-confirm="Delete this tour? All stops, routes, crew, and data will be permanently removed."
            class="px-3 py-2 rounded-[var(--radius-md)] cursor-pointer transition-colors hover:bg-[var(--signal-stop-tint)]"
            style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--signal-stop); background: transparent; border: 1px solid var(--signal-stop);"
          >DELETE</button>
          <div class="flex items-center gap-3">
            <button type="button" phx-click="close_manage_tour" class="px-4 py-2.5 rounded-[var(--radius-md)] cursor-pointer transition-colors hover:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400); background: var(--surface-card); border: 1px solid var(--paper-300);">CANCEL</button>
            <button type="submit" class="px-5 py-2.5 rounded-[var(--radius-md)] cursor-pointer transition-all" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);">SAVE</button>
          </div>
        </div>
      </.form>
    </.tm_modal>
    """
  end

  attr :show, :boolean, default: false
  attr :calendar_token, :string, default: nil
  attr :calendar_mode, :string, default: "subscribe"
  attr :current_tour, :map, default: nil

  def calendar_modal(assigns) do
    cal_url =
      if assigns.calendar_token do
        TourmanagerV2Web.Endpoint.url() <> "/cal/#{assigns.calendar_token}"
      end

    webcal_url =
      if cal_url do
        String.replace(cal_url, ~r/^https?/, "webcal")
      end

    assigns =
      assigns
      |> assign(:cal_url, cal_url)
      |> assign(:webcal_url, webcal_url)

    ~H"""
    <.tm_modal id="calendar-modal" show={@show} on_close="close_calendar">
      <div class="px-6 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
        <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand-on-dark);">CALENDAR</div>
        <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; margin-top: 2px;">Subscribe to tour</div>
        <div :if={@current_tour} class="mt-1" style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-300);">
          {@current_tour.name}
        </div>
      </div>

      <%!-- Mode switcher --%>
      <div class="px-6 pt-5 pb-3">
        <div class="flex gap-2">
          <button
            :for={{mode, icon, label} <- [{"subscribe", "hero-calendar-days", "Subscribe"}, {"link", "hero-link", "Link"}, {"qr", "hero-qr-code", "QR Code"}]}
            type="button"
            phx-click="set_calendar_mode"
            phx-value-mode={mode}
            class={[
              "flex-1 flex items-center justify-center gap-2 py-2.5 rounded-[var(--radius-md)] cursor-pointer transition-all",
              if(@calendar_mode == mode, do: "border-2 border-[var(--brand)]", else: "border border-[var(--paper-300)] hover:border-[var(--ink-400)]")
            ]}
            style={"font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; background: #{if @calendar_mode == mode, do: "var(--marker-050)", else: "var(--surface-card)"}; color: #{if @calendar_mode == mode, do: "var(--brand)", else: "var(--ink-500)"};"}
          >
            <.icon name={icon} class="w-4 h-4" />
            {label}
          </button>
        </div>
      </div>

      <div class="px-6 pb-6">
        <%!-- Subscribe mode --%>
        <div :if={@calendar_mode == "subscribe" && @webcal_url} class="mt-2">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); margin-bottom: 12px;">ADD TO YOUR CALENDAR</div>
          <a
            href={@webcal_url}
            class="w-full flex items-center justify-center gap-2.5 py-3 rounded-[var(--radius-md)] no-underline transition-all"
            style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);"
          >
            <.icon name="hero-calendar-days" class="w-5 h-5" />
            SUBSCRIBE NOW
          </a>
          <div class="mt-4" style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); line-height: 1.5;">
            Opens your default calendar app and creates a live subscription. Tour dates update automatically.
          </div>
          <div class="mt-4 pt-4 border-t border-[var(--paper-300)]">
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); margin-bottom: 8px;">FOR GOOGLE CALENDAR</div>
            <div class="flex gap-2">
              <input
                type="text"
                readonly
                value={@cal_url}
                id="gcal-url-input"
                class="flex-1 px-3 py-2.5 text-[11px] rounded-[var(--radius-md)] border border-[var(--paper-300)] outline-none"
                style="background: var(--paper-200); color: var(--ink-700); font-family: var(--font-mono);"
              />
              <button
                type="button"
                phx-click={Phoenix.LiveView.JS.dispatch("phx:copy", to: "#gcal-url-input")}
                class="px-3 py-2.5 rounded-[var(--radius-md)] cursor-pointer transition-all flex items-center gap-1.5"
                style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);"
              >
                <.icon name="hero-clipboard-document" class="w-3.5 h-3.5" />
                COPY
              </button>
            </div>
            <div class="mt-2" style="font-family: var(--font-mono); font-size: 9px; color: var(--ink-300); line-height: 1.4;">
              Google Calendar: Settings → Add calendar → From URL → paste this link
            </div>
          </div>
        </div>

        <%!-- Link mode --%>
        <div :if={@calendar_mode == "link" && @cal_url} class="mt-2">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); margin-bottom: 8px;">CALENDAR FEED URL</div>
          <div class="flex gap-2">
            <input
              type="text"
              readonly
              value={@cal_url}
              id="cal-share-input"
              class="flex-1 px-3 py-2.5 text-[12px] rounded-[var(--radius-md)] border border-[var(--paper-300)] outline-none"
              style="background: var(--paper-200); color: var(--ink-700); font-family: var(--font-mono);"
            />
            <button
              type="button"
              phx-click={Phoenix.LiveView.JS.dispatch("phx:copy", to: "#cal-share-input")}
              class="px-4 py-2.5 rounded-[var(--radius-md)] cursor-pointer transition-all flex items-center gap-1.5"
              style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);"
            >
              <.icon name="hero-clipboard-document" class="w-4 h-4" />
              COPY
            </button>
          </div>
          <div class="mt-3" style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400);">
            Share this URL with anyone. They can subscribe in any calendar app.
          </div>
        </div>

        <%!-- QR Code mode --%>
        <div :if={@calendar_mode == "qr" && @cal_url} class="mt-2">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); margin-bottom: 8px;">SCAN TO SUBSCRIBE</div>
          <div class="flex justify-center p-6 rounded-[var(--radius-md)] border border-[var(--paper-300)]" style="background: #fff;">
            <img
              src={"https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=#{URI.encode(@cal_url)}"}
              class="w-[200px] h-[200px]"
              alt="Calendar QR code"
            />
          </div>
          <div class="mt-3 text-center" style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400);">
            Scan with a phone camera to subscribe to the calendar feed.
          </div>
        </div>
      </div>
    </.tm_modal>
    """
  end

  attr :day, :integer, required: true
  attr :date, :string, required: true
  attr :city, :string, required: true
  attr :venue, :string, required: true
  attr :code, :string, required: true
  attr :km, :integer, required: true
  attr :status, :string, required: true
  attr :type, :string, default: "gig"
  attr :distance_label, :string, default: nil
  attr :venue_image_url, :string, default: nil
  attr :travel_duration, :integer, default: nil
  attr :booking_ref, :string, default: nil
  attr :address, :string, default: nil
  attr :entry_id, :string, default: nil
  attr :place_id, :string, default: nil
  attr :lat, :float, default: nil
  attr :lng, :float, default: nil
  attr :origin_address, :string, default: nil
  attr :dest_address, :string, default: nil
  attr :directions_url, :string, default: nil
  attr :accommodation_name, :string, default: nil

  def route_stop_enhanced(assigns) do
    is_today = assigns.status == "today"
    assigns = assign(assigns, :is_today, is_today)

    ~H"""
    <div class="relative mb-1.5">
      <div class="grid grid-cols-[54px_8px_1fr] gap-0 items-center">
        <%!-- Date label --%>
        <div class="text-right leading-tight pr-2" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">
          <div class="font-bold text-[var(--ink-700)]">D{String.pad_leading(to_string(@day), 2, "0")}</div>
          <div class="text-[9px]">{@date}</div>
        </div>
        <%!-- Timeline line (right of date, between date and card) --%>
        <div class="flex flex-col items-center self-stretch py-1">
          <div class="flex-1 w-0.5 bg-[var(--paper-300)]" />
        </div>
        <%!-- Stop card --%>
        <div
          class={["flex items-center gap-3.5 px-3.5 py-3 ml-3 rounded-[var(--radius-md)]",
            if(@is_today, do: "border-2 border-[var(--ink-900)]", else: "border border-[var(--paper-300)]")
          ]}
          style={"background: #{if @is_today, do: "var(--surface-stage)", else: "var(--surface-card)"}; color: #{if @is_today, do: "var(--paper-100)", else: "var(--ink-700)"}; #{if @is_today, do: "box-shadow: var(--shadow-hard);", else: ""}"}
        >
          <%!-- Venue thumbnail — desktop: hover popover, mobile: tap modal --%>
          <div :if={@venue_image_url && @type in ~w(gig off_day)} class="relative flex-none">
            <%!-- Desktop hover popover --%>
            <div class="hidden md:block group/venue">
              <img
                src={@venue_image_url}
                class="w-12 h-12 rounded-[var(--radius-sm)] object-cover cursor-pointer transition-all group-hover/venue:ring-2 group-hover/venue:ring-[var(--brand)]"
                style="border: 1px solid var(--paper-300);"
                loading="lazy"
              />
              <div class="absolute left-0 top-1/2 -translate-y-1/2 z-50 pl-14 opacity-0 pointer-events-none group-hover/venue:opacity-100 group-hover/venue:pointer-events-auto" style="width: 340px; transition: opacity 150ms ease;">
                <div class="rounded-[var(--radius-md)] overflow-hidden" style="background: var(--surface-card); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard);">
                  <img src={@venue_image_url} class="w-full h-40 object-cover" loading="lazy" />
                  <div class="p-3">
                    <div style="font-family: var(--font-display); font-weight: 700; font-size: 15px; color: var(--ink-900);">{@venue}</div>
                    <div :if={@address || @city} style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); margin-top: 3px;">{@address || @city}</div>
                    <a href={venue_maps_link(@venue, @city, @address, @lat, @lng)} target="_blank" class="flex items-center gap-1.5 mt-2.5 no-underline transition-colors hover:text-[var(--brand)]" style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400);">
                      <.icon name="hero-map-pin-mini" class="w-3.5 h-3.5" /> OPEN IN GOOGLE <.icon name="hero-arrow-top-right-on-square-mini" class="w-3 h-3" />
                    </a>
                  </div>
                </div>
              </div>
            </div>
            <%!-- Mobile tap modal --%>
            <div class="md:hidden">
              <label for={"stop-modal-#{@entry_id}"}>
                <img
                  src={@venue_image_url}
                  class="w-12 h-12 rounded-[var(--radius-sm)] object-cover cursor-pointer active:ring-2 active:ring-[var(--brand)]"
                  style="border: 1px solid var(--paper-300);"
                  loading="lazy"
                />
              </label>
              <input type="checkbox" id={"stop-modal-#{@entry_id}"} class="hidden peer/stop" />
              <div class="fixed inset-0 z-50 hidden peer-checked/stop:flex items-end justify-center">
                <label for={"stop-modal-#{@entry_id}"} class="absolute inset-0" style="background: rgba(20, 17, 15, 0.55); backdrop-filter: blur(4px);" />
                <div class="relative z-10 w-full max-w-md rounded-t-[var(--radius-xl)] overflow-hidden" style="background: var(--surface-card); border: 2px solid var(--ink-900); border-bottom: none; box-shadow: var(--shadow-hard);">
                  <img src={@venue_image_url} class="w-full h-48 object-cover" loading="lazy" />
                  <div class="p-5">
                    <div style="font-family: var(--font-display); font-weight: 700; font-size: 20px; color: var(--ink-900);">{@venue}</div>
                    <div :if={@address || @city} style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400); margin-top: 4px;">{@address || @city}</div>
                    <a href={venue_maps_link(@venue, @city, @address, @lat, @lng)} target="_blank" class="flex items-center justify-center gap-2 mt-4 py-3 rounded-[var(--radius-md)] no-underline transition-colors" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);">
                      <.icon name="hero-map-pin-mini" class="w-4 h-4" /> OPEN IN GOOGLE MAPS
                    </a>
                    <label for={"stop-modal-#{@entry_id}"} class="flex items-center justify-center mt-3 py-2.5 cursor-pointer rounded-[var(--radius-md)]" style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400); border: 1px solid var(--paper-300);">
                      CLOSE
                    </label>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <%!-- Travel icon — desktop: hover popover, mobile: tap modal --%>
          <div :if={@type == "vehicle_travel"} class="relative flex-none">
            <%!-- Desktop hover --%>
            <div class="hidden md:block group/travel">
              <span class="w-12 h-12 rounded-[var(--radius-sm)] flex items-center justify-center cursor-pointer transition-all group-hover/travel:ring-2 group-hover/travel:ring-[var(--signal-load)]" style="background: var(--signal-load-tint); border: 1px solid var(--paper-300);">
                <.icon name="hero-truck" class="w-5 h-5 text-[var(--signal-load)]" />
              </span>
              <div class="absolute left-0 top-1/2 -translate-y-1/2 z-50 pl-14 opacity-0 pointer-events-none group-hover/travel:opacity-100 group-hover/travel:pointer-events-auto" style="width: 300px; transition: opacity 150ms ease;">
                <div class="rounded-[var(--radius-md)] overflow-hidden" style="background: var(--surface-card); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard);">
                  <div class="px-3 py-2.5 flex items-center gap-2" style="background: var(--signal-load-tint); border-bottom: 1px solid var(--paper-300);">
                    <.icon name="hero-truck" class="w-4 h-4 text-[var(--signal-load)]" />
                    <div style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.1em; color: var(--signal-load);">VEHICLE TRAVEL</div>
                  </div>
                  <div class="p-3">
                    <div class="flex items-start gap-2 mb-2">
                      <div class="flex flex-col items-center gap-0.5 pt-0.5 flex-none">
                        <span class="w-2 h-2 rounded-full" style="background: var(--signal-load);" />
                        <span class="w-px h-5" style="background: var(--paper-300);" />
                        <span class="w-2 h-2 rounded-full" style="background: var(--signal-load);" />
                      </div>
                      <div class="flex-1 min-w-0">
                        <div>
                          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.1em; color: var(--ink-400);">FROM</div>
                          <div style="font-family: var(--font-display); font-weight: 700; font-size: 14px; color: var(--ink-900);">{@venue}</div>
                        </div>
                        <div class="mt-2">
                          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.1em; color: var(--ink-400);">TO</div>
                          <div style="font-family: var(--font-display); font-weight: 700; font-size: 14px; color: var(--ink-900);">{@city}</div>
                        </div>
                      </div>
                    </div>
                    <a :if={@directions_url} href={@directions_url} target="_blank" class="flex items-center gap-1.5 mt-2.5 no-underline transition-colors hover:text-[var(--brand)]" style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400);">
                      <.icon name="hero-map-pin-mini" class="w-3.5 h-3.5" /> OPEN ROUTE IN MAPS <.icon name="hero-arrow-top-right-on-square-mini" class="w-3 h-3" />
                    </a>
                  </div>
                </div>
              </div>
            </div>
            <%!-- Mobile tap modal --%>
            <div class="md:hidden">
              <label for={"travel-modal-#{@entry_id}"}>
                <span class="w-12 h-12 rounded-[var(--radius-sm)] flex items-center justify-center cursor-pointer active:ring-2 active:ring-[var(--signal-load)]" style="background: var(--signal-load-tint); border: 1px solid var(--paper-300);">
                  <.icon name="hero-truck" class="w-5 h-5 text-[var(--signal-load)]" />
                </span>
              </label>
              <input type="checkbox" id={"travel-modal-#{@entry_id}"} class="hidden peer/trav" />
              <div class="fixed inset-0 z-50 hidden peer-checked/trav:flex items-end justify-center">
                <label for={"travel-modal-#{@entry_id}"} class="absolute inset-0" style="background: rgba(20, 17, 15, 0.55); backdrop-filter: blur(4px);" />
                <div class="relative z-10 w-full max-w-md rounded-t-[var(--radius-xl)] overflow-hidden" style="background: var(--surface-card); border: 2px solid var(--ink-900); border-bottom: none; box-shadow: var(--shadow-hard);">
                  <div class="px-5 py-3 flex items-center gap-2" style="background: var(--signal-load-tint); border-bottom: 1px solid var(--paper-300);">
                    <.icon name="hero-truck" class="w-4 h-4 text-[var(--signal-load)]" />
                    <div style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.1em; color: var(--signal-load);">VEHICLE TRAVEL</div>
                  </div>
                  <div class="p-5">
                    <div class="mb-1" style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.1em; color: var(--ink-400);">FROM</div>
                    <div style="font-family: var(--font-display); font-weight: 700; font-size: 18px; color: var(--ink-900);">{@venue}</div>
                    <div :if={@origin_address} style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); margin-top: 2px;">{@origin_address}</div>
                    <div class="mt-4 mb-1" style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.1em; color: var(--ink-400);">TO</div>
                    <div style="font-family: var(--font-display); font-weight: 700; font-size: 18px; color: var(--ink-900);">{@city}</div>
                    <div :if={@dest_address} style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); margin-top: 2px;">{@dest_address}</div>
                    <a :if={@directions_url} href={@directions_url} target="_blank" class="flex items-center justify-center gap-2 mt-5 py-3 rounded-[var(--radius-md)] no-underline" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);">
                      <.icon name="hero-map-pin-mini" class="w-4 h-4" /> OPEN ROUTE IN MAPS
                    </a>
                    <label for={"travel-modal-#{@entry_id}"} class="flex items-center justify-center mt-3 py-2.5 cursor-pointer rounded-[var(--radius-md)]" style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400); border: 1px solid var(--paper-300);">
                      CLOSE
                    </label>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <span
            :if={@type == "off_day" && !@venue_image_url}
            class="w-12 h-12 rounded-[var(--radius-sm)] flex items-center justify-center flex-none"
            style="background: var(--paper-200); border: 1px solid var(--paper-300);"
          >
            <.icon name="hero-moon" class="w-5 h-5 text-[var(--ink-400)]" />
          </span>

          <span
            :if={!@venue_image_url && @type == "gig"}
            class="w-3 h-3 flex-none rounded-full border-2 border-[var(--paper-50)]"
            style={"background: var(--signal-#{route_tone(@status)}); opacity: #{if @status == "done", do: "0.3", else: "1"}; box-shadow: 0 0 0 2px var(--paper-300);"}
          />

          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2">
              <div
                style={"font-family: var(--font-display); font-weight: 700; font-size: 17px; letter-spacing: -0.01em; color: #{if @is_today, do: "#fff", else: "var(--ink-900)"};"}
              >
                {cond do
                  @type == "gig" -> @venue
                  @type == "vehicle_travel" -> "#{@venue} → #{@city}"
                  @type == "off_day" && @venue && @venue != "—" -> @venue
                  true -> "Off day"
                end}
              </div>
              <.signal_chip
                :if={@type == "vehicle_travel"}
                tone="load"
                size="sm"
                variant="tint"
              >
                TRAVEL
              </.signal_chip>
              <.signal_chip
                :if={@type == "off_day"}
                tone="ink"
                size="sm"
                variant="tint"
              >
                OFF DAY
              </.signal_chip>
            </div>
            <div style={"font-family: var(--font-mono); font-size: 10.5px; letter-spacing: 0.04em; color: #{if @is_today, do: "var(--ink-300)", else: "var(--ink-400)"};"}>{@city}{if @address, do: " · #{@address}", else: ""}</div>
            <div
              :if={@travel_duration}
              class="flex items-center gap-1 mt-0.5"
              style={"font-family: var(--font-mono); font-size: 10px; color: #{if @is_today, do: "var(--ink-300)", else: "var(--ink-400)"}"}
            >
              <.icon name="hero-clock-mini" class="w-3 h-3" />
              {TourmanagerV2.GoogleMaps.format_duration(@travel_duration)}
            </div>
            <div
              :if={@booking_ref}
              class="flex items-center gap-1 mt-0.5"
              style={"font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.06em; color: #{if @is_today, do: "var(--ink-300)", else: "var(--ink-400)"}"}
            >
              REF: {@booking_ref}
            </div>
            <div
              :if={@accommodation_name}
              class="flex items-center gap-1 mt-0.5"
              style={"font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.06em; color: #{if @is_today, do: "var(--ink-300)", else: "var(--ink-400)"}"}
            >
              <.icon name="hero-building-office-2-mini" class="w-3 h-3" /> {@accommodation_name}
            </div>
          </div>
          <.signal_chip :if={@status not in ~w(done upcoming)} tone={route_tone(@status)} size="sm">
            {@status}
          </.signal_chip>
        </div>
      </div>
    </div>
    """
  end

  attr :form, :map, required: true
  attr :show, :boolean, default: false
  attr :entry_type, :string, default: "gig"
  attr :editing, :boolean, default: false
  attr :place_suggestions, :list, default: []
  attr :autocomplete_field, :string, default: nil
  attr :production_venue, :any, default: nil

  def route_entry_modal(assigns) do
    close_event = if assigns.editing, do: "close_edit_route", else: "close_add_route"
    submit_event = if assigns.editing, do: "update_route_entry", else: "save_route_entry"
    modal_id = if assigns.editing, do: "edit-route-modal", else: "add-route-modal"

    assigns =
      assigns
      |> assign(:close_event, close_event)
      |> assign(:submit_event, submit_event)
      |> assign(:modal_id, modal_id)

    ~H"""
    <.tm_modal id={@modal_id} show={@show} on_close={@close_event}>
      <%!-- Header --%>
      <div class="flex items-center justify-between px-6 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
        <div>
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand-on-dark);">
            {if @editing, do: "EDIT STOP", else: "ADD TO ROUTE"}
          </div>
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; margin-top: 2px;">
            {if @editing, do: "Edit stop", else: "New stop"}
          </div>
        </div>
        <button type="button" phx-click={@close_event} class="w-8 h-8 flex items-center justify-center rounded-[var(--radius-sm)] cursor-pointer transition-colors hover:bg-[var(--ink-700)]" aria-label="Close">
          <.icon name="hero-x-mark" class="w-5 h-5 text-[var(--ink-300)]" />
        </button>
      </div>

      <%!-- Type selector (only for new) --%>
      <div :if={!@editing} class="px-6 pt-5 pb-3">
        <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); margin-bottom: 8px;">TYPE</div>
        <div class="flex gap-2">
          <button
            :for={t <- [{"gig", "hero-musical-note", "Gig"}, {"vehicle_travel", "hero-truck", "Travel"}, {"off_day", "hero-moon", "Off day"}]}
            type="button"
            phx-click="set_route_type"
            phx-value-type={elem(t, 0)}
            class={[
              "flex-1 flex items-center justify-center gap-2 py-2.5 rounded-[var(--radius-md)] cursor-pointer transition-all",
              if(@entry_type == elem(t, 0), do: "border-2 border-[var(--brand)]", else: "border border-[var(--paper-300)] hover:border-[var(--ink-400)]")
            ]}
            style={"font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; background: #{if @entry_type == elem(t, 0), do: "var(--marker-050)", else: "var(--surface-card)"}; color: #{if @entry_type == elem(t, 0), do: "var(--brand)", else: "var(--ink-500)"};"}
          >
            <.icon name={elem(t, 1)} class="w-4 h-4" />
            {elem(t, 2)}
          </button>
        </div>
      </div>

      <%!-- Form --%>
      <.form for={@form} id={"#{@modal_id}-form"} phx-change="validate_route_entry" phx-submit={@submit_event} class="px-6 pb-5" style="max-height: 60vh; overflow-y: auto;">
        <.input field={@form[:type]} type="hidden" value={@entry_type} />

        <div class="flex flex-col gap-4 mt-2">
          <%!-- ===== GIG FIELDS ===== --%>
          <%= if @entry_type == "gig" do %>
            <.place_autocomplete_field
              form={@form}
              field={:venue}
              label="LOCATION"
              placeholder="Search venue or address"
              suggestions={if @autocomplete_field == "venue", do: @place_suggestions, else: []}
              autocomplete_field="venue"
            />
            <.input field={@form[:place_id]} type="hidden" />
            <.input field={@form[:lat]} type="hidden" />
            <.input field={@form[:lng]} type="hidden" />
            <.input field={@form[:city]} type="hidden" />
            <.input field={@form[:venue_image_url]} type="hidden" />

            <.selected_place_chip
              :if={Phoenix.HTML.Form.input_value(@form, :place_id) not in [nil, ""]}
              name={Phoenix.HTML.Form.input_value(@form, :venue)}
              subtitle={Phoenix.HTML.Form.input_value(@form, :city)}
              place_id={Phoenix.HTML.Form.input_value(@form, :place_id)}
            />

            <.production_info_panel
              :if={Phoenix.HTML.Form.input_value(@form, :place_id) not in [nil, ""]}
              venue={@production_venue}
            />

            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">DATE</label>
              <.input field={@form[:date]} type="date" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none transition-colors" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
            </div>
          <% end %>

          <%!-- ===== VEHICLE TRAVEL FIELDS ===== --%>
          <%= if @entry_type == "vehicle_travel" do %>
            <.place_autocomplete_field
              form={@form}
              field={:origin}
              label="FROM"
              placeholder="Search origin"
              suggestions={if @autocomplete_field == "origin", do: @place_suggestions, else: []}
              autocomplete_field="origin"
            />
            <.input field={@form[:origin_place_id]} type="hidden" />
            <.input field={@form[:origin_lat]} type="hidden" />
            <.input field={@form[:origin_lng]} type="hidden" />
            <.input field={@form[:origin_address]} type="hidden" />

            <.selected_place_chip
              :if={Phoenix.HTML.Form.input_value(@form, :origin_place_id) not in [nil, ""]}
              name={Phoenix.HTML.Form.input_value(@form, :origin)}
              subtitle={Phoenix.HTML.Form.input_value(@form, :origin_address)}
              place_id={Phoenix.HTML.Form.input_value(@form, :origin_place_id)}
            />

            <.place_autocomplete_field
              form={@form}
              field={:destination}
              label="TO"
              placeholder="Search destination"
              suggestions={if @autocomplete_field == "destination", do: @place_suggestions, else: []}
              autocomplete_field="destination"
            />
            <.input field={@form[:dest_place_id]} type="hidden" />
            <.input field={@form[:dest_lat]} type="hidden" />
            <.input field={@form[:dest_lng]} type="hidden" />
            <.input field={@form[:dest_address]} type="hidden" />

            <.selected_place_chip
              :if={Phoenix.HTML.Form.input_value(@form, :dest_place_id) not in [nil, ""]}
              name={Phoenix.HTML.Form.input_value(@form, :destination)}
              subtitle={Phoenix.HTML.Form.input_value(@form, :dest_address)}
              place_id={Phoenix.HTML.Form.input_value(@form, :dest_place_id)}
            />

            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">DATE</label>
              <.input field={@form[:date]} type="date" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none transition-colors" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
            </div>

            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">BOOKING REFERENCE</label>
              <.input field={@form[:booking_reference]} type="text" placeholder="Optional — e.g. confirmation #" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none transition-colors" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
            </div>
          <% end %>

          <%!-- ===== OFF DAY FIELDS ===== --%>
          <%= if @entry_type == "off_day" do %>
            <.place_autocomplete_field
              form={@form}
              field={:venue}
              label="LOCATION (OPTIONAL)"
              placeholder="Search hotel, city, or address"
              suggestions={if @autocomplete_field == "venue", do: @place_suggestions, else: []}
              autocomplete_field="venue"
            />
            <.input field={@form[:place_id]} type="hidden" />
            <.input field={@form[:lat]} type="hidden" />
            <.input field={@form[:lng]} type="hidden" />
            <.input field={@form[:city]} type="hidden" />
            <.input field={@form[:venue_image_url]} type="hidden" />

            <.selected_place_chip
              :if={Phoenix.HTML.Form.input_value(@form, :place_id) not in [nil, ""]}
              name={Phoenix.HTML.Form.input_value(@form, :venue)}
              subtitle={Phoenix.HTML.Form.input_value(@form, :city)}
              place_id={Phoenix.HTML.Form.input_value(@form, :place_id)}
            />

            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">DATE</label>
              <.input field={@form[:date]} type="date" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none transition-colors" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
            </div>
          <% end %>

          <%!-- Accommodation (collapsible, all types) --%>
          <details class="group/accom rounded-[var(--radius-md)] border border-[var(--paper-300)]" style="background: var(--paper-200);">
            <summary class="flex items-center gap-2 px-3 py-2.5 cursor-pointer list-none" style="list-style: none;">
              <.icon name="hero-building-office-2-mini" class="w-4 h-4 text-[var(--ink-400)]" />
              <span style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-500);">ACCOMMODATION</span>
              <.icon name="hero-chevron-down" class="w-3.5 h-3.5 text-[var(--ink-300)] ml-auto transition-transform group-open/accom:rotate-180" />
            </summary>
            <div class="px-3 pb-3 pt-1 flex flex-col gap-3">
              <div class="relative">
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">HOTEL / LOCATION</label>
                <input
                  type="text"
                  name="accommodation[location]"
                  value={@form.params["accommodation"]["location"] || ""}
                  placeholder="Search hotel or address"
                  phx-debounce="400"
                  phx-keyup="place_autocomplete"
                  phx-value-field="accommodation"
                  autocomplete="off"
                  class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none transition-colors"
                  style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);"
                />
                <div
                  :if={@autocomplete_field == "accommodation" && @place_suggestions != []}
                  class="absolute left-0 right-0 top-full mt-1 rounded-[var(--radius-md)] overflow-hidden z-50"
                  style="background: var(--surface-card); border: 1px solid var(--paper-300); box-shadow: var(--shadow-hard);"
                >
                  <button
                    :for={s <- @place_suggestions}
                    type="button"
                    phx-click="select_place"
                    phx-value-place-id={s.place_id}
                    phx-value-field="accommodation"
                    class="w-full text-left px-4 py-3 cursor-pointer transition-colors hover:bg-[var(--paper-200)] border-b border-[var(--paper-300)] last:border-b-0"
                  >
                    <div class="text-[14px] font-semibold text-[var(--ink-900)]">{s.main_text}</div>
                    <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400);">{s.secondary_text}</div>
                  </button>
                </div>
              </div>
              <input type="hidden" name="accommodation[place_id]" value={@form.params["accommodation"]["place_id"] || ""} />
              <input type="hidden" name="accommodation[lat]" value={@form.params["accommodation"]["lat"] || ""} />
              <input type="hidden" name="accommodation[lng]" value={@form.params["accommodation"]["lng"] || ""} />

              <.selected_place_chip
                :if={@form.params["accommodation"]["place_id"] not in [nil, ""]}
                name={@form.params["accommodation"]["location"]}
                place_id={@form.params["accommodation"]["place_id"]}
              />

              <div class="grid grid-cols-2 gap-3">
                <div>
                  <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">CHECK-IN</label>
                  <input type="date" name="accommodation[check_in]" value={@form.params["accommodation"]["check_in"] || ""} class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none transition-colors" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
                </div>
                <div>
                  <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">CHECK-OUT</label>
                  <input type="date" name="accommodation[check_out]" value={@form.params["accommodation"]["check_out"] || ""} class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none transition-colors" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
                </div>
              </div>
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">BOOKING REF</label>
                <input type="text" name="accommodation[booking_reference]" value={@form.params["accommodation"]["booking_reference"] || ""} placeholder="Confirmation #" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none transition-colors" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
              </div>
            </div>
          </details>

          <%!-- Notes (all types) --%>
          <div>
            <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">NOTES</label>
            <.input field={@form[:notes]} type="textarea" rows="2" placeholder="Optional" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none transition-colors resize-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
          </div>
        </div>

        <%!-- Footer --%>
        <div class="flex items-center justify-between mt-6 pt-5 border-t border-[var(--paper-300)]">
          <div>
            <button
              :if={@editing}
              type="button"
              phx-click="delete_route_entry"
              data-confirm="Delete this stop? This cannot be undone."
              class="px-3 py-2 rounded-[var(--radius-md)] cursor-pointer transition-colors hover:bg-[var(--signal-stop-tint)]"
              style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--signal-stop); background: transparent; border: 1px solid var(--signal-stop);"
            >DELETE</button>
          </div>
          <div class="flex items-center gap-3">
            <button type="button" phx-click={@close_event} class="px-4 py-2.5 rounded-[var(--radius-md)] cursor-pointer transition-colors hover:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400); background: var(--surface-card); border: 1px solid var(--paper-300);">CANCEL</button>
            <button type="submit" class="px-5 py-2.5 rounded-[var(--radius-md)] cursor-pointer transition-all" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);">{if @editing, do: "SAVE CHANGES", else: "ADD STOP"}</button>
          </div>
        </div>
      </.form>
    </.tm_modal>
    """
  end

  attr :venue, :any, default: nil

  def production_info_panel(assigns) do
    ~H"""
    <div class="rounded-[var(--radius-md)] border border-[var(--paper-300)] px-3 py-3" style="background: var(--paper-200);">
      <div class="flex items-center gap-2 mb-2">
        <.icon name="hero-wrench-screwdriver-mini" class="w-4 h-4 text-[var(--ink-400)]" />
        <span style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-500);">PRODUCTION INFO</span>
        <.signal_chip
          :if={@venue && @venue.production_profile}
          tone={production_profile_tone(@venue.production_profile.profile_status)}
          size="sm"
          variant="tint"
        >{String.upcase(String.replace(@venue.production_profile.profile_status, "_", " "))}</.signal_chip>
      </div>

      <%= if is_nil(@venue) do %>
        <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); line-height: 1.5;">
          Not yet in the shared production database.
        </div>
        <button
          type="button"
          phx-click="create_production_venue"
          class="mt-2 px-3 py-1.5 rounded-[var(--radius-sm)] cursor-pointer transition-colors hover:bg-[var(--paper-300)]"
          style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--brand); background: var(--surface-card); border: 1px solid var(--paper-300);"
        >
          + ADD TO PRODUCTION DATABASE
        </button>
      <% else %>
        <div class="grid grid-cols-3 gap-x-3 gap-y-2 mb-2">
          <.production_stat label="Capacity" value={@venue.capacity && to_string(@venue.capacity)} />
          <.production_stat label="Stage" value={profile_stage_summary(@venue.production_profile)} />
          <.production_stat label="Rigging" value={"#{length(@venue.rigging_points)} pts"} />
          <.production_stat label="Power" value={"#{length(@venue.power_services)} svc"} />
          <.production_stat label="Lighting" value={"#{length(@venue.lighting_fixtures)} fx"} />
          <.production_stat label="Docs" value={"#{length(@venue.production_documents)}"} />
        </div>
        <.link
          navigate={"/production/venues/#{@venue.id}"}
          class="inline-flex items-center gap-1 no-underline transition-colors hover:text-[var(--brand)]"
          style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400);"
        >
          VIEW FULL PROFILE <.icon name="hero-arrow-top-right-on-square-mini" class="w-3 h-3" />
        </.link>
      <% end %>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :string, default: nil

  def production_stat(assigns) do
    ~H"""
    <div :if={@value}>
      <div style="font-family: var(--font-mono); font-size: 8px; letter-spacing: 0.1em; color: var(--ink-400);">{String.upcase(@label)}</div>
      <div style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; color: var(--ink-900);">{@value}</div>
    </div>
    """
  end

  defp production_profile_tone("published"), do: "live"
  defp production_profile_tone("needs_review"), do: "doors"
  defp production_profile_tone(_), do: "ink"

  defp profile_stage_summary(nil), do: nil
  defp profile_stage_summary(%{stage_width_m: nil, stage_depth_m: nil}), do: nil
  defp profile_stage_summary(%{stage_width_m: w, stage_depth_m: d}) do
    "#{fmt_stage_m(w)}×#{fmt_stage_m(d)}"
  end

  defp fmt_stage_m(nil), do: "?"
  defp fmt_stage_m(val), do: "#{:erlang.float_to_binary(val / 1, decimals: 1)}m"

  attr :form, :map, required: true
  attr :field, :atom, required: true
  attr :label, :string, required: true
  attr :placeholder, :string, default: ""
  attr :suggestions, :list, default: []
  attr :autocomplete_field, :string, required: true

  def place_autocomplete_field(assigns) do
    ~H"""
    <div class="relative">
      <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">{@label}</label>
      <.input
        field={@form[@field]}
        type="text"
        placeholder={@placeholder}
        phx-debounce="400"
        phx-keyup="place_autocomplete"
        phx-value-field={@autocomplete_field}
        phx-key=""
        autocomplete="off"
        class="w-full px-3 py-2.5 text-[15px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none transition-colors"
        style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);"
      />
      <div
        :if={@suggestions != []}
        class="absolute left-0 right-0 top-full mt-1 rounded-[var(--radius-md)] overflow-hidden z-50"
        style="background: var(--surface-card); border: 1px solid var(--paper-300); box-shadow: var(--shadow-hard);"
      >
        <button
          :for={s <- @suggestions}
          type="button"
          phx-click="select_place"
          phx-value-place-id={s.place_id}
          phx-value-field={@autocomplete_field}
          class="w-full text-left px-4 py-3 cursor-pointer transition-colors hover:bg-[var(--paper-200)] border-b border-[var(--paper-300)] last:border-b-0"
        >
          <div class="text-[14px] font-semibold text-[var(--ink-900)]">{s.main_text}</div>
          <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400); margin-top: 2px;">{s.secondary_text}</div>
        </button>
      </div>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :subtitle, :string, default: nil
  attr :place_id, :string, default: nil

  def selected_place_chip(assigns) do
    ~H"""
    <div class="flex items-center gap-3 p-3 rounded-[var(--radius-md)] border border-[var(--paper-300)]" style="background: var(--paper-200);">
      <.icon name="hero-map-pin" class="w-4 h-4 text-[var(--brand)] flex-none" />
      <div class="flex-1 min-w-0">
        <div class="text-[13px] font-semibold text-[var(--ink-900)] truncate">{@name}</div>
        <div :if={@subtitle} style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400);">{@subtitle}</div>
      </div>
      <a
        :if={@place_id}
        href={"https://www.google.com/maps/place/?q=place_id:#{@place_id}"}
        target="_blank"
        class="text-[var(--brand)] hover:text-[var(--brand-hover)] transition-colors"
        title="Open in Google Maps"
      >
        <.icon name="hero-arrow-top-right-on-square-mini" class="w-4 h-4" />
      </a>
    </div>
    """
  end

  attr :current_user, :map, required: true
  attr :tour_form, :map, default: nil
  attr :onboarding_step, :string, default: "profile"
  attr :profile_form, :map, default: nil

  def onboarding_welcome(assigns) do
    ~H"""
    <div class="flex items-center justify-center min-h-[60vh]">
      <div class="w-full max-w-[480px]">
        <div
          class="tm-halftone tm-halftone--light rounded-[var(--radius-xl)] overflow-hidden"
          style="border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard);"
        >
          <%!-- Stage header --%>
          <div class="px-8 py-6" style="background: var(--surface-stage);">
            <div class="relative z-[2]">
              <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.24em; color: var(--brand-on-dark);">
                {if @onboarding_step == "profile", do: "STEP 1 OF 2", else: "STEP 2 OF 2"}
              </div>
              <div style="font-family: var(--font-display); font-weight: 800; font-size: 28px; letter-spacing: -0.02em; line-height: 1.1; color: #fff; margin-top: 6px;">
                {if @onboarding_step == "profile", do: "About you", else: "Your first tour"}
              </div>
              <div class="mt-3" style="font-family: var(--font-sans); font-size: 14px; color: var(--ink-300); line-height: 1.5;">
                <%= if @onboarding_step == "profile" do %>
                  Tell your crew who you are. This info shows on day sheets so people can reach you.
                <% else %>
                  Name your tour and set the dates. You can always change these later.
                <% end %>
              </div>
            </div>
          </div>

          <%!-- Trial badge --%>
          <div class="px-8 py-3 flex items-center gap-3 border-b border-[var(--paper-300)]" style="background: var(--signal-live-tint);">
            <.icon name="hero-clock" class="w-4 h-4 text-[var(--signal-live)]" />
            <div style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--signal-live);">
              7-DAY MANAGER TRIAL · FULL ACCESS
            </div>
          </div>

          <%!-- Form --%>
          <div class="px-8 py-6" style="background: var(--surface-card);">
            <%= if @onboarding_step == "profile" && @profile_form do %>
              <.form for={@profile_form} id="onboarding-profile-form" phx-submit="save_onboarding_profile" phx-change="validate_onboarding_profile">
                <div class="flex flex-col gap-4">
                  <div>
                    <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">YOUR NAME</label>
                    <.input
                      field={@profile_form[:name]}
                      type="text"
                      placeholder="Full name"
                      class="w-full px-3 py-2.5 text-[15px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none transition-colors"
                      style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);"
                    />
                  </div>
                  <div>
                    <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">ROLE</label>
                    <.input
                      field={@profile_form[:role_title]}
                      type="text"
                      placeholder="e.g. Tour Manager, FOH Engineer, Guitar Tech"
                      class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none transition-colors"
                      style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);"
                    />
                  </div>
                  <div>
                    <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">PHONE</label>
                    <.input
                      field={@profile_form[:phone_number]}
                      type="tel"
                      placeholder="+61 400 000 000"
                      class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none transition-colors"
                      style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);"
                    />
                  </div>
                  <button
                    type="submit"
                    class="w-full mt-2 px-5 py-3 rounded-[var(--radius-md)] cursor-pointer transition-all flex items-center justify-center gap-2"
                    style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);"
                  >
                    CONTINUE
                    <.icon name="hero-arrow-right-mini" class="w-4 h-4" />
                  </button>
                </div>
              </.form>
              <div class="mt-4 text-center">
                <button type="button" phx-click="skip_onboarding_profile" class="cursor-pointer" style="font-family: var(--font-mono); font-size: 10px; letter-spacing: 0.06em; color: var(--ink-300);">
                  SKIP FOR NOW
                </button>
              </div>
            <% else %>
            <.form for={@tour_form} id="onboarding-tour-form" phx-submit="create_first_tour" phx-change="validate_tour">
              <div class="flex flex-col gap-4">
                <div>
                  <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">TOUR NAME</label>
                  <.input
                    field={@tour_form[:name]}
                    type="text"
                    placeholder="e.g. UK Summer Run 2026"
                    class="w-full px-3 py-2.5 text-[15px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none transition-colors"
                    style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);"
                  />
                </div>

                <div class="grid grid-cols-2 gap-3">
                  <div>
                    <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">START DATE</label>
                    <.input
                      field={@tour_form[:start_date]}
                      type="date"
                      class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none transition-colors"
                      style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);"
                    />
                  </div>
                  <div>
                    <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">END DATE</label>
                    <.input
                      field={@tour_form[:end_date]}
                      type="date"
                      class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none transition-colors"
                      style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);"
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  class="w-full mt-2 px-5 py-3 rounded-[var(--radius-md)] cursor-pointer transition-all flex items-center justify-center gap-2"
                  style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);"
                >
                  <.icon name="hero-map" class="w-4 h-4" />
                  CREATE TOUR
                </button>
              </div>
            </.form>

            <%!-- What happens after trial --%>
            <div class="mt-5 pt-4 border-t border-[var(--paper-300)]">
              <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); margin-bottom: 8px;">AFTER YOUR TRIAL</div>
              <div class="flex flex-col gap-2">
                <div class="flex items-start gap-2.5">
                  <.icon name="hero-check-mini" class="w-3.5 h-3.5 text-[var(--signal-live)] mt-0.5 flex-none" />
                  <div style="font-family: var(--font-sans); font-size: 13px; color: var(--ink-500);">Subscribe to keep creating tours and managing crew</div>
                </div>
                <div class="flex items-start gap-2.5">
                  <.icon name="hero-check-mini" class="w-3.5 h-3.5 text-[var(--ink-300)] mt-0.5 flex-none" />
                  <div style="font-family: var(--font-sans); font-size: 13px; color: var(--ink-500);">Or continue as crew with read-only access to your tours</div>
                </div>
              </div>
            </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :current_user, :map, required: true

  def trial_banner(assigns) do
    days = TourmanagerV2.Accounts.User.trial_days_remaining(assigns.current_user)
    urgent = days <= 2

    assigns =
      assigns
      |> assign(:days, days)
      |> assign(:urgent, urgent)

    ~H"""
    <div
      :if={TourmanagerV2.Accounts.User.trial_active?(@current_user) && !TourmanagerV2.Accounts.User.subscribed?(@current_user)}
      class="flex items-center justify-between px-5 py-2.5"
      style={"background: #{if @urgent, do: "var(--signal-stop-tint)", else: "var(--signal-live-tint)"}; border-bottom: 1px solid #{if @urgent, do: "var(--signal-stop)", else: "var(--signal-live)"};"}
    >
      <div class="flex items-center gap-2">
        <.icon name="hero-clock" class={["w-3.5 h-3.5", if(@urgent, do: "text-[var(--signal-stop)]", else: "text-[var(--signal-live)]")]} />
        <div style={"font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: #{if @urgent, do: "var(--signal-stop)", else: "var(--signal-live)"};"}>
          {cond do
            @days == 0 -> "TRIAL ENDS TODAY"
            @days == 1 -> "1 DAY LEFT ON TRIAL"
            true -> "#{@days} DAYS LEFT ON TRIAL"
          end}
        </div>
      </div>
      <button
        type="button"
        phx-click="open_settings"
        class="px-3 py-1 rounded-[var(--radius-sm)] cursor-pointer transition-colors"
        style={"font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: #{if @urgent, do: "var(--signal-stop)", else: "var(--brand)"};"}
      >SUBSCRIBE</button>
    </div>
    """
  end

  def trial_expired_banner(assigns) do
    ~H"""
    <div
      :if={TourmanagerV2.Accounts.User.trial_expired?(@current_user) && !TourmanagerV2.Accounts.User.subscribed?(@current_user)}
      class="flex items-center justify-between px-5 py-2.5"
      style="background: var(--paper-200); border-bottom: 1px solid var(--paper-300);"
    >
      <div class="flex items-center gap-2">
        <.icon name="hero-lock-closed-mini" class="w-3.5 h-3.5 text-[var(--ink-400)]" />
        <div style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-500);">
          CREW ACCESS · SUBSCRIBE TO CREATE TOURS
        </div>
      </div>
      <button
        type="button"
        phx-click="open_settings"
        class="px-3 py-1 rounded-[var(--radius-sm)] cursor-pointer transition-colors"
        style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand);"
      >SUBSCRIBE</button>
    </div>
    """
  end

  attr :route_count, :integer, default: 0

  def onboarding_add_stop_nudge(assigns) do
    ~H"""
    <div
      :if={@route_count == 1}
      class="rounded-[var(--radius-md)] p-4 border border-[var(--paper-300)]"
      style="background: var(--surface-card);"
    >
      <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); margin-bottom: 6px;">KEEP GOING</div>
      <div style="font-family: var(--font-display); font-weight: 700; font-size: 16px; color: var(--ink-900);">Add your next stop</div>
      <div class="mt-1.5" style="font-family: var(--font-sans); font-size: 13px; color: var(--ink-400); line-height: 1.4;">
        Add a second venue to see the route. Distance and drive time calculated automatically.
      </div>
    </div>
    """
  end
end
