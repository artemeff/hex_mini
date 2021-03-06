defmodule Integration.Endpoint.RepoTest do
  use HexMini.Case

  describe "GET /public_key" do
    test "returns public_key" do
      conn = request(:get, "/public_key")

      assert response(conn, 200) == HexMini.public_key
      assert response_content_type(conn, "application/x-pem-file")
    end
  end

  describe "GET /packages/:name" do
    test "respond in gzipped protobuf message with package info" do
      release = build(:release)
      package = insert(:package, releases: [release])

      conn = request(:get, "/packages/#{package.name}", %{}, [
        {"authorization", "ANN_KEY"}
      ])

      body = :zlib.gunzip(conn.resp_body)
      dependencies = Enum.map(release.requirements, fn(r) ->
        %{app: r.app, optional: r.optional, package: "",
          repository: r.repository, requirement: r.requirement}
      end)

      assert response(conn, 200)
      assert {:ok, protobuf} = :hex_registry.decode_and_verify_signed(body, HexMini.public_key)
      assert %{name: "test_package", repository: "",
               releases: [
                 %{checksum: release.checksum, dependencies: dependencies,
                   retired: :undefined, version: release.version}
               ]}
          == :hex_registry.decode_package(protobuf)
    end

    test "respond with 404 when package not found" do
      conn = request(:get, "/packages/undefined", %{}, [
        {"authorization", "ANN_KEY"}
      ])

      assert json_response(conn, 404)
          == %{"status" => 404, "message" => "Package not found"}
    end

    test "respond with 401 json when there is no authorization header" do
      conn = request(:get, "/packages/undefined", %{}, [])

      assert json_response(conn, 401)
          == %{"status" => 401, "message" => "missing authentication information"}
    end

    test "respond with 401 json when authorization token is invalid" do
      conn = request(:get, "/packages/undefined", %{}, [
        {"authorization", "INVALID"}
      ])

      assert json_response(conn, 401)
          == %{"status" => 401, "message" => "invalid API key"}
    end

    test "respond with 401 erlang when authorization token is invalid" do
      conn = request(:get, "/packages/undefined", %{}, [
        {"accept", "application/vnd.hex+erlang"},
        {"authorization", "INVALID"}
      ])

      assert erlang_response(conn, 401)
          == %{"status" => 401, "message" => "invalid API key"}
    end
  end

  describe "GET /packages/:name/owners" do
    test "respond in json with package info" do
      package = insert(:package)

      conn = request(:get, "/packages/#{package.name}/owners", %{}, [
        {"authorization", "ANN_KEY"}
      ])

      assert json_response(conn, 200)
          == [%{"email" => "john@doe", "level" => "full"}]
    end

    test "respond with 404 when package not found" do
      conn = request(:get, "/packages/undefined/owners", %{}, [
        {"authorization", "ANN_KEY"}
      ])

      assert json_response(conn, 404)
          == %{"status" => 404, "message" => "Package not found"}
    end

    test "respond with 401 json when there is no authorization header" do
      conn = request(:get, "/packages/undefined/owners", %{}, [])

      assert json_response(conn, 401)
          == %{"status" => 401, "message" => "missing authentication information"}
    end
  end

  describe "PUT /packages/:name/owners/:owner" do
    test "adds owner and respond 204 with empty body" do
      package = insert(:package, owners: ["ann@local"])

      conn = request(:put, "/packages/#{package.name}/owners/john@doe", %{}, [
        {"authorization", "ANN_KEY"}
      ])

      assert response(conn, 204) == ""
    end

    test "respond with 403 when current user is not in owners" do
      package = insert(:package, owners: ["john@doe"])

      conn = request(:put, "/packages/#{package.name}/owners/some@user", %{}, [
        {"authorization", "ANN_KEY"}
      ])

      assert json_response(conn, 403)
          == %{"status" => 403, "message" => "Forbidden"}
    end

    test "respond with 404 when package not found" do
      conn = request(:put, "/packages/undefined/owners/john@doe", %{}, [
        {"authorization", "ANN_KEY"}
      ])

      assert json_response(conn, 404)
          == %{"status" => 404, "message" => "Package not found"}
    end

    test "respond with 401 json when there is no authorization header" do
      conn = request(:put, "/packages/undefined/owners/john@doe", %{}, [])

      assert json_response(conn, 401)
          == %{"status" => 401, "message" => "missing authentication information"}
    end
  end

  describe "DELETE /packages/:name/owners/:owner" do
    test "adds owner and respond 204 with empty body" do
      package = insert(:package, owners: ["ann@local"])

      conn = request(:delete, "/packages/#{package.name}/owners/john@doe", %{}, [
        {"authorization", "ANN_KEY"}
      ])

      assert response(conn, 204) == ""
    end

    test "respond with 400 when we remove yourself (the last authorized owner)" do
      package = insert(:package, owners: ["ann@local"])

      conn = request(:delete, "/packages/#{package.name}/owners/ann@local", %{}, [
        {"authorization", "ANN_KEY"}
      ])

      assert json_response(conn, 400)
          == %{"status" => 400, "message" => "You can not remove yourself"}
    end

    test "respond with 403 when current user is not in owners" do
      package = insert(:package, owners: ["john@doe"])

      conn = request(:delete, "/packages/#{package.name}/owners/john@doe", %{}, [
        {"authorization", "ANN_KEY"}
      ])

      assert json_response(conn, 403)
          == %{"status" => 403, "message" => "Forbidden"}
    end

    test "respond with 404 when package not found" do
      conn = request(:delete, "/packages/undefined/owners/john@doe", %{}, [
        {"authorization", "ANN_KEY"}
      ])

      assert json_response(conn, 404)
          == %{"status" => 404, "message" => "Package not found"}
    end

    test "respond with 401 json when there is no authorization header" do
      conn = request(:delete, "/packages/undefined/owners/john@doe", %{}, [])

      assert json_response(conn, 401)
          == %{"status" => 401, "message" => "missing authentication information"}
    end
  end

  describe "GET /tarballs/:name_with_version" do
    test "respond with tarball file" do
      info = build(:publish_package)
      tarball = :crypto.strong_rand_bytes(128)

      {:ok, _, package, release} = HexMini.Packages.publish(info, tarball, "john_doe")

      conn = request(:get, "/tarballs/#{package.name}-#{release.version}.tar", "", [
        {"authorization", "ANN_KEY"}
      ])

      assert response(conn, 200) == tarball
    end

    test "respond with error when passing name and version only" do
      conn = request(:get, "/tarballs/test-1.0.0", "", [
        {"authorization", "ANN_KEY"}
      ])

      assert response(conn, 404) == ""
    end

    test "respond with error when passing name only" do
      conn = request(:get, "/tarballs/test", "", [
        {"authorization", "ANN_KEY"}
      ])

      assert response(conn, 404) == ""
    end

    test "respond with 401 json when there is no authorization header" do
      conn = request(:get, "/tarballs/test", "", [])

      assert json_response(conn, 401)
          == %{"status" => 401, "message" => "missing authentication information"}
    end
  end

  describe "POST /publish with valid params" do
    setup do
      meta = build(:publish_metadata, %{"description" => random_description()})
      body = publish_package_body(meta)

      conn = request(:post, "/publish", body, [
        {"accept", "application/vnd.hex+erlang"},
        {"authorization", "ANN_KEY"},
        {"content-type", "application/octet-stream"},
        {"user-agent", "Hex/0.18.2 (Elixir/1.7.4) (OTP/21.2)"}
      ])

      {:ok, conn: conn, meta: meta, body: body}
    end

    test "creates Package with owner from authorization token", %{meta: meta} do
      assert {:ok, package} = HexMini.Packages.fetch(meta["name"])
      assert package.owners == ["ann@local"]
      assert List.first(package.releases).owner == "ann@local"
    end

    test "respond 201 status in Erlang term with all required information", %{meta: meta, conn: conn} do
      assert erlang_response(conn, 201)
          == %{"url" => "/packages/#{meta["name"]}", "version" => "1.0.0"}
    end

    test "respond with 200 status when we publish a new release", %{meta: meta} do
      meta = Map.put(meta, "version", "2.0.0")
      body = publish_package_body(meta)

      conn = request(:post, "/publish", body, [
        {"accept", "application/vnd.hex+erlang"},
        {"authorization", "ANN_KEY"},
        {"content-type", "application/octet-stream"},
        {"user-agent", "Hex/0.18.2 (Elixir/1.7.4) (OTP/21.2)"}
      ])

      assert erlang_response(conn, 200)
          == %{"url" => "/packages/#{meta["name"]}", "version" => "2.0.0"}
    end
  end

  describe "POST /publish returns error" do
    test "with empty body" do
      conn = request(:post, "/publish", "", [
        {"accept", "application/vnd.hex+erlang"},
        {"authorization", "ANN_KEY"},
      ])

      assert erlang_response(conn, 422)
          == %{"status" => 422, "errors" => %{"tar" => "tarball error, Unexpected end of file"},
               "message" => "Validation error(s)"}
    end

    test "with invalid package metadata" do
      meta =
        build(:publish_metadata, %{"description" => random_description()})
        |> put_in(["version"], 42)
        |> put_in(["requirements", "test_dependency_1", "requirement"], 42)

      conn = request(:post, "/publish", publish_package_body(meta), [
        {"accept", "application/vnd.hex+erlang"},
        {"authorization", "ANN_KEY"},
        {"content-type", "application/octet-stream"},
        {"user-agent", "Hex/0.18.2 (Elixir/1.7.4) (OTP/21.2)"}
      ])

      assert erlang_response(conn, 422)
          == %{"status" => 422, "message" => "Validation error(s)",
               "errors" => %{"requirements" => %{"requirement" => "is invalid"},
                             "version" => "is invalid"}}
    end

    test "without authorization header" do
      conn = request(:post, "/publish", "", [
        {"accept", "application/vnd.hex+erlang"},
      ])

      assert erlang_response(conn, 401)
          == %{"status" => 401, "message" => "missing authentication information"}
    end
  end

  defp publish_package_body(metadata) do
    {:ok, {tarball, _checksum}} = :hex_tarball.create(metadata, [])
    tarball
  end

  # just for package uniqueness
  defp random_description do
    "#{NaiveDateTime.utc_now} from #{Base.encode64(:crypto.strong_rand_bytes(8))}"
  end
end
