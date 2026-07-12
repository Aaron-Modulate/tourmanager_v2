defmodule TourmanagerV2.ProductionFixtures do
  @moduledoc "Test fixtures for the Production context."

  alias TourmanagerV2.Repo
  alias TourmanagerV2.Accounts.{User, Workspace, WorkspaceMembership}
  alias TourmanagerV2.Touring.{Tour, TourMembership}
  alias TourmanagerV2.Production.{
    Venue, VenueProductionProfile, ProductionDocument,
    RiggingPoint, HouseTruss, PowerService, LoadingAccess,
    HouseLightingFixture, ProductionDataSuggestion, TourProductionRequirement
  }

  def user_fixture(attrs \\ %{}) do
    Repo.insert!(%User{
      email: attrs[:email] || "user#{System.unique_integer()}@example.com",
      name: attrs[:name] || "Test User",
      hashed_password: "hashed",
      role: attrs[:role] || "crew",
      plan: attrs[:plan] || "free"
    })
  end

  def workspace_fixture(attrs \\ %{}) do
    slug = attrs[:slug] || "ws-#{System.unique_integer([:positive])}"
    Repo.insert!(%Workspace{name: attrs[:name] || "Test Workspace", slug: slug})
  end

  def workspace_membership_fixture(workspace, user, role \\ "owner") do
    Repo.insert!(%WorkspaceMembership{
      workspace_id: workspace.id,
      user_id: user.id,
      role: role
    })
  end

  def tour_fixture(workspace, attrs \\ %{}) do
    Repo.insert!(%Tour{
      name: attrs[:name] || "Test Tour",
      workspace_id: workspace.id,
      status: "active"
    })
  end

  def tour_membership_fixture(tour, user, role \\ "manager") do
    Repo.insert!(%TourMembership{
      tour_id: tour.id,
      user_id: user.id,
      role: role
    })
  end

  def venue_fixture(_workspace \\ nil, attrs \\ %{}) do
    Repo.insert!(%Venue{
      name: attrs[:name] || "Test Venue",
      city: attrs[:city] || "Test City",
      formatted_address: attrs[:formatted_address] || "1 Test St, Test City",
      google_place_id: attrs[:google_place_id] || "test_place_#{System.unique_integer([:positive])}"
    })
  end

  def production_profile_fixture(venue, attrs \\ %{}) do
    Repo.insert!(%VenueProductionProfile{
      venue_id: venue.id,
      profile_status: attrs[:profile_status] || "draft",
      stage_width_m: attrs[:stage_width_m],
      stage_depth_m: attrs[:stage_depth_m],
      trim_height_m: attrs[:trim_height_m]
    })
  end

  def production_document_fixture(venue, user, attrs \\ %{}) do
    Repo.insert!(%ProductionDocument{
      venue_id: venue.id,
      uploaded_by_user_id: user.id,
      title: attrs[:title] || "Test Doc",
      document_type: attrs[:document_type] || "other",
      file_url: attrs[:file_url] || "https://example.com/doc.pdf",
      uploaded_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end

  def rigging_point_fixture(venue, attrs \\ %{}) do
    Repo.insert!(%RiggingPoint{
      venue_id: venue.id,
      label: attrs[:label] || "RP-#{System.unique_integer([:positive])}",
      safe_working_load_kg: attrs[:safe_working_load_kg] || 500.0,
      motor_available: attrs[:motor_available] || false
    })
  end

  def power_service_fixture(venue, attrs \\ %{}) do
    Repo.insert!(%PowerService{
      venue_id: venue.id,
      name: attrs[:name] || "Power #{System.unique_integer([:positive])}",
      phase_type: attrs[:phase_type] || "three_phase",
      amps: attrs[:amps] || 63
    })
  end

  def loading_access_fixture(venue, attrs \\ %{}) do
    Repo.insert!(%LoadingAccess{
      venue_id: venue.id,
      dock_available: attrs[:dock_available] || false,
      lift_available: attrs[:lift_available] || false
    })
  end

  def suggestion_fixture(venue, user, attrs \\ %{}) do
    Repo.insert!(%ProductionDataSuggestion{
      venue_id: venue.id,
      submitted_by_user_id: user.id,
      target_type: attrs[:target_type] || "profile",
      target_id: attrs[:target_id],
      field_name: attrs[:field_name] || "stage_width_m",
      current_value: attrs[:current_value],
      suggested_value: attrs[:suggested_value] || "20.0",
      evidence_note: attrs[:evidence_note],
      status: attrs[:status] || "pending"
    })
  end

  def tour_requirement_fixture(tour, attrs \\ %{}) do
    Repo.insert!(%TourProductionRequirement{
      tour_id: tour.id,
      minimum_stage_width_m: attrs[:minimum_stage_width_m] || 15.0,
      minimum_stage_depth_m: attrs[:minimum_stage_depth_m] || 10.0,
      minimum_trim_height_m: attrs[:minimum_trim_height_m] || 8.0,
      required_three_phase_amps: attrs[:required_three_phase_amps] || 63,
      required_rigging_points: attrs[:required_rigging_points] || 4,
      required_total_rigging_capacity_kg: attrs[:required_total_rigging_capacity_kg] || 2000.0
    })
  end
end
