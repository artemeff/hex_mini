defmodule HexMini.Endpoint.Repo.Publish do
  use HexMini.Endpoint.API

  plug :read_tarball_body
  plug :unpack_tarball
  plug :publish_release

  defp read_tarball_body(conn, _opts) do
    case read_body(conn) do
      {:ok, tarball, conn} ->
        assign(conn, :tarball, tarball)

      {:more, _, conn} ->
        respond_error(conn, 422)

      {:error, _reason} ->
        respond_error(conn, 422)
    end
  end

  defp unpack_tarball(conn, _opts) do
    case :hex_tarball.unpack(conn.assigns.tarball, :memory) do
      {:ok, %{checksum: _, metadata: _, contents: _} = package} ->
        assign(conn, :package, package)

      {:error, reason} ->
        respond_error(conn, 422, errors: %{tar: List.to_string(:hex_tarball.format_error(reason))})
    end
  end

  defp publish_release(conn, _opts) do
    # TODO if it's a new package - 201, otherwise 200
    case HexMini.Packages.publish(conn.assigns.package, conn.assigns.tarball, conn.assigns.current_user) do
      {:ok, package, release} ->
        conn
        |> put_resp_header("location", "http://localhost:4000/publish/some/package")
        |> respond(201, response_body(package, release))

      {:error, %Ecto.Changeset{} = changeset} ->
        respond_error(conn, 422, errors: changeset_errors(changeset))

      {:error, reason} ->
        respond_error(conn, 422, message: inspect(reason))
    end
  end

  defp response_body(_package, release) do
    %{
      html_url: "http://localhost"
    }
  end

  def changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn({message, opts}) ->
      Enum.reduce(opts, message, fn({key, value}, acc) ->
        String.replace(acc, "%{#{key}}", inspect(value))
      end)
    end)
    |> normalize_errors()
  end

  defp normalize_errors(errors) do
    errors |> Enum.flat_map(&normalize_key_value/1) |> Map.new()
  end

  defp normalize_key_value({key, value}) do
    case value do
      _ when value == %{} ->
        []

      [%{} | _] = value ->
        [{key, Enum.reduce(value, %{}, &Map.merge(&2, normalize_errors(&1)))}]

      [] ->
        []

      value when is_map(value) ->
        [{key, normalize_errors(value)}]

      [value | _] ->
        [{key, value}]
    end
  end
end
