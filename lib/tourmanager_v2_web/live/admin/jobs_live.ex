defmodule TourmanagerV2Web.Admin.JobsLive do
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  alias TourmanagerV2.Admin

  def mount(_params, _session, socket) do
    user = socket.assigns[:current_user]

    if user && TourmanagerV2.Accounts.User.admin?(user) do
      job = Admin.get_or_create_job("stripe_sync_pricing")

      socket =
        socket
        |> assign(
          active_nav: "admin_jobs",
          tour_menu_open: false,
          settings_open: false,
          new_tour_open: false,
          new_tour_form: nil,
          add_route_open: false,
          add_route_type: "gig",
          add_route_form: nil,
          place_suggestions: [],
          autocomplete_field: nil,
          editing_route: false,
          editing_route_entry: nil,
          billing_seats: user.crew_seats || 10,
          billing_error: nil,
          page_title: "Admin · Jobs",
          job: job,
          job_running: false,
          job_result: nil,
          cron_form: to_form(%{"cron_expression" => job.cron_expression})
        )
        |> load_tour_data(socket.assigns[:current_tour])

      {:ok, socket}
    else
      {:ok, redirect(socket, to: "/")}
    end
  end

  def handle_event("run_job", %{"name" => name}, socket) do
    socket = assign(socket, :job_running, true)

    case Admin.run_job(name) do
      {:ok, data} ->
        job = Admin.get_or_create_job(name)

        {:noreply,
         socket
         |> assign(:job, job)
         |> assign(:job_running, false)
         |> assign(:job_result, {:ok, data})}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:job_running, false)
         |> assign(:job_result, {:error, reason})}
    end
  end

  def handle_event("update_cron", %{"cron_expression" => cron}, socket) do
    case Admin.update_job(socket.assigns.job, %{cron_expression: cron}) do
      {:ok, job} ->
        {:noreply,
         socket
         |> assign(:job, job)
         |> assign(:cron_form, to_form(%{"cron_expression" => job.cron_expression}))}

      {:error, _changeset} ->
        {:noreply, socket}
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
    >
      <div id="admin-jobs" class="p-7 max-w-3xl">
        <div class="mb-5">
          <.overline>Admin</.overline>
          <.display size={26} class="mt-1.5">Jobs</.display>
        </div>

        <%!-- Stripe pricing sync job --%>
        <.stamp_card hard overline_text="Stripe sync pricing" padding="20px">
          <div class="flex items-center justify-between mb-4">
            <div>
              <div style="font-family: var(--font-display); font-weight: 700; font-size: 16px; color: var(--ink-900);">Fetch pricing from Stripe</div>
              <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400); margin-top: 2px;">
                GET /v1/prices/{System.get_env("STRIPE_PRICE_ID") || "—"}
              </div>
            </div>
            <button
              type="button"
              phx-click="run_job"
              phx-value-name="stripe_sync_pricing"
              disabled={@job_running}
              class={[
                "px-4 py-2 rounded-[var(--radius-md)] cursor-pointer transition-all flex items-center gap-2",
                if(@job_running, do: "opacity-50 cursor-not-allowed", else: "")
              ]}
              style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);"
            >
              <.icon name={if @job_running, do: "hero-arrow-path", else: "hero-play"} class={["w-4 h-4", if(@job_running, do: "motion-safe:animate-spin", else: "")]} />
              {if @job_running, do: "RUNNING", else: "RUN NOW"}
            </button>
          </div>

          <%!-- Cron schedule --%>
          <div class="flex items-center gap-3 mb-4 p-3 rounded-[var(--radius-md)] border border-[var(--paper-300)]" style="background: var(--paper-200);">
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">SCHEDULE</div>
            <.form for={@cron_form} phx-submit="update_cron" class="flex items-center gap-2 flex-1">
              <input
                type="text"
                name="cron_expression"
                value={@job.cron_expression}
                class="flex-1 px-3 py-1.5 text-[13px] rounded-[var(--radius-sm)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none"
                style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);"
                placeholder="0 */6 * * *"
              />
              <button
                type="submit"
                class="px-3 py-1.5 rounded-[var(--radius-sm)] cursor-pointer transition-colors"
                style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; color: var(--ink-500); background: var(--surface-card); border: 1px solid var(--paper-300);"
              >SAVE</button>
            </.form>
          </div>

          <%!-- Last run --%>
          <div class="flex items-center gap-3 mb-3" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">
            <.icon name="hero-clock-mini" class="w-3.5 h-3.5" />
            Last run: {if @job.last_run_at, do: Calendar.strftime(@job.last_run_at, "%d %b %Y %H:%M UTC"), else: "Never"}
          </div>

          <%!-- Result --%>
          <%= if @job_result do %>
            <%= case @job_result do %>
              <% {:ok, data} -> %>
                <div class="p-3 rounded-[var(--radius-md)] border border-[var(--paper-300)] overflow-auto max-h-64" style="background: var(--ink-900);">
                  <pre style="font-family: var(--font-mono); font-size: 11px; color: var(--paper-100); white-space: pre-wrap; word-break: break-all;">{Jason.encode!(data, pretty: true)}</pre>
                </div>
              <% {:error, reason} -> %>
                <div class="p-3 rounded-[var(--radius-sm)]" style="background: var(--signal-stop-tint); border: 1px solid var(--signal-stop); font-family: var(--font-mono); font-size: 11px; color: var(--signal-stop);">
                  {inspect(reason)}
                </div>
            <% end %>
          <% else %>
            <%= if @job.last_result do %>
              <div class="p-3 rounded-[var(--radius-md)] border border-[var(--paper-300)] overflow-auto max-h-64" style="background: var(--ink-900);">
                <pre style="font-family: var(--font-mono); font-size: 11px; color: var(--paper-100); white-space: pre-wrap; word-break: break-all;">{@job.last_result}</pre>
              </div>
            <% end %>
          <% end %>
        </.stamp_card>
      </div>
    </Layouts.app>
    """
  end
end
