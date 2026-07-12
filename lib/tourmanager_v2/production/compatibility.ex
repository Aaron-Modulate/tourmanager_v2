defmodule TourmanagerV2.Production.Compatibility do
  @moduledoc """
  Rule-based compatibility engine that matches a venue's production profile
  against a tour's technical requirements.

  Design principles:
  - Missing venue data is "unknown", never "incompatible"
  - Scoring: (passing checks / total checks) × 100
  - All logic is explicit and explainable — no machine learning
  """

  import Ecto.Query
  alias TourmanagerV2.Repo
  alias TourmanagerV2.Production.{VenueProductionProfile, RiggingPoint, PowerService, TourProductionRequirement}

  @type check_status :: :pass | :fail | :unknown
  @type overall_status :: :compatible | :warning | :incompatible | :unknown

  @type check_result :: %{
    requirement: String.t(),
    venue_value: any(),
    status: check_status(),
    message: String.t()
  }

  @type compatibility_result :: %{
    overall_status: overall_status(),
    percentage_score: integer(),
    checks: [check_result()]
  }

  @doc """
  Runs all compatibility checks for a venue against a tour's requirements.

  Returns a map with overall_status, percentage_score (0–100), and a list of
  per-check results. Venues with no published profile return :unknown overall status.
  """
  @spec check(binary(), binary()) :: compatibility_result()
  def check(venue_id, tour_id) do
    profile = Repo.get_by(VenueProductionProfile, venue_id: venue_id)
    requirements = Repo.get_by(TourProductionRequirement, tour_id: tour_id)

    if is_nil(requirements) do
      %{
        overall_status: :unknown,
        percentage_score: 0,
        checks: [
          %{
            requirement: "Tour requirements",
            venue_value: nil,
            status: :unknown,
            message: "No production requirements have been set for this tour."
          }
        ]
      }
    else
      rigging_points = Repo.all(from r in RiggingPoint, where: r.venue_id == ^venue_id)
      power_services = Repo.all(from p in PowerService, where: p.venue_id == ^venue_id)

      checks = [
        check_stage_width(profile, requirements),
        check_stage_depth(profile, requirements),
        check_trim_height(profile, requirements),
        check_three_phase_power(power_services, requirements),
        check_rigging_point_count(rigging_points, requirements),
        check_total_rigging_capacity(rigging_points, requirements)
      ]

      scored = Enum.filter(checks, fn c -> c.status != :unknown end)
      passing = Enum.count(scored, fn c -> c.status == :pass end)
      total = length(checks)
      percentage = if total > 0, do: round(passing / total * 100), else: 0

      overall =
        cond do
          Enum.all?(checks, fn c -> c.status == :unknown end) -> :unknown
          Enum.any?(checks, fn c -> c.status == :fail end) -> :incompatible
          Enum.any?(checks, fn c -> c.status == :unknown end) -> :warning
          true -> :compatible
        end

      %{overall_status: overall, percentage_score: percentage, checks: checks}
    end
  end

  # ---------------------------------------------------------------------------
  # Individual checks
  # ---------------------------------------------------------------------------

  defp check_stage_width(profile, req) do
    required = req.minimum_stage_width_m
    actual = profile && profile.stage_width_m

    cond do
      is_nil(required) ->
        %{requirement: "Stage width", venue_value: actual, status: :pass,
          message: "No minimum stage width required."}

      is_nil(actual) ->
        %{requirement: "Stage width (min #{format_m(required)})",
          venue_value: nil, status: :unknown,
          message: "Venue has not confirmed stage width. Ask venue to update their profile."}

      actual >= required ->
        %{requirement: "Stage width (min #{format_m(required)})",
          venue_value: format_m(actual), status: :pass,
          message: "Stage width #{format_m(actual)} meets requirement of #{format_m(required)}."}

      true ->
        %{requirement: "Stage width (min #{format_m(required)})",
          venue_value: format_m(actual), status: :fail,
          message: "Stage width #{format_m(actual)} is less than the required #{format_m(required)}."}
    end
  end

  defp check_stage_depth(profile, req) do
    required = req.minimum_stage_depth_m
    actual = profile && profile.stage_depth_m

    cond do
      is_nil(required) ->
        %{requirement: "Stage depth", venue_value: actual, status: :pass,
          message: "No minimum stage depth required."}

      is_nil(actual) ->
        %{requirement: "Stage depth (min #{format_m(required)})",
          venue_value: nil, status: :unknown,
          message: "Venue has not confirmed stage depth. Ask venue to update their profile."}

      actual >= required ->
        %{requirement: "Stage depth (min #{format_m(required)})",
          venue_value: format_m(actual), status: :pass,
          message: "Stage depth #{format_m(actual)} meets requirement of #{format_m(required)}."}

      true ->
        %{requirement: "Stage depth (min #{format_m(required)})",
          venue_value: format_m(actual), status: :fail,
          message: "Stage depth #{format_m(actual)} is less than the required #{format_m(required)}."}
    end
  end

  defp check_trim_height(profile, req) do
    required = req.minimum_trim_height_m
    actual = profile && profile.trim_height_m

    cond do
      is_nil(required) ->
        %{requirement: "Trim height", venue_value: actual, status: :pass,
          message: "No minimum trim height required."}

      is_nil(actual) ->
        %{requirement: "Trim height (min #{format_m(required)})",
          venue_value: nil, status: :unknown,
          message: "Venue trim height is unknown. Ask venue to confirm trim height."}

      actual >= required ->
        %{requirement: "Trim height (min #{format_m(required)})",
          venue_value: format_m(actual), status: :pass,
          message: "Trim height #{format_m(actual)} meets requirement of #{format_m(required)}."}

      true ->
        %{requirement: "Trim height (min #{format_m(required)})",
          venue_value: format_m(actual), status: :fail,
          message: "Trim height #{format_m(actual)} is below required #{format_m(required)}."}
    end
  end

  defp check_three_phase_power(power_services, req) do
    required_amps = req.required_three_phase_amps

    if is_nil(required_amps) do
      %{requirement: "3-phase power", venue_value: nil, status: :pass,
        message: "No 3-phase power requirement set."}
    else
      three_phase = Enum.filter(power_services, fn p -> p.phase_type == "three_phase" end)

      if three_phase == [] do
        %{requirement: "3-phase power (min #{required_amps}A)",
          venue_value: nil, status: :unknown,
          message: "No 3-phase power services listed for this venue. Ask venue to add power data."}
      else
        best = Enum.max_by(three_phase, fn p -> p.amps || 0 end)
        actual_amps = best.amps

        cond do
          is_nil(actual_amps) ->
            %{requirement: "3-phase power (min #{required_amps}A)",
              venue_value: "Available (amps unknown)", status: :unknown,
              message: "3-phase power available but amperage not specified."}

          actual_amps >= required_amps ->
            %{requirement: "3-phase power (min #{required_amps}A)",
              venue_value: "#{actual_amps}A", status: :pass,
              message: "3-phase power available at #{actual_amps}A, meets #{required_amps}A requirement."}

          true ->
            %{requirement: "3-phase power (min #{required_amps}A)",
              venue_value: "#{actual_amps}A", status: :fail,
              message: "Best 3-phase service is #{actual_amps}A, below required #{required_amps}A."}
        end
      end
    end
  end

  defp check_rigging_point_count(rigging_points, req) do
    required = req.required_rigging_points
    actual = length(rigging_points)

    cond do
      is_nil(required) ->
        %{requirement: "Rigging points", venue_value: actual, status: :pass,
          message: "No minimum rigging point count required."}

      actual == 0 ->
        %{requirement: "Rigging points (min #{required})",
          venue_value: nil, status: :unknown,
          message: "No rigging points recorded for this venue. Ask venue to add rigging data."}

      actual >= required ->
        %{requirement: "Rigging points (min #{required})",
          venue_value: to_string(actual), status: :pass,
          message: "#{actual} rigging points available, meets requirement of #{required}."}

      true ->
        %{requirement: "Rigging points (min #{required})",
          venue_value: to_string(actual), status: :fail,
          message: "Only #{actual} rigging points available, #{required} required."}
    end
  end

  defp check_total_rigging_capacity(rigging_points, req) do
    required = req.required_total_rigging_capacity_kg

    if is_nil(required) do
      %{requirement: "Total rigging capacity", venue_value: nil, status: :pass,
        message: "No total rigging capacity requirement set."}
    else
      capacities = Enum.map(rigging_points, fn p -> p.safe_working_load_kg end)

      if capacities == [] or Enum.all?(capacities, &is_nil/1) do
        %{requirement: "Total rigging capacity (min #{format_kg(required)})",
          venue_value: nil, status: :unknown,
          message: "Rigging point safe working loads are not recorded. Ask venue to confirm capacities."}
      else
        known = Enum.reject(capacities, &is_nil/1)
        total = Enum.sum(known)

        cond do
          length(known) < length(capacities) ->
            %{requirement: "Total rigging capacity (min #{format_kg(required)})",
              venue_value: "#{format_kg(total)} (partial)",
              status: :unknown,
              message: "Total capacity #{format_kg(total)} from #{length(known)} of #{length(capacities)} points — some SWLs unknown."}

          total >= required ->
            %{requirement: "Total rigging capacity (min #{format_kg(required)})",
              venue_value: format_kg(total), status: :pass,
              message: "Total SWL #{format_kg(total)} meets requirement of #{format_kg(required)}."}

          true ->
            %{requirement: "Total rigging capacity (min #{format_kg(required)})",
              venue_value: format_kg(total), status: :fail,
              message: "Total SWL #{format_kg(total)} is below required #{format_kg(required)}."}
        end
      end
    end
  end

  defp format_m(nil), do: "—"
  defp format_m(val), do: "#{:erlang.float_to_binary(val / 1, decimals: 1)}m"

  defp format_kg(nil), do: "—"
  defp format_kg(val), do: "#{round(val)}kg"
end
