defmodule HexMini.Endpoint.Plugs.Authorization do
  alias Plug.Conn
  alias HexMini.Endpoint.API

  def init(opts) do
    %{except: Keyword.get(opts, :except, [])}
  end

  def call(conn, %{except: except}) do
    client = fetch_user_agent!(conn)

    if {conn.method, conn.request_path} in except do
      conn
    else
      check_authorization_header(conn, client)
    end
  end

  defp fetch_user_agent!(conn) do
    case Conn.get_req_header(conn, "user-agent") do
      [ua] ->
        if String.starts_with?(ua, "Hex") do
          :hex
        else
          :browser
        end

      _ ->
        API.respond_error(conn, 401, message: "missing user-agent information")
    end
  end

  defp check_authorization_header(conn, client) do
    case Conn.get_req_header(conn, "authorization") do
      [value | _] ->
        check_token(conn, value)

      [] ->
        conn
        |> maybe_put_www_authorization(client)
        |> API.respond_error(401, message: "missing authentication information")
    end
  end

  defp maybe_put_www_authorization(conn, :browser) do
    Conn.put_resp_header(conn, "www-authenticate", ~s(Basic realm="hex_mini"))
  end
  defp maybe_put_www_authorization(conn, _client) do
    conn
  end

  defp check_token(conn, "Basic " <> base64) do
    with {:ok, slug} <- Base.decode64(base64),
         [user, token] <- String.split(slug, ":", parts: 2),
         {^user, ^token} <- fetch_credentials(token)
    do
      Conn.assign(conn, :current_user, user)
    else
      _ -> API.respond_error(conn, 401, message: "invalid API key")
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
