defmodule TourmanagerV2Web.AuthController do
  use TourmanagerV2Web, :controller
  plug :save_invite_token when action == :request
  plug Ueberauth

  alias TourmanagerV2.Accounts

  defp save_invite_token(conn, _opts) do
    case conn.params["invite_token"] do
      token when is_binary(token) and token != "" ->
        put_session(conn, :invite_token, token)

      _ ->
        conn
    end
  end

  def callback(%{assigns: %{ueberauth_failure: _}} = conn, _params) do
    conn
    |> put_flash(:error, "Authentication failed.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    invite_token = get_session(conn, :invite_token)

    case Accounts.find_or_create_oauth_user(auth) do
      {:ok, %{new_user: true} = _user} ->
        conn
        |> put_session(:user_id, _user.id)
        |> put_session(:detect_distance_unit, true)
        |> delete_session(:invite_token)
        |> configure_session(renew: true)
        |> redirect(to: post_auth_redirect(invite_token))

      {:ok, user} ->
        Accounts.update_last_login(user)

        conn
        |> put_session(:user_id, user.id)
        |> delete_session(:invite_token)
        |> configure_session(renew: true)
        |> redirect(to: post_auth_redirect(invite_token))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Could not sign in.")
        |> redirect(to: "/")
    end
  end

  def send_magic_link(conn, %{"email" => email}) do
    email = String.trim(email) |> String.downcase()

    if String.match?(email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/) do
      case Accounts.create_magic_link(email) do
        {:ok, token} ->
          url = TourmanagerV2Web.Endpoint.url() <> "/auth/magic_link/verify?token=#{token}"

          TourmanagerV2.Accounts.AuthEmail.magic_link_email(email, url)
          |> TourmanagerV2.Mailer.deliver()

        _ ->
          :ok
      end
    end

    conn
    |> put_flash(:info, "If that email is valid, a sign-in link has been sent.")
    |> redirect(to: "/")
  end

  def verify_magic_link(conn, %{"token" => token}) do
    case Accounts.verify_magic_link(token) do
      {:ok, %{new_user: true} = user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_session(:detect_distance_unit, true)
        |> configure_session(renew: true)
        |> redirect(to: "/app")

      {:ok, user} ->
        Accounts.update_last_login(user)

        conn
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)
        |> redirect(to: "/app")

      {:error, :expired} ->
        conn
        |> put_flash(:error, "This sign-in link has expired. Request a new one.")
        |> redirect(to: "/")

      {:error, :already_used} ->
        conn
        |> put_flash(:error, "This sign-in link has already been used. Request a new one.")
        |> redirect(to: "/")

      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid sign-in link.")
        |> redirect(to: "/")
    end
  end

  def sign_out(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end

  defp post_auth_redirect(nil), do: "/app"
  defp post_auth_redirect(""), do: "/app"
  defp post_auth_redirect(token), do: "/invite/#{token}"
end
