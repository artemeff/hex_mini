defmodule HexMini.Endpoint.Repo.PublicKey do
  @moduledoc """
  Returns Public Key of the current HexMini instance.
  """

  import Plug.Conn

  def init(_), do: []

  def call(conn, _opts) do
    conn
    |> put_resp_header("content-type", "application/x-pem-file")
    |> send_resp(200, HexMini.public_key)
  end
end
