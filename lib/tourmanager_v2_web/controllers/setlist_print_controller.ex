defmodule TourmanagerV2Web.SetlistPrintController do
  use TourmanagerV2Web, :controller

  alias TourmanagerV2.Touring
  alias TourmanagerV2.Repo

  def show(conn, %{"id" => id} = params) do
    setlist = Touring.get_setlist!(id)
    tour = if params["tour"], do: Repo.get(TourmanagerV2.Touring.Tour, params["tour"])

    date =
      case params["date"] do
        d when is_binary(d) and d != "" ->
          case Date.from_iso8601(d) do
            {:ok, date} -> date
            _ -> nil
          end

        _ ->
          setlist.date
      end

    venue = find_venue(tour, date)

    total_seconds =
      Enum.reduce(setlist.items, 0, fn item, acc ->
        acc + (item.duration_seconds || 0)
      end)

    mode = params["mode"] || "print"

    assigns = %{
      setlist: setlist,
      tour: tour,
      date: date,
      venue: venue,
      total_seconds: total_seconds,
      mode: mode
    }

    html =
      case mode do
        "stage" -> render_stage_page(assigns)
        _ -> render_print_page(assigns)
      end

    conn
    |> put_layout(false)
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  defp find_venue(nil, _date), do: nil

  defp find_venue(tour, date) do
    entries = Touring.build_route_with_entries(tour.id)

    if date do
      Enum.find(entries, fn r -> r.raw_date && Date.compare(r.raw_date, date) == :eq end)
    else
      nil
    end
  end

  defp render_print_page(assigns) do
    tour_name = if assigns.tour, do: assigns.tour.name, else: ""
    setlist_name = assigns.setlist.name |> String.upcase()

    date_str =
      if assigns.date do
        Calendar.strftime(assigns.date, "%d/%m/%y")
      else
        ""
      end

    venue_str =
      cond do
        assigns.venue && assigns.venue.venue -> assigns.venue.venue |> String.upcase()
        true -> ""
      end

    items_html =
      assigns.setlist.items
      |> Enum.map(fn item ->
        title = Phoenix.HTML.html_escape(item.title |> String.upcase()) |> Phoenix.HTML.safe_to_string()

        artist =
          if item.artist && item.artist != "" do
            " <span class=\"artist\">#{Phoenix.HTML.html_escape(item.artist) |> Phoenix.HTML.safe_to_string()}</span>"
          else
            ""
          end

        notes =
          if item.notes && item.notes != "" do
            "<div class=\"notes\">#{Phoenix.HTML.html_escape(item.notes) |> Phoenix.HTML.safe_to_string()}</div>"
          else
            ""
          end

        "<div class=\"song\"><div class=\"title\">#{title}#{artist}</div>#{notes}</div>"
      end)
      |> Enum.join("")

    esc = fn s -> Phoenix.HTML.html_escape(s) |> Phoenix.HTML.safe_to_string() end

    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8" />
      <title>#{esc.(assigns.setlist.name)} — #{esc.(tour_name)}</title>
      <style>
        @page { size: A4; margin: 18mm 20mm; }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
          color: #14110F;
          background: #fff;
        }
        .page {
          max-width: 700px; margin: 0 auto; padding: 40px 20px;
          min-height: 100vh;
          display: flex; flex-direction: column;
        }
        @media print {
          .page { padding: 0; max-width: none; min-height: auto; height: 100%; }
        }

        .header {
          display: flex;
          align-items: flex-start;
          gap: 14px;
          border-bottom: 3px solid #14110F;
          padding-bottom: 20px;
          margin-bottom: 28px;
        }
        .logo {
          width: 32px; height: 32px;
          background: #2B4FF0; border-radius: 5px;
          display: flex; align-items: center; justify-content: center;
          font-family: Georgia, serif;
          font-weight: 800; font-size: 20px; color: #fff;
          flex-shrink: 0;
          margin-top: 2px;
        }
        .header-text { flex: 1; }
        .tour-name {
          font-family: monospace;
          font-size: 9px; letter-spacing: 0.2em;
          color: #A8A29E; text-transform: uppercase;
        }
        .venue-name {
          font-weight: 800; font-size: 32px;
          letter-spacing: -0.02em; line-height: 1.05;
          margin-top: 4px;
        }
        .date-line {
          font-family: monospace;
          font-size: 12px; color: #78716C;
          margin-top: 4px; letter-spacing: 0.04em;
        }
        .setlist-label {
          font-family: monospace;
          font-size: 9px; letter-spacing: 0.2em;
          color: #2B4FF0;
          margin-top: 8px;
        }

        .artist-branding {
          text-align: center; padding: 16px;
          margin-bottom: 20px;
          color: #E7E5E4; font-family: monospace;
          font-size: 9px; letter-spacing: 0.1em;
        }
        @media print { .artist-branding { display: none; } }

        .songs { flex: 1; }
        .song {
          padding: 7px 0;
        }
        .title {
          font-size: 15px; font-weight: 600;
          text-transform: uppercase; letter-spacing: 0.02em;
          line-height: 1.3;
        }
        .artist {
          font-weight: 400; font-size: 13px;
          color: #78716C; text-transform: none;
          letter-spacing: 0;
        }
        .notes {
          font-family: monospace;
          font-size: 10px; color: #A8A29E;
          margin-top: 2px; padding-left: 12px;
          font-style: italic;
        }

        .footer {
          margin-top: auto; padding-top: 16px;
          border-top: 1px solid #E7E5E4;
          font-family: monospace; font-size: 8px;
          color: #D6D3D1; text-align: center;
          letter-spacing: 0.1em;
        }

        @media screen {
          .print-btn {
            position: fixed; bottom: 24px; right: 24px;
            background: #2B4FF0; color: #fff; border: 2px solid #14110F;
            font-family: monospace; font-size: 12px; font-weight: 700;
            letter-spacing: 0.06em;
            padding: 12px 24px; border-radius: 8px;
            cursor: pointer; box-shadow: 3px 3px 0 #14110F;
          }
        }
        @media print { .no-print { display: none !important; } }
      </style>
    </head>
    <body>
      <div class="page">
        <div class="header">
          <div class="logo">T</div>
          <div class="header-text">
            <div class="tour-name">#{esc.(tour_name)}</div>
            #{if venue_str != "" do "<div class=\"venue-name\">#{esc.(venue_str)}</div>" else "" end}
            #{if date_str != "" do "<div class=\"date-line\">#{date_str}</div>" else "" end}
            <div class="setlist-label">#{esc.(setlist_name)}</div>
          </div>
        </div>

        <div class="artist-branding">ARTIST BRANDING</div>

        <div class="songs">
          #{items_html}
        </div>

        <div class="footer">TOUR MANAGER — DAY SHEET OS</div>
      </div>

      <button class="print-btn no-print" onclick="window.print()">PRINT / SAVE PDF</button>
    </body>
    </html>
    """
  end

  defp render_stage_page(assigns) do
    setlist_name = assigns.setlist.name |> String.upcase()
    esc = fn s -> Phoenix.HTML.html_escape(s) |> Phoenix.HTML.safe_to_string() end

    venue_str =
      cond do
        assigns.venue && assigns.venue.venue -> assigns.venue.venue |> String.upcase()
        true -> ""
      end

    date_str =
      if assigns.date do
        Calendar.strftime(assigns.date, "%d/%m/%y")
      else
        ""
      end

    items_html =
      assigns.setlist.items
      |> Enum.map(fn item ->
        title = esc.(item.title |> String.upcase())

        notes =
          if item.notes && item.notes != "" do
            "<div class=\"notes\">#{esc.(item.notes)}</div>"
          else
            ""
          end

        "<div class=\"song\"><div class=\"title\">#{title}</div>#{notes}</div>"
      end)
      |> Enum.join("")

    tour_name = if assigns.tour, do: assigns.tour.name, else: ""

    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8" />
      <title>STAGE — #{esc.(assigns.setlist.name)}</title>
      <style>
        @page { size: A4; margin: 10mm 12mm; }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
          color: #000;
          background: #fff;
        }
        .page {
          max-width: 700px; margin: 0 auto; padding: 24px 16px;
          display: flex; flex-direction: column;
          min-height: 100vh;
        }
        @media print {
          .page { padding: 0; max-width: none; min-height: auto; }
        }

        .header {
          border-bottom: 4px solid #000;
          padding-bottom: 12px;
          margin-bottom: 10px;
        }
        .header-row {
          display: flex;
          align-items: center;
          gap: 12px;
        }
        .logo {
          width: 28px; height: 28px;
          background: #2B4FF0; border-radius: 4px;
          display: flex; align-items: center; justify-content: center;
          font-family: Georgia, serif;
          font-weight: 800; font-size: 17px; color: #fff;
          flex-shrink: 0;
        }
        .header-center {
          flex: 1; text-align: center;
          padding-right: 40px;
        }
        .venue {
          font-weight: 900; font-size: 22px;
          letter-spacing: 0.04em; line-height: 1.1;
        }
        .meta {
          font-size: 11px; color: #555;
          margin-top: 4px; letter-spacing: 0.06em;
        }
        .artist-branding {
          text-align: center; padding: 10px;
          margin-bottom: 10px;
          color: #ccc; font-size: 9px;
          letter-spacing: 0.1em;
        }
        @media print { .artist-branding { display: none; } }

        .songs {
          flex: 1;
          text-align: center;
        }
        .song {
          padding: 4px 0;
        }
        .title {
          font-size: 28px;
          font-weight: 800;
          letter-spacing: 0.04em;
          line-height: 1.2;
        }
        .notes {
          font-size: 12px;
          color: #666;
          margin-top: 1px;
          font-style: italic;
        }

        .footer {
          margin-top: 12px;
          padding-top: 8px;
          border-top: 2px solid #000;
          text-align: center;
          font-size: 8px; color: #aaa;
          letter-spacing: 0.1em;
        }

        @media screen {
          .print-btn {
            position: fixed; bottom: 24px; right: 24px;
            background: #000; color: #fff; border: none;
            font-family: monospace; font-size: 12px; font-weight: 700;
            letter-spacing: 0.06em;
            padding: 12px 24px; border-radius: 8px;
            cursor: pointer;
          }
        }
        @media print { .no-print { display: none !important; } }
      </style>
    </head>
    <body>
      <div class="page">
        <div class="header">
          <div class="header-row">
            <div class="logo">T</div>
            <div class="header-center">
              #{if venue_str != "" do "<div class=\"venue\">#{esc.(venue_str)}</div>" else "" end}
              <div class="meta">#{esc.(setlist_name)}#{if date_str != "", do: " — #{date_str}", else: ""}</div>
            </div>
          </div>
        </div>

        <div class="artist-branding">ARTIST BRANDING</div>

        <div class="songs">
          #{items_html}
        </div>

        <div class="footer">#{esc.(tour_name)}</div>
      </div>

      <button class="print-btn no-print" onclick="window.print()">PRINT / SAVE PDF</button>
    </body>
    </html>
    """
  end
end
