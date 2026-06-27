defmodule TourmanagerV2.Touring do
  import Ecto.Query
  alias TourmanagerV2.Repo
  alias TourmanagerV2.Touring.{Tour, Gig, RouteEntry, TourMembership, TourInvite, DateCrewAssignment}
  alias TourmanagerV2.Scheduling.Event

  def get_tour!(id), do: Repo.get!(Tour, id)

  # --- Tour memberships & crew ---

  def list_tour_memberships(tour_id) do
    TourMembership
    |> where(tour_id: ^tour_id)
    |> join(:inner, [tm], u in assoc(tm, :user))
    |> select([tm, u], %{membership: tm, user: u})
    |> order_by([tm, u], [asc: tm.role, asc: u.name])
    |> Repo.all()
  end

  def list_crew_memberships(tour_id) do
    TourMembership
    |> where(tour_id: ^tour_id, role: "crew")
    |> join(:inner, [tm], u in assoc(tm, :user))
    |> select([tm, u], %{membership: tm, user: u})
    |> order_by([_tm, u], asc: u.name)
    |> Repo.all()
  end

  def count_crew_on_tour(tour_id) do
    TourMembership
    |> where(tour_id: ^tour_id, role: "crew")
    |> Repo.aggregate(:count)
  end

  @doc """
  Total seats = sum of crew_seats from all managers on the tour.
  Each manager's subscription contributes their crew_seats allocation.
  """
  def total_seats_on_tour(tour_id) do
    TourMembership
    |> where(tour_id: ^tour_id, role: "manager")
    |> join(:inner, [tm], u in assoc(tm, :user))
    |> select([_tm, u], u.crew_seats)
    |> Repo.all()
    |> Enum.sum()
  end

  def crew_seats_remaining(tour_id) do
    total = total_seats_on_tour(tour_id)
    used = count_crew_on_tour(tour_id)
    max(total - used, 0)
  end

  def remove_crew_from_tour(tour_id, user_id) do
    case Repo.get_by(TourMembership, tour_id: tour_id, user_id: user_id, role: "crew") do
      nil -> {:error, :not_found}
      membership -> Repo.delete(membership)
    end
  end

  def promote_to_manager(tour_id, user_id) do
    case Repo.get_by(TourMembership, tour_id: tour_id, user_id: user_id) do
      nil ->
        {:error, :not_found}

      membership ->
        user = Repo.get!(TourmanagerV2.Accounts.User, user_id)

        if TourmanagerV2.Accounts.User.subscribed?(user) do
          membership
          |> TourMembership.changeset(%{role: "manager"})
          |> Repo.update()
        else
          {:error, :not_subscribed}
        end
    end
  end

  def demote_to_crew(tour_id, user_id) do
    case Repo.get_by(TourMembership, tour_id: tour_id, user_id: user_id, role: "manager") do
      nil -> {:error, :not_found}
      membership ->
        if crew_seats_remaining(tour_id) > 0 do
          membership
          |> TourMembership.changeset(%{role: "crew"})
          |> Repo.update()
        else
          {:error, :no_seats}
        end
    end
  end

  # --- Date crew assignments ---

  def list_crew_for_date(tour_id, date) do
    all_dates_members =
      TourMembership
      |> where(tour_id: ^tour_id, all_dates_default: true)
      |> join(:inner, [tm], u in assoc(tm, :user))
      |> select([tm, u], %{user: u, membership: tm})
      |> Repo.all()

    date_assigned =
      DateCrewAssignment
      |> where(tour_id: ^tour_id, date: ^date)
      |> join(:inner, [dca], u in assoc(dca, :user))
      |> join(:inner, [dca, _u], tm in TourMembership,
        on: tm.tour_id == dca.tour_id and tm.user_id == dca.user_id
      )
      |> select([dca, u, tm], %{user: u, membership: tm})
      |> Repo.all()

    (all_dates_members ++ date_assigned)
    |> Enum.uniq_by(fn %{user: u} -> u.id end)
    |> Enum.sort_by(fn %{user: u} -> u.name end)
  end

  def assign_crew_to_date(tour_id, user_id, date) do
    %DateCrewAssignment{tour_id: tour_id, user_id: user_id}
    |> DateCrewAssignment.changeset(%{date: date})
    |> Repo.insert(on_conflict: :nothing)
  end

  def remove_crew_from_date(tour_id, user_id, date) do
    case Repo.get_by(DateCrewAssignment, tour_id: tour_id, user_id: user_id, date: date) do
      nil -> {:error, :not_found}
      assignment -> Repo.delete(assignment)
    end
  end

  def toggle_all_dates_default(tour_id, user_id) do
    case Repo.get_by(TourMembership, tour_id: tour_id, user_id: user_id) do
      nil -> {:error, :not_found}
      membership ->
        membership
        |> TourMembership.changeset(%{all_dates_default: !membership.all_dates_default})
        |> Repo.update()
    end
  end

  # --- Tour invites ---

  def create_tour_invite(tour, invited_by) do
    %TourInvite{tour_id: tour.id, invited_by_id: invited_by.id}
    |> TourInvite.changeset(%{role: "crew"})
    |> Repo.insert()
  end

  def get_or_create_active_invite(tour, invited_by) do
    case Repo.one(
           from i in TourInvite,
             where: i.tour_id == ^tour.id and i.status == "pending",
             order_by: [desc: :inserted_at],
             limit: 1
         ) do
      nil -> create_tour_invite(tour, invited_by)
      invite -> {:ok, invite}
    end
  end

  def get_invite_by_token(token) do
    case Repo.one(
           from i in TourInvite,
             where: i.token == ^token and i.status in ["pending", "accepted"],
             limit: 1
         ) do
      nil -> {:error, :not_found}
      invite -> {:ok, Repo.preload(invite, :tour)}
    end
  end

  def accept_invite(invite, user) do
    Repo.transaction(fn ->
      case Repo.get_by(TourMembership, tour_id: invite.tour_id, user_id: user.id) do
        nil ->
          remaining = crew_seats_remaining(invite.tour_id)

          if remaining > 0 do
            %TourMembership{tour_id: invite.tour_id, user_id: user.id}
            |> TourMembership.changeset(%{role: "crew"})
            |> Repo.insert!()
          else
            Repo.rollback(:no_seats)
          end

        existing ->
          existing
      end

      invite
      |> TourInvite.changeset(%{status: "accepted"})
      |> Repo.update!()
    end)
  end

  def revoke_invite(invite_id) do
    case Repo.get(TourInvite, invite_id) do
      nil -> {:error, :not_found}
      invite ->
        invite
        |> TourInvite.changeset(%{status: "revoked"})
        |> Repo.update()
    end
  end

  # --- Event CRUD ---

  def get_event!(id), do: Repo.get!(Event, id)

  def create_event(gig, workspace_id, attrs) do
    %Event{gig_id: gig.id, workspace_id: workspace_id}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  def change_event(event \\ %Event{}, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end

  def list_gigs_for_tour(tour_id) do
    Gig
    |> where(tour_id: ^tour_id)
    |> order_by(asc: :date)
    |> Repo.all()
  end

  def get_gig_for_date(tour_id, date) do
    Gig
    |> where(tour_id: ^tour_id, date: ^date)
    |> limit(1)
    |> Repo.one()
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
