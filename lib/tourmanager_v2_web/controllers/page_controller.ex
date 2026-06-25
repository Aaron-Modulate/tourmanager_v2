defmodule TourmanagerV2Web.PageController do
  use TourmanagerV2Web, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
