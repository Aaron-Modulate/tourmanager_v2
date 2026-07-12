# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     TourmanagerV2.Repo.insert!(%TourmanagerV2.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Ecto.Query, only: [from: 2]

alias TourmanagerV2.Repo
alias TourmanagerV2.Accounts.{User, Workspace, WorkspaceMembership}
alias TourmanagerV2.Touring.{Tour, TourMembership}
alias TourmanagerV2.Production.{
  Venue,
  VenueProductionProfile,
  ProductionDocument,
  RiggingPoint,
  HouseTruss,
  PowerService,
  LoadingAccess,
  HouseLightingFixture,
  ProductionDataSuggestion,
  TourProductionRequirement
}

IO.puts("Seeding production data...")

# ---------------------------------------------------------------------------
# Users
# ---------------------------------------------------------------------------

venue_admin =
  case Repo.get_by(User, email: "venue@example.com") do
    nil ->
      Repo.insert!(%User{
        email: "venue@example.com",
        name: "Venue Admin",
        hashed_password: Bcrypt.hash_pwd_salt("password123"),
        role: "manager",
        plan: "paid"
      })
    user -> user
  end

touring_user =
  case Repo.get_by(User, email: "touring@example.com") do
    nil ->
      Repo.insert!(%User{
        email: "touring@example.com",
        name: "Touring User",
        hashed_password: Bcrypt.hash_pwd_salt("password123"),
        role: "manager",
        plan: "paid"
      })
    user -> user
  end

# ---------------------------------------------------------------------------
# Workspaces
# ---------------------------------------------------------------------------

venue_workspace =
  case Repo.get_by(Workspace, slug: "roundhouse-productions") do
    nil -> Repo.insert!(%Workspace{name: "Roundhouse Productions", slug: "roundhouse-productions"})
    ws -> ws
  end

unless Repo.get_by(WorkspaceMembership, workspace_id: venue_workspace.id, user_id: venue_admin.id) do
  Repo.insert!(%WorkspaceMembership{workspace_id: venue_workspace.id, user_id: venue_admin.id, role: "owner"})
end

tour_workspace =
  case Repo.get_by(Workspace, slug: "summer-circuit") do
    nil -> Repo.insert!(%Workspace{name: "Summer Circuit Touring", slug: "summer-circuit"})
    ws -> ws
  end

unless Repo.get_by(WorkspaceMembership, workspace_id: tour_workspace.id, user_id: touring_user.id) do
  Repo.insert!(%WorkspaceMembership{workspace_id: tour_workspace.id, user_id: touring_user.id, role: "owner"})
end

# ---------------------------------------------------------------------------
# Tour
# ---------------------------------------------------------------------------

tour =
  case Repo.get_by(Tour, workspace_id: tour_workspace.id) do
    nil ->
      Repo.insert!(%Tour{
        name: "Summer Circuit 2026",
        workspace_id: tour_workspace.id,
        status: "active",
        start_date: ~D[2026-07-01],
        end_date: ~D[2026-08-31]
      })
    t -> t
  end

unless Repo.get_by(TourMembership, tour_id: tour.id, user_id: touring_user.id) do
  Repo.insert!(%TourMembership{tour_id: tour.id, user_id: touring_user.id, role: "manager"})
end

# ---------------------------------------------------------------------------
# Venue
# ---------------------------------------------------------------------------

venue =
  case Repo.get_by(Venue, workspace_id: venue_workspace.id) do
    nil ->
      Repo.insert!(%Venue{
        name: "The Roundhouse",
        city: "London",
        country: "UK",
        capacity: 3300,
        website: "https://www.roundhouse.org.uk",
        workspace_id: venue_workspace.id
      })
    v -> v
  end

# ---------------------------------------------------------------------------
# Production profile
# ---------------------------------------------------------------------------

unless Repo.get_by(VenueProductionProfile, venue_id: venue.id) do
  Repo.insert!(%VenueProductionProfile{
    venue_id: venue.id,
    profile_status: "published",
    stage_width_m: 22.0,
    stage_depth_m: 14.5,
    trim_height_m: 9.8,
    notes: "Main stage. Thrust configuration available. Grid weight limit 20t total.",
    last_verified_at: ~U[2025-11-15 10:00:00Z],
    verified_by_user_id: venue_admin.id
  })
  IO.puts("  → Production profile seeded")
