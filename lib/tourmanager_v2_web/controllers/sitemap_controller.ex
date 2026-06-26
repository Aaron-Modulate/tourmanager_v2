defmodule TourmanagerV2Web.SitemapController do
  use TourmanagerV2Web, :controller

  def index(conn, _params) do
    host = System.get_env("PHX_HOST") || "tourmanager.live"
    today = Date.utc_today() |> Date.to_iso8601()

    xml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
      <url>
        <loc>https://#{host}/</loc>
        <lastmod>#{today}</lastmod>
        <changefreq>weekly</changefreq>
        <priority>1.0</priority>
      </url>
    </urlset>
    """

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, xml)
  end
end
