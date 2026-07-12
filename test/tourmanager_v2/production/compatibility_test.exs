defmodule TourmanagerV2.Production.CompatibilityTest do
  use TourmanagerV2.DataCase, async: true

  import TourmanagerV2.ProductionFixtures

  alias TourmanagerV2.Production.Compatibility

  describe "check/2" do
    setup do
      ws = workspace_fixture()
      venue = venue_fixture(ws)
      tour_ws = workspace_fixture()
      tour = tour_fixture(tour_ws)
      %{venue: venue, tour: tour}
    end

    test "returns unknown when no tour requirements set", %{venue: venue, tour: tour} do
      result = Compatibility.check(venue.id, tour.id)
      assert result.overall_status == :unknown
      assert result.percentage_score == 0
    end

    test "all pass — full compatibility", %{venue: venue, tour: tour} do
      production_profile_fixture(venue, stage_width_m: 20.0, stage_depth_m: 15.0, trim_height_m: 10.0)
      rigging_point_fixture(venue, label: "RP-1", safe_working_load_kg: 600.0)
      rigging_point_fixture(venue, label: "RP-2", safe_working_load_kg: 600.0)
      rigging_point_fixture(venue, label: "RP-3", safe_working_load_kg: 600.0)
      rigging_point_fixture(venue, label: "RP-4", safe_working_load_kg: 600.0)
      power_service_fixture(venue, phase_type: "three_phase", amps: 100)

      tour_requirement_fixture(tour,
        minimum_stage_width_m: 18.0,
        minimum_stage_depth_m: 12.0,
        minimum_trim_height_m: 9.0,
        required_three_phase_amps: 63,
        required_rigging_points: 4,
        required_total_rigging_capacity_kg: 2000.0
      )

      result = Compatibility.check(venue.id, tour.id)
      assert result.overall_status == :compatible
      assert result.percentage_score == 100
      assert Enum.all?(result.checks, fn c -> c.status == :pass end)
    end

    test "all fail — incompatible", %{venue: venue, tour: tour} do
      production_profile_fixture(venue, stage_width_m: 10.0, stage_depth_m: 8.0, trim_height_m: 5.0)
      power_service_fixture(venue, phase_type: "three_phase", amps: 32)
      rigging_point_fixture(venue, safe_working_load_kg: 100.0)

      tour_requirement_fixture(tour,
        minimum_stage_width_m: 20.0,
        minimum_stage_depth_m: 15.0,
        minimum_trim_height_m: 9.0,
        required_three_phase_amps: 63,
        required_rigging_points: 8,
        required_total_rigging_capacity_kg: 5000.0
      )

      result = Compatibility.check(venue.id, tour.id)
      assert result.overall_status == :incompatible
      fail_checks = Enum.filter(result.checks, fn c -> c.status == :fail end)
      assert length(fail_checks) > 0
    end

    test "unknown when venue data missing", %{venue: venue, tour: tour} do
      # No profile, no rigging, no power
      tour_requirement_fixture(tour,
        minimum_stage_width_m: 15.0,
        minimum_stage_depth_m: 10.0,
        minimum_trim_height_m: 8.0,
        required_three_phase_amps: 63,
        required_rigging_points: 4,
        required_total_rigging_capacity_kg: 2000.0
      )

      result = Compatibility.check(venue.id, tour.id)
      assert result.overall_status == :unknown
      assert Enum.all?(result.checks, fn c -> c.status == :unknown end)
    end

    test "warning when some checks are unknown and none fail", %{venue: venue, tour: tour} do
      # Profile has stage width but no trim height
      production_profile_fixture(venue, stage_width_m: 20.0, stage_depth_m: 15.0, trim_height_m: nil)
      rigging_point_fixture(venue, safe_working_load_kg: 600.0)
      rigging_point_fixture(venue, safe_working_load_kg: 600.0)
      rigging_point_fixture(venue, safe_working_load_kg: 600.0)
      rigging_point_fixture(venue, safe_working_load_kg: 600.0)
      power_service_fixture(venue, phase_type: "three_phase", amps: 100)

      tour_requirement_fixture(tour,
        minimum_stage_width_m: 18.0,
        minimum_stage_depth_m: 12.0,
        minimum_trim_height_m: 9.0,
        required_three_phase_amps: 63,
        required_rigging_points: 4,
        required_total_rigging_capacity_kg: 2000.0
      )

      result = Compatibility.check(venue.id, tour.id)
      assert result.overall_status == :warning
    end

    test "mixed pass/fail gives incompatible with partial score", %{venue: venue, tour: tour} do
      production_profile_fixture(venue, stage_width_m: 20.0, stage_depth_m: 8.0, trim_height_m: 10.0)
      rigging_point_fixture(venue, safe_working_load_kg: 600.0)
      rigging_point_fixture(venue, safe_working_load_kg: 600.0)
      rigging_point_fixture(venue, safe_working_load_kg: 600.0)
      rigging_point_fixture(venue, safe_working_load_kg: 600.0)
      power_service_fixture(venue, phase_type: "three_phase", amps: 100)

      tour_requirement_fixture(tour,
        minimum_stage_width_m: 18.0,
        minimum_stage_depth_m: 12.0,
        minimum_trim_height_m: 9.0,
        required_three_phase_amps: 63,
        required_rigging_points: 4,
        required_total_rigging_capacity_kg: 2000.0
      )

      result = Compatibility.check(venue.id, tour.id)
      assert result.overall_status == :incompatible
      # Stage depth fails (8.0 < 12.0), others pass
      assert result.percentage_score < 100
      assert result.percentage_score > 0
    end

    test "percentage_score is 0–100 integer", %{venue: venue, tour: tour} do
      production_profile_fixture(venue, stage_width_m: 20.0, stage_depth_m: 15.0, trim_height_m: 10.0)
      rigging_point_fixture(venue, safe_working_load_kg: 600.0)
      rigging_point_fixture(venue, safe_working_load_kg: 600.0)
      rigging_point_fixture(venue, safe_working_load_kg: 600.0)
      rigging_point_fixture(venue, safe_working_load_kg: 600.0)
      power_service_fixture(venue, phase_type: "three_phase", amps: 100)

      tour_requirement_fixture(tour,
        minimum_stage_width_m: 18.0,
        minimum_stage_depth_m: 12.0,
        minimum_trim_height_m: 9.0,
        required_three_phase_amps: 63,
        required_rigging_points: 4,
        required_total_rigging_capacity_kg: 2000.0
      )

      result = Compatibility.check(venue.id, tour.id)
      assert is_integer(result.percentage_score)
      assert result.percentage_score >= 0
      assert result.percentage_score <= 100
    end
  end
end
