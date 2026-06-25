defmodule TourmanagerV2Web.Plugs.Auth do
  import Plug.Conn
  alias TourmanagerV2.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    if user_id do
      user = Accounts.get_user!(user_id)
      assign(conn, :current_user, user)
    else
      assign(conn, :current_user, nil)
    end
  rescue
    Ecto.NoResultsError ->
      conn
      |> configure_session(drop: true)
      |> assign(:current_user, nil)
  end

  def fetch_current_user(conn, _opts), do: call(conn, [])
end
