defmodule HexMini.Endpoint do
  use Plug.Builder

  plug Plug.Logger, log: :debug
  plug Plug.RequestId

  plug Plug.Parsers,
    parsers: [:multipart, :urlencoded, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug :log
  plug HexMini.Endpoint.Router

  def child_spec(opts) do
    Plug.Adapters.Cowboy.child_spec(
      Keyword.merge([scheme: :http, plug: __MODULE__], opts))
  end

  defp log(conn, _opts) do
    IO.inspect conn
    conn
  end
end
