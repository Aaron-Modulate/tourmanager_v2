defmodule TourmanagerV2.Production.SuggestionsTest do
  use TourmanagerV2.DataCase, async: true

  import TourmanagerV2.ProductionFixtures

  alias TourmanagerV2.Production.Suggestions
  alias TourmanagerV2.Repo
  alias TourmanagerV2.Accounts.User

  describe "create_suggestion/8" do
    test "tour-side user can submit a suggestion" do
      venue = venue_fixture()
      _profile = production_profile_fixture(venue, stage_width_m: 15.0)
      ws = workspace_fixture()
      tour = tour_fixture(ws)
      user = user_fixture()
      tour_membership_fixture(tour, user, "crew")

      assert {:ok, suggestion} =
               Suggestions.create_suggestion(venue.id, user.id, "profile", nil,
                 "stage_width_m", "15.0", "18.0", "Measured on site")

      assert suggestion.status == "pending"
      assert suggestion.suggested_value == "18.0"
    end

    test "user with no tour membership cannot submit" do
      venue = venue_fixture()
      user = user_fixture()
      assert {:error, :unauthorized} =
               Suggestions.create_suggestion(venue.id, user.id, "profile", nil,
                 "stage_width_m", "15.0", "18.0", nil)
    end

    test "pending count increases after submission" do
      venue = venue_fixture()
      ws = workspace_fixture()
      tour = tour_fixture(ws)
      user = user_fixture()
      tour_membership_fixture(tour, user)

      Suggestions.create_suggestion(venue.id, user.id, "profile", nil, "stage_width_m", nil, "20.0", nil)
      Suggestions.create_suggestion(venue.id, user.id, "profile", nil, "stage_width_m", nil, "21.0", nil)
      assert Suggestions.count_pending_by_field(venue.id, "profile", nil, "stage_width_m") == 2
    end
  end

  defp make_admin(user) do
    Repo.update!(Ecto.Changeset.change(user, is_admin: true))
  end

  describe "accept_suggestion/2" do
    setup do
      venue = venue_fixture()
      _profile = production_profile_fixture(venue, stage_width_m: 15.0)
      admin = make_admin(user_fixture())
      ws = workspace_fixture()
      tour = tour_fixture(ws)
      submitter = user_fixture()
      tour_membership_fixture(tour, submitter)
      {:ok, suggestion} = Suggestions.create_suggestion(venue.id, submitter.id, "profile", nil,
          "stage_width_m", "15.0", "20.0", "Measured")
      %{venue: venue, admin: admin, suggestion: suggestion}
    end

    test "platform admin can accept a suggestion", %{suggestion: s, admin: admin, venue: venue} do
      assert {:ok, updated} = Suggestions.accept_suggestion(s.id, admin.id)
      assert updated.status == "accepted"
      assert updated.reviewed_by_user_id == admin.id
      assert updated.reviewed_at != nil
      profile = Repo.get_by!(TourmanagerV2.Production.VenueProductionProfile, venue_id: venue.id)
      assert profile.stage_width_m == 20.0
    end

    test "non-admin cannot accept", %{suggestion: s} do
      regular_user = user_fixture()
      assert {:error, :unauthorized} = Suggestions.accept_suggestion(s.id, regular_user.id)
      updated = Repo.get!(TourmanagerV2.Production.ProductionDataSuggestion, s.id)
      assert updated.status == "pending"
    end
  end

  describe "reject_suggestion/3" do
    setup do
      venue = venue_fixture()
      _profile = production_profile_fixture(venue, stage_width_m: 15.0)
      admin = make_admin(user_fixture())
      ws = workspace_fixture()
      tour = tour_fixture(ws)
      submitter = user_fixture()
      tour_membership_fixture(tour, submitter)
      {:ok, suggestion} = Suggestions.create_suggestion(venue.id, submitter.id, "profile", nil,
          "stage_width_m", "15.0", "20.0", nil)
      %{venue: venue, admin: admin, suggestion: suggestion}
    end

    test "platform admin can reject a suggestion", %{suggestion: s, admin: admin} do
      assert {:ok, updated} = Suggestions.reject_suggestion(s.id, admin.id, "Value confirmed correct.")
      assert updated.status == "rejected"
      assert updated.rejection_reason == "Value confirmed correct."
    end

    test "rejecting does not change the target field", %{suggestion: s, admin: admin, venue: venue} do
      {:ok, _} = Suggestions.reject_suggestion(s.id, admin.id, nil)
      profile = Repo.get_by!(TourmanagerV2.Production.VenueProductionProfile, venue_id: venue.id)
      assert profile.stage_width_m == 15.0
    end

    test "non-admin cannot reject", %{suggestion: s} do
      other = user_fixture()
      assert {:error, :unauthorized} = Suggestions.reject_suggestion(s.id, other.id)
    end
  end

  describe "list_pending_suggestions/1" do
    test "returns only pending suggestions" do
      venue = venue_fixture()
      _profile = production_profile_fixture(venue)
      admin = make_admin(user_fixture())
      ws = workspace_fixture()
      tour = tour_fixture(ws)
      user = user_fixture()
      tour_membership_fixture(tour, user)

      s1 = suggestion_fixture(venue, user, status: "pending")
      s2 = suggestion_fixture(venue, user, status: "pending")
      to_accept = suggestion_fixture(venue, user, %{status: "pending", field_name: "trim_height_m", suggested_value: "10.0"})

      Suggestions.accept_suggestion(to_accept.id, admin.id)

      pending_ids = Suggestions.list_pending_suggestions(venue.id) |> Enum.map(& &1.id)
      assert s1.id in pending_ids
      assert s2.id in pending_ids
      refute to_accept.id in pending_ids
    end
  end
end
