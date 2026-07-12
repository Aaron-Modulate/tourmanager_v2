defmodule TourmanagerV2.Production.Suggestions do
  @moduledoc """
  Context for the correction workflow. Tour-side users submit corrections;
  venue admins review and accept or reject them.

  Accepted suggestions update the underlying data field. Rejected suggestions
  are preserved for audit purposes. All suggestion records are permanent —
  no hard deletes.
  """

  import Ecto.Query
  alias TourmanagerV2.Repo
  alias TourmanagerV2.Production.{
    ProductionDataSuggestion,
    Venue,
    VenueProductionProfile,
    RiggingPoint,
    HouseTruss,
    PowerService,
    LoadingAccess,
    HouseLightingFixture,
    ProductionDocument
  }
  alias TourmanagerV2.Accounts.User
  alias TourmanagerV2.Touring.TourMembership

  # ---------------------------------------------------------------------------
  # Submission
  # ---------------------------------------------------------------------------

  @doc """
  Submits a correction suggestion. Any authenticated user with at least one
  tour membership (a "tour-side user") may submit.
  """
  @spec create_suggestion(binary(), binary(), String.t(), binary() | nil, String.t(), String.t() | nil, String.t(), String.t() | nil) ::
          {:ok, ProductionDataSuggestion.t()} | {:error, :unauthorized} | {:error, Ecto.Changeset.t()}
  def create_suggestion(venue_id, user_id, target_type, target_id, field_name, current_value, suggested_value, evidence_note) do
    unless tour_side_user?(user_id) do
      {:error, :unauthorized}
    else
      %ProductionDataSuggestion{venue_id: venue_id, submitted_by_user_id: user_id}
      |> ProductionDataSuggestion.changeset(%{
        target_type: target_type,
        target_id: target_id,
        field_name: field_name,
        current_value: current_value,
        suggested_value: suggested_value,
        evidence_note: evidence_note
      })
      |> Repo.insert()
    end
  end

  # ---------------------------------------------------------------------------
  # Review
  # ---------------------------------------------------------------------------

  @doc """
  Accepts a suggestion: updates the target field with the suggested value,
  marks the suggestion as accepted. Only venue admins may accept.
  """
  @spec accept_suggestion(binary(), binary()) ::
          {:ok, ProductionDataSuggestion.t()} | {:error, :unauthorized} | {:error, :not_found} | {:error, any()}
  def accept_suggestion(suggestion_id, reviewer_id) do
    suggestion = Repo.get!(ProductionDataSuggestion, suggestion_id)

    unless platform_admin?(reviewer_id) do
      {:error, :unauthorized}
    else
      Repo.transaction(fn ->
        apply_suggestion(suggestion)

        suggestion
        |> ProductionDataSuggestion.review_changeset(%{
          status: "accepted",
          reviewed_by_user_id: reviewer_id,
          reviewed_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })
        |> Repo.update!()
      end)
      |> case do
        {:ok, updated} -> {:ok, updated}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Rejects a suggestion. Target data is not modified. Only venue admins may reject.
  """
  @spec reject_suggestion(binary(), binary(), String.t() | nil) ::
          {:ok, ProductionDataSuggestion.t()} | {:error, :unauthorized} | {:error, Ecto.Changeset.t()}
  def reject_suggestion(suggestion_id, reviewer_id, reason \\ nil) do
    suggestion = Repo.get!(ProductionDataSuggestion, suggestion_id)

    unless platform_admin?(reviewer_id) do
      {:error, :unauthorized}
    else
      suggestion
      |> ProductionDataSuggestion.review_changeset(%{
        status: "rejected",
        rejection_reason: reason,
        reviewed_by_user_id: reviewer_id,
        reviewed_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Repo.update()
    end
  end

  # ---------------------------------------------------------------------------
  # Queries
  # ---------------------------------------------------------------------------

  @doc "Returns all pending suggestions for a venue, preloaded with submitter info."
  @spec list_pending_suggestions(binary()) :: [ProductionDataSuggestion.t()]
  def list_pending_suggestions(venue_id) do
    Repo.all(
      from s in ProductionDataSuggestion,
        where: s.venue_id == ^venue_id and s.status == "pending",
        order_by: [s.target_type, s.field_name, desc: s.inserted_at],
        preload: [:submitted_by_user]
    )
  end

  @doc "Returns all reviewed (accepted/rejected) suggestions for audit history."
  @spec list_reviewed_suggestions(binary()) :: [ProductionDataSuggestion.t()]
  def list_reviewed_suggestions(venue_id) do
    Repo.all(
      from s in ProductionDataSuggestion,
        where: s.venue_id == ^venue_id and s.status != "pending",
        order_by: [desc: s.reviewed_at],
        preload: [:submitted_by_user, :reviewed_by_user]
    )
  end

  @doc "Returns the count of pending suggestions for a specific field — used for community confidence display."
  @spec count_pending_by_field(binary(), String.t(), binary() | nil, String.t()) :: integer()
  def count_pending_by_field(venue_id, target_type, target_id, field_name) do
    query =
      from s in ProductionDataSuggestion,
        where:
          s.venue_id == ^venue_id and
            s.target_type == ^target_type and
            s.field_name == ^field_name and
            s.status == "pending"

    query =
      if target_id do
        where(query, [s], s.target_id == ^target_id)
      else
        query
      end

    Repo.aggregate(query, :count)
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  # Applies the suggested value to the target record's field.
  # All values arrive as strings from form input; the changeset coerces to the right type.
  defp apply_suggestion(%ProductionDataSuggestion{} = s) do
    attrs = %{s.field_name => s.suggested_value}

    case s.target_type do
      "profile" ->
        profile = Repo.get_by!(VenueProductionProfile, venue_id: s.venue_id)
        profile |> VenueProductionProfile.changeset(attrs) |> Repo.update!()

      "rigging_point" when not is_nil(s.target_id) ->
        Repo.get!(RiggingPoint, s.target_id) |> RiggingPoint.changeset(attrs) |> Repo.update!()

      "truss" when not is_nil(s.target_id) ->
        Repo.get!(HouseTruss, s.target_id) |> HouseTruss.changeset(attrs) |> Repo.update!()

      "power" when not is_nil(s.target_id) ->
        Repo.get!(PowerService, s.target_id) |> PowerService.changeset(attrs) |> Repo.update!()

      "loading" ->
        access = Repo.get_by!(LoadingAccess, venue_id: s.venue_id)
        access |> LoadingAccess.changeset(attrs) |> Repo.update!()

      "lighting_fixture" when not is_nil(s.target_id) ->
        Repo.get!(HouseLightingFixture, s.target_id)
        |> HouseLightingFixture.changeset(attrs)
        |> Repo.update!()

      "document" when not is_nil(s.target_id) ->
        Repo.get!(ProductionDocument, s.target_id)
        |> ProductionDocument.changeset(attrs)
        |> Repo.update!()

      _ ->
        :noop
    end
  end

  defp platform_admin?(user_id) do
    alias TourmanagerV2.Accounts.User
    case Repo.get(User, user_id) do
      %User{is_admin: true} -> true
      _ -> false
    end
  end

  # A tour-side user is any authenticated user with at least one tour membership.
  defp tour_side_user?(user_id) do
    Repo.exists?(from m in TourMembership, where: m.user_id == ^user_id)
  end
end
