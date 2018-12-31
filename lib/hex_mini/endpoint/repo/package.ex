defmodule HexMini.Endpoint.Repo.Package do
  @moduledoc """
  Returns package metainfo: name, releases, requirements...
  Invokes when user runs `mix deps.get`.
  """

  import Plug.Conn
  import HexMini.Endpoint.API, only: [respond_error: 3]

  def init(_), do: []

  def call(conn, _opts) do
    case HexMini.Packages.fetch(conn.path_params["name"]) do
      {:ok, package} ->
        send_resp(conn, 200, build_package(package))

      {:error, :not_found} ->
        respond_error(conn, 404, message: "Package not found")
    end
  end

  def build_package(package) do
    package
    |> serialize()
    |> :hex_registry.encode_package()
    |> :hex_registry.sign_protobuf(HexMini.private_key)
    |> :zlib.gzip()
  end

  defp serialize(%HexMini.Packages.Package{releases: releases} = package) when is_list(releases) do
    # TODO add field: `repository`
    %{name: package.name, releases: Enum.map(releases, &serialize_release/1)}
  end

  defp serialize_release(%HexMini.Packages.Release{} = r) do
    # TODO add retirements, field: `retired`
    %{checksum: r.checksum, version: r.version,
      dependencies: Enum.map(r.requirements, &serialize_dependency/1)}
  end

  defp serialize_dependency(%HexMini.Packages.Requirement{} = r) do
    %{requirement: r.requirement, optional: r.optional,
      app: r.app, repository: r.repository}
  end
end
