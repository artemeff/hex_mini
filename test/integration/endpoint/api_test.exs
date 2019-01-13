defmodule Integration.Endpoint.APITest do
  use HexMini.Case

  describe "GET /" do
    test "returns changelog in json format" do
      p = insert(:package, name: "test_package")

      cl1 = insert(:changelog, package: p, release: build(:release))
      cl2 = insert(:changelog, package: p, action: "owner_add", meta: %{"user" => "john_doe"})

      conn = request(:get, "/", "", [
        {"authorization", "ANN_KEY"}
      ])

      assert json_response(conn, 200)
          == [%{"name" => cl1.package.name, "user" => cl1.user,
                "action" => "publish test_package 1.0.0",
                "date" => date(cl1.inserted_at)},
              %{"name" => cl2.package.name, "user" => cl2.user,
                "action" => "add owner john_doe to test_package",
                "date" => date(cl2.inserted_at)}]
    end

    test "returns changelog in plaintext format" do
      p = insert(:package, name: "test_package")

      cl1 = insert(:changelog, package: p, release: build(:release))
      cl2 = insert(:changelog, package: p, action: "owner_add", meta: %{"user" => "john_doe"})

      conn = request(:get, "/", "", [
        {"accept", "text/html"},
        {"authorization", "ANN_KEY"}
      ])

      assert response(conn, 200) ==
        """
        publish test_package 1.0.0
          at #{NaiveDateTime.truncate(cl1.inserted_at, :second)}
          by #{cl1.user}

        add owner john_doe to test_package
          at #{NaiveDateTime.truncate(cl2.inserted_at, :second)}
          by #{cl2.user}

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

    test "returns 401 with invalid Basic authorization token" do
      token = Base.encode64("ann@local")

      conn = request(:get, "/", "", [
        {"authorization", "Basic #{token}"}
      ])

      assert json_response(conn, 401) == %{"status" => 401, "message" => "invalid API key"}
    end

    test "returns 401 when authorization header is not provided" do
      conn = request(:get, "/")

      assert json_response(conn, 401) == %{"status" => 401, "message" => "missing authentication information"}
    end
  end

  defp date(v) do
    v |> NaiveDateTime.truncate(:second) |> NaiveDateTime.to_iso8601
  end
end
