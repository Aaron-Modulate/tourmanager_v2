defmodule TourmanagerV2Web.Plugs.RawBody do
  def init(opts), do: opts

  def call(conn, _opts) do
    case Plug.Conn.read_body(conn) do
      {:ok, body, conn} ->
        Plug.Conn.assign(conn, :raw_body, body)
        |> Plug.Conn.put_private(:raw_body, body)

      _ ->
        conn
    end
  end
end
