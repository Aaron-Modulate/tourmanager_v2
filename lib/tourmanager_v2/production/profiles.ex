defmodule TourmanagerV2.Production.Profiles do
  @moduledoc """
  Context for managing venue production profiles.

  Venues are global shared records keyed by Google Place ID — any user can view
  them and suggest corrections. Only platform admins (is_admin: true) can
  accept/reject suggestions or directly edit data.
  """

  import Ecto.Query
  alias TourmanagerV2.Repo
  alias TourmanagerV2.Production.{
    Venue,
    VenueProductionProfile,
    RiggingPoint,
    HouseTruss,
    PowerService,
    LoadingAccess,
    HouseLightingFixture
  }

  # ---------------------------------------------------------------------------
  # Venues
  # ---------------------------------------------------------------------------

  @spec list_venues_with_profiles() :: [Venue.t()]
  def list_venues_with_profiles do
    Repo.all(
      from v in Venue,
        join: p in assoc(v, :production_profile),
        where: p.profile_status == "published",
        order_by: v.name,
        preload: [production_profile: p]
    )
  end

  @spec search_venues(String.t()) :: [Venue.t()]
  def search_venues(query) when byte_size(query) >= 2 do
    term = "%#{query}%"
    Repo.all(
      from v in Venue,
        where: ilike(v.name, ^term) or ilike(v.city, ^term) or ilike(v.formatted_address, ^term),
        order_by: v.name,
        limit: 20
    )
  end
  def search_venues(_), do: []

  @spec get_venue!(binary()) :: Venue.t()
  def get_venue!(id), do: Repo.get!(Venue, id)

  @spec get_venue_by_place_id(String.t()) :: Venue.t() | nil
  def get_venue_by_place_id(place_id) when is_binary(place_id) do
    Repo.get_by(Venue, google_place_id: place_id)
  end

  @spec get_venue_with_production_data(binary()) :: Venue.t() | nil
  def get_venue_with_production_data(id) do
    case Repo.get(Venue, id) do
      nil -> nil
      venue ->
        Repo.preload(venue, [
          :production_profile,
          :rigging_points,
          :house_trusses,
          :power_services,
          :loading_access,
          :lighting_fixtures,
          production_documents: [:uploaded_by_user]
        ])
    end
  end

  @doc """
  Finds an existing venue by Google Place ID, or creates a new one from the
  place map returned by GoogleMaps.place_details/1.
  """
  @spec get_or_create_venue_by_place(map()) :: {:ok, Venue.t()} | {:error, Ecto.Changeset.t()}
  def get_or_create_venue_by_place(%{place_id: place_id} = place) do
    case get_venue_by_place_id(place_id) do
      %Venue{} = venue ->
        {:ok, venue}

      nil ->
        %Venue{}
        |> Venue.changeset(%{
          google_place_id: place_id,
          name: place.name,
          formatted_address: place[:address],
          lat: place[:lat],
          lng: place[:lng]
        })
        |> Repo.insert()
    end
  end

  @spec update_venue(Venue.t(), map()) :: {:ok, Venue.t()} | {:error, Ecto.Changeset.t()}
  def update_venue(%Venue{} = venue, attrs) do
    venue |> Venue.changeset(attrs) |> Repo.update()
  end

  # ---------------------------------------------------------------------------
  # Production Profile
  # ---------------------------------------------------------------------------

  @spec get_or_create_profile(binary()) :: {:ok, VenueProductionProfile.t()} | {:error, Ecto.Changeset.t()}
  def get_or_create_profile(venue_id) do
    case Repo.get_by(VenueProductionProfile, venue_id: venue_id) do
      nil ->
        %VenueProductionProfile{venue_id: venue_id}
        |> VenueProductionProfile.changeset(%{})
        |> Repo.insert()

      profile ->
        {:ok, profile}
    end
  end

  @spec update_profile(VenueProductionProfile.t(), map()) ::
          {:ok, VenueProductionProfile.t()} | {:error, Ecto.Changeset.t()}
  def update_profile(%VenueProductionProfile{} = profile, attrs) do
    profile |> VenueProductionProfile.changeset(attrs) |> Repo.update()
  end

  @spec publish_profile(VenueProductionProfile.t(), binary()) ::
          {:ok, VenueProductionProfile.t()} | {:error, Ecto.Changeset.t()}
  def publish_profile(%VenueProductionProfile{} = profile, user_id) do
    profile
    |> VenueProductionProfile.changeset(%{
      profile_status: "published",
      last_verified_at: DateTime.utc_now(),
      verified_by_user_id: user_id
    })
    |> Repo.update()
  end

  @spec change_profile(VenueProductionProfile.t(), map()) :: Ecto.Changeset.t()
  def change_profile(%VenueProductionProfile{} = profile, attrs \\ %{}) do
    VenueProductionProfile.changeset(profile, attrs)
  end

  # ---------------------------------------------------------------------------
  # Rigging Points
  # ---------------------------------------------------------------------------

  @spec list_rigging_points(binary()) :: [RiggingPoint.t()]
  def list_rigging_points(venue_id) do
    Repo.all(from r in RiggingPoint, where: r.venue_id == ^venue_id, order_by: r.label)
  end

  @spec get_rigging_point!(binary()) :: RiggingPoint.t()
  def get_rigging_point!(id), do: Repo.get!(RiggingPoint, id)

  @spec create_rigging_point(binary(), map()) :: {:ok, RiggingPoint.t()} | {:error, Ecto.Changeset.t()}
  def create_rigging_point(venue_id, attrs) do
    %RiggingPoint{venue_id: venue_id} |> RiggingPoint.changeset(attrs) |> Repo.insert()
  end

  @spec update_rigging_point(RiggingPoint.t(), map()) :: {:ok, RiggingPoint.t()} | {:error, Ecto.Changeset.t()}
  def update_rigging_point(%RiggingPoint{} = point, attrs) do
    point |> RiggingPoint.changeset(attrs) |> Repo.update()
  end

  @spec delete_rigging_point(RiggingPoint.t()) :: {:ok, RiggingPoint.t()} | {:error, any()}
  def delete_rigging_point(%RiggingPoint{} = point), do: Repo.delete(point)

  # ---------------------------------------------------------------------------
  # House Trusses
  # ---------------------------------------------------------------------------

  @spec list_house_trusses(binary()) :: [HouseTruss.t()]
  def list_house_trusses(venue_id) do
    Repo.all(from t in HouseTruss, where: t.venue_id == ^venue_id, order_by: t.label)
  end

  @spec get_house_truss!(binary()) :: HouseTruss.t()
  def get_house_truss!(id), do: Repo.get!(HouseTruss, id)

  @spec create_house_truss(binary(), map()) :: {:ok, HouseTruss.t()} | {:error, Ecto.Changeset.t()}
  def create_house_truss(venue_id, attrs) do
    %HouseTruss{venue_id: venue_id} |> HouseTruss.changeset(attrs) |> Repo.insert()
  end

  @spec delete_house_truss(HouseTruss.t()) :: {:ok, HouseTruss.t()} | {:error, any()}
  def delete_house_truss(%HouseTruss{} = truss), do: Repo.delete(truss)

  # ---------------------------------------------------------------------------
  # Power Services
  # ---------------------------------------------------------------------------

  @spec list_power_services(binary()) :: [PowerService.t()]
  def list_power_services(venue_id) do
    Repo.all(from p in PowerService, where: p.venue_id == ^venue_id, order_by: p.name)
  end

  @spec create_power_service(binary(), map()) :: {:ok, PowerService.t()} | {:error, Ecto.Changeset.t()}
  def create_power_service(venue_id, attrs) do
    %PowerService{venue_id: venue_id} |> PowerService.changeset(attrs) |> Repo.insert()
  end

  @spec update_power_service(PowerService.t(), map()) :: {:ok, PowerService.t()} | {:error, Ecto.Changeset.t()}
  def update_power_service(%PowerService{} = service, attrs) do
    service |> PowerService.changeset(attrs) |> Repo.update()
  end

  @spec delete_power_service(PowerService.t()) :: {:ok, PowerService.t()} | {:error, any()}
  def delete_power_service(%PowerService{} = service), do: Repo.delete(service)

  @spec get_power_service!(binary()) :: PowerService.t()
  def get_power_service!(id), do: Repo.get!(PowerService, id)

  # ---------------------------------------------------------------------------
  # Loading Access
  # ---------------------------------------------------------------------------

  @spec get_or_create_loading_access(binary()) :: {:ok, LoadingAccess.t()} | {:error, Ecto.Changeset.t()}
  def get_or_create_loading_access(venue_id) do
    case Repo.get_by(LoadingAccess, venue_id: venue_id) do
      nil ->
        %LoadingAccess{venue_id: venue_id} |> LoadingAccess.changeset(%{}) |> Repo.insert()

      access ->
        {:ok, access}
    end
  end

  @spec update_loading_access(LoadingAccess.t(), map()) :: {:ok, LoadingAccess.t()} | {:error, Ecto.Changeset.t()}
  def update_loading_access(%LoadingAccess{} = access, attrs) do
    access |> LoadingAccess.changeset(attrs) |> Repo.update()
  end

  # ---------------------------------------------------------------------------
  # Lighting Fixtures
  # ---------------------------------------------------------------------------

  @spec list_lighting_fixtures(binary()) :: [HouseLightingFixture.t()]
  def list_lighting_fixtures(venue_id) do
    Repo.all(
      from f in HouseLightingFixture,
      where: f.venue_id == ^venue_id,
      order_by: [f.fixture_name, f.manufacturer]
    )
  end

  @spec create_lighting_fixture(binary(), map()) :: {:ok, HouseLightingFixture.t()} | {:error, Ecto.Changeset.t()}
  def create_lighting_fixture(venue_id, attrs) do
    %HouseLightingFixture{venue_id: venue_id} |> HouseLightingFixture.changeset(attrs) |> Repo.insert()
  end

  @spec update_lighting_fixture(HouseLightingFixture.t(), map()) :: {:ok, HouseLightingFixture.t()} | {:error, Ecto.Changeset.t()}
  def update_lighting_fixture(%HouseLightingFixture{} = fixture, attrs) do
    fixture |> HouseLightingFixture.changeset(attrs) |> Repo.update()
  end

  @spec delete_lighting_fixture(HouseLightingFixture.t()) :: {:ok, HouseLightingFixture.t()} | {:error, any()}
  def delete_lighting_fixture(%HouseLightingFixture{} = fixture), do: Repo.delete(fixture)

  @spec get_lighting_fixture!(binary()) :: HouseLightingFixture.t()
  def get_lighting_fixture!(id), do: Repo.get!(HouseLightingFixture, id)

  # ---------------------------------------------------------------------------
  # Authorization
  # ---------------------------------------------------------------------------

  @doc "Returns true if the user is a platform admin (is_admin: true on the user record)."
  @spec platform_admin?(map() | nil) :: boolean()
  def platform_admin?(%{is_admin: true}), do: true
  def platform_admin?(_), do: false
end
