defmodule TourmanagerV2Web.SetlistLive do
  use TourmanagerV2Web, :live_view
  use TourmanagerV2Web.TourSwitching

  alias TourmanagerV2.Touring
  alias TourmanagerV2.Accounts.User

  @max_file_size 10_000_000
  @accepted_types ~w(.pdf .jpg .jpeg .png .heic)

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(TourSwitching.default_assigns())
      |> assign(
        active_nav: "setlists",
        page_title: "Setlists",
        setlists: [],
        viewing_setlist: nil,
        setlist_form: nil,
        setlist_modal_open: false,
        item_form: nil,
        item_modal_open: false,
        editing_item: nil
      )
      |> TourSwitching.load_tour_data(socket.assigns[:current_tour])
      |> load_setlists()
      |> allow_upload(:setlist_file,
        accept: @accepted_types,
        max_file_size: @max_file_size,
        max_entries: 1
      )

    {:ok, socket}
  end

  def handle_event("select_tour", %{"tour-id" => tour_id}, socket) do
    {:noreply, socket} = TourSwitching.handle_event("select_tour", %{"tour-id" => tour_id}, socket)
    {:noreply, load_setlists(socket)}
  end

  def handle_info({:tour_data_changed, tour_id, source_pid}, socket) do
    if source_pid != self() && socket.assigns[:current_tour] && socket.assigns.current_tour.id == tour_id do
      {:noreply,
       socket
       |> TourSwitching.load_tour_data(socket.assigns.current_tour)
       |> load_setlists()}
    else
      {:noreply, socket}
    end
  end

  def handle_event("new_setlist", _params, socket) do
    changeset = Touring.change_setlist()

    {:noreply,
     socket
     |> assign(:setlist_modal_open, true)
     |> assign(:setlist_form, Phoenix.Component.to_form(changeset))
     |> assign(:viewing_setlist, nil)}
  end

  def handle_event("close_setlist_modal", _params, socket) do
    {:noreply, assign(socket, :setlist_modal_open, false)}
  end

  def handle_event("validate_setlist", %{"setlist" => params}, socket) do
    changeset = Touring.change_setlist(%TourmanagerV2.Touring.Setlist{}, params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, :setlist_form, Phoenix.Component.to_form(changeset))}
  end

  def handle_event("save_setlist", %{"setlist" => params}, socket) do
    tour = socket.assigns.current_tour
    user = socket.assigns.current_user

    if tour && user do
      {file_url, file_type, source} = consume_upload(socket)

      params =
        params
        |> Map.put("file_url", file_url)
        |> Map.put("file_type", file_type)
        |> Map.put("source", source)

      case Touring.create_setlist(tour.id, user.id, params) do
        {:ok, setlist} ->
          if file_url && file_type in ["jpg", "jpeg", "png", "heic"] do
            Task.start(fn -> run_ocr(setlist) end)
          end

          TourmanagerV2.TourBroadcast.broadcast_change(tour.id)

          {:noreply,
           socket
           |> assign(:setlist_modal_open, false)
           |> load_setlists()}

        {:error, changeset} ->
          {:noreply, assign(socket, :setlist_form, Phoenix.Component.to_form(changeset))}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("view_setlist", %{"id" => id}, socket) do
    setlist = Touring.get_setlist!(id)
    {:noreply, assign(socket, :viewing_setlist, setlist)}
  end

  def handle_event("close_setlist_view", _params, socket) do
    {:noreply, assign(socket, :viewing_setlist, nil)}
  end

  def handle_event("delete_setlist", %{"id" => id}, socket) do
    tour = socket.assigns.current_tour
    setlist = Touring.get_setlist!(id)
    Touring.delete_setlist(setlist)

    if tour, do: TourmanagerV2.TourBroadcast.broadcast_change(tour.id)

    {:noreply,
     socket
     |> assign(:viewing_setlist, nil)
     |> load_setlists()}
  end

  def handle_event("toggle_tour_default", %{"id" => id}, socket) do
    setlist = Touring.get_setlist!(id)
    tour = socket.assigns.current_tour
    new_value = !setlist.is_tour_default

    Touring.update_setlist(setlist, %{is_tour_default: new_value, date: nil})

    if tour, do: TourmanagerV2.TourBroadcast.broadcast_change(tour.id)

    {:noreply, load_setlists(socket)}
  end

  # --- Setlist items ---

  def handle_event("add_item", %{"setlist-id" => setlist_id}, socket) do
    setlist = Touring.get_setlist!(setlist_id)
    next_position = length(setlist.items)
    changeset = TourmanagerV2.Touring.SetlistItem.changeset(%TourmanagerV2.Touring.SetlistItem{}, %{position: next_position})

    {:noreply,
     socket
     |> assign(:item_modal_open, true)
     |> assign(:item_form, Phoenix.Component.to_form(changeset))
     |> assign(:editing_item, nil)
     |> assign(:editing_setlist_id, setlist_id)}
  end

  def handle_event("edit_item", %{"id" => id}, socket) do
    item = TourmanagerV2.Repo.get!(TourmanagerV2.Touring.SetlistItem, id)
    changeset = TourmanagerV2.Touring.SetlistItem.changeset(item, %{})

    {:noreply,
     socket
     |> assign(:item_modal_open, true)
     |> assign(:item_form, Phoenix.Component.to_form(changeset))
     |> assign(:editing_item, item)
     |> assign(:editing_setlist_id, item.setlist_id)}
  end

  def handle_event("close_item_modal", _params, socket) do
    {:noreply, assign(socket, :item_modal_open, false)}
  end

  def handle_event("validate_item", %{"setlist_item" => params}, socket) do
    source = socket.assigns[:editing_item] || %TourmanagerV2.Touring.SetlistItem{}
    changeset = TourmanagerV2.Touring.SetlistItem.changeset(source, params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, :item_form, Phoenix.Component.to_form(changeset))}
  end

  def handle_event("save_item", %{"setlist_item" => params}, socket) do
    setlist_id = socket.assigns[:editing_setlist_id]

    case Touring.add_setlist_item(setlist_id, params) do
      {:ok, _item} ->
        setlist = Touring.get_setlist!(setlist_id)

        {:noreply,
         socket
         |> assign(:item_modal_open, false)
         |> assign(:viewing_setlist, setlist)
         |> load_setlists()}

      {:error, changeset} ->
        {:noreply, assign(socket, :item_form, Phoenix.Component.to_form(changeset))}
    end
  end

  def handle_event("update_item", %{"setlist_item" => params}, socket) do
    item = socket.assigns[:editing_item]

    if item do
      case Touring.update_setlist_item(item, params) do
        {:ok, _} ->
          setlist = Touring.get_setlist!(item.setlist_id)

          {:noreply,
           socket
           |> assign(:item_modal_open, false)
           |> assign(:viewing_setlist, setlist)
           |> load_setlists()}

        {:error, changeset} ->
          {:noreply, assign(socket, :item_form, Phoenix.Component.to_form(changeset))}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("reorder_items", %{"ids" => ids}, socket) do
    setlist = socket.assigns[:viewing_setlist]

    if setlist do
      Touring.reorder_setlist_items(setlist.id, ids)
      updated = Touring.get_setlist!(setlist.id)

      {:noreply,
       socket
       |> assign(:viewing_setlist, updated)
       |> load_setlists()}
    else
      {:noreply, socket}
    end
  end

  def handle_event("delete_item", %{"id" => id}, socket) do
    item = TourmanagerV2.Repo.get!(TourmanagerV2.Touring.SetlistItem, id)
    setlist_id = item.setlist_id
    Touring.delete_setlist_item(item)
    setlist = Touring.get_setlist!(setlist_id)

    {:noreply,
     socket
     |> assign(:viewing_setlist, setlist)
     |> load_setlists()}
  end

  defp load_setlists(socket) do
    tour = socket.assigns[:current_tour]

    if tour do
      assign(socket, :setlists, Touring.list_setlists_for_tour(tour.id))
    else
      assign(socket, :setlists, [])
    end
  end

  defp consume_upload(socket) do
    uploaded =
      consume_uploaded_entries(socket, :setlist_file, fn %{path: path}, entry ->
        ext = Path.extname(entry.client_name) |> String.trim_leading(".") |> String.downcase()
        content_type = entry.client_type
        filename = "setlists/#{Ecto.UUID.generate()}.#{ext}"
        content = File.read!(path)

        case TourmanagerV2.Storage.upload(filename, content, content_type) do
          {:ok, url} -> {:ok, {url, ext}}
          _ -> {:ok, {nil, nil}}
        end
      end)

    case uploaded do
      [{url, ext}] -> {url, ext, if(ext in ~w(jpg jpeg png heic), do: "upload", else: "upload")}
      _ -> {nil, nil, "manual"}
    end
  end

  defp run_ocr(setlist) do
    Touring.update_setlist(setlist, %{ocr_status: "pending"})
    # OCR via Claude Vision will be implemented as a separate module
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
    >
      <div id="setlist-page" class="p-4 md:p-7 max-w-3xl">
        <div class="flex items-end justify-between mb-5">
          <div>
            <.overline>Setlists</.overline>
            <.display size={26} class="mt-1.5">
              {if @current_tour, do: @current_tour.name, else: "Setlists"}
            </.display>
          </div>
          <%= if @current_tour && @current_user && User.manager?(@current_user) do %>
            <.tm_button variant="primary" size="sm" icon_name="hero-plus" phx-click="new_setlist">New</.tm_button>
          <% end %>
        </div>

        <%= if !@current_tour do %>
          <div class="py-16 text-center" style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400); letter-spacing: 0.06em;">
            Select a tour to manage setlists.
          </div>
        <% else %>
          <%= if @viewing_setlist do %>
            <%!-- Setlist detail view --%>
            <div class="mb-4">
              <button type="button" phx-click="close_setlist_view" class="flex items-center gap-1.5 cursor-pointer" style="font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400);">
                <.icon name="hero-arrow-left-mini" class="w-3.5 h-3.5" /> ALL SETLISTS
              </button>
            </div>

            <div class="rounded-[var(--radius-md)] border-2 border-[var(--ink-900)] overflow-hidden" style="box-shadow: var(--shadow-hard);">
              <%!-- Header --%>
              <div class="px-5 py-4 flex items-center justify-between" style="background: var(--surface-stage);">
                <div>
                  <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);">
                    {cond do
                      @viewing_setlist.is_tour_default -> "TOUR DEFAULT"
                      @viewing_setlist.date -> Calendar.strftime(@viewing_setlist.date, "%d %b %Y") |> String.upcase()
                      true -> "SETLIST"
                    end}
                  </div>
                  <div style="font-family: var(--font-display); font-weight: 800; font-size: 22px; color: #fff; margin-top: 2px;">
                    {@viewing_setlist.name}
                  </div>
                </div>
                <div class="flex items-center gap-2">
                  <%= if @current_user && User.manager?(@current_user) do %>
                    <.tm_button variant="secondary" size="sm" icon_name="hero-plus" phx-click="add_item" phx-value-setlist-id={@viewing_setlist.id}>Add song</.tm_button>
                    <button type="button" phx-click="delete_setlist" phx-value-id={@viewing_setlist.id} data-confirm="Delete this setlist?" class="p-2 rounded-[var(--radius-sm)] cursor-pointer transition-colors hover:bg-[var(--ink-700)]">
                      <.icon name="hero-trash-mini" class="w-4 h-4 text-[var(--signal-stop)]" />
                    </button>
                  <% end %>
                </div>
              </div>

              <%!-- File preview --%>
              <div :if={@viewing_setlist.file_url} class="border-b border-[var(--paper-300)]">
                <%= if @viewing_setlist.file_type in ~w(jpg jpeg png heic) do %>
                  <img src={@viewing_setlist.file_url} class="w-full max-h-[400px] object-contain" style="background: var(--paper-200);" />
                <% else %>
                  <div class="px-5 py-4 flex items-center gap-3" style="background: var(--paper-200);">
                    <.icon name="hero-document" class="w-5 h-5 text-[var(--ink-400)]" />
                    <a href={@viewing_setlist.file_url} target="_blank" class="no-underline" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; color: var(--brand);">
                      DOWNLOAD PDF
                    </a>
                  </div>
                <% end %>
              </div>

              <%!-- Items list --%>
              <div style="background: var(--surface-card);">
                <%= if @viewing_setlist.items == [] do %>
                  <div class="py-10 text-center" style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400);">
                    No songs added yet.
                    <%= if @viewing_setlist.ocr_status == "pending" do %>
                      <div class="mt-2 flex items-center justify-center gap-2" style="color: var(--brand);">
                        <.icon name="hero-arrow-path" class="w-3.5 h-3.5 motion-safe:animate-spin" />
                        Processing uploaded image...
                      </div>
                    <% end %>
                  </div>
                <% else %>
                  <div id={"setlist-items-#{@viewing_setlist.id}"} phx-hook=".SortableList" phx-update="ignore">
                    <div :for={item <- @viewing_setlist.items} id={"item-#{item.id}"} data-id={item.id} class="flex items-center gap-3 px-5 py-3 border-b border-[var(--paper-300)] last:border-b-0 group/item transition-colors hover:bg-[var(--paper-200)]" style="background: var(--surface-card);">
                      <%= if @current_user && User.manager?(@current_user) do %>
                        <div class="flex-none cursor-grab active:cursor-grabbing drag-handle touch-none" style="color: var(--ink-300);">
                          <.icon name="hero-bars-2-mini" class="w-4 h-4" />
                        </div>
                      <% end %>
                      <div class="w-6 text-right flex-none setlist-position" style="font-family: var(--font-mono); font-size: 13px; font-weight: 700; color: var(--ink-300);">
                        {item.position + 1}
                      </div>
                      <div class="flex-1 min-w-0">
                        <div class="text-[14px] font-semibold text-[var(--ink-900)] truncate">{item.title}</div>
                        <div :if={item.artist || item.notes} style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); margin-top: 1px;">
                          {item.artist}{if item.artist && item.notes, do: " · "}{item.notes}
                        </div>
                      </div>
                      <div :if={item.duration_seconds} style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400);">
                        {div(item.duration_seconds, 60)}:{rem(item.duration_seconds, 60) |> Integer.to_string() |> String.pad_leading(2, "0")}
                      </div>
                      <%= if @current_user && User.manager?(@current_user) do %>
                        <div class="flex items-center gap-1 opacity-0 group-hover/item:opacity-100 transition-opacity">
                          <button type="button" phx-click="edit_item" phx-value-id={item.id} class="p-1 rounded-[var(--radius-sm)] cursor-pointer hover:bg-[var(--paper-300)]">
                            <.icon name="hero-pencil-mini" class="w-3.5 h-3.5 text-[var(--ink-400)]" />
                          </button>
                          <button type="button" phx-click="delete_item" phx-value-id={item.id} data-confirm="Remove this song?" class="p-1 rounded-[var(--radius-sm)] cursor-pointer hover:bg-[var(--signal-stop-tint)]">
                            <.icon name="hero-trash-mini" class="w-3.5 h-3.5 text-[var(--signal-stop)]" />
                          </button>
                        </div>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          <% else %>
            <%!-- Setlist list --%>
            <%= if @setlists == [] do %>
              <div class="py-16 text-center">
                <div style="font-family: var(--font-mono); font-size: 12px; color: var(--ink-400); letter-spacing: 0.06em;">
                  No setlists yet.
                </div>
                <%= if @current_user && User.manager?(@current_user) do %>
                  <button type="button" phx-click="new_setlist" class="mt-4 px-5 py-2.5 rounded-[var(--radius-md)] cursor-pointer inline-flex items-center gap-2" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);">
                    <.icon name="hero-musical-note" class="w-4 h-4" /> CREATE SETLIST
                  </button>
                <% end %>
              </div>
            <% else %>
              <div class="flex flex-col gap-2">
                <div
                  :for={sl <- @setlists}
                  phx-click="view_setlist"
                  phx-value-id={sl.id}
                  class="flex items-center gap-3 p-4 rounded-[var(--radius-md)] border border-[var(--paper-300)] cursor-pointer transition-colors hover:bg-[var(--paper-200)]"
                  style="background: var(--surface-card);"
                >
                  <div class="w-10 h-10 rounded-[var(--radius-sm)] flex items-center justify-center flex-none" style={"background: #{if sl.is_tour_default, do: "var(--brand)", else: "var(--paper-200)"};"}>
                    <.icon name="hero-musical-note" class={["w-5 h-5", if(sl.is_tour_default, do: "text-white", else: "text-[var(--ink-400)]")]} />
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="text-[14px] font-semibold text-[var(--ink-900)] truncate">{sl.name}</div>
                    <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400); margin-top: 1px;">
                      {length(sl.items)} songs
                      {if sl.date, do: " · #{Calendar.strftime(sl.date, "%d %b %Y")}", else: ""}
                    </div>
                  </div>
                  <div class="flex items-center gap-2">
                    <%= if sl.is_tour_default do %>
                      <.signal_chip tone="brand" size="sm" variant="tint">DEFAULT</.signal_chip>
                    <% end %>
                    <%= if sl.date do %>
                      <.signal_chip tone="doors" size="sm" variant="tint">DATE</.signal_chip>
                    <% end %>
                    <%= if sl.file_url do %>
                      <.icon name="hero-paper-clip-mini" class="w-3.5 h-3.5 text-[var(--ink-300)]" />
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>
        <% end %>
      </div>

      <%!-- New setlist modal --%>
      <.tm_modal :if={@setlist_form} id="setlist-modal" show={@setlist_modal_open} on_close="close_setlist_modal">
        <div class="px-6 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);">NEW</div>
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; margin-top: 2px;">Create setlist</div>
        </div>
        <.form for={@setlist_form} id="setlist-form" phx-change="validate_setlist" phx-submit="save_setlist" class="px-6 py-5">
          <div class="flex flex-col gap-4">
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">NAME</label>
              <.input field={@setlist_form[:name]} type="text" placeholder="e.g. Main Set, Encore" class="w-full px-3 py-2.5 text-[15px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
            </div>
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">DATE (LEAVE BLANK FOR TOUR DEFAULT)</label>
              <.input field={@setlist_form[:date]} type="date" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
            </div>
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">UPLOAD SETLIST (PDF OR PHOTO)</label>
              <div class="rounded-[var(--radius-md)] border-2 border-dashed border-[var(--paper-300)] p-6 text-center transition-colors" phx-drop-target={@uploads.setlist_file.ref}>
                <.live_file_input upload={@uploads.setlist_file} class="hidden" />
                <label for={@uploads.setlist_file.ref} class="cursor-pointer">
                  <.icon name="hero-arrow-up-tray" class="w-8 h-8 text-[var(--ink-300)] mx-auto mb-2" />
                  <div style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-400);">
                    Drop a file or <span style="color: var(--brand); font-weight: 700;">browse</span>
                  </div>
                  <div class="mt-1" style="font-family: var(--font-mono); font-size: 9px; color: var(--ink-300);">PDF, JPG, PNG · Max 10MB</div>
                </label>
              </div>
              <%= for entry <- @uploads.setlist_file.entries do %>
                <div class="mt-3 flex items-center gap-3 px-3 py-2 rounded-[var(--radius-sm)] border border-[var(--paper-300)]" style="background: var(--paper-200);">
                  <.icon name="hero-document" class="w-4 h-4 text-[var(--ink-400)]" />
                  <div class="flex-1 min-w-0 truncate" style="font-family: var(--font-mono); font-size: 11px; color: var(--ink-700);">
                    {entry.client_name}
                  </div>
                  <div style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400);">
                    {Float.round(entry.client_size / 1_000_000, 1)}MB
                  </div>
                  <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} class="p-0.5 cursor-pointer">
                    <.icon name="hero-x-mark-mini" class="w-3.5 h-3.5 text-[var(--ink-400)]" />
                  </button>
                </div>
              <% end %>
            </div>
            <div class="flex items-center gap-3">
              <input type="checkbox" name="setlist[is_tour_default]" value="true" id="setlist-default-toggle" class="hidden peer/default" />
              <label for="setlist-default-toggle" class="flex items-center gap-2 cursor-pointer">
                <div class="w-7 h-4 rounded-full relative transition-colors peer-checked/default:bg-[var(--brand)]" style="background: var(--paper-300); border: 1px solid var(--ink-300);">
                  <div class="absolute top-0.5 left-0.5 w-2.5 h-2.5 rounded-full bg-white transition-all peer-checked/default:left-[14px]" />
                </div>
                <span style="font-family: var(--font-mono); font-size: 10px; color: var(--ink-400);">USE AS TOUR DEFAULT</span>
              </label>
            </div>
          </div>
          <div class="flex items-center justify-end gap-3 mt-6 pt-5 border-t border-[var(--paper-300)]">
            <button type="button" phx-click="close_setlist_modal" class="px-4 py-2.5 rounded-[var(--radius-md)] cursor-pointer hover:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400); border: 1px solid var(--paper-300);">CANCEL</button>
            <button type="submit" class="px-5 py-2.5 rounded-[var(--radius-md)] cursor-pointer" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);">CREATE</button>
          </div>
        </.form>
      </.tm_modal>

      <%!-- Add/edit item modal --%>
      <.tm_modal :if={@item_form} id="item-modal" show={@item_modal_open} on_close="close_item_modal">
        <div class="px-6 py-4 border-b-2 border-[var(--ink-900)]" style="background: var(--surface-stage);">
          <div style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--brand);">{if @editing_item, do: "EDIT", else: "ADD"}</div>
          <div style="font-family: var(--font-display); font-weight: 800; font-size: 20px; color: #fff; margin-top: 2px;">{if @editing_item, do: "Edit song", else: "Add song"}</div>
        </div>
        <.form for={@item_form} id="item-form" phx-change="validate_item" phx-submit={if @editing_item, do: "update_item", else: "save_item"} class="px-6 py-5">
          <div class="flex flex-col gap-4">
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">SONG TITLE</label>
              <.input field={@item_form[:title]} type="text" placeholder="e.g. Bohemian Rhapsody" class="w-full px-3 py-2.5 text-[15px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] focus:ring-2 focus:ring-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
            </div>
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">ARTIST (FOR COVERS)</label>
              <.input field={@item_form[:artist]} type="text" placeholder="Original artist" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
            </div>
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">POSITION</label>
                <.input field={@item_form[:position]} type="number" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
              </div>
              <div>
                <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">DURATION (SECONDS)</label>
                <.input field={@item_form[:duration_seconds]} type="number" placeholder="240" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-mono);" />
              </div>
            </div>
            <div>
              <label style="font-family: var(--font-mono); font-size: 9px; letter-spacing: 0.2em; color: var(--ink-400); display: block; margin-bottom: 6px;">NOTES</label>
              <.input field={@item_form[:notes]} type="text" placeholder="e.g. Drop D, click track, long intro" class="w-full px-3 py-2.5 text-[14px] rounded-[var(--radius-md)] border border-[var(--paper-300)] focus:border-[var(--brand)] outline-none" style="background: var(--surface-card); color: var(--ink-900); font-family: var(--font-sans);" />
            </div>
          </div>
          <div class="flex items-center justify-end gap-3 mt-6 pt-5 border-t border-[var(--paper-300)]">
            <button type="button" phx-click="close_item_modal" class="px-4 py-2.5 rounded-[var(--radius-md)] cursor-pointer hover:bg-[var(--paper-200)]" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: var(--ink-400); border: 1px solid var(--paper-300);">CANCEL</button>
            <button type="submit" class="px-5 py-2.5 rounded-[var(--radius-md)] cursor-pointer" style="font-family: var(--font-mono); font-size: 12px; font-weight: 700; letter-spacing: 0.06em; color: #fff; background: var(--brand); border: 2px solid var(--ink-900); box-shadow: var(--shadow-hard-sm);">{if @editing_item, do: "SAVE", else: "ADD SONG"}</button>
          </div>
        </.form>
      </.tm_modal>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".SortableList">
        export default {
          mounted() {
            this.dragEl = null
            this.placeholder = null
            this.startY = 0
            this.startIndex = 0

            this.items().forEach((item, i) => {
              const handle = item.querySelector('.drag-handle')
              if (!handle) return

              handle.addEventListener('pointerdown', (e) => {
                e.preventDefault()
                this.startDrag(item, e.clientY)
              })
            })

            document.addEventListener('pointermove', (e) => this.onMove(e))
            document.addEventListener('pointerup', () => this.endDrag())
          },

          items() {
            return [...this.el.children]
          },

          startDrag(el, clientY) {
            this.dragEl = el
            this.startY = clientY
            const rect = el.getBoundingClientRect()

            this.placeholder = document.createElement('div')
            this.placeholder.style.height = rect.height + 'px'
            this.placeholder.style.background = 'var(--marker-050)'
            this.placeholder.style.borderRadius = 'var(--radius-sm)'
            this.placeholder.style.border = '2px dashed var(--brand)'
            this.placeholder.style.margin = '0'

            el.style.position = 'fixed'
            el.style.zIndex = '100'
            el.style.width = rect.width + 'px'
            el.style.left = rect.left + 'px'
            el.style.top = rect.top + 'px'
            el.style.boxShadow = 'var(--shadow-hard)'
            el.style.opacity = '0.95'
            el.style.pointerEvents = 'none'

            el.parentNode.insertBefore(this.placeholder, el)
          },

          onMove(e) {
            if (!this.dragEl) return
            const dy = e.clientY - this.startY
            const rect = this.dragEl.getBoundingClientRect()
            this.dragEl.style.top = (rect.top + dy) + 'px'
            this.startY = e.clientY

            const siblings = this.items().filter(c => c !== this.dragEl && c !== this.placeholder)
            for (const sib of siblings) {
              const r = sib.getBoundingClientRect()
              const mid = r.top + r.height / 2
              if (e.clientY < mid) {
                sib.parentNode.insertBefore(this.placeholder, sib)
                return
              }
            }
            if (siblings.length > 0) {
              const last = siblings[siblings.length - 1]
              last.parentNode.insertBefore(this.placeholder, last.nextSibling)
            }
          },

          endDrag() {
            if (!this.dragEl) return

            this.dragEl.style.position = ''
            this.dragEl.style.zIndex = ''
            this.dragEl.style.width = ''
            this.dragEl.style.left = ''
            this.dragEl.style.top = ''
            this.dragEl.style.boxShadow = ''
            this.dragEl.style.opacity = ''
            this.dragEl.style.pointerEvents = ''

            this.placeholder.parentNode.insertBefore(this.dragEl, this.placeholder)
            this.placeholder.remove()

            const ids = this.items().map(el => el.dataset.id).filter(Boolean)
            this.items().forEach((el, i) => {
              const pos = el.querySelector('.setlist-position')
              if (pos) pos.textContent = i + 1
            })

            this.pushEvent('reorder_items', { ids })

            this.dragEl = null
            this.placeholder = null
          }
        }
      </script>
    </Layouts.app>
    """
  end
end
