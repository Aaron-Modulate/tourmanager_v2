defmodule TourmanagerV2.Touring do
  import Ecto.Query
  alias TourmanagerV2.Repo
  alias TourmanagerV2.Touring.{Tour, Gig, RouteEntry}
  alias TourmanagerV2.Scheduling.Event

  def get_tour!(id), do: Repo.get!(Tour, id)

  def list_gigs_for_tour(tour_id) do
    Gig
    |> where(tour_id: ^tour_id)
    |> order_by(asc: :date)
    |> Repo.all()
  end

  def get_today_gig(tour_id) do
    today = Date.utc_today()

    Gig
    |> where(tour_id: ^tour_id, date: ^today)
    |> limit(1)
    |> Repo.one()
  end

  def get_next_gig(tour_id) do
    today = Date.utc_today()

    Gig
    |> where(tour_id: ^tour_id)
    |> where([g], g.date > ^today)
    |> order_by(asc: :date)
    |> limit(1)
    |> Repo.one()
  end

  def list_events_for_gig(nil), do: []

  def list_events_for_gig(gig_id) do
    Event
    |> where(gig_id: ^gig_id)
    |> order_by(asc: :starts_at, asc: :sort_order)
    |> Repo.all()
  end

  def list_crew_for_tour(tour_id) do
    Gig
    |> where(tour_id: ^tour_id)
    |> join(:inner, [g], cm in assoc(g, :crew_members))
    |> select([_g, cm], cm)
    |> distinct(true)
    |> order_by([_g, cm], asc: cm.name)
    |> Repo.all()
  end

  def list_crew_for_gig(nil), do: []

  def list_crew_for_gig(gig_id) do
    Gig
    |> where(id: ^gig_id)
    |> join(:inner, [g], cm in assoc(g, :crew_members))
    |> select([_g, cm], cm)
    |> order_by([_g, cm], asc: cm.name)
    |> Repo.all()
  end

  def list_artists_for_gig(nil), do: []

  def list_artists_for_gig(gig_id) do
    Gig
    |> where(id: ^gig_id)
    |> join(:inner, [g], a in assoc(g, :artists))
    |> select([_g, a], a)
    |> order_by([_g, a], asc: a.name)
    |> Repo.all()
  end

  def tour_stats(tour_id) do
    entries = list_route_entries(tour_id)
    gigs = list_gigs_for_tour(tour_id)
    today = Date.utc_today()

    gig_entries = Enum.filter(entries, &(&1.type == "gig"))
    total_gigs = length(gig_entries)
    gigs_played = Enum.count(gig_entries, fn e -> e.date && Date.compare(e.date, today) == :lt end)

    unconfirmed = Enum.count(gigs, fn g -> g.status != "confirmed" end)

    all_dates = entries |> Enum.map(& &1.date) |> Enum.reject(&is_nil/1)
    start_date = Enum.min(all_dates, Date, fn -> today end)
    end_date = Enum.max(all_dates, Date, fn -> today end)
    days_elapsed = Date.diff(today, start_date) |> max(0)
    total_days = (Date.diff(end_date, start_date) + 1) |> max(1)

    gig_dates = gig_entries |> Enum.map(& &1.date) |> MapSet.new()

    travel_only_dates =
      entries
      |> Enum.filter(&(&1.type == "vehicle_travel"))
      |> Enum.map(& &1.date)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.reject(&MapSet.member?(gig_dates, &1))

    travel_days = length(travel_only_dates)
    is_travel_today = today in travel_only_dates

    %{
      shows_played: gigs_played,
      shows_total: total_gigs,
      days_on_road: days_elapsed,
      total_days: total_days,
      travel_days: travel_days,
      unconfirmed_gigs: unconfirmed,
      start_date: if(all_dates != [], do: start_date),
      end_date: if(all_dates != [], do: end_date),
      is_travel_today: is_travel_today
    }
  end

  def delete_route_entry(%RouteEntry{} = entry) do
    Repo.delete(entry)
  end

  def build_route(tour_id) do
    gigs = list_gigs_for_tour(tour_id)
    today = Date.utc_today()

    gigs
    |> Enum.with_index(1)
    |> Enum.map(fn {gig, day_num} ->
      status =
        cond do
          gig.date && Date.compare(gig.date, today) == :lt -> "done"
          gig.date && Date.compare(gig.date, today) == :eq -> "today"
          true -> "next"
        end

      %{
        day: day_num,
        date: if(gig.date, do: Calendar.strftime(gig.date, "%d %b") |> String.upcase(), else: "TBD"),
        city: gig.city || "TBD",
        venue: gig.venue || gig.name,
        code: gig.venue_code || String.slice(gig.city || "TBD", 0, 3) |> String.upcase(),
        km: 0,
        status: status,
        gig: gig
      }
    end)
  end

  def get_today_route_entry(tour_id) do
    today = Date.utc_today()

    RouteEntry
    |> where(tour_id: ^tour_id, date: ^today)
    |> where([r], r.type == "gig")
    |> order_by(asc: :sort_order)
    |> limit(1)
    |> Repo.one()
  end

  def get_next_route_entry(tour_id) do
    today = Date.utc_today()

    RouteEntry
    |> where(tour_id: ^tour_id)
    |> where([r], r.date > ^today)
    |> where([r], r.type == "gig")
    |> order_by(asc: :date, asc: :sort_order)
    |> limit(1)
    |> Repo.one()
  end

  def list_route_entries(tour_id) do
    RouteEntry
    |> where(tour_id: ^tour_id)
    |> order_by([r], asc: r.date, asc: r.sort_order)
    |> Repo.all()
  end

  def create_route_entry(tour, workspace_id, attrs) do
    %RouteEntry{tour_id: tour.id, workspace_id: workspace_id}
    |> RouteEntry.changeset(attrs)
    |> Repo.insert()
  end

  def get_route_entry!(id), do: Repo.get!(RouteEntry, id)

  def update_route_entry(%RouteEntry{} = entry, attrs) do
    entry
    |> RouteEntry.changeset(attrs)
    |> Repo.update()
  end

  def change_route_entry(entry \\ %RouteEntry{}, attrs \\ %{}) do
    RouteEntry.changeset(entry, attrs)
  end

  def build_route_with_entries(tour_id) do
    entries = list_route_entries(tour_id)
    today = Date.utc_today()

    {built, _next_assigned} =
      entries
      |> Enum.with_index(1)
      |> Enum.map_reduce(false, fn {entry, day_num}, next_assigned ->
        {status, next_assigned} =
          cond do
            entry.date && Date.compare(entry.date, today) == :lt -> {"done", next_assigned}
            entry.date && Date.compare(entry.date, today) == :eq -> {"today", next_assigned}
            !next_assigned -> {"next", true}
            true -> {"upcoming", next_assigned}
          end

        item = %{
          id: entry.id,
          day: day_num,
          type: entry.type,
          date: if(entry.date, do: Calendar.strftime(entry.date, "%d %b") |> String.upcase(), else: "TBD"),
          raw_date: entry.date,
          city: entry.city || entry.destination || "—",
          venue: entry.venue || entry.origin || "—",
          address: entry.origin_address || entry.dest_address,
          code: entry.venue_code || String.slice(entry.city || entry.destination || "—", 0, 3) |> String.upcase(),
          km: entry.distance_km || 0,
          travel_duration: entry.travel_duration_seconds,
          booking_ref: entry.booking_reference,
          status: status,
          entry: entry
        }

        {item, next_assigned}
    end)

    built
  end

  def compute_leg_distances(entries) when length(entries) < 2, do: entries

  def compute_leg_distances(entries) do
    entries
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.reduce(%{}, fn [a, b], acc ->
      origin = a.entry.city || a.entry.destination
      dest = b.entry.city || b.entry.origin || b.entry.city

      if origin && dest do
        case TourmanagerV2.GoogleMaps.distance_between(origin, dest) do
          {:ok, %{km: km}} -> Map.put(acc, b.id, km)
          _ -> acc
        end
      else
        acc
      end
    end)
  end
end
