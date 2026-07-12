defmodule TourmanagerV2Web.VenueProductionProfileLive.Index do
  @moduledoc "Lists every venue in the shared production database."
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  alias TourmanagerV2.Production.Profiles
  alias TourmanagerV2.Production.Venue

  def mount(_params, _session, socket) do
    venues = Profiles.list_all_venues()

    socket =
      socket
      |> assign(TourSwitching.default_assigns())
      |> assign(
        active_nav: "production",
        page_title: "Venue Production",
        venues: venues,
        new_venue_open: false,
        new_venue_form: nil
      )
      |> TourSwitching.load_tour_data(socket.assigns[:current_tour])

    {:ok, socket}
  end

  def handle_event("open_new_venue", _params, socket) do
    changeset = Venue.changeset(%Venue{}, %{})

    {:noreply,
     socket
     |> assign(:new_venue_open, true)
     |> assign(:new_venue_form, Phoenix.Component.to_form(changeset))
     |> assign(:place_suggestions, [])
     |> assign(:autocomplete_field, nil)}
  end

  def handle_event("close_new_venue", _params, socket) do
    {:noreply,
     socket
     |> assign(:new_venue_open, false)
     |> assign(:place_suggestions, [])}
  end

  def handle_event("validate_venue", %{"venue" => params}, socket) do
    cs = Venue.changeset(%Venue{}, params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, :new_venue_form, Phoenix.Component.to_form(cs))}
  end

  def handle_event("save_venue", %{"venue" => params}, socket) do
    case Profiles.create_venue(params) do
      {:ok, venue} ->
        {:noreply,
         socket
         |> assign(:new_venue_open, false)
         |> assign(:venues, Enum.sort_by([venue | socket.assigns.venues], & &1.name))
         |> put_flash(:info, "Venue created.")}

      {:error, cs} ->
        {:noreply,
         socket
         |> assign(:new_venue_form, Phoenix.Component.to_form(cs))
         |> assign(:place_suggestions, [])}
    end
  end

  def handle_event("place_autocomplete", %{"value" => query, "field" => "new_venue"}, socket)
      when byte_size(query) >= 3 do
    case TourmanagerV2.GoogleMaps.autocomplete(query) do
      {:ok, suggestions} ->
        {:noreply,
         socket
         |> assign(:place_suggestions, suggestions)
         |> assign(:autocomplete_field, "new_venue")}

      _ ->
        {:noreply, assign(socket, :place_suggestions, [])}
    end
  end

  def handle_event("place_autocomplete", %{"field" => "new_venue"}, socket) do
    {:noreply, assign(socket, :place_suggestions, [])}
  end

  def handle_event("select_place", %{"place-id" => place_id, "field" => "new_venue"}, socket) do
    case TourmanagerV2.GoogleMaps.place_details(place_id) do
      {:ok, place} ->
        params = %{
          "name" => place.name,
          "google_place_id" => place.place_id,
          "formatted_address" => place.address,
          "lat" => place.lat && to_string(place.lat),
          "lng" => place.lng && to_string(place.lng),
          "city" => extract_city(place.address),
          "country" => extract_country(place.address)
        }

        changeset = Venue.changeset(%Venue{}, params) |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(:new_venue_form, Phoenix.Component.to_form(changeset))
         |> assign(:place_suggestions, [])
         |> assign(:autocomplete_field, nil)}

      _ ->
        {:noreply, assign(socket, :place_suggestions, [])}
    end
  end

  defp extract_city(address) when is_binary(address) do
    parts = String.split(address, ",") |> Enum.map(&String.trim/1)

    case length(parts) do
      n when n >= 3 -> Enum.at(parts, -3)
      n when n >= 2 -> Enum.at(parts, 0)
      _ -> nil
    end
  end

  defp extract_city(_), do: nil

  defp extract_country(address) when is_binary(address) do
    address |> String.split(",") |> List.last() |> String.trim()
  end

  defp extract_country(_), do: nil

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
        <div class="flex items-end justify-between mb-6">
          <div>
            <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);">PRODUCTION</div>
            <div style="font-family: var(--font-display); font-weight: 800; font-size: 26px; letter-spacing: -0.01em; color: var(--ink-900); margin-top: 4px;">Venue Profiles</div>
          </div>
          <.tm_button variant="primary" size="sm" icon_name="hero-plus" phx-click="open_new_venue">
            New venue
          </.tm_button>
        </div>

        <%= if @venues == [] do %>
          <div class="py-16 text-center rounded-[var(--radius-md)] border-2 border-dashed border-[var(--paper-300)]">
            <.icon name="hero-building-library" class="w-10 h-10 text-[var(--ink-300)] mx-auto mb-3" />
            <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400); letter-spacing: 0.06em;">
              No venues yet. Add your first venue to start publishing production data.
            </div>
          </div>
        <% else %>
          <div class="flex flex-col gap-3">
            <.link
              :for={venue <- @venues}
              navigate={"/production/venues/#{venue.id}"}
              class="flex items-center justify-between gap-4 p-4 rounded-[var(--radius-md)] border border-[var(--paper-300)] no-underline transition-colors hover:border-[var(--brand)] hover:bg-[var(--marker-050)]"
              style="background: var(--surface-card);"
            >
              <div>
                <div style="font-family: var(--font-display); font-weight: 700; font-size: 18px; color: var(--ink-900);">{venue.name}</div>
                <div :if={venue.city} style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); margin-top: 3px;">{venue.city}{if venue.country, do: ", #{venue.country}", else: ""}</div>
              </div>
              <div class="flex items-center gap-3 flex-none">
                <%= cond do %>
                  <% !venue.production_profile || venue.production_profile.profile_status == "draft" -> %>
                    <.signal_chip tone="ink" size="sm">DRAFT</.signal_chip>
                  <% venue.production_profile.profile_status == "published" -> %>
                    <.signal_chip tone="live" size="sm" variant="tint">PUBLISHED</.signal_chip>
                  <% venue.production_profile.profile_status == "needs_review" -> %>
                    <.signal_chip tone="doors" size="sm" variant="tint">NEEDS REVIEW</.signal_chip>
                <% end %>
                <.icon name="hero-chevron-right" class="w-4 h-4 text-[var(--ink-400)]" />
              </div>
            </.link>
          </div>
        <% end %>
      </div>

      <.tm_modal id="new-venue-modal" show={@new_venue_open} on_close="close_new_venue">
        <div class="px-6 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);">PRODUCTION</div>
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; margin-top: 2px;">Add venue</div>
        </div>
        <div class="px-6 py-5">
          <.form for={@new_venue_form} phx-change="validate_venue" phx-submit="save_venue">
            <div class="flex flex-col gap-4">
              <.place_autocomplete_field
                form={@new_venue_form}
                field={:name}
                label="VENUE"
                placeholder="Search Google for the venue"
                suggestions={if @autocomplete_field == "new_venue", do: @place_suggestions, else: []}
                autocomplete_field="new_venue"
              />
              <.input field={@new_venue_form[:google_place_id]} type="hidden" />
              <.input field={@new_venue_form[:formatted_address]} type="hidden" />
              <.input field={@new_venue_form[:lat]} type="hidden" />
              <.input field={@new_venue_form[:lng]} type="hidden" />
              <.input field={@new_venue_form[:city]} type="hidden" />
              <.input field={@new_venue_form[:country]} type="hidden" />

              <.selected_place_chip
                :if={Phoenix.HTML.Form.input_value(@new_venue_form, :google_place_id) not in [nil, ""]}
                name={Phoenix.HTML.Form.input_value(@new_venue_form, :name)}
                subtitle={Phoenix.HTML.Form.input_value(@new_venue_form, :formatted_address)}
                place_id={Phoenix.HTML.Form.input_value(@new_venue_form, :google_place_id)}
              />

              <div :if={Phoenix.HTML.Form.input_value(@new_venue_form, :google_place_id) in [nil, ""]} style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); line-height: 1.5;">
                Search and select the venue from Google to continue — this keeps the shared production database free of duplicates.
              </div>

              <div class="flex justify-end gap-3 pt-2">
                <.tm_button variant="ghost" size="sm" phx-click="close_new_venue">Cancel</.tm_button>
                <button type="submit" class="px-3 py-1.5 rounded-[var(--radius-md)] text-[11px] font-bold tracking-wide cursor-pointer" style="background: var(--brand); color: #fff; font-family: var(--font-mono);">Create venue</button>
              </div>
            </div>
          </.form>
        </div>
      </.tm_modal>
    </Layouts.app>
    """
  end
end
