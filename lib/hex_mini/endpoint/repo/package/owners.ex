defmodule HexMini.Endpoint.Repo.Package.Owners do
  @moduledoc """
  Returns Package owners from:

    $ mix hex.owner list <lib>
  """

  import HexMini.Endpoint.API, only: [respond: 3, respond_error: 3]

  def init(_), do: []

  def call(conn, _opts) do
    case HexMini.Packages.owners(conn.path_params["name"]) do
      {:ok, owners} -> respond(conn, 200, serialize(owners))
      {:error, :not_found} -> respond_error(conn, 404, message: "Package not found")
    end
  end

  defp serialize(owners) do
    Enum.map(owners, fn(o) ->
      %{email: o, level: "full"}
    end)
  end
end