end

# ---------------------------------------------------------------------------
# Rigging points
# ---------------------------------------------------------------------------

if Repo.aggregate(from(r in RiggingPoint, where: r.venue_id == ^venue.id), :count) == 0 do
  Enum.each([
    {"RP-01", 750.0, true, 500.0, nil},
    {"RP-02", 750.0, true, 500.0, nil},
    {"RP-03", 1000.0, true, 750.0, "Centre point, reinforced"},
    {"RP-04", 750.0, true, 500.0, nil},
    {"RP-05", 750.0, true, 500.0, nil},
    {"RP-06", 500.0, false, nil, nil},
    {"RP-07", 500.0, false, nil, nil}
  ], fn {label, swl, motor, motor_cap, notes} ->
    Repo.insert!(%RiggingPoint{
      venue_id: venue.id,
      label: label,
      safe_working_load_kg: swl,
      motor_available: motor,
      motor_capacity_kg: motor_cap,
      notes: notes
    })
  end)
  IO.puts("  → 7 rigging points seeded")
end

# ---------------------------------------------------------------------------
# House trusses
# ---------------------------------------------------------------------------

if Repo.aggregate(from(t in HouseTruss, where: t.venue_id == ^venue.id), :count) == 0 do
  Enum.each([
    {"FOH Truss", "foh", 14.0, 9.5, 800.0, nil},
    {"Mid Truss", "midstage", 18.0, 9.8, 1200.0, "Primary rig point"},
    {"Upstage Truss", "upstage", 16.0, 9.0, 600.0, nil}
  ], fn {name, pos, length, trim, max_load, notes} ->
    Repo.insert!(%HouseTruss{
      venue_id: venue.id,
      name: name,
      position: pos,
      length_m: length,
      trim_height_m: trim,
      max_load_kg: max_load,
      notes: notes
    })
  end)
  IO.puts("  → House trusses seeded")
end

# ---------------------------------------------------------------------------
# Power services
# ---------------------------------------------------------------------------

if Repo.aggregate(from(p in PowerService, where: p.venue_id == ^venue.id), :count) == 0 do
  Enum.each([
    {"Stage Left 3-Phase", "three_phase", 63, 400, "CEE 63A", "Stage left wing"},
    {"Stage Right 3-Phase", "three_phase", 63, 400, "CEE 63A", "Stage right wing"},
    {"FOH Distro", "three_phase", 32, 400, "CEE 32A", "Front of house position"},
    {"Dressing Room Ring", "single_phase", 32, 230, "13A sockets", "Dressing room corridor"}
  ], fn {name, phase, amps, voltage, connector, location} ->
    Repo.insert!(%PowerService{
      venue_id: venue.id,
      name: name,
      phase_type: phase,
      amps: amps,
      voltage: voltage,
      connector_type: connector,
      location: location
    })
  end)
  IO.puts("  → Power services seeded")
end

# ---------------------------------------------------------------------------
# Loading access
# ---------------------------------------------------------------------------

unless Repo.get_by(LoadingAccess, venue_id: venue.id) do
  Repo.insert!(%LoadingAccess{
    venue_id: venue.id,
    dock_available: true,
    truck_access_notes: "Access via Chalk Farm Road. Max 2 trucks on site simultaneously. Timed window 06:00–10:00 for load-in.",
    max_vehicle_height_m: 4.2,
    lift_available: true,
    parking_notes: "No dedicated parking. Production vehicles on Chalk Farm Road loading bays only.",
    notes: "Contact production manager 48h in advance to book loading slot."
  })
  IO.puts("  → Loading access seeded")
end

# ---------------------------------------------------------------------------
# House lighting fixtures
# ---------------------------------------------------------------------------

