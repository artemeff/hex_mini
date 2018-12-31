defmodule HexMini.Endpoint.Repo.Tarball do
  @moduledoc """
  Returns package tarball, invokes with `mix deps.get`
  """

  import Plug.Conn

  @regex ~r/(?<name>.*)-(?<version>.*).tar/

  def init(_), do: []

  def call(conn, _opts) do
    case Regex.named_captures(@regex, conn.path_params["name_with_version"]) do
      %{"name" => name, "version" => version} ->
        send_file(conn, 200, HexMini.packages_path([name, version]))

      _otherwise ->
        send_resp(conn, 404, "")
    end
  end
end
