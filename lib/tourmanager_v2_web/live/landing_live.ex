defmodule TourmanagerV2Web.LandingLive do
  use TourmanagerV2Web, :live_view

  @demo_stops [
    %{day: 1, date: "01 JUL", city: "Auckland", venue: "Spark Arena", code: "AKL", status: "done", type: "gig"},
    %{day: 2, date: "03 JUL", city: "Wellington", venue: "TSB Arena", code: "WLG", status: "done", type: "gig"},
    %{day: 3, date: "04 JUL", city: "—", venue: "Wellington → Christchurch", code: "TRV", status: "today", type: "vehicle_travel"},
    %{day: 4, date: "05 JUL", city: "Christchurch", venue: "Town Hall", code: "CHC", status: "next", type: "gig"},
    %{day: 5, date: "07 JUL", city: "Queenstown", venue: "Memorial Centre", code: "ZQN", status: "upcoming", type: "gig"}
  ]

  @demo_schedule [
    %{time: "08:30", label: "Bus call", tone: "ink", loc: "Hotel lobby", done: true, flag: false},
    %{time: "12:00", label: "Load in", tone: "load", loc: "Stage door", done: true, flag: false},
    %{time: "16:00", label: "Soundcheck", tone: "sound", loc: "Main stage", done: false, flag: false},
    %{time: "19:00", label: "Doors", tone: "doors", loc: "FOH", done: false, flag: true},
    %{time: "20:00", label: "Show", tone: "live", loc: "Main stage", done: false, flag: true},
    %{time: "22:30", label: "Curfew", tone: "stop", loc: "House", done: false, flag: true}
  ]

  def mount(_params, session, socket) do
    user_id = session["user_id"]

    if user_id do
      {:ok, push_navigate(socket, to: "/app")}
    else
      {:ok, assign(socket,
        page_title: "Tour Manager — Tour Routing, Day Sheets & Crew Logistics for Music Tours",
        meta_description: "Plan tour routes, manage day sheets, and coordinate crew for music tours. Google Maps integration, real-time scheduling, and crew management. Free to start, 7-day manager trial.",
        canonical_path: "/",
        demo_stops: @demo_stops,
        demo_schedule: @demo_schedule
      )}
    end
  end

  def render(assigns) do
    ~H"""
    <main style="background: var(--paper-100); color: var(--ink-700); font-family: var(--font-sans); min-height: 100vh;">
      <%!-- Hero section --%>
      <section class="tm-halftone tm-halftone--light relative" style="background: var(--surface-stage); border-bottom: 2px solid var(--ink-900);" aria-label="Tour management software for music tours">
        <div class="relative z-[2] max-w-5xl mx-auto px-6 md:px-10 py-12 md:py-20">
          <div class="flex items-center gap-3 mb-6">
            <span
              class="w-[44px] h-[44px] rounded-[var(--radius-sm)] flex items-center justify-center"
              style="background: var(--brand); box-shadow: var(--shadow-hard-sm); font-family: var(--font-display); font-weight: 800; font-size: 28px; color: #fff;"
            >T</span>
            <div class="leading-none">
              <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; letter-spacing: -0.01em; color: #fff;">TOUR MANAGER</div>
              <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.28em; color: var(--brand); margin-top: 3px;">DAY SHEET OS</div>
            </div>
          </div>

          <h1 style="font-family: var(--font-display); font-weight: 800; font-size: clamp(32px, 6vw, 56px); letter-spacing: -0.02em; line-height: 1.05; color: #fff; max-width: 600px; margin: 0;">
            Tour management software for music tours
          </h1>

          <p class="mt-5 max-w-md" style="font-family: var(--font-sans); font-size: 16px; line-height: 1.6; color: var(--ink-300); margin-bottom: 0;">
            Tour routing, day sheets, and crew logistics for touring artists and production teams. Plan routes with Google Maps, manage gig schedules, and keep your crew informed — a modern alternative to spreadsheets and MasterTour.
          </p>

          <div class="mt-8 flex flex-wrap gap-3">
            <label
              for="auth-modal-trial"
              class="px-6 py-3 rounded-[var(--radius-md)] flex items-center gap-2 cursor-pointer transition-all"
              style="font-family: var(--font-mono); font-size: 13px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);"
            >
              <.icon name="hero-play" class="w-4 h-4" />
              START FREE TRIAL
            </label>
            <label
              for="auth-modal-signin"
              class="px-6 py-3 rounded-[var(--radius-md)] flex items-center gap-2 cursor-pointer transition-all"
              style="font-family: var(--font-mono); font-size: 13px; font-weight: 700; letter-spacing: 0.06em; color: var(--paper-100); background: var(--ink-700); border: 1px solid var(--ink-500);"
            >
              SIGN IN
            </label>
          </div>

          <div class="mt-4" style="font-family: var(--font-mono); font-size: 10px; letter-spacing: 0.06em; color: var(--ink-400);">
            7-day manager trial · No credit card required
          </div>

          <%!-- Auth modal: Start Free Trial --%>
          <input type="checkbox" id="auth-modal-trial" class="hidden peer/trial" />
          <div class="fixed inset-0 z-50 hidden peer-checked/trial:flex items-center justify-center">
            <label for="auth-modal-trial" class="absolute inset-0" style="background: rgba(20, 17, 15, 0.55); backdrop-filter: blur(4px);" />
            <div class="relative z-10 w-full max-w-sm mx-4 rounded-[var(--radius-xl)] overflow-hidden" style="background: var(--surface-card); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard);">
              <div class="px-6 py-5" style="background: var(--surface-stage);">
                <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);">FREE TRIAL</div>
                <div style="font-family: var(--font-display); font-weight: 800; font-size: 22px; color: #fff; margin-top: 4px;">Start your 7-day trial</div>
                <div class="mt-2" style="font-family: var(--font-sans); font-size: 13px; color: var(--ink-300);">Full manager access. No credit card required.</div>
              </div>
              <div class="px-6 py-5 flex flex-col gap-3">
                <.link href="/auth/google" class="w-full px-5 py-3 rounded-[var(--radius-md)] no-underline flex items-center justify-center gap-2.5 transition-all" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);">
                  <.icon name="hero-globe-alt" class="w-4 h-4" /> CONTINUE WITH GOOGLE
                </.link>
                <.link href="/auth/microsoft" class="w-full px-5 py-3 rounded-[var(--radius-md)] no-underline flex items-center justify-center gap-2.5 transition-all" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-700); background: var(--surface-card); border: 1px solid var(--paper-300);">
                  <.icon name="hero-building-office" class="w-4 h-4" /> CONTINUE WITH MICROSOFT
                </.link>
                <div class="flex items-center gap-3 my-1">
                  <div class="flex-1 border-t border-[var(--paper-300)]" />
                  <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300);">OR</div>
                  <div class="flex-1 border-t border-[var(--paper-300)]" />
                </div>
                <form action="/auth/magic_link" method="post" class="flex flex-col gap-2">
                  <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />
                  <input type="email" name="email" placeholder="you@example.com" required class="w-full px-4 py-3 text-[13px] rounded-[var(--radius-md)] outline-none" style="background: var(--paper-200); color: var(--ink-700); font-family: var(--font-mono); border: 1px solid var(--paper-300);" />
                  <button type="submit" class="w-full px-5 py-3 rounded-[var(--radius-md)] cursor-pointer flex items-center justify-center gap-2.5 transition-all" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-500); background: var(--surface-card); border: 1px solid var(--paper-300);">
                    <.icon name="hero-envelope" class="w-4 h-4" /> SIGN IN WITH EMAIL
                  </button>
                </form>
              </div>
              <div class="px-6 pb-5">
                <label for="auth-modal-trial" class="flex items-center justify-center py-2.5 cursor-pointer rounded-[var(--radius-md)]" style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400);">
                  CANCEL
                </label>
              </div>
            </div>
          </div>

          <%!-- Auth modal: Sign In --%>
          <input type="checkbox" id="auth-modal-signin" class="hidden peer/signin" />
          <div class="fixed inset-0 z-50 hidden peer-checked/signin:flex items-center justify-center">
            <label for="auth-modal-signin" class="absolute inset-0" style="background: rgba(20, 17, 15, 0.55); backdrop-filter: blur(4px);" />
            <div class="relative z-10 w-full max-w-sm mx-4 rounded-[var(--radius-xl)] overflow-hidden" style="background: var(--surface-card); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard);">
              <div class="px-6 py-5" style="background: var(--surface-stage);">
                <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);">WELCOME BACK</div>
                <div style="font-family: var(--font-display); font-weight: 800; font-size: 22px; color: #fff; margin-top: 4px;">Sign in</div>
              </div>
              <div class="px-6 py-5 flex flex-col gap-3">
                <.link href="/auth/google" class="w-full px-5 py-3 rounded-[var(--radius-md)] no-underline flex items-center justify-center gap-2.5 transition-all" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);">
                  <.icon name="hero-globe-alt" class="w-4 h-4" /> CONTINUE WITH GOOGLE
                </.link>
                <.link href="/auth/microsoft" class="w-full px-5 py-3 rounded-[var(--radius-md)] no-underline flex items-center justify-center gap-2.5 transition-all" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-700); background: var(--surface-card); border: 1px solid var(--paper-300);">
                  <.icon name="hero-building-office" class="w-4 h-4" /> CONTINUE WITH MICROSOFT
                </.link>
                <div class="flex items-center gap-3 my-1">
                  <div class="flex-1 border-t border-[var(--paper-300)]" />
                  <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-300);">OR</div>
                  <div class="flex-1 border-t border-[var(--paper-300)]" />
                </div>
                <form action="/auth/magic_link" method="post" class="flex flex-col gap-2">
                  <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />
                  <input type="email" name="email" placeholder="you@example.com" required class="w-full px-4 py-3 text-[13px] rounded-[var(--radius-md)] outline-none" style="background: var(--paper-200); color: var(--ink-700); font-family: var(--font-mono); border: 1px solid var(--paper-300);" />
                  <button type="submit" class="w-full px-5 py-3 rounded-[var(--radius-md)] cursor-pointer flex items-center justify-center gap-2.5 transition-all" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-500); background: var(--surface-card); border: 1px solid var(--paper-300);">
                    <.icon name="hero-envelope" class="w-4 h-4" /> SIGN IN WITH EMAIL
                  </button>
                </form>
              </div>
              <div class="px-6 pb-5">
                <label for="auth-modal-signin" class="flex items-center justify-center py-2.5 cursor-pointer rounded-[var(--radius-md)]" style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400);">
                  CANCEL
                </label>
              </div>
            </div>
          </div>
        </div>
      </section>

      <%!-- Live preview section — show real components with demo data --%>
      <section class="max-w-5xl mx-auto px-6 md:px-10 py-12 md:py-16" aria-label="Tour management features preview">
        <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); margin-bottom: 8px;">LIVE PREVIEW</div>
        <h2 style="font-family: var(--font-display); font-weight: 800; font-size: clamp(24px, 4vw, 36px); letter-spacing: -0.02em; color: var(--ink-900); margin: 0 0 24px 0;">
          Tour routing and day sheet management built for the road
        </h2>

        <%!-- Desktop: side by side app previews. Mobile: single preview --%>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <%!-- Day sheet preview --%>
          <div class="rounded-[var(--radius-xl)] overflow-hidden border-2 border-[var(--ink-900)]" style="box-shadow: var(--shadow-hard);">
            <div class="px-4 py-2.5 flex items-center gap-2 border-b border-[var(--ink-900)]" style="background: var(--surface-stage);">
              <div class="flex gap-1.5">
                <span class="w-2.5 h-2.5 rounded-full" style="background: var(--signal-stop);" />
                <span class="w-2.5 h-2.5 rounded-full" style="background: var(--signal-sound);" />
                <span class="w-2.5 h-2.5 rounded-full" style="background: var(--signal-live);" />
              </div>
              <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-300); letter-spacing: 0.06em;">DAY SHEET</div>
            </div>
            <div class="p-4" style="background: var(--surface-card);">
              <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); margin-bottom: 6px;">RUN OF SHOW</div>
              <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: var(--ink-900); margin-bottom: 12px;">Saturday 05 Jul</div>
              <div class="flex flex-col">
                <.schedule_row
                  :for={row <- @demo_schedule}
                  time={row.time}
                  label={row.label}
                  tone={row.tone}
                  loc={row.loc}
                  done={row.done}
                  flag={row.flag}
                />
              </div>
            </div>
          </div>

          <%!-- Routing preview --%>
          <div class="rounded-[var(--radius-xl)] overflow-hidden border-2 border-[var(--ink-900)]" style="box-shadow: var(--shadow-hard);">
            <div class="px-4 py-2.5 flex items-center gap-2 border-b border-[var(--ink-900)]" style="background: var(--surface-stage);">
              <div class="flex gap-1.5">
                <span class="w-2.5 h-2.5 rounded-full" style="background: var(--signal-stop);" />
                <span class="w-2.5 h-2.5 rounded-full" style="background: var(--signal-sound);" />
                <span class="w-2.5 h-2.5 rounded-full" style="background: var(--signal-live);" />
              </div>
              <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-300); letter-spacing: 0.06em;">ROUTING</div>
            </div>
            <div class="p-4" style="background: var(--surface-card);">
              <div class="flex items-center justify-between mb-3">
                <div>
                  <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">NZ SUMMER RUN</div>
                  <div style="font-family: var(--font-display); font-weight: 700; font-size: 18px; color: var(--ink-900);">Auckland → Queenstown</div>
                </div>
                <.signal_chip tone="brand" hard>5 stops</.signal_chip>
              </div>
              <div class="relative pl-2">
                <div class="absolute left-[35px] top-3 bottom-3 w-0.5 bg-[var(--paper-300)]" />
                <%= for stop <- @demo_stops do %>
                  <div class="grid grid-cols-[54px_1fr] gap-4 items-center relative mb-1.5">
                    <div class="text-right leading-tight" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">
                      <div class="font-bold text-[var(--ink-700)]">D{String.pad_leading(to_string(stop.day), 2, "0")}</div>
                      <div class="text-[9px]">{stop.date}</div>
                    </div>
                    <div
                      class={["flex items-center gap-3 px-3 py-2.5 rounded-[var(--radius-md)]",
                        if(stop.status == "today", do: "border-2 border-[var(--ink-900)]", else: "border border-[var(--paper-300)]")
                      ]}
                      style={"background: #{if stop.status == "today", do: "var(--surface-stage)", else: "var(--surface-card)"}; color: #{if stop.status == "today", do: "var(--paper-100)", else: "var(--ink-700)"}; #{if stop.status == "today", do: "box-shadow: var(--shadow-hard-sm);", else: ""}"}
                    >
                      <div class="flex-1 min-w-0">
                        <div style={"font-family: var(--font-display); font-weight: 700; font-size: 15px; color: #{if stop.status == "today", do: "#fff", else: "var(--ink-900)"};"}>{stop.venue}</div>
                        <div style={"font-family: var(--font-mono); font-size: 10px; color: #{if stop.status == "today", do: "var(--ink-300)", else: "var(--ink-400)"};"}>
                          {stop.city} · {stop.code}
                        </div>
                      </div>
                      <.signal_chip
                        :if={stop.status not in ~w(done upcoming)}
                        tone={cond do
                          stop.status == "today" -> "live"
                          stop.status == "next" -> "doors"
                          true -> "load"
                        end}
                        size="sm"
                      >{stop.status}</.signal_chip>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </section>

      <%!-- Features section --%>
      <section style="background: var(--surface-stage); border-top: 2px solid var(--ink-900); border-bottom: 2px solid var(--ink-900);" aria-label="Tour management features">
        <div class="max-w-5xl mx-auto px-6 md:px-10 py-12 md:py-16">
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-8">
            <div>
              <div class="flex items-center gap-2 mb-3">
                <.icon name="hero-map" class="w-5 h-5 text-[var(--brand)]" />
                <div style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.12em; color: var(--brand);">ROUTING</div>
              </div>
              <h3 style="font-family: var(--font-display); font-weight: 700; font-size: 18px; color: #fff; margin: 0 0 6px 0;">Plan tour routes with Google Maps</h3>
              <div style="font-family: var(--font-sans); font-size: 14px; color: var(--ink-300); line-height: 1.5;">
                Add gigs, travel days, and off days. Google Maps integration shows distances and drive times between every stop.
              </div>
            </div>
            <div>
              <div class="flex items-center gap-2 mb-3">
                <.icon name="hero-clipboard-document-list" class="w-5 h-5 text-[var(--brand)]" />
                <div style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.12em; color: var(--brand);">DAY SHEET</div>
              </div>
              <h3 style="font-family: var(--font-display); font-weight: 700; font-size: 18px; color: #fff; margin: 0 0 6px 0;">Day sheets and run of show scheduling</h3>
              <div style="font-family: var(--font-sans); font-size: 14px; color: var(--ink-300); line-height: 1.5;">
                Times, locations, and statuses for every moment of gig day. Call sheet format your crew already knows.
              </div>
            </div>
            <div>
              <div class="flex items-center gap-2 mb-3">
                <.icon name="hero-users" class="w-5 h-5 text-[var(--brand)]" />
                <div style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; letter-spacing: 0.12em; color: var(--brand);">CREW</div>
              </div>
              <h3 style="font-family: var(--font-display); font-weight: 700; font-size: 18px; color: #fff; margin: 0 0 6px 0;">Crew management and logistics</h3>
              <div style="font-family: var(--font-sans); font-size: 14px; color: var(--ink-300); line-height: 1.5;">
                Invite crew members who see exactly what they need. Managers run the show, crew stays informed.
              </div>
            </div>
          </div>
        </div>
      </section>

      <%!-- Pricing section --%>
      <section class="max-w-5xl mx-auto px-6 md:px-10 py-12 md:py-16" aria-label="Tour manager pricing plans">
        <div class="text-center mb-10">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); margin-bottom: 8px;">PRICING</div>
          <h2 style="font-family: var(--font-display); font-weight: 800; font-size: clamp(24px, 4vw, 32px); letter-spacing: -0.02em; color: var(--ink-900); margin: 0;">
            Tour management software pricing — start free
          </h2>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-5 max-w-2xl mx-auto">
          <%!-- Crew tier --%>
          <div class="rounded-[var(--radius-md)] p-6 border border-[var(--paper-300)]" style="background: var(--surface-card);">
            <div style="font-family: var(--font-display); font-weight: 700; font-size: 20px; color: var(--ink-900);">Crew</div>
            <div class="mt-1" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">Free forever</div>
            <div class="mt-4 flex flex-col gap-2">
              <div :for={f <- ["View assigned tours", "Day sheet access", "Schedule and alerts"]} class="flex items-center gap-2" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-500);">
                <.icon name="hero-check-mini" class="w-3.5 h-3.5 text-[var(--ink-300)]" />
                {f}
              </div>
            </div>
          </div>

          <%!-- Manager tier --%>
          <div class="rounded-[var(--radius-md)] p-6 border-2 border-[var(--brand)]" style="background: var(--marker-050); box-shadow: var(--shadow-hard-sm);">
            <div class="flex items-center gap-2">
              <div style="font-family: var(--font-display); font-weight: 700; font-size: 20px; color: var(--ink-900);">Manager</div>
              <span class="px-2 py-0.5 rounded-[var(--radius-stamp)]" style="background: var(--brand); color: #fff; font-family: var(--font-mono); font-weight: 700; font-size: 9px; letter-spacing: 0.1em;">7-DAY TRIAL</span>
            </div>
            <div class="mt-1" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">From $49 NZD/mo · 10 crew seats</div>
            <div class="mt-4 flex flex-col gap-2">
              <div :for={f <- ["Everything in Crew", "Create and manage tours", "Invite crew members", "Google Maps integration", "Full admin controls"]} class="flex items-center gap-2" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-500);">
                <.icon name="hero-check-mini" class="w-3.5 h-3.5 text-[var(--brand)]" />
                {f}
              </div>
            </div>
          </div>
        </div>
      </section>

      <%!-- Footer CTA --%>
      <section class="tm-halftone tm-halftone--light" style="background: var(--surface-stage); border-top: 2px solid var(--ink-900);" aria-label="Start your free trial">
        <div class="max-w-5xl mx-auto px-6 md:px-10 py-12 text-center">
          <div class="relative z-[2]">
            <h2 style="font-family: var(--font-display); font-weight: 800; font-size: clamp(24px, 4vw, 36px); letter-spacing: -0.02em; color: #fff; margin: 0;">
              Start managing your tour today
            </h2>
            <p class="mt-3" style="font-family: var(--font-sans); font-size: 15px; color: var(--ink-300); margin-bottom: 0;">
              7-day manager trial. No credit card. Set up your first tour in under a minute.
            </p>
            <div class="mt-6 flex flex-wrap justify-center gap-3">
              <label
                for="auth-modal-trial"
                class="px-8 py-3.5 rounded-[var(--radius-md)] flex items-center gap-2 cursor-pointer transition-all"
                style="font-family: var(--font-mono); font-size: 14px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard);"
              >
                <.icon name="hero-play" class="w-5 h-5" />
                START FREE TRIAL
              </label>
              <label
                for="auth-modal-signin"
                class="px-8 py-3.5 rounded-[var(--radius-md)] flex items-center gap-2 cursor-pointer transition-all"
                style="font-family: var(--font-mono); font-size: 14px; font-weight: 700; letter-spacing: 0.06em; color: var(--paper-100); background: var(--ink-700); border: 1px solid var(--ink-500);"
              >
                SIGN IN
              </label>
            </div>
          </div>
        </div>
      </section>
    </main>
    """
  end
end
