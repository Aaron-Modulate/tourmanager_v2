defmodule TourmanagerV2Web.SessionController do
  use TourmanagerV2Web, :controller

  def set_tour(conn, %{"tour_id" => tour_id}) do
    conn
    |> put_session(:current_tour_id, tour_id)
    |> json(%{ok: true})
  end

  def set_distance_unit(conn, %{"distance_unit" => unit}) when unit in ~w(km mi) do
    case get_session(conn, :user_id) do
      nil ->
        conn |> put_status(401) |> json(%{error: "not authenticated"})

      user_id ->
        user = TourmanagerV2.Accounts.get_user!(user_id)

        case TourmanagerV2.Accounts.update_distance_unit(user, unit) do
          {:ok, _user} ->
            conn |> delete_session(:detect_distance_unit) |> json(%{ok: true})
          {:error, _} -> conn |> put_status(422) |> json(%{error: "could not update"})
        end
    end
  end

  def set_distance_unit(conn, _params) do
    conn |> put_status(400) |> json(%{error: "invalid distance_unit"})
  end
end
