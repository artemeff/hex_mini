defmodule HexMini.Endpoint.API do
  alias Plug.Conn

  defmacro __using__(_opts \\ []) do
    quote do
      use Plug.Builder

      import HexMini.Endpoint.API
    end
  end

  def respond(conn, status, body) do
    accept = accept_header(conn)
    {response, content_type} = serialize(conn, accept, body)

    conn
    |> Conn.put_resp_header("content-type", content_type)
    |> Conn.send_resp(status, response)
    |> Conn.halt
  end

  def respond_text_lazy(conn, responder) when is_function(responder, 1) do
    Conn.put_private(conn, :response_text_lazy, responder)
  end

  def respond_error(conn, status, assigns \\ []) do
    response =
      assigns
      |> Enum.into(%{})
      |> Map.take([:message, :errors])
      |> Map.put(:status, status)
      |> Map.put_new(:message, message(status))

    respond(conn, status, response)
  end

  defp message(400), do: "Bad request"
  defp message(404), do: "Page not found"
  defp message(408), do: "Request timeout"
  defp message(413), do: "Payload too large"
  defp message(415), do: "Unsupported media type"
  defp message(422), do: "Validation error(s)"
  defp message(500), do: "Internal server error"
  defp message(_), do: nil

  defp accept_header(conn) do
    case Conn.get_req_header(conn, "accept") do
      [v] -> String.split(v, ",")
      _or -> ["application/json"]
    end
  end

  defp serialize(_conn, ["application/vnd.hex+erlang" | _], body) do
    {serialize_erlang(body), "application/vnd.hex+erlang"}
  end
  defp serialize(conn, ["text/" <> _ | _], body) do
    case Map.fetch(conn.private, :response_text_lazy) do
      {:ok, responder} -> {responder.(body), "text/plain"}
      :error -> {inspect(body, pretty: true), "text/plain"}
    end
  end
  defp serialize(_conn, _, body) do
    {Jason.encode!(body), "application/json"}
  end

  defp serialize_erlang(term) do
    term
    |> binarify()
    |> :erlang.term_to_binary()
  end

  defp binarify(binary) when is_binary(binary), do: binary
  defp binarify(number) when is_number(number), do: number
  defp binarify(atom) when is_nil(atom) or is_boolean(atom), do: atom
  defp binarify(atom) when is_atom(atom), do: Atom.to_string(atom)
  defp binarify(list) when is_list(list), do: for(elem <- list, do: binarify(elem))
  defp binarify(%Version{} = version), do: to_string(version)

  defp binarify(%DateTime{} = dt) do
    dt |> DateTime.truncate(:second) |> DateTime.to_iso8601()
  end

  defp binarify(%NaiveDateTime{} = ndt) do
    ndt |> NaiveDateTime.truncate(:second) |> NaiveDateTime.to_iso8601()
  end

  defp binarify(%{__struct__: atom}) when is_atom(atom) do
    raise ArgumentError, "not able to binarify %#{inspect(atom)}{}"
  end

  defp binarify(tuple) when is_tuple(tuple) do
    for(elem <- Tuple.to_list(tuple), do: binarify(elem)) |> List.to_tuple()
  end

  defp binarify(map) when is_map(map) do
    for(elem <- map, into: %{}, do: binarify(elem))
  end
end
