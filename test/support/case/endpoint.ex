defmodule HexMini.Case.Endpoint do
  use Plug.Test

  alias Plug.Conn

  def request(method, path, body \\ "", headers \\ []) do
    conn = conn(method, path, body)
    conn =
      Enum.reduce(headers, conn, fn({key, value}, conn) ->
        put_req_header(conn, key, value)
      end)

    HexMini.Endpoint.call(conn, [])
  end

  def response(%Conn{status: status, resp_body: body}, given) do
    given = Conn.Status.code(given)

    if given == status do
      body
    else
      raise "expected response with status #{given}, got: #{status}, with body:\n#{inspect(body)}"
    end
  end

  def json_response(conn, status) do
    body = response(conn, status)
    _    = response_content_type(conn, "application/json")

    Jason.decode!(body)
  end

  def erlang_response(conn, status) do
    body = response(conn, status)
    _    = response_content_type(conn, "application/vnd.hex+erlang")

    :erlang.binary_to_term(body, [:safe])
  end

  def response_content_type(conn, content_type) do
    case Conn.get_resp_header(conn, "content-type") do
      [] ->
        raise "no content-type was set, expected a #{content_type} response"

      [^content_type] ->
        content_type

      [h] ->
        raise "expected content-type for #{content_type}, got: #{h}"

      [_|_] ->
        raise "more than one content-type was set, expected a #{content_type} response"
    end
  end
end
