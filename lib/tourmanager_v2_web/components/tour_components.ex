defmodule TourmanagerV2Web.TourComponents do
  @moduledoc """
  Shared UI components for the Tour Manager design system.
  """
  use Phoenix.Component

  import TourmanagerV2Web.CoreComponents, only: [icon: 1, input: 1]

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
    <div class={["flex gap-1 border-b-2 border-[var(--paper-300)] pb-0", @class]} role="tablist">
      <button
        :for={tab <- @tabs}
        type="button"
        role="tab"
        phx-click="switch_tab"
        phx-value-tab={tab.value}
        class={[
          "px-4 py-2 -mb-[2px] border-b-2 cursor-pointer transition-colors",
          if(tab.value == @active,
            do: "border-[var(--brand)] text-[var(--ink-900)] font-semibold",
            else: "border-transparent text-[var(--ink-400)] hover:text-[var(--ink-700)]"
          )
        ]}
        style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase;"
      >
        {tab.label}
        <span
          :if={Map.has_key?(tab, :count)}
          class={[
            "ml-2 px-1.5 py-0.5 rounded text-[10px]",
            if(tab.value == @active,
              do: "bg-[var(--brand)] text-white",
              else: "bg-[var(--paper-200)] text-[var(--ink-400)]"
            )
          ]}
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

  attr :time, :string, required: true
  attr :label, :string, required: true
  attr :tone, :string, required: true
  attr :loc, :string, required: true
  attr :done, :boolean, default: false
  attr :flag, :boolean, default: false

  def schedule_row(assigns) do
    ~H"""
    <div
      class={["grid grid-cols-[64px_14px_1fr_auto] gap-3.5 items-center px-3 py-2.5 rounded-[var(--radius-sm)]", if(@flag, do: "bg-[var(--surface-card)] border border-[var(--paper-300)]", else: "border border-transparent")]}
      style={if @done, do: "opacity: 0.5;", else: ""}
    >
      <div style="font-family: var(--font-mono); font-weight: 700; font-size: 16px; color: var(--ink-900); letter-spacing: -0.01em;">
        {@time}
      </div>
      <div
        class="w-2.5 h-2.5 rounded-full justify-self-center"
        style={"background: var(--signal-#{if @tone == "ink", do: "load", else: @tone}); opacity: #{if @tone == "ink", do: "0.25", else: "1"};"}
      />
      <div>
        <div class={["text-[15px] font-semibold text-[var(--ink-900)]", if(@done, do: "line-through", else: "")]}>
          {@label}
        </div>
        <div class="flex items-center gap-1.5 mt-0.5" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">
          <.icon name="hero-map-pin-mini" class="w-3 h-3" /> {@loc}
        </div>
      </div>
      <.signal_chip :if={@flag} tone={@tone} hard>
        {cond do
          @tone == "live" -> "Key"
          @tone == "stop" -> "Hard"
          true -> "Flag"
        end}
      </.signal_chip>
      <span :if={!@flag} />
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

  attr :day, :integer, required: true
  attr :date, :string, required: true
  attr :city, :string, required: true
  attr :venue, :string, required: true
  attr :code, :string, required: true
  attr :km, :integer, required: true
  attr :status, :string, required: true

  def route_stop(assigns) do
    is_today = assigns.status == "today"
    assigns = assign(assigns, :is_today, is_today)

    ~H"""
    <div class="grid grid-cols-[54px_1fr] gap-4 items-center relative mb-1.5">
      <div class="text-right leading-tight" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">
        <div class="font-bold text-[var(--ink-700)]">D{String.pad_leading(to_string(@day), 2, "0")}</div>
        <div class="text-[9px]">{@date}</div>
      </div>
      <div
        class={["flex items-center gap-3.5 px-3.5 py-3 rounded-[var(--radius-md)]",
          if(@is_today, do: "border-2 border-[var(--ink-900)]", else: "border border-[var(--paper-300)]")
        ]}
        style={"background: #{if @is_today, do: "var(--surface-stage)", else: "var(--surface-card)"}; color: #{if @is_today, do: "var(--paper-100)", else: "var(--ink-700)"}; #{if @is_today, do: "box-shadow: var(--shadow-hard);", else: ""}"}
      >
        <span
          class="w-3 h-3 flex-none rounded-full border-2 border-[var(--paper-50)]"
          style={"background: var(--signal-#{route_tone(@status)}); opacity: #{if @status == "done", do: "0.3", else: "1"}; box-shadow: 0 0 0 2px var(--paper-300);"}
        />
        <div class="flex-1 min-w-0">
          <div
            style={"font-family: var(--font-display); font-weight: 700; font-size: 17px; letter-spacing: -0.01em; color: #{if @is_today, do: "#fff", else: "var(--ink-900)"};"}
          >
            {@city}
          </div>
          <div style={"font-family: var(--font-mono); font-size: 10.5px; letter-spacing: 0.04em; color: #{if @is_today, do: "var(--ink-300)", else: "var(--ink-400)"};"}>{@venue} · {@code}</div>
        </div>
        <div :if={@km > 0} class="flex items-center gap-1" style={"font-family: var(--font-mono); font-size: 10px; color: #{if @is_today, do: "var(--ink-300)", else: "var(--ink-400)"}"}>
          <.icon name="hero-truck-mini" class="w-3 h-3" /> {@km}km
        </div>
        <.signal_chip :if={@status != "done"} tone={route_tone(@status)} size="sm">
          {@status}
        </.signal_chip>
      </div>
    </div>
    """
  end

  defp route_tone("today"), do: "live"
  defp route_tone("next"), do: "doors"
  defp route_tone("upcoming"), do: "load"
  defp route_tone("hold"), do: "load"
  defp route_tone(_), do: "load"

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
        class="relative z-10 w-full max-w-[480px] mx-4 rounded-[var(--radius-xl)] overflow-hidden"
        style="background: var(--surface-card); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard);"
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
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);">SETTINGS</div>
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
              <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-500);">{@billing.extra_seats} extra seat{if @billing.extra_seats != 1, do: "s", else: ""} × $2</div>
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
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);">NEW</div>
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

  def route_stop_enhanced(assigns) do
    is_today = assigns.status == "today"
    assigns = assign(assigns, :is_today, is_today)

    ~H"""
    <div class="relative mb-1.5">
      <%!-- Distance connector between stops --%>
      <div
        :if={@distance_label}
        class="flex items-center gap-2 ml-[70px] mb-1 py-1"
      >
        <div class="flex-1 h-px bg-[var(--paper-300)]" />
        <div class="flex items-center gap-1.5 px-2 py-0.5 rounded-[var(--radius-stamp)]" style="background: var(--paper-200);">
          <.icon name="hero-truck-mini" class="w-3 h-3 text-[var(--ink-400)]" />
          <span style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; color: var(--ink-500); letter-spacing: 0.04em;">
            {@distance_label}
          </span>
        </div>
        <div class="flex-1 h-px bg-[var(--paper-300)]" />
      </div>

      <div class="grid grid-cols-[54px_1fr] gap-4 items-center">
        <div class="text-right leading-tight" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">
          <div class="font-bold text-[var(--ink-700)]">D{String.pad_leading(to_string(@day), 2, "0")}</div>
          <div class="text-[9px]">{@date}</div>
        </div>
        <div
          class={["flex items-center gap-3.5 px-3.5 py-3 rounded-[var(--radius-md)]",
            if(@is_today, do: "border-2 border-[var(--ink-900)]", else: "border border-[var(--paper-300)]")
          ]}
          style={"background: #{if @is_today, do: "var(--surface-stage)", else: "var(--surface-card)"}; color: #{if @is_today, do: "var(--paper-100)", else: "var(--ink-700)"}; #{if @is_today, do: "box-shadow: var(--shadow-hard);", else: ""}"}
        >
          <%!-- Venue thumbnail --%>
          <img
            :if={@venue_image_url && @type == "gig"}
            src={@venue_image_url}
            class="w-12 h-12 rounded-[var(--radius-sm)] object-cover flex-none"
            style="border: 1px solid var(--paper-300);"
            loading="lazy"
          />

          <%!-- Type icon for non-gig entries --%>
          <span
            :if={@type != "gig"}
            class="w-12 h-12 rounded-[var(--radius-sm)] flex items-center justify-center flex-none"
            style={"background: #{if @type == "vehicle_travel", do: "var(--signal-load-tint)", else: "var(--paper-200)"}; border: 1px solid var(--paper-300);"}
          >
            <.icon
              name={if @type == "vehicle_travel", do: "hero-truck", else: "hero-moon"}
              class={["w-5 h-5", if(@type == "vehicle_travel", do: "text-[var(--signal-load)]", else: "text-[var(--ink-400)]")]}
            />
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
                  true -> "Off day"
                end}
              </div>
              <.signal_chip
                :if={@type != "gig"}
                tone={if @type == "vehicle_travel", do: "load", else: "ink"}
                size="sm"
                variant="tint"
              >
                TRAVEL
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
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);">
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
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">DATE</label>
              <.input field={@form[:date]} type="date" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none transition-colors" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
            </div>
          <% end %>

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

  defp initials(name) when is_binary(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
  end

  defp initials(_), do: "?"
end
