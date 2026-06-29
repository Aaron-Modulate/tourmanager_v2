defmodule TourmanagerV2.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TourmanagerV2Web.Telemetry,
      TourmanagerV2.Repo,
      {DNSCluster, query: Application.get_env(:tourmanager_v2, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TourmanagerV2.PubSub},
      TourmanagerV2.Admin.Scheduler,
      TourmanagerV2Web.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TourmanagerV2.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TourmanagerV2Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
