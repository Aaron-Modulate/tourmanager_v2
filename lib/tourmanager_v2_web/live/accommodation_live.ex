defmodule TourmanagerV2Web.AccommodationLive do
  @moduledoc "Lists every accommodation booking linked across the current tour."
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  alias TourmanagerV2.Touring
  alias TourmanagerV2.Touring.Accommodation

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(TourSwitching.default_assigns())
      |> assign(
        active_nav: "accommodation",
        page_title: "Accommodation",
        accommodation_modal_open: false,
        accommodation_form: nil,
        editing_accommodation: nil
      )
      |> TourSwitching.load_tour_data(socket.assigns[:current_tour])
      |> load_accommodations()

    {:ok, socket}
  end

  def handle_event("select_tour", %{"tour-id" => tour_id}, socket) do
    {:noreply, socket} = TourSwitching.handle_event("select_tour", %{"tour-id" => tour_id}, socket)
    {:noreply, load_accommodations(socket)}
  end

  def handle_event("open_add_accommodation", _params, socket) do
    changeset = Touring.change_accommodation()

    {:noreply,
     socket
     |> assign(:accommodation_modal_open, true)
     |> assign(:accommodation_form, Phoenix.Component.to_form(changeset))
     |> assign(:editing_accommodation, nil)
     |> assign(:place_suggestions, [])
     |> assign(:autocomplete_field, nil)}
  end

  def handle_event("edit_accommodation", %{"id" => id}, socket) do
    acc = Touring.get_accommodation!(id)
    changeset = Touring.change_accommodation(acc)

    {:noreply,
     socket
     |> assign(:accommodation_modal_open, true)
     |> assign(:accommodation_form, Phoenix.Component.to_form(changeset))
     |> assign(:editing_accommodation, acc)
     |> assign(:place_suggestions, [])
     |> assign(:autocomplete_field, nil)}
  end

  def handle_event("close_accommodation_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:accommodation_modal_open, false)
     |> assign(:place_suggestions, [])}
  end

  def handle_event("validate_accommodation", %{"accommodation" => params}, socket) do
    source = socket.assigns[:editing_accommodation] || %Accommodation{}

    changeset =
      Touring.change_accommodation(source, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :accommodation_form, Phoenix.Component.to_form(changeset))}
  end

  def handle_event("save_accommodation", %{"accommodation" => params}, socket) do
    tour = socket.assigns[:current_tour]
    editing = socket.assigns[:editing_accommodation]

    result =
      cond do
        editing -> Touring.update_accommodation(editing, params)
        tour -> Touring.create_accommodation(tour.id, nil, params)
        true -> {:error, :no_tour}
      end

    case result do
      {:ok, _accommodation} ->
        {:noreply,
         socket
         |> assign(:accommodation_modal_open, false)
         |> put_flash(:info, if(editing, do: "Accommodation updated.", else: "Accommodation added."))
         |> load_accommodations()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:accommodation_form, Phoenix.Component.to_form(changeset))
         |> assign(:place_suggestions, [])}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("delete_accommodation", %{"id" => id}, socket) do
    id
    |> Touring.get_accommodation!()
    |> Touring.delete_accommodation()

    {:noreply, load_accommodations(socket)}
  end

  def handle_event("place_autocomplete", %{"value" => query, "field" => "accommodation"}, socket)
      when byte_size(query) >= 3 do
    case TourmanagerV2.GoogleMaps.autocomplete(query) do
      {:ok, suggestions} ->
        {:noreply,
         socket
         |> assign(:place_suggestions, suggestions)
         |> assign(:autocomplete_field, "accommodation")}

      _ ->
        {:noreply, assign(socket, :place_suggestions, [])}
    end
  end

  def handle_event("place_autocomplete", %{"field" => "accommodation"}, socket) do
    {:noreply, assign(socket, :place_suggestions, [])}
  end

  def handle_event("select_place", %{"place-id" => place_id, "field" => "accommodation"}, socket) do
    case TourmanagerV2.GoogleMaps.place_details(place_id) do
      {:ok, place} ->
        current_params =
          (socket.assigns[:accommodation_form] && socket.assigns.accommodation_form.params) || %{}

        merged =
          Map.merge(current_params, %{
            "location" => place.address || place.name,
            "place_id" => place.place_id,
            "lat" => place.lat && to_string(place.lat),
            "lng" => place.lng && to_string(place.lng)
          })

        source = socket.assigns[:editing_accommodation] || %Accommodation{}
        changeset = Touring.change_accommodation(source, merged) |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(:accommodation_form, Phoenix.Component.to_form(changeset))
         |> assign(:place_suggestions, [])
         |> assign(:autocomplete_field, nil)}

      _ ->
        {:noreply, assign(socket, :place_suggestions, [])}
    end
  end

  defp load_accommodations(socket) do
    tour = socket.assigns[:current_tour]

    accommodations =
      if tour do
        Touring.list_accommodations_for_tour(tour.id)
      else
        []
      end

    assign(socket, :accommodations, accommodations)
  end

  defp stay_status(%{check_in: check_in, check_out: check_out}) do
    today = Date.utc_today()

    cond do
      check_out && Date.compare(check_out, today) == :lt -> :past
      Date.compare(check_in, today) == :gt -> :upcoming
      true -> :current
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
      <div id="accommodation-page" class="p-4 md:p-7 max-w-3xl">
        <div class="flex items-end justify-between mb-5">
          <div>
            <.drilldown_breadcrumb current_label="ACCOMMODATION" />
            <.display size={26} class="mt-1.5">Where you're staying</.display>
          </div>
          <%= if @current_tour && @current_user && TourmanagerV2.Accounts.User.manager?(@current_user) do %>
            <.tm_button variant="primary" size="sm" icon_name="hero-plus" phx-click="open_add_accommodation">Add</.tm_button>
          <% end %>
        </div>

        <%= if !@current_tour do %>
          <div class="py-16 text-center">
            <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400); letter-spacing: 0.06em;">
              Select a tour to manage accommodation.
            </div>
          </div>
        <% else %>
          <%= if @accommodations == [] do %>
            <div class="py-16 text-center rounded-[var(--radius-md)] border-2 border-dashed border-[var(--paper-300)]">
              <.icon name="hero-building-office-2" class="w-10 h-10 text-[var(--ink-300)] mx-auto mb-3" />
              <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400); letter-spacing: 0.06em;">
                No accommodation booked yet. Add the first hotel for this tour.
              </div>
            </div>
          <% else %>
            <div class="flex flex-col gap-2">
              <div
                :for={acc <- @accommodations}
                class="flex items-center gap-3 p-4 rounded-[var(--radius-md)] border border-[var(--paper-300)]"
                style="background: var(--surface-card);"
              >
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2">
                    <div style="font-family: var(--font-display); font-weight: 700; font-size: 16px; color: var(--ink-900);">{acc.location}</div>
                    <.signal_chip
                      tone={if stay_status(acc) == :current, do: "live", else: "ink"}
                      size="sm"
                      variant="tint"
                    >{stay_status(acc) |> Atom.to_string() |> String.upcase()}</.signal_chip>
                  </div>
                  <div class="mt-1 flex items-center gap-3 flex-wrap" style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400);">
                    <span>{Calendar.strftime(acc.check_in, "%d %b %Y")}{if acc.check_out, do: " – #{Calendar.strftime(acc.check_out, "%d %b %Y")}", else: " – open"}</span>
                    <span :if={acc.booking_reference}>REF: {acc.booking_reference}</span>
                  </div>
                  <div :if={acc.notes} class="mt-1 text-[13px]" style="color: var(--ink-700);">{acc.notes}</div>
                </div>
                <%= if @current_tour && @current_user && TourmanagerV2.Accounts.User.manager?(@current_user) do %>
                  <div class="flex items-center gap-1 flex-none">
                    <button type="button" phx-click="edit_accommodation" phx-value-id={acc.id} class="p-1.5 rounded-[var(--radius-sm)] cursor-pointer transition-colors hover:bg-[var(--paper-200)]" title="Edit">
                      <.icon name="hero-pencil-mini" class="w-4 h-4 text-[var(--ink-400)]" />
                    </button>
                    <button type="button" phx-click="delete_accommodation" phx-value-id={acc.id} data-confirm={"Remove #{acc.location}?"} class="p-1.5 rounded-[var(--radius-sm)] cursor-pointer transition-colors hover:bg-[var(--signal-stop-tint)]" title="Remove">
                      <.icon name="hero-trash-mini" class="w-4 h-4 text-[var(--signal-stop)]" />
                    </button>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>

      <%!-- Accommodation modal --%>
      <.tm_modal :if={@accommodation_form} id="accommodation-modal" show={@accommodation_modal_open} on_close="close_accommodation_modal">
        <div class="px-6 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand-on-dark);">ACCOMMODATION</div>
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; margin-top: 2px;">{if @editing_accommodation, do: "Edit accommodation", else: "Add accommodation"}</div>
        </div>
        <.form for={@accommodation_form} id="accommodation-form" phx-change="validate_accommodation" phx-submit="save_accommodation" class="px-6 py-5">
          <div class="flex flex-col gap-4">
            <.place_autocomplete_field
              form={@accommodation_form}
              field={:location}
              label="HOTEL / LOCATION"
              placeholder="Search hotel or address"
              suggestions={if @autocomplete_field == "accommodation", do: @place_suggestions, else: []}
              autocomplete_field="accommodation"
            />
            <.input field={@accommodation_form[:place_id]} type="hidden" />
            <.input field={@accommodation_form[:lat]} type="hidden" />
            <.input field={@accommodation_form[:lng]} type="hidden" />

            <.selected_place_chip
              :if={Phoenix.HTML.Form.input_value(@accommodation_form, :place_id) not in [nil, ""]}
              name={Phoenix.HTML.Form.input_value(@accommodation_form, :location)}
              place_id={Phoenix.HTML.Form.input_value(@accommodation_form, :place_id)}
            />

            <div class="grid grid-cols-2 gap-3">
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">CHECK-IN</label>
                <.input field={@accommodation_form[:check_in]} type="date" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
              </div>
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">CHECK-OUT</label>
                <.input field={@accommodation_form[:check_out]} type="date" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
              </div>
            </div>
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">BOOKING REF</label>
              <.input field={@accommodation_form[:booking_reference]} type="text" placeholder="Confirmation #" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
            </div>
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">NOTES</label>
              <.input field={@accommodation_form[:notes]} type="textarea" rows="2" placeholder="Optional" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none resize-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
            </div>
          </div>
          <div class="flex items-center justify-end gap-3 mt-6 pt-5 border-t border-[var(--paper-300)]">
            <button type="button" phx-click="close_accommodation_modal" class="px-4 py-2.5 rounded-[var(--radius-md)] cursor-pointer hover:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400); border: 1px solid var(--paper-300);">CANCEL</button>
            <button type="submit" class="px-5 py-2.5 rounded-[var(--radius-md)] cursor-pointer" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);">{if @editing_accommodation, do: "SAVE", else: "ADD"}</button>
          </div>
        </.form>
      </.tm_modal>
    </Layouts.app>
    """
  end
end
