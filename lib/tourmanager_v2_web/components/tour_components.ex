defmodule TourmanagerV2Web.TourComponents do
  @moduledoc """
  Shared UI components for the Tour Manager design system.
  """
  use Phoenix.Component

  import TourmanagerV2Web.CoreComponents, only: [icon: 1]

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
end
