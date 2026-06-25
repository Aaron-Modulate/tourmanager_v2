defmodule TourmanagerV2Web.RoutingLive do
  use TourmanagerV2Web, :live_view

  @route [
    %{day: 11, date: "21 JUN", city: "Paris", venue: "L'Olympia", code: "PAR", km: 0, status: "done"},
    %{day: 12, date: "22 JUN", city: "Brussels", venue: "AB", code: "BRU", km: 264, status: "done"},
    %{day: 13, date: "23 JUN", city: "Amsterdam", venue: "Paradiso", code: "AMS", km: 209, status: "done"},
    %{day: 14, date: "25 JUN", city: "London", venue: "Brixton Academy", code: "LON", km: 358, status: "today"},
    %{day: 15, date: "27 JUN", city: "Manchester", venue: "Albert Hall", code: "MAN", km: 325, status: "next"},
    %{day: 16, date: "28 JUN", city: "Glasgow", venue: "Barrowland", code: "GLA", km: 345, status: "hold"},
    %{day: 17, date: "30 JUN", city: "Dublin", venue: "3Olympia", code: "DUB", km: 470, status: "hold"}
  ]

  def mount(_params, _session, socket) do
    total_km = Enum.reduce(@route, 0, fn r, acc -> acc + r.km end)

    {:ok,
     assign(socket,
       active_nav: "routing",
       route: @route,
       total_km: total_km,
       page_title: "Routing"
     )}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_nav={@active_nav}>
      <div id="routing" class="p-7 grid grid-cols-[minmax(0,1fr)_minmax(0,1fr)] gap-5 items-start">
        <%!-- Left: the road list --%>
        <div>
          <div class="flex items-end justify-between mb-[18px]">
            <div>
              <.overline>Routing</.overline>
              <.display size={26} class="mt-1.5">The road</.display>
            </div>
            <div class="text-right" style="font-family: var(--font-mono);">
              <div style="font-size: 10px; letter-spacing: 0.18em; color: var(--ink-400);">TOTAL DRIVE</div>
              <div style="font-size: 18px; font-weight: 700; color: var(--ink-900);">{@total_km} KM</div>
            </div>
          </div>

          <div class="relative pl-2">
            <%!-- vertical road line --%>
            <div class="absolute left-[35px] top-3 bottom-3 w-0.5 bg-[var(--paper-300)]" />

            <.route_stop
              :for={r <- @route}
              day={r.day}
              date={r.date}
              city={r.city}
              venue={r.venue}
              code={r.code}
              km={r.km}
              status={r.status}
            />
          </div>
        </div>

        <%!-- Right: poster map panel --%>
        <div class="flex flex-col gap-[18px] sticky top-0">
          <%!-- Map panel --%>
          <div
            class="tm-halftone tm-halftone--light relative rounded-[var(--radius-md)] overflow-hidden border-2 border-[var(--ink-900)] flex flex-col justify-between p-5 min-h-[280px]"
            style="background: var(--surface-stage); box-shadow: var(--shadow-hard);"
          >
            <div class="relative z-[2] flex justify-between items-start">
              <div>
                <div style="font-family: var(--font-mono); font-size: 10px; letter-spacing: 0.22em; color: var(--brand);">LEG 02 · UK RUN</div>
                <.display size={28} class="mt-1.5" style="color: #fff;">Paris → Dublin</.display>
              </div>
              <.signal_chip tone="brand" hard>7 stops</.signal_chip>
            </div>
            <%!-- Node strip --%>
            <div class="relative z-[2] flex items-center justify-between mt-6">
              <%= for {r, i} <- Enum.with_index(@route) do %>
                <div class="flex flex-col items-center gap-1.5">
                  <span
                    class="w-[11px] h-[11px] rounded-full"
                    style={"background: #{cond do
                      r.status == "today" -> "var(--brand)"
                      r.status == "done" -> "var(--ink-500)"
                      true -> "var(--paper-100)"
                    end};"}
                  />
                  <span style={"font-family: var(--font-mono); font-size: 9px; font-weight: 700; color: #{if r.status == "today", do: "#fff", else: "var(--ink-300)"};"}>
                    {r.code}
                  </span>
                </div>
                <div :if={i < length(@route) - 1} class="flex-1 h-0.5 bg-[var(--ink-700)] mx-0.5 mb-4" />
              <% end %>
            </div>
          </div>

          <%!-- Next move --%>
          <.stamp_card hard overline_text="Next move" padding="18px">
            <div class="flex items-center gap-3.5">
              <.pass init="MAN" tone="brand" size={46} />
              <div class="flex-1">
                <.display size={20}>Manchester</.display>
                <div class="mt-1" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">ALBERT HALL · 325 KM · ~3H40</div>
              </div>
              <.signal_chip tone="doors">D15</.signal_chip>
            </div>
            <.tm_button variant="stage" block icon_name="hero-arrow-right" class="mt-4">Open route brief</.tm_button>
          </.stamp_card>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
