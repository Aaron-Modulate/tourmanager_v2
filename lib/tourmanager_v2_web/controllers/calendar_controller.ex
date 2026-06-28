defmodule TourmanagerV2Web.CalendarController do
  use TourmanagerV2Web, :controller

  alias TourmanagerV2.Touring

  def feed(conn, %{"token" => token}) do
    case Touring.get_tour_by_calendar_token(token) do
      nil ->
        conn
        |> put_status(404)
        |> text("Calendar not found")

      tour ->
        entries = Touring.build_route_with_entries(tour.id)
        ical = build_ical(tour, entries)

        conn
        |> put_resp_content_type("text/calendar")
        |> put_resp_header("content-disposition", "inline; filename=\"#{slugify(tour.name)}.ics\"")
        |> send_resp(200, ical)
    end
  end

  defp build_ical(tour, entries) do
    now = DateTime.utc_now() |> Calendar.strftime("%Y%m%dT%H%M%SZ")

    events =
      entries
      |> Enum.filter(fn e -> e.raw_date end)
      |> Enum.map(fn entry ->
        date_str = Date.to_iso8601(entry.raw_date) |> String.replace("-", "")

        summary =
          case entry.type do
            "vehicle_travel" -> "Travel: #{entry.city}"
            "gig" -> entry.venue
            "off_day" -> "Day off — #{entry.city}"
            _ -> entry.venue || entry.city
          end

        location =
          [entry.venue, entry.city]
          |> Enum.filter(&(&1 && &1 != "" && &1 != "—"))
          |> Enum.join(", ")

        description =
          [
            if(entry.booking_ref, do: "Ref: #{entry.booking_ref}"),
            if(entry.address && entry.address != "", do: entry.address)
          ]
          |> Enum.filter(& &1)
          |> Enum.join("\\n")

        uid = "#{entry.id}@tourmanager.live"

        """
        BEGIN:VEVENT
        UID:#{uid}
        DTSTART;VALUE=DATE:#{date_str}
        SUMMARY:#{escape_ical(summary)}
        #{if location != "", do: "LOCATION:#{escape_ical(location)}", else: ""}
        #{if description != "", do: "DESCRIPTION:#{escape_ical(description)}", else: ""}
        DTSTAMP:#{now}
        END:VEVENT
        """
        |> String.split("\n")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.join("\r\n")
      end)
      |> Enum.join("\r\n")

    tour_dates =
      if tour.start_date && tour.end_date do
        " (#{Calendar.strftime(tour.start_date, "%d %b")} – #{Calendar.strftime(tour.end_date, "%d %b %Y")})"
      else
        ""
      end

    """
    BEGIN:VCALENDAR\r
    VERSION:2.0\r
    PRODID:-//Tour Manager//tourmanager.live//EN\r
    CALSCALE:GREGORIAN\r
    METHOD:PUBLISH\r
    X-WR-CALNAME:#{escape_ical(tour.name)}#{tour_dates}\r
    X-WR-TIMEZONE:UTC\r
    #{events}\r
    END:VCALENDAR\r
    """
    |> String.trim()
  end

  defp escape_ical(text) when is_binary(text) do
    text
    |> String.replace("\\", "\\\\")
    |> String.replace(",", "\\,")
    |> String.replace(";", "\\;")
    |> String.replace("\n", "\\n")
  end

  defp escape_ical(nil), do: ""

  defp slugify(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end
end
