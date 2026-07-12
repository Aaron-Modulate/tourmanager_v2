defmodule TourmanagerV2.Production.ProfilesTest do
  use TourmanagerV2.DataCase, async: true

  import TourmanagerV2.ProductionFixtures

  alias TourmanagerV2.Production.Profiles
  alias TourmanagerV2.Production.VenueProductionProfile

  describe "venues" do
    test "get_or_create_venue_by_place/1 creates a new venue from place data" do
      place = %{place_id: "gp_abc", name: "Apollo Theatre", address: "51 Shaftesbury Ave", lat: 51.5, lng: -0.1}
      assert {:ok, venue} = Profiles.get_or_create_venue_by_place(place)
      assert venue.name == "Apollo Theatre"
      assert venue.google_place_id == "gp_abc"
      assert venue.formatted_address == "51 Shaftesbury Ave"
    end

    test "get_or_create_venue_by_place/1 returns existing venue on duplicate place_id" do
      place = %{place_id: "gp_xyz", name: "The Roundhouse", address: "Chalk Farm Rd", lat: 51.5, lng: -0.15}
      {:ok, v1} = Profiles.get_or_create_venue_by_place(place)
      {:ok, v2} = Profiles.get_or_create_venue_by_place(place)
      assert v1.id == v2.id
    end

    test "get_venue_with_production_data/1 preloads all associations" do
      venue = venue_fixture()
      _profile = production_profile_fixture(venue)
      _rp = rigging_point_fixture(venue)
      _ps = power_service_fixture(venue)

      loaded = Profiles.get_venue_with_production_data(venue.id)
      assert loaded.production_profile != nil
      assert length(loaded.rigging_points) == 1
      assert length(loaded.power_services) == 1
    end
  end

  describe "production profiles" do
    test "get_or_create_profile/1 creates a draft profile if none exists" do
      venue = venue_fixture()
      assert {:ok, profile} = Profiles.get_or_create_profile(venue.id)
      assert profile.venue_id == venue.id
      assert profile.profile_status == "draft"
    end

    test "get_or_create_profile/1 returns existing profile" do
      venue = venue_fixture()
      _existing = production_profile_fixture(venue, stage_width_m: 20.0)
      assert {:ok, profile} = Profiles.get_or_create_profile(venue.id)
      assert profile.stage_width_m == 20.0
    end

    test "update_profile/2 updates fields" do
      venue = venue_fixture()
      {:ok, profile} = Profiles.get_or_create_profile(venue.id)
      assert {:ok, updated} = Profiles.update_profile(profile, %{stage_width_m: 18.5, trim_height_m: 9.0})
      assert updated.stage_width_m == 18.5
      assert updated.trim_height_m == 9.0
    end

    test "update_profile/2 allows partial data" do
      venue = venue_fixture()
      {:ok, profile} = Profiles.get_or_create_profile(venue.id)
      assert {:ok, _} = Profiles.update_profile(profile, %{notes: "Stage under construction"})
    end

    test "publish_profile/2 sets status to published and records verifier" do
      venue = venue_fixture()
      user = user_fixture()
      {:ok, profile} = Profiles.get_or_create_profile(venue.id)
      assert {:ok, published} = Profiles.publish_profile(profile, user.id)
      assert published.profile_status == "published"
      assert published.verified_by_user_id == user.id
      assert published.last_verified_at != nil
    end
  end

  describe "rigging points" do
    test "create_rigging_point/2 creates a point" do
      venue = venue_fixture()
      assert {:ok, rp} = Profiles.create_rigging_point(venue.id, %{label: "RP-1", safe_working_load_kg: 500.0})
      assert rp.label == "RP-1"
    end

    test "create_rigging_point/2 requires label" do
      venue = venue_fixture()
      assert {:error, cs} = Profiles.create_rigging_point(venue.id, %{safe_working_load_kg: 500.0})
      assert cs.errors[:label]
    end

    test "list_rigging_points/1 returns all points for venue" do
      venue = venue_fixture()
      rp1 = rigging_point_fixture(venue, label: "RP-A")
      rp2 = rigging_point_fixture(venue, label: "RP-B")
      ids = Profiles.list_rigging_points(venue.id) |> Enum.map(& &1.id)
      assert rp1.id in ids
      assert rp2.id in ids
    end

    test "delete_rigging_point/1 removes the point" do
      venue = venue_fixture()
      rp = rigging_point_fixture(venue)
      assert {:ok, _} = Profiles.delete_rigging_point(rp)
      assert Profiles.list_rigging_points(venue.id) == []
    end
  end

  describe "platform_admin?/1" do
    test "returns true for users with is_admin: true" do
      user = user_fixture() |> Map.put(:is_admin, true)
      assert Profiles.platform_admin?(user)
    end

    test "returns false for regular users" do
      user = user_fixture()
      refute Profiles.platform_admin?(user)
    end

    test "returns false for nil" do
      refute Profiles.platform_admin?(nil)
    end
  end
end
