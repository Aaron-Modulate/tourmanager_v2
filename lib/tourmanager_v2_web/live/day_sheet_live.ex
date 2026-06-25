defmodule TourmanagerV2Web.DaySheetLive do
  use TourmanagerV2Web, :live_view

  @run_of_show [
    %{time: "08:30", label: "Bus arrival", tone: "ink", loc: "Loading dock, Stockwell Rd", done: true, flag: false},
    %{time: "12:00", label: "Crew call / Load in", tone: "load", loc: "Stage door B", done: true, flag: false},
    %{time: "14:30", label: "Local crew + rigging", tone: "load", loc: "Main stage", done: false, flag: false},
    %{time: "16:00", label: "Line check", tone: "sound", loc: "FOH", done: false, flag: false},
    %{time: "17:00", label: "Soundcheck — NOVA RIOT", tone: "sound", loc: "Main stage", done: false, flag: false},
    %{time: "18:30", label: "Catering / Dinner", tone: "ink", loc: "Green room 2", done: false, flag: false},
    %{time: "19:00", label: "Doors", tone: "doors", loc: "FOH", done: false, flag: true},
    %{time: "19:45", label: "Support — WILD CASSETTE", tone: "doors", loc: "Main stage", done: false, flag: false},
    %{time: "21:00", label: "NOVA RIOT — Set", tone: "live", loc: "Main stage", done: false, flag: true},
    %{time: "22:30", label: "Curfew", tone: "stop", loc: "House", done: false, flag: true},
    %{time: "23:30", label: "Load out", tone: "ink", loc: "Stage door B", done: false, flag: false}
  ]

  @crew [
    %{name: "Mara Quinn", role: "Tour Manager", init: "MQ", pass: "AAA", status: "on-site"},
    %{name: "Deshawn Cole", role: "Production Mgr", init: "DC", pass: "AAA", status: "on-site"},
    %{name: "Iris Vöng", role: "FOH Engineer", init: "IV", pass: "CREW", status: "on-site"},
    %{name: "Theo Park", role: "Monitor Eng", init: "TP", pass: "CREW", status: "travel"},
    %{name: "Lena Hart", role: "Lighting Dir", init: "LH", pass: "CREW", status: "on-site"},
    %{name: "Sam Okafor", role: "Backline", init: "SO", pass: "CREW", status: "break"}
  ]

  @alerts [
    %{tone: "stop", text: "Monitor desk firmware mismatch — Theo to confirm spare on arrival.", meta: "PROD · 2h ago"},
    %{tone: "sound", text: "Soundcheck window tight: support overlaps by 15 min.", meta: "SCHED · today"},
    %{tone: "load", text: "Glasgow get-in moved to 11:00 — union crew confirmed.", meta: "ADV · 1d ago"}
  ]

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       active_nav: "daysheet",
       active_tab: "show",
       run_of_show: @run_of_show,
       crew: @crew,
       alerts: @alerts,
       page_title: "Day Sheet"
     )}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_nav={@active_nav}>
      <div id="day-sheet" class="p-7 grid grid-cols-[minmax(0,1.55fr)_minmax(0,1fr)] gap-5 items-start">
        <%!-- Left: run of show --%>
        <div>
          <div class="flex items-center justify-between mb-3.5">
            <div>
              <.overline>Run of show</.overline>
              <.display size={26} class="mt-1.5">Today&rsquo;s schedule</.display>
            </div>
            <.tm_button variant="secondary" size="sm" icon_name="hero-plus">Add</.tm_button>
          </div>

          <.tab_bar
            tabs={[
              %{value: "show", label: "Schedule", count: length(@run_of_show)},
              %{value: "crew", label: "Crew", count: length(@crew)},
              %{value: "notes", label: "Notes"}
            ]}
            active={@active_tab}
            class="mb-4"
          />

          <%!-- Schedule tab --%>
          <div :if={@active_tab == "show"} id="schedule-list" class="flex flex-col">
            <.schedule_row
              :for={row <- @run_of_show}
              time={row.time}
              label={row.label}
              tone={row.tone}
              loc={row.loc}
              done={row.done}
              flag={row.flag}
            />
          </div>

          <%!-- Crew tab --%>
          <div :if={@active_tab == "crew"} id="crew-grid" class="grid grid-cols-2 gap-2.5">
            <.crew_card
              :for={c <- @crew}
              name={c.name}
              role={c.role}
              init={c.init}
              pass_level={c.pass}
              status={c.status}
            />
          </div>

          <%!-- Notes tab --%>
          <div :if={@active_tab == "notes"} id="notes-panel">
            <.stamp_card overline_text="Production notes" halftone>
              <div class="text-[15px] leading-relaxed text-[var(--ink-700)]">
                Stage right wing is tight — keep cases clear of the dimmer beach. House sound limit <b>102 dB(A)</b> at FOH, hard curfew <b>22:30</b>. Local crew of 8 confirmed for load-in; rigging call moved 30 min earlier per the venue.
              </div>
            </.stamp_card>
          </div>
        </div>

        <%!-- Right column --%>
        <div class="flex flex-col gap-[18px]">
          <.stamp_card hard overline_text="Next up" padding="18px">
            <div class="flex items-center justify-between">
              <div>
                <.signal_chip tone="doors" dot>Doors</.signal_chip>
                <.display size={32} class="mt-2.5">19:00</.display>
                <div class="mt-1" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">FOH · IN 1H 46M</div>
              </div>
              <div class="text-right">
                <div style="font-family: var(--font-mono); font-size: 10px; letter-spacing: 0.18em; color: var(--ink-400);">SET</div>
                <.display size={22} class="mt-1">21:00</.display>
              </div>
            </div>
            <.tm_button variant="primary" block icon_name="hero-bell" class="mt-4">Notify crew</.tm_button>
          </.stamp_card>

          <div>
            <.overline style="margin-bottom: 10px;">Alerts</.overline>
            <div class="flex flex-col gap-2">
              <.alert_card :for={a <- @alerts} text={a.text} tone={a.tone} meta={a.meta} />
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
