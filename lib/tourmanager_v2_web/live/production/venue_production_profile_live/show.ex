defmodule TourmanagerV2Web.VenueProductionProfileLive.Show do
  @moduledoc "Shows a venue's full production profile. Venue admins can edit inline; tour users can suggest corrections."
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  alias TourmanagerV2.Production.{Profiles, Documents, Suggestions}
  alias TourmanagerV2.Production.{VenueProductionProfile, RiggingPoint, PowerService}

  def mount(%{"id" => venue_id}, _session, socket) do
    venue = Profiles.get_venue_with_production_data(venue_id)
    user = socket.assigns.current_user

    if is_nil(venue) do
      {:ok, push_navigate(socket, to: "/production/venues")}
    else
      is_admin = user && Profiles.platform_admin?(user)
      pending_count = Suggestions.count_pending_by_field(venue_id, "profile", nil, "stage_width_m") +
                      Suggestions.count_pending_by_field(venue_id, "profile", nil, "stage_depth_m") +
                      Suggestions.count_pending_by_field(venue_id, "profile", nil, "trim_height_m")

      socket =
        socket
        |> assign(TourSwitching.default_assigns())
        |> assign(
          active_nav: "production",
          page_title: venue.name,
          venue: venue,
          is_admin: is_admin,
          pending_count: pending_count,
          # section open/closed state
          stage_expanded: true,
          truss_expanded: false,
          rigging_expanded: false,
          power_expanded: false,
          loading_expanded: false,
          lighting_expanded: false,
          documents_expanded: true,
          # edit modal
          edit_section: nil,
          edit_form: nil,
          # suggest modal
          suggest_open: false,
          suggest_target_type: "profile",
          suggest_target_id: nil,
          suggest_field: nil,
          suggest_current_value: nil,
          suggest_form: nil,
          # document upload
          upload_open: false,
          upload_form: nil
        )
        |> TourSwitching.load_tour_data(socket.assigns[:current_tour])
        |> allow_upload(:production_document,
            accept: ~w(.pdf .dwg .dxf .jpg .jpeg .png .svg .zip),
            max_entries: 1,
            max_file_size: 50_000_000
          )

      {:ok, socket}
    end
  end

  # ---------------------------------------------------------------------------
  # Collapsible sections
  # ---------------------------------------------------------------------------

  def handle_event("toggle_section", %{"section" => section}, socket) do
    key = String.to_existing_atom("#{section}_expanded")
    {:noreply, assign(socket, key, !Map.get(socket.assigns, key, false))}
  end

  # ---------------------------------------------------------------------------
  # Profile edit (venue admin only)
  # ---------------------------------------------------------------------------

  def handle_event("edit_profile", _params, socket) do
    if socket.assigns.is_admin do
      profile = socket.assigns.venue.production_profile || %VenueProductionProfile{}
      cs = Profiles.change_profile(profile)
      {:noreply, socket |> assign(:edit_section, :profile) |> assign(:edit_form, Phoenix.Component.to_form(cs))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("validate_profile", %{"venue_production_profile" => params}, socket) do
    profile = socket.assigns.venue.production_profile || %VenueProductionProfile{}
    cs = Profiles.change_profile(profile, params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, :edit_form, Phoenix.Component.to_form(cs))}
  end

  def handle_event("save_profile", %{"venue_production_profile" => params}, socket) do
    venue = socket.assigns.venue

    result =
      case venue.production_profile do
        nil ->
          case Profiles.get_or_create_profile(venue.id) do
            {:ok, profile} -> Profiles.update_profile(profile, params)
            err -> err
          end

        profile ->
          Profiles.update_profile(profile, params)
      end

    case result do
      {:ok, _profile} ->
        venue = Profiles.get_venue_with_production_data(venue.id)
        {:noreply, socket |> assign(:venue, venue) |> assign(:edit_section, nil) |> put_flash(:info, "Profile updated.")}

      {:error, cs} ->
        {:noreply, assign(socket, :edit_form, Phoenix.Component.to_form(cs))}
    end
  end

  def handle_event("publish_profile", _params, socket) do
    if socket.assigns.is_admin do
      venue = socket.assigns.venue
      profile = venue.production_profile

      if profile do
        case Profiles.publish_profile(profile, socket.assigns.current_user.id) do
          {:ok, _} ->
            venue = Profiles.get_venue_with_production_data(venue.id)
            {:noreply, socket |> assign(:venue, venue) |> put_flash(:info, "Profile published.")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Could not publish profile.")}
        end
      else
        {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("close_edit", _params, socket) do
    {:noreply, socket |> assign(:edit_section, nil) |> assign(:edit_form, nil)}
  end

  # ---------------------------------------------------------------------------
  # Rigging point CRUD (venue admin only)
  # ---------------------------------------------------------------------------

  def handle_event("add_rigging_point", _params, socket) do
    if socket.assigns.is_admin do
      cs = RiggingPoint.changeset(%RiggingPoint{}, %{})
      {:noreply, socket |> assign(:edit_section, :rigging_point_new) |> assign(:edit_form, Phoenix.Component.to_form(cs))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("save_rigging_point", %{"rigging_point" => params}, socket) do
    venue = socket.assigns.venue

    case Profiles.create_rigging_point(venue.id, params) do
      {:ok, _} ->
        venue = Profiles.get_venue_with_production_data(venue.id)
        {:noreply, socket |> assign(:venue, venue) |> assign(:edit_section, nil) |> put_flash(:info, "Rigging point added.")}

      {:error, cs} ->
        {:noreply, assign(socket, :edit_form, Phoenix.Component.to_form(cs))}
    end
  end

  def handle_event("delete_rigging_point", %{"id" => id}, socket) do
    if socket.assigns.is_admin do
      Profiles.get_rigging_point!(id) |> Profiles.delete_rigging_point()
      venue = Profiles.get_venue_with_production_data(socket.assigns.venue.id)
      {:noreply, socket |> assign(:venue, venue) |> put_flash(:info, "Rigging point removed.")}
    else
      {:noreply, socket}
    end
  end

  # ---------------------------------------------------------------------------
  # Power service CRUD (venue admin only)
  # ---------------------------------------------------------------------------

  def handle_event("add_power_service", _params, socket) do
    if socket.assigns.is_admin do
      cs = PowerService.changeset(%PowerService{}, %{})
      {:noreply, socket |> assign(:edit_section, :power_new) |> assign(:edit_form, Phoenix.Component.to_form(cs))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("save_power_service", %{"power_service" => params}, socket) do
    venue = socket.assigns.venue

    case Profiles.create_power_service(venue.id, params) do
      {:ok, _} ->
        venue = Profiles.get_venue_with_production_data(venue.id)
        {:noreply, socket |> assign(:venue, venue) |> assign(:edit_section, nil) |> put_flash(:info, "Power service added.")}

      {:error, cs} ->
        {:noreply, assign(socket, :edit_form, Phoenix.Component.to_form(cs))}
    end
  end

  def handle_event("delete_power_service", %{"id" => id}, socket) do
    if socket.assigns.is_admin do
      Profiles.get_power_service!(id) |> Profiles.delete_power_service()
      venue = Profiles.get_venue_with_production_data(socket.assigns.venue.id)
      {:noreply, socket |> assign(:venue, venue) |> put_flash(:info, "Power service removed.")}
    else
      {:noreply, socket}
    end
  end

  # ---------------------------------------------------------------------------
  # Suggestion workflow
  # ---------------------------------------------------------------------------

  def handle_event("open_suggest", params, socket) do
    target_type = params["target-type"] || "profile"
    target_id = params["target-id"]
    field = params["field"]
    current_value = params["current-value"]

    suggest_form = Phoenix.Component.to_form(%{
      "target_type" => target_type,
      "target_id" => target_id,
      "field_name" => field,
      "current_value" => current_value,
      "suggested_value" => "",
      "evidence_note" => ""
    })

    {:noreply,
     socket
     |> assign(:suggest_open, true)
     |> assign(:suggest_target_type, target_type)
     |> assign(:suggest_target_id, target_id)
     |> assign(:suggest_field, field)
     |> assign(:suggest_current_value, current_value)
     |> assign(:suggest_form, suggest_form)}
  end

  def handle_event("close_suggest", _params, socket) do
    {:noreply, assign(socket, :suggest_open, false)}
  end

  def handle_event("submit_suggestion", params, socket) do
    user = socket.assigns.current_user
    venue = socket.assigns.venue

    %{
      "target_type" => target_type,
      "target_id" => target_id,
      "field_name" => field_name,
      "current_value" => current_value,
      "suggested_value" => suggested_value,
      "evidence_note" => evidence_note
    } = params

    case Suggestions.create_suggestion(
           venue.id, user.id, target_type, target_id,
           field_name, current_value, suggested_value, evidence_note
         ) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:suggest_open, false)
         |> put_flash(:info, "Suggestion submitted. Thank you!")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You must be a tour member to suggest corrections.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not submit suggestion.")}
    end
  end

  # ---------------------------------------------------------------------------
  # Document upload
  # ---------------------------------------------------------------------------

  def handle_event("open_upload", _params, socket) do
    form = Phoenix.Component.to_form(%{"title" => "", "document_type" => "other", "notes" => ""})
    {:noreply, socket |> assign(:upload_open, true) |> assign(:upload_form, form)}
  end

  def handle_event("close_upload", _params, socket) do
    {:noreply,
     Enum.reduce(socket.assigns.uploads.production_document.entries, assign(socket, :upload_open, false), fn entry, s ->
       cancel_upload(s, :production_document, entry.ref)
     end)}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :production_document, ref)}
  end

  def handle_event("save_document", params, socket) do
    user = socket.assigns.current_user
    venue = socket.assigns.venue

    uploads =
      consume_uploaded_entries(socket, :production_document, fn %{path: path}, entry ->
        dest = "production/#{venue.id}/#{System.unique_integer([:positive])}_#{entry.client_name}"

        case File.read(path) do
          {:ok, content} ->
            TourmanagerV2.Storage.upload(dest, content, entry.client_type)

          _ ->
            {:ok, nil}
        end
      end)

    file_url = List.first(uploads)
    entry = List.first(socket.assigns.uploads.production_document.entries)

    title = params["title"] || (entry && Path.rootname(entry.client_name)) || "Document"

    attrs = %{
      "title" => title,
      "document_type" => params["document_type"] || "other",
      "notes" => params["notes"],
      "file_url" => file_url,
      "original_filename" => entry && entry.client_name,
      "content_type" => entry && entry.client_type,
      "file_size" => entry && entry.client_size
    }

    case Documents.create_document(venue.id, user.id, attrs) do
      {:ok, _doc} ->
        venue = Profiles.get_venue_with_production_data(venue.id)
        {:noreply, socket |> assign(:venue, venue) |> assign(:upload_open, false) |> put_flash(:info, "Document uploaded.")}

      {:error, cs} ->
        {:noreply, assign(socket, :upload_form, Phoenix.Component.to_form(cs))}
    end
  end

  def handle_event("delete_document", %{"id" => id}, socket) do
    user = socket.assigns.current_user

    case Documents.delete_document(id, user.id) do
      {:ok, _} ->
        venue = Profiles.get_venue_with_production_data(socket.assigns.venue.id)
        {:noreply, socket |> assign(:venue, venue) |> put_flash(:info, "Document removed.")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You can't delete this document.")}

      _ ->
        {:noreply, socket}
    end
  end

  # ---------------------------------------------------------------------------
  # Render
  # ---------------------------------------------------------------------------

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
        <div class="flex items-start justify-between mb-6 gap-4">
          <div>
            <.drilldown_breadcrumb back_label="PRODUCTION" navigate="/production/venues" current_label="VENUE" />
            <div style="font-family: var(--font-display); font-weight: 800; font-size: 26px; letter-spacing: -0.01em; color: var(--ink-900);">{@venue.name}</div>
            <div :if={@venue.city} style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400); margin-top: 4px;">
              {@venue.city}{if @venue.country, do: ", #{@venue.country}", else: ""}
            </div>
          </div>
          <div class="flex items-center gap-2 flex-none">
            <%= if @pending_count > 0 && @is_admin do %>
              <.link navigate={"/production/venues/#{@venue.id}/suggestions"} class="flex items-center gap-1.5 px-3 py-1.5 rounded-[var(--radius-stamp)] no-underline" style="background: var(--signal-doors-tint); border: 1px solid var(--signal-doors); font-family: var(--font-mono); font-size: 9px; font-weight: 700; letter-spacing: 0.1em; color: var(--signal-doors);">
                <.icon name="hero-chat-bubble-left-ellipsis-mini" class="w-3 h-3" />
                {@pending_count} PENDING
              </.link>
            <% end %>
            <%= cond do %>
              <% !@venue.production_profile || @venue.production_profile.profile_status == "draft" -> %>
                <.signal_chip tone="ink" size="sm">DRAFT</.signal_chip>
              <% @venue.production_profile.profile_status == "published" -> %>
                <.signal_chip tone="live" size="sm" variant="tint">PUBLISHED</.signal_chip>
              <% @venue.production_profile.profile_status == "needs_review" -> %>
                <.signal_chip tone="doors" size="sm" variant="tint">NEEDS REVIEW</.signal_chip>
              <% true -> %>
                <span />
            <% end %>
          </div>
        </div>

        <%!-- Admin publish button --%>
        <%= if @is_admin && @venue.production_profile && @venue.production_profile.profile_status == "draft" do %>
          <div class="mb-5 flex items-center gap-3 px-4 py-3 rounded-[var(--radius-md)] border border-[var(--paper-300)]" style="background: var(--surface-card);">
            <.icon name="hero-information-circle" class="w-4 h-4 text-[var(--ink-400)]" />
            <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-500); flex: 1;">
              This profile is in draft. Publish it to make it visible to touring teams.
            </div>
            <.tm_button variant="primary" size="sm" phx-click="publish_profile">Publish</.tm_button>
          </div>
        <% end %>

        <%!-- Stage dimensions section --%>
        <.production_section id="stage" title="Stage" icon="hero-rectangle-stack" expanded={@stage_expanded}>
          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <.prod_metric
              label="WIDTH"
              value={@venue.production_profile && format_m(@venue.production_profile.stage_width_m)}
              field="stage_width_m"
              venue_id={@venue.id}
              is_admin={@is_admin}
              on_suggest="open_suggest"
            />
            <.prod_metric
              label="DEPTH"
              value={@venue.production_profile && format_m(@venue.production_profile.stage_depth_m)}
              field="stage_depth_m"
              venue_id={@venue.id}
              is_admin={@is_admin}
              on_suggest="open_suggest"
            />
            <.prod_metric
              label="HEIGHT"
              value={@venue.production_profile && format_m(@venue.production_profile.stage_height_m)}
              field="stage_height_m"
              venue_id={@venue.id}
              is_admin={@is_admin}
              on_suggest="open_suggest"
            />
            <.prod_metric
              label="TRIM"
              value={@venue.production_profile && format_m(@venue.production_profile.trim_height_m)}
              field="trim_height_m"
              venue_id={@venue.id}
              is_admin={@is_admin}
              on_suggest="open_suggest"
            />
          </div>
          <%= if @venue.production_profile && @venue.production_profile.last_verified_at do %>
            <div class="mt-3" style="font-family: var(--font-mono); font-size: 9px; color: var(--ink-400);">
              LAST VERIFIED {@venue.production_profile.last_verified_at |> Calendar.strftime("%d %b %Y") |> String.upcase()}
            </div>
          <% end %>
          <%= if @is_admin do %>
            <div class="mt-4 flex gap-2">
              <.tm_button variant="ghost" size="sm" icon_name="hero-pencil-mini" phx-click="edit_profile">Edit stage data</.tm_button>
            </div>
          <% end %>
        </.production_section>

        <%!-- Rigging section --%>
        <.production_section id="rigging" title={"Rigging (#{length(@venue.rigging_points)})"} icon="hero-wrench-screwdriver" expanded={@rigging_expanded}>
          <%= if @venue.rigging_points == [] do %>
            <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">No rigging points recorded yet.</div>
          <% else %>
            <div class="overflow-x-auto">
              <table class="w-full text-left" style="font-family: var(--font-mono); font-size: 10px;">
                <thead>
                  <tr style="color: var(--ink-400); letter-spacing: 0.1em;">
                    <th class="py-1.5 pr-3">LABEL</th>
                    <th class="py-1.5 pr-3">SWL (KG)</th>
                    <th class="py-1.5 pr-3">MOTOR</th>
                    <th class="py-1.5 pr-3">MOTOR CAP.</th>
                    <th class="py-1.5">NOTES</th>
                    <%= if @is_admin do %><th class="py-1.5"></th><% end %>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={point <- @venue.rigging_points} class="border-t border-[var(--paper-300)]">
                    <td class="py-2 pr-3 font-bold" style="color: var(--ink-900);">{point.label}</td>
                    <td class="py-2 pr-3">{point.safe_working_load_kg || "—"}</td>
                    <td class="py-2 pr-3">{if point.motor_available, do: "Yes", else: "No"}</td>
                    <td class="py-2 pr-3">{point.motor_capacity_kg || "—"}</td>
                    <td class="py-2">{point.notes || "—"}</td>
                    <%= if @is_admin do %>
                      <td class="py-2">
                        <button
                          phx-click="delete_rigging_point"
                          phx-value-id={point.id}
                          data-confirm="Remove this rigging point?"
                          class="p-1 rounded cursor-pointer hover:bg-[var(--signal-stop-tint)]"
                          style="color: var(--signal-stop);"
                        >
                          <.icon name="hero-trash-mini" class="w-3.5 h-3.5" />
                        </button>
                      </td>
                    <% end %>
                  </tr>
                </tbody>
              </table>
            </div>
          <% end %>
          <%= if @is_admin do %>
            <div class="mt-4">
              <.tm_button variant="ghost" size="sm" icon_name="hero-plus-mini" phx-click="add_rigging_point">Add rigging point</.tm_button>
            </div>
          <% end %>
        </.production_section>

        <%!-- Power section --%>
        <.production_section id="power" title={"Power (#{length(@venue.power_services)})"} icon="hero-bolt" expanded={@power_expanded}>
          <%= if @venue.power_services == [] do %>
            <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">No power services recorded yet.</div>
          <% else %>
            <div class="flex flex-col gap-2">
              <div :for={svc <- @venue.power_services} class="flex items-center gap-3 px-3 py-2.5 rounded-[var(--radius-sm)] border border-[var(--paper-300)]" style="background: var(--paper-200);">
                <.icon name="hero-bolt" class="w-4 h-4 text-[var(--ink-300)]" />
                <div class="flex-1">
                  <div style="font-family: var(--font-mono); font-weight: 700; font-size: 11px; color: var(--ink-900);">{svc.name}</div>
                  <div style="font-family: var(--font-mono); font-size: 9px; color: var(--ink-400);">
                    {String.upcase(String.replace(svc.phase_type, "_", " "))}
                    {if svc.amps, do: " · #{svc.amps}A", else: ""}
                    {if svc.voltage, do: " · #{svc.voltage}V", else: ""}
                    {if svc.connector_type, do: " · #{svc.connector_type}", else: ""}
                  </div>
                </div>
                <%= if @is_admin do %>
                  <button phx-click="delete_power_service" phx-value-id={svc.id} data-confirm="Remove this power service?" class="p-1 rounded cursor-pointer hover:bg-[var(--signal-stop-tint)]" style="color: var(--signal-stop);">
                    <.icon name="hero-trash-mini" class="w-3.5 h-3.5" />
                  </button>
                <% end %>
              </div>
            </div>
          <% end %>
          <%= if @is_admin do %>
            <div class="mt-4">
              <.tm_button variant="ghost" size="sm" icon_name="hero-plus-mini" phx-click="add_power_service">Add power service</.tm_button>
            </div>
          <% end %>
        </.production_section>

        <%!-- Documents section --%>
        <.production_section id="documents" title={"Documents (#{length(@venue.production_documents)})"} icon="hero-document-text" expanded={@documents_expanded}>
          <%= if @venue.production_documents == [] do %>
            <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">No documents uploaded yet.</div>
          <% else %>
            <div class="flex flex-col gap-2">
              <div :for={doc <- @venue.production_documents} class="flex items-center gap-3 px-3 py-2.5 rounded-[var(--radius-sm)] border border-[var(--paper-300)]" style="background: var(--paper-200);">
                <.icon name="hero-document-text" class="w-4 h-4 text-[var(--ink-300)]" />
                <div class="flex-1 min-w-0">
                  <div class="truncate" style="font-family: var(--font-mono); font-weight: 700; font-size: 11px; color: var(--ink-900);">{doc.title}</div>
                  <div style="font-family: var(--font-mono); font-size: 9px; color: var(--ink-400);">
                    {String.upcase(String.replace(doc.document_type, "_", " "))}
                    {if doc.uploaded_by_user, do: " · #{doc.uploaded_by_user.name}", else: ""}
                  </div>
                </div>
                <div class="flex items-center gap-2">
                  <a :if={doc.file_url} href={doc.file_url} target="_blank" class="px-2 py-1 rounded-[var(--radius-sm)] no-underline" style="font-family: var(--font-mono); font-size: 9px; font-weight: 700; letter-spacing: 0.1em; background: var(--marker-050); color: var(--brand); border: 1px solid var(--brand);">
                    OPEN
                  </a>
                  <button phx-click="delete_document" phx-value-id={doc.id} data-confirm="Remove this document?" class="p-1 rounded cursor-pointer hover:bg-[var(--signal-stop-tint)]" style="color: var(--signal-stop);">
                    <.icon name="hero-trash-mini" class="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            </div>
          <% end %>
          <div class="mt-4">
            <.tm_button variant="ghost" size="sm" icon_name="hero-arrow-up-tray-mini" phx-click="open_upload">Upload document</.tm_button>
          </div>
        </.production_section>

      </div>

      <%!-- Edit profile modal --%>
      <.tm_modal id="edit-profile-modal" show={@edit_section == :profile} on_close="close_edit">
        <div class="px-6 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);">EDIT</div>
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; margin-top: 2px;">Stage dimensions</div>
        </div>
        <div :if={@edit_form} class="px-6 py-5">
          <.form for={@edit_form} phx-change="validate_profile" phx-submit="save_profile">
            <div class="grid grid-cols-2 gap-4 mb-4">
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">STAGE WIDTH (M)</label>
                <.input field={@edit_form[:stage_width_m]} type="number" step="0.1" placeholder="e.g. 18.0" class="mt-1" />
              </div>
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">STAGE DEPTH (M)</label>
                <.input field={@edit_form[:stage_depth_m]} type="number" step="0.1" placeholder="e.g. 12.0" class="mt-1" />
              </div>
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">STAGE HEIGHT (M)</label>
                <.input field={@edit_form[:stage_height_m]} type="number" step="0.1" placeholder="e.g. 6.0" class="mt-1" />
              </div>
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">TRIM HEIGHT (M)</label>
                <.input field={@edit_form[:trim_height_m]} type="number" step="0.1" placeholder="e.g. 9.0" class="mt-1" />
              </div>
            </div>
            <div class="mb-4">
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">NOTES</label>
              <.input field={@edit_form[:notes]} type="textarea" placeholder="Any additional stage notes..." class="mt-1" />
            </div>
            <div class="flex justify-end gap-3">
              <.tm_button variant="ghost" size="sm" phx-click="close_edit">Cancel</.tm_button>
              <button type="submit" class="px-3 py-1.5 rounded-[var(--radius-md)] text-[11px] font-bold tracking-wide cursor-pointer" style="background: var(--brand); color: #fff; font-family: var(--font-mono);">Save</button>
            </div>
          </.form>
        </div>
      </.tm_modal>

      <%!-- Add rigging point modal --%>
      <.tm_modal id="add-rigging-modal" show={@edit_section == :rigging_point_new} on_close="close_edit">
        <div class="px-6 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);">RIGGING</div>
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; margin-top: 2px;">Add rigging point</div>
        </div>
        <div :if={@edit_form} class="px-6 py-5">
          <.form for={@edit_form} phx-submit="save_rigging_point">
            <div class="grid grid-cols-2 gap-4 mb-4">
              <div class="col-span-2">
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">LABEL *</label>
                <.input field={@edit_form[:label]} placeholder="e.g. RP-1A" class="mt-1" />
              </div>
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">SWL (KG)</label>
                <.input field={@edit_form[:safe_working_load_kg]} type="number" step="0.1" placeholder="750" class="mt-1" />
              </div>
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">MOTOR CAPACITY (KG)</label>
                <.input field={@edit_form[:motor_capacity_kg]} type="number" step="0.1" placeholder="500" class="mt-1" />
              </div>
            </div>
            <div class="mb-4 flex items-center gap-3">
              <.input field={@edit_form[:motor_available]} type="checkbox" />
              <label style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-700);">Motor available</label>
            </div>
            <div class="flex justify-end gap-3">
              <.tm_button variant="ghost" size="sm" phx-click="close_edit">Cancel</.tm_button>
              <button type="submit" class="px-3 py-1.5 rounded-[var(--radius-md)] text-[11px] font-bold tracking-wide cursor-pointer" style="background: var(--brand); color: #fff; font-family: var(--font-mono);">Add point</button>
            </div>
          </.form>
        </div>
      </.tm_modal>

      <%!-- Add power service modal --%>
      <.tm_modal id="add-power-modal" show={@edit_section == :power_new} on_close="close_edit">
        <div class="px-6 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);">POWER</div>
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; margin-top: 2px;">Add power service</div>
        </div>
        <div :if={@edit_form} class="px-6 py-5">
          <.form for={@edit_form} phx-submit="save_power_service">
            <div class="grid grid-cols-2 gap-4 mb-4">
              <div class="col-span-2">
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">NAME *</label>
                <.input field={@edit_form[:name]} placeholder="e.g. Stage Left 3-Phase" class="mt-1" />
              </div>
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">PHASE TYPE</label>
                <.input field={@edit_form[:phase_type]} type="select" options={[{"Single phase", "single_phase"}, {"Three phase", "three_phase"}]} class="mt-1" />
              </div>
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">AMPS</label>
                <.input field={@edit_form[:amps]} type="number" placeholder="63" class="mt-1" />
              </div>
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">VOLTAGE</label>
                <.input field={@edit_form[:voltage]} type="number" placeholder="400" class="mt-1" />
              </div>
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">CONNECTOR</label>
                <.input field={@edit_form[:connector_type]} placeholder="CEE 63A" class="mt-1" />
              </div>
            </div>
            <div class="flex justify-end gap-3">
              <.tm_button variant="ghost" size="sm" phx-click="close_edit">Cancel</.tm_button>
              <button type="submit" class="px-3 py-1.5 rounded-[var(--radius-md)] text-[11px] font-bold tracking-wide cursor-pointer" style="background: var(--brand); color: #fff; font-family: var(--font-mono);">Add service</button>
            </div>
          </.form>
        </div>
      </.tm_modal>

      <%!-- Suggest correction modal --%>
      <.tm_modal id="suggest-modal" show={@suggest_open} on_close="close_suggest">
        <div class="px-6 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);">COMMUNITY</div>
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; margin-top: 2px;">Suggest a correction</div>
        </div>
        <div class="px-6 py-5">
          <div class="mb-4 px-3 py-2.5 rounded-[var(--radius-sm)] border border-[var(--paper-300)]" style="background: var(--paper-200);">
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.15em; color: var(--ink-400);">FIELD</div>
            <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-900); margin-top: 2px;">{@suggest_field}</div>
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.15em; color: var(--ink-400); margin-top: 6px;">CURRENT VALUE</div>
            <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-700); margin-top: 2px;">{@suggest_current_value || "No data"}</div>
          </div>
          <.form :if={@suggest_form} for={@suggest_form} phx-submit="submit_suggestion">
            <input type="hidden" name="target_type" value={@suggest_target_type} />
            <input type="hidden" name="target_id" value={@suggest_target_id} />
            <input type="hidden" name="field_name" value={@suggest_field} />
            <input type="hidden" name="current_value" value={@suggest_current_value} />
            <div class="flex flex-col gap-4">
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">SUGGESTED VALUE *</label>
                <input
                  type="text"
                  name="suggested_value"
                  required
                  placeholder="Enter the correct value"
                  class="mt-1 w-full px-3 py-2.5 rounded-[var(--radius-md)] border border-[var(--paper-300)] text-[12px] outline-none focus:border-[var(--brand)]"
                  style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);"
                />
              </div>
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">EVIDENCE / SOURCE</label>
                <textarea
                  name="evidence_note"
                  placeholder="e.g. Visited the venue on June 2025, measured with laser."
                  rows="3"
                  class="mt-1 w-full px-3 py-2.5 rounded-[var(--radius-md)] border border-[var(--paper-300)] text-[12px] outline-none focus:border-[var(--brand)] resize-none"
                  style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);"
                ></textarea>
              </div>
              <div class="flex justify-end gap-3">
                <.tm_button variant="ghost" size="sm" phx-click="close_suggest">Cancel</.tm_button>
                <button type="submit" class="px-3 py-1.5 rounded-[var(--radius-md)] text-[11px] font-bold tracking-wide cursor-pointer" style="background: var(--brand); color: #fff; font-family: var(--font-mono);">Submit suggestion</button>
              </div>
            </div>
          </.form>
        </div>
      </.tm_modal>

      <%!-- Document upload modal --%>
      <.tm_modal id="upload-modal" show={@upload_open} on_close="close_upload">
        <div class="px-6 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);">DOCUMENTS</div>
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; margin-top: 2px;">Upload document</div>
        </div>
        <div class="px-6 py-5">
          <.form for={%{}} phx-submit="save_document">
            <div class="flex flex-col gap-4">
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">DOCUMENT TYPE</label>
                <select
                  name="document_type"
                  class="mt-1 w-full px-3 py-2.5 rounded-[var(--radius-md)] border border-[var(--paper-300)] text-[12px] outline-none"
                  style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);"
                >
                  <option value="tech_pack">Tech Pack</option>
                  <option value="rigging_plot">Rigging Plot</option>
                  <option value="lighting_plot">Lighting Plot</option>
                  <option value="stage_plot">Stage Plot</option>
                  <option value="cad">CAD File</option>
                  <option value="photo">Photo</option>
                  <option value="other">Other</option>
                </select>
              </div>
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400);">TITLE</label>
                <input
                  type="text"
                  name="title"
                  placeholder="e.g. Main Stage Rigging Plot 2025"
                  class="mt-1 w-full px-3 py-2.5 rounded-[var(--radius-md)] border border-[var(--paper-300)] text-[12px] outline-none focus:border-[var(--brand)]"
                  style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);"
                />
              </div>
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">FILE</label>
                <.live_file_input upload={@uploads.production_document} class="text-[12px]" style="font-family: var(--font-mono);" />
              </div>
              <div :for={entry <- @uploads.production_document.entries} class="flex items-center gap-2 px-3 py-2 rounded-[var(--radius-sm)] border border-[var(--paper-300)]">
                <span style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-700); flex: 1;">{entry.client_name}</span>
                <button type="button" phx-click="cancel_upload" phx-value-ref={entry.ref} style="color: var(--signal-stop);">
                  <.icon name="hero-x-mark-mini" class="w-4 h-4" />
                </button>
              </div>
              <div class="flex justify-end gap-3">
                <.tm_button variant="ghost" size="sm" phx-click="close_upload">Cancel</.tm_button>
                <button type="submit" class="px-3 py-1.5 rounded-[var(--radius-md)] text-[11px] font-bold tracking-wide cursor-pointer" style="background: var(--brand); color: #fff; font-family: var(--font-mono);">Upload</button>
              </div>
            </div>
          </.form>
        </div>
      </.tm_modal>
    </Layouts.app>
    """
  end

  # ---------------------------------------------------------------------------
  # Private components
  # ---------------------------------------------------------------------------

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :icon, :string, required: true
  attr :expanded, :boolean, default: false
  slot :inner_block, required: true

  defp production_section(assigns) do
    ~H"""
    <div class="mb-3 rounded-[var(--radius-md)] border border-[var(--paper-300)] overflow-hidden" style="background: var(--surface-card);">
      <button
        type="button"
        phx-click="toggle_section"
        phx-value-section={@id}
        class="w-full flex items-center justify-between px-4 py-3 text-left cursor-pointer hover:bg-[var(--paper-200)] transition-colors"
      >
        <div class="flex items-center gap-2.5">
          <.icon name={@icon} class="w-4 h-4 text-[var(--ink-400)]" />
          <span style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.08em; color: var(--ink-900);">{String.upcase(@title)}</span>
        </div>
        <.icon name={if @expanded, do: "hero-chevron-up-mini", else: "hero-chevron-down-mini"} class="w-4 h-4 text-[var(--ink-400)]" />
      </button>
      <div :if={@expanded} class="px-4 pb-4 pt-1 border-t border-[var(--paper-300)]">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :string, default: nil
  attr :field, :string, required: true
  attr :venue_id, :string, required: true
  attr :is_admin, :boolean, default: false
  attr :on_suggest, :string, default: nil

  defp prod_metric(assigns) do
    ~H"""
    <div class="flex flex-col gap-1">
      <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.15em; color: var(--ink-400);">{@label}</div>
      <div style={"font-family: var(--font-display); font-weight: 800; font-size: 22px; color: #{if @value && @value != "—", do: "var(--ink-900)", else: "var(--ink-300)"};"}>
        {@value || "—"}
      </div>
      <%= if !@is_admin && @on_suggest do %>
        <button
          type="button"
          phx-click={@on_suggest}
          phx-value-target-type="profile"
          phx-value-field={@field}
          phx-value-current-value={@value}
          class="mt-0.5 text-left cursor-pointer"
          style="font-family: var(--font-mono); font-size: 8px; letter-spacing: 0.1em; color: var(--brand); text-decoration: underline;"
        >
          SUGGEST CORRECTION
        </button>
      <% end %>
    </div>
    """
  end

  defp format_m(nil), do: "—"
  defp format_m(val), do: "#{:erlang.float_to_binary(val / 1, decimals: 1)}m"
end
