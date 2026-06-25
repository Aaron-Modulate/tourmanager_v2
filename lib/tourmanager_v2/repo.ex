defmodule TourmanagerV2.Repo do
  use Ecto.Repo,
    otp_app: :tourmanager_v2,
    adapter: Ecto.Adapters.Postgres
end