if Repo.aggregate(from(f in HouseLightingFixture, where: f.venue_id == ^venue.id), :count) == 0 do
  Enum.each([
    {"MAC Aura XB", "Martin", "MAC Aura XB", 24, "Mid truss", 1, 1, nil},
    {"Sharpy", "Clay Paky", "Sharpy", 12, "Upstage floor positions", 2, 1, nil},
    {"Sola Frame", "ETC", "Sola Frame", 8, "FOH balcony rail", 3, 1, "House specials only"}
  ], fn {name, mfr, model, qty, loc, universe, addr, notes} ->
    Repo.insert!(%HouseLightingFixture{
      venue_id: venue.id,
      fixture_name: name,
      manufacturer: mfr,
      model: model,
      quantity: qty,
      location: loc,
      universe: universe,
      address_start: addr,
      notes: notes
    })
  end)
  IO.puts("  → Lighting fixtures seeded")
end

# ---------------------------------------------------------------------------
# Production document
# ---------------------------------------------------------------------------

if Repo.aggregate(from(d in ProductionDocument, where: d.venue_id == ^venue.id), :count) == 0 do
  Repo.insert!(%ProductionDocument{
    venue_id: venue.id,
    uploaded_by_user_id: venue_admin.id,
    title: "The Roundhouse Technical Pack 2025",
    document_type: "tech_pack",
    original_filename: "roundhouse-tech-pack-2025.pdf",
    content_type: "application/pdf",
    notes: "Full venue technical specification including load schedule and rigging grid layout.",
    uploaded_at: ~U[2025-09-01 09:00:00Z]
  })
  IO.puts("  → Production document seeded")
end

# ---------------------------------------------------------------------------
# Tour production requirements (partial match to demonstrate compatibility)
# Stage width (22 >= 18 ✓), depth (14.5 >= 12 ✓), trim (9.8 >= 9 ✓)
# 3-phase (63A >= 63 ✓), rigging points (7 >= 6 ✓), capacity (5250 >= 4000 ✓)
# ---------------------------------------------------------------------------

unless Repo.get_by(TourProductionRequirement, tour_id: tour.id) do
  Repo.insert!(%TourProductionRequirement{
    tour_id: tour.id,
    minimum_stage_width_m: 18.0,
    minimum_stage_depth_m: 12.0,
    minimum_trim_height_m: 9.0,
    required_three_phase_amps: 63,
    required_rigging_points: 6,
    required_total_rigging_capacity_kg: 4000.0,
    notes: "Standard touring production. Monitor world at FOH. 6 motor points required minimum."
  })
  IO.puts("  → Tour production requirements seeded")
end

# ---------------------------------------------------------------------------
# Correction suggestions
# ---------------------------------------------------------------------------

if Repo.aggregate(from(s in ProductionDataSuggestion, where: s.venue_id == ^venue.id), :count) == 0 do
  # Pending — trim height correction from a touring user
  Repo.insert!(%ProductionDataSuggestion{
    venue_id: venue.id,
    submitted_by_user_id: touring_user.id,
    target_type: "profile",
    field_name: "trim_height_m",
    current_value: "9.8",
    suggested_value: "10.2",
    evidence_note: "Measured with laser during load-in on 2025-10-12. Published 9.8m predates 2024 refurbishment.",
    status: "pending"
  })

  # Previously accepted — stage width was corrected
  Repo.insert!(%ProductionDataSuggestion{
    venue_id: venue.id,
    submitted_by_user_id: touring_user.id,
    target_type: "profile",
    field_name: "stage_width_m",
    current_value: "20.0",
    suggested_value: "22.0",
    evidence_note: "Venue shared updated CAD drawings confirming 22m width.",
    status: "accepted",
    reviewed_by_user_id: venue_admin.id,
    reviewed_at: ~U[2025-11-01 14:30:00Z]
  })

  IO.puts("  → Correction suggestions seeded (1 pending, 1 accepted)")
end

IO.puts("")
IO.puts("Production seed complete.")
IO.puts("  Venue:        The Roundhouse, London")
IO.puts("  Tour:         Summer Circuit 2026")
IO.puts("  Venue admin:  venue@example.com / password123")
IO.puts("  Touring user: touring@example.com / password123")
IO.puts("")
IO.puts("  /production/venues           → venue list")
IO.puts("  /production/compatibility    → compatibility check")
