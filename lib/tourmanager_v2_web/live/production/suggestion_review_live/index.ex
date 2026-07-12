defmodule TourmanagerV2Web.SuggestionReviewLive.Index do
  @moduledoc "Venue admin dashboard for reviewing pending correction suggestions."
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  alias TourmanagerV2.Production.{Profiles, Suggestions}

  def mount(%{"venue_id" => venue_id}, _session, socket) do
    user = socket.assigns.current_user

    venue = Profiles.get_venue!(venue_id)
    is_admin = user && Profiles.platform_admin?(user)

    unless is_admin do
      {:ok, socket |> put_flash(:error, "Access denied.") |> push_navigate(to: "/production/venues/#{venue_id}")}
    else
      socket =
        socket
        |> assign(TourSwitching.default_assigns())
        |> assign(
          active_nav: "production",
          page_title: "Suggestions — #{venue.name}",
          venue: venue,
          pending: Suggestions.list_pending_suggestions(venue_id),
          reviewed: Suggestions.list_reviewed_suggestions(venue_id),
          reject_modal_open: false,
          reject_suggestion_id: nil,
          reject_reason: ""
        )
        |> TourSwitching.load_tour_data(socket.assigns[:current_tour])

      {:ok, socket}
    end
  end

  def handle_event("accept_suggestion", %{"id" => id}, socket) do
    user = socket.assigns.current_user

    case Suggestions.accept_suggestion(id, user.id) do
      {:ok, _} ->
        venue_id = socket.assigns.venue.id
        {:noreply,
         socket
         |> assign(:pending, Suggestions.list_pending_suggestions(venue_id))
         |> assign(:reviewed, Suggestions.list_reviewed_suggestions(venue_id))
         |> put_flash(:info, "Suggestion accepted and applied.")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "Not authorized.")}

      _ ->
        {:noreply, put_flash(socket, :error, "Could not apply suggestion.")}
    end
  end

  def handle_event("open_reject", %{"id" => id}, socket) do
    {:noreply, socket |> assign(:reject_modal_open, true) |> assign(:reject_suggestion_id, id) |> assign(:reject_reason, "")}
  end

  def handle_event("close_reject", _params, socket) do
    {:noreply, assign(socket, :reject_modal_open, false)}
  end

  def handle_event("set_reject_reason", %{"value" => reason}, socket) do
    {:noreply, assign(socket, :reject_reason, reason)}
  end

  def handle_event("confirm_reject", _params, socket) do
    user = socket.assigns.current_user
    id = socket.assigns.reject_suggestion_id
    reason = socket.assigns.reject_reason

    case Suggestions.reject_suggestion(id, user.id, reason) do
      {:ok, _} ->
        venue_id = socket.assigns.venue.id
        {:noreply,
         socket
         |> assign(:pending, Suggestions.list_pending_suggestions(venue_id))
         |> assign(:reviewed, Suggestions.list_reviewed_suggestions(venue_id))
         |> assign(:reject_modal_open, false)
         |> put_flash(:info, "Suggestion rejected.")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "Not authorized.")}

      _ ->
        {:noreply, put_flash(socket, :error, "Could not reject suggestion.")}
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
      manage_tour_open={@manage_tour_open}
      manage_tour_form={@manage_tour_form}
      calendar_modal_open={@calendar_modal_open}
      calendar_token={@calendar_token}
      calendar_mode={@calendar_mode}
    >
      <div class="p-4 md:p-7 max-w-4xl">
        <%!-- Header --%>
        <div class="mb-6">
          <.drilldown_breadcrumb
            back_label={String.upcase(@venue.name)}
            navigate={"/production/venues/#{@venue.id}"}
            current_label="SUGGESTIONS"
          />
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 26px; letter-spacing: -0.01em; color: var(--ink-900);">Correction Review</div>
        </div>

        <%!-- Pending suggestions --%>
        <div class="mb-8">
          <div class="flex items-center gap-2 mb-3">
            <span style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">PENDING</span>
            <.signal_chip tone="doors" size="sm" variant="tint">{length(@pending)}</.signal_chip>
          </div>

          <%= if @pending == [] do %>
            <div class="py-10 text-center rounded-[var(--radius-md)] border border-dashed border-[var(--paper-300)]">
              <.icon name="hero-check-circle" class="w-8 h-8 text-[var(--signal-live)] mx-auto mb-2" />
              <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">All caught up — no pending suggestions.</div>
            </div>
          <% else %>
            <div class="flex flex-col gap-3">
              <div :for={s <- @pending} class="rounded-[var(--radius-md)] border border-[var(--paper-300)] overflow-hidden" style="background: var(--surface-card);">
                <div class="px-4 py-3 border-b border-[var(--paper-300)]" style="background: var(--paper-200);">
                  <div class="flex items-center gap-2 flex-wrap">
                    <.signal_chip tone="ink" size="sm" variant="tint">{String.upcase(s.target_type)}</.signal_chip>
                    <span style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; color: var(--ink-900);">{s.field_name}</span>
                    <span class="flex-1" />
                    <span style="font-family: var(--font-mono); font-size: 9px; color: var(--ink-400);">
                      {if s.submitted_by_user, do: s.submitted_by_user.name, else: "Unknown"}
                      · {Calendar.strftime(s.inserted_at, "%d %b %Y")}
                    </span>
                  </div>
                </div>
                <div class="px-4 py-3 grid grid-cols-2 gap-4">
                  <div>
                    <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.15em; color: var(--ink-400); margin-bottom: 4px;">CURRENT VALUE</div>
                    <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-500);">{s.current_value || "No data"}</div>
                  </div>
                  <div>
                    <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.15em; color: var(--ink-400); margin-bottom: 4px;">SUGGESTED VALUE</div>
                    <div style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; color: var(--ink-900);">{s.suggested_value}</div>
                  </div>
                </div>
                <%= if s.evidence_note do %>
                  <div class="px-4 pb-3">
                    <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.15em; color: var(--ink-400); margin-bottom: 4px;">EVIDENCE</div>
                    <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-700);">{s.evidence_note}</div>
                  </div>
                <% end %>
                <div class="px-4 pb-4 flex gap-2">
                  <.tm_button variant="primary" size="sm" icon_name="hero-check-mini" phx-click="accept_suggestion" phx-value-id={s.id}>Accept</.tm_button>
                  <.tm_button variant="ghost" size="sm" icon_name="hero-x-mark-mini" phx-click="open_reject" phx-value-id={s.id}>Reject</.tm_button>
                </div>
              </div>
            </div>
          <% end %>
        </div>

        <%!-- Reviewed history --%>
        <div>
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); margin-bottom: 12px;">HISTORY</div>

          <%= if @reviewed == [] do %>
            <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">No reviewed suggestions yet.</div>
          <% else %>
            <div class="flex flex-col gap-2">
              <div :for={s <- @reviewed} class="flex items-center gap-3 px-3 py-2.5 rounded-[var(--radius-sm)] border border-[var(--paper-300)]" style="background: var(--surface-card);">
                <.signal_chip tone={if s.status == "accepted", do: "live", else: "stop"} size="sm" variant="tint">
                  {String.upcase(s.status)}
                </.signal_chip>
                <div class="flex-1 min-w-0">
                  <div style="font-family: var(--font-mono); font-size: 10px; font-weight: 700; color: var(--ink-900);">{s.field_name} → {s.suggested_value}</div>
                  <div style="font-family: var(--font-mono); font-size: 9px; color: var(--ink-400);">
                    by {if s.submitted_by_user, do: s.submitted_by_user.name, else: "?"}
                    · reviewed {if s.reviewed_at, do: Calendar.strftime(s.reviewed_at, "%d %b %Y"), else: ""}
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <%!-- Reject reason modal --%>
      <.tm_modal id="reject-modal" show={@reject_modal_open} on_close="close_reject">
        <div class="px-6 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--signal-stop);">REJECT</div>
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; margin-top: 2px;">Reject suggestion</div>
        </div>
        <div class="px-6 py-5">
          <div class="mb-4">
            <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">REASON (OPTIONAL)</label>
            <textarea
              phx-input="set_reject_reason"
              placeholder="e.g. We have confirmed the current value is correct."
              rows="3"
              class="w-full px-3 py-2.5 rounded-[var(--radius-md)] border border-[var(--paper-300)] text-[12px] outline-none focus:border-[var(--brand)] resize-none"
              style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);"
            ></textarea>
          </div>
          <div class="flex justify-end gap-3">
            <.tm_button variant="ghost" size="sm" phx-click="close_reject">Cancel</.tm_button>
            <.tm_button variant="primary" size="sm" phx-click="confirm_reject">Confirm reject</.tm_button>
          </div>
        </div>
      </.tm_modal>
    </Layouts.app>
    """
  end
end
