defmodule Integration.Endpoint.APITest do
  use HexMini.Case

  describe "GET /" do
    test "returns changelog in json format" do
      cl = insert(:changelog)

      conn = request(:get, "/", "", [
        {"authorization", "ANN_KEY"}
      ])

      assert json_response(conn, 200)
          == [%{"name" => cl.package.name, "version" => cl.release.version,
                "user" => cl.release.owner, "action" => cl.action,
                "date" => cl.release.inserted_at |> NaiveDateTime.truncate(:second) |> NaiveDateTime.to_iso8601}]
    end

    test "returns changelog in plaintext format" do
      cl = insert(:changelog)

      conn = request(:get, "/", "", [
        {"accept", "text/html"},
        {"authorization", "ANN_KEY"}
      ])

      assert response(conn, 200) ==
        """
        #{cl.package.name} #{cl.release.version} #{cl.action}
          at #{NaiveDateTime.truncate(cl.release.inserted_at, :second)}
          by #{cl.release.owner}

        """
    end

    test "returns changelog with Basic authorization" do
      token = Base.encode64("ann@local:ANN_KEY")

      conn = request(:get, "/", "", [
        {"authorization", "Basic #{token}"}
      ])

      assert json_response(conn, 200) == []
    end

    test "returns 401 when authorization failed" do
      conn = request(:get, "/", "", [
        {"authorization", "UNKNOWN_KEY"}
      ])

      assert json_response(conn, 401) == %{"status" => 401, "message" => "invalid API key"}
    end

    test "returns 401 when authorization header is not provided" do
      conn = request(:get, "/")

      assert json_response(conn, 401) == %{"status" => 401, "message" => "missing authentication information"}
    end
  end
end
