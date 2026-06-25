defmodule TourmanagerV2Web.AuthController do
  use TourmanagerV2Web, :controller
  plug Ueberauth

  alias TourmanagerV2.Accounts

  def callback(%{assigns: %{ueberauth_failure: _}} = conn, _params) do
    conn
    |> put_flash(:error, "Authentication failed.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Accounts.find_or_create_oauth_user(auth) do
      {:ok, %{new_user: true} = user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_session(:detect_distance_unit, true)
        |> configure_session(renew: true)
        |> redirect(to: "/")

      {:ok, user} ->
        Accounts.update_last_login(user)

        conn
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)
        |> redirect(to: "/")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Could not sign in.")
        |> redirect(to: "/")
    end
  end

  def sign_out(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end
end
