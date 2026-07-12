defmodule TourmanagerV2Web.Router do
  use TourmanagerV2Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TourmanagerV2Web.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug TourmanagerV2Web.Plugs.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :calendar do
    plug :accepts, ["html", "json", "ics"]
  end

  scope "/auth", TourmanagerV2Web do
    pipe_through :browser

    post "/magic_link", AuthController, :send_magic_link
    get "/magic_link/verify", AuthController, :verify_magic_link
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    delete "/sign_out", AuthController, :sign_out
  end

  scope "/api", TourmanagerV2Web do
    pipe_through :browser

    post "/set_tour", SessionController, :set_tour
    post "/set_distance_unit", SessionController, :set_distance_unit
  end

  scope "/webhooks", TourmanagerV2Web do
    pipe_through :api

    post "/stripe", StripeWebhookController, :webhook
  end

  scope "/", TourmanagerV2Web do
    pipe_through :calendar

    get "/cal/:token", CalendarController, :feed
  end

  scope "/", TourmanagerV2Web do
    pipe_through :browser

    get "/sitemap.xml", SitemapController, :index
    get "/setlist/:id/print", SetlistPrintController, :show

    live_session :public do
      live "/", LandingLive
      live "/invite/:token", InviteLive
    end

    live_session :default,
      on_mount: [{TourmanagerV2Web.AuthHooks, :default}] do
      live "/app", DaySheetLive
      live "/routing", RoutingLive
      live "/crew", CrewLive
      live "/dashboard", DashboardLive
      live "/profile", ProfileLive
      live "/setlists", SetlistLive
      live "/accommodation", AccommodationLive
      live "/guests", GuestListLive
      live "/admin/tours", Admin.ToursLive
      live "/admin/jobs", Admin.JobsLive
      live "/admin/users", Admin.UsersLive

      # Production — Venue Production Knowledge Map
      live "/production/venues", VenueProductionProfileLive.Index
      live "/production/venues/:id", VenueProductionProfileLive.Show
      live "/production/venues/:venue_id/suggestions", SuggestionReviewLive.Index
      live "/production/compatibility", CompatibilityLive.Show
    end
  end

  if Application.compile_env(:tourmanager_v2, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TourmanagerV2Web.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
