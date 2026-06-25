defmodule TourmanagerV2Web.DashboardLive do
  use TourmanagerV2Web, :live_view

  @metrics [
    %{k: "Shows played", v: "13", sub: "of 28"},
    %{k: "Capacity sold", v: "94%", sub: "avg run"},
    %{k: "Days on road", v: "14", sub: "of 60"},
    %{k: "Open advances", v: "06", sub: "2 urgent"}
  ]

  @advances [
    %{city: "Manchester", code: "MAN", pct: 90, tone: "live", open: 1},
    %{city: "Glasgow", code: "GLA", pct: 60, tone: "sound", open: 3},
    %{city: "Dublin", code: "DUB", pct: 35, tone: "stop", open: 5}
  ]

  @crew [
    %{name: "Mara Quinn", role: "Tour Manager", init: "MQ", pass: "AAA", status: "on-site"},
    %{name: "Deshawn Cole", role: "Production Mgr", init: "DC", pass: "AAA", status: "on-site"},
    %{name: "Iris Vöng", role: "FOH Engineer", init: "IV", pass: "CREW", status: "on-site"},
    %{name: "Theo Park", role: "Monitor Eng", init: "TP", pass: "CREW", status: "travel"}
  ]

  @priority_alert %{
    tone: "stop",
    text: "Monitor desk firmware mismatch — Theo to confirm spare on arrival."
  }

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       active_nav: "dashboard",
       metrics: @metrics,
       advances: @advances,
       crew: @crew,
       priority_alert: @priority_alert,
       page_title: "Dashboard"
     )}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_nav={@active_nav}>
      <div id="dashboard" class="p-7">
        <div class="flex items-end justify-between mb-5">
          <div>
            <.overline>Management</.overline>
            <.display size={26} class="mt-1.5">Tour at a glance</.display>
          </div>
          <.tm_button variant="secondary" size="sm" icon_name="hero-arrow-down-tray">Export sheet</.tm_button>
        </div>

        <%!-- Metric row --%>
        <div id="metrics-row" class="grid grid-cols-4 gap-3.5 mb-5">
          <.metric_card
            :for={{m, i} <- Enum.with_index(@metrics)}
            label={m.k}
            value={m.v}
            sub={m.sub}
            featured={i == 0}
          />
        </div>

        <div class="grid grid-cols-[minmax(0,1.3fr)_minmax(0,1fr)] gap-5 items-start">
          <%!-- Advancing progress --%>
          <.stamp_card overline_text="Advancing — upcoming">
            <div class="flex flex-col gap-4">
              <.advance_row
                :for={a <- @advances}
                city={a.city}
                code={a.code}
                pct={a.pct}
                tone={a.tone}
                open={a.open}
              />
            </div>
          </.stamp_card>

          <%!-- Crew + Priority --%>
          <div class="flex flex-col gap-[18px]">
            <.stamp_card overline_text="Crew on duty">
              <div class="flex flex-col gap-3">
                <div :for={c <- @crew} class="flex items-center gap-3">
                  <.pass init={c.init} tone={if c.pass == "AAA", do: "brand", else: "ink"} size={30} />
                  <div class="flex-1">
                    <div class="text-[13.5px] font-semibold text-[var(--ink-900)]">{c.name}</div>
                    <div style="font-family: var(--font-mono); font-size: 9.5px; letter-spacing: 0.06em; color: var(--ink-400); text-transform: uppercase;">{c.role}</div>
                  </div>
                  <.signal_chip
                    tone={cond do
                      c.status == "on-site" -> "live"
                      c.status == "travel" -> "load"
                      true -> "sound"
                    end}
                    variant="tint"
                    size="sm"
                  >
                    {c.status}
                  </.signal_chip>
                </div>
              </div>
            </.stamp_card>

            <%!-- Priority alert --%>
            <div
              class="tm-halftone tm-halftone--light relative p-[18px] rounded-[var(--radius-md)] border-2 border-[var(--ink-900)]"
              style="background: var(--surface-stage); color: var(--paper-100);"
            >
              <div class="relative z-[2]">
                <div class="flex items-center justify-between">
                  <.overline style="color: var(--brand);">Priority</.overline>
                  <.signal_chip tone="stop" hard size="sm">1 urgent</.signal_chip>
                </div>
                <div class="text-[15px] leading-normal text-[var(--paper-100)] mt-2.5">
                  {@priority_alert.text}
                </div>
                <.tm_button variant="primary" size="sm" icon_name="hero-arrow-right" class="mt-3.5">Resolve</.tm_button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
