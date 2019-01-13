defmodule HexMini.Endpoint.Repo.Package.Owner.Delete do
  @moduledoc """
  Remove owner from Package:

    $ mix hex.owner remove <lib> <john@doe>
  """

  import Plug.Conn
  import HexMini.Endpoint.API, only: [respond_error: 2, respond_error: 3]

  def init(_), do: []

  def call(%{path_params: params, assigns: assigns} = conn, _opts) do
    case HexMini.Packages.delete_owner(params["name"], assigns.current_user, params["owner"]) do
      {:ok, _package} -> send_resp(conn, 204, "")
      {:error, :forbidden} -> respond_error(conn, 403)
      {:error, :not_found} -> respond_error(conn, 404, message: "Package not found")
      {:error, :empty_owners} -> respond_error(conn, 400, message: "You can not remove yourself")
    end
  end
end
