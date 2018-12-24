defmodule HexMini.Endpoint.Plugs.Authorization do
  alias Plug.Conn
  alias HexMini.Endpoint.API

  def init(opts) do
    %{except: Keyword.get(opts, :except, [])}
  end

  def call(conn, %{except: except}) do
    if {conn.method, conn.request_path} in except do
      conn
    else
      check_authorization_header(conn)
    end
  end

  defp check_authorization_header(conn) do
    case Conn.get_req_header(conn, "authorization") do
      [value | _] ->
        check_token(conn, value)

      [] ->
        API.respond_error(conn, 401, message: "missing authentication information")
    end
  end

  defp check_token(conn, token) do
    case fetch_credentials(token) do
      {user, _user_token} -> Conn.assign(conn, :current_user, user)
      nil -> API.respond_error(conn, 401, message: "invalid API key")
    end
  end

  defp fetch_credentials(token) do
    Enum.find(HexMini.credentials, fn({_user, user_token}) ->
      token == user_token
    end)
  end
end
