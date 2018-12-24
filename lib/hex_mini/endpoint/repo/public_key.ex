defmodule HexMini.Endpoint.Repo.PublicKey do
  import Plug.Conn

  def init(_), do: []

  def call(conn, _opts) do
    case HexMini.public_key do
      nil ->
        send_resp(conn, 404, "public key not found")

      key ->
        conn
        |> put_resp_header("content-type", "application/x-pem-file")
        |> send_resp(200, key)
    end
  end
end
