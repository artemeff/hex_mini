defmodule HexMini.PackagesTest do
  use HexMini.Case

  alias HexMini.{Repo, Packages, Storage}
  alias HexMini.Packages.Changelog

  describe "#publish/3" do
    test "creates package with release and requirements" do
      info = build(:publish_package)
      tarball = <<1, 2, 3, 4, 5>>

      assert {:ok, _, package, release} = Packages.publish(info, tarball, "john@doe")

      assert package.name == info.metadata["name"]
      assert package.owners == ["john@doe"]

      assert release.package_id == package.id
      assert release.version == info.metadata["version"]
      assert release.owner == "john@doe"
      assert length(release.requirements) == 2
    end

    test "creates package without requirements" do
      info = build(:publish_package)
      info = put_in(info, [:metadata, "requirements"], %{})
      tarball = <<1, 2, 3, 4, 5>>

      assert {:ok, _, package, release} = Packages.publish(info, tarball, "john@doe")

      assert package.name == info.metadata["name"]
      assert package.owners == ["john@doe"]

      assert release.package_id == package.id
      assert release.version == info.metadata["version"]
      assert release.owner == "john@doe"
      assert length(release.requirements) == 0
    end

    test "saves package in Storage" do
      info = build(:publish_package)
      tarball = <<1, 2, 3, 4, 5>>

      assert {:ok, _, package, release} = Packages.publish(info, tarball, "john@doe")
      assert path = Storage.fetch_path(package.name, release.version)
      assert {:ok, tarball} == File.read(path)
    end

    test "creates changelog" do
      info = build(:publish_package)

      assert {:ok, _, package, release} = Packages.publish(info, <<>>, "john@doe")
      assert changelog = Repo.get_by(Changelog, package_id: package.id, release_id: release.id)
      assert changelog.action == "publish"
      assert changelog.user == "john@doe"
    end

    test "returns action = :create when it is a new package" do
      info = build(:publish_package)
      assert {:ok, :create, _, _} = Packages.publish(info, <<>>, "john@doe")
    end

    test "returns action = :update when it is a new release for package" do
      info = build(:publish_package)
      assert {:ok, :create, _, _} = Packages.publish(info, <<>>, "john@doe")

      info = put_in(info, [:metadata, "version"], "2.0.0")
      assert {:ok, :update, _, _} = Packages.publish(info, <<>>, "john@doe")
    end

    test "returns error `forbidden` when user is not in package owners" do
      info = build(:publish_package)
      insert(:package, name: Map.fetch!(info.metadata, "name"))

      assert {:error, :forbidden} == Packages.publish(info, <<>>, "undefined@user")
    end

    test "returns error `already_released` when package version already published" do
      info = build(:publish_package)

      assert {:ok, _, _, _} = Packages.publish(info, <<>>, "john@doe")
      assert {:error, :already_released} = Packages.publish(info, <<>>, "john@doe")
    end
  end

  describe "#fetch/1" do
    test "returns package info with requirements" do
      release = build(:release, requirements: [build(:requirement)])
      package = insert(:package, releases: [release])

      assert {:ok, package} == Packages.fetch(package.name)
    end

    test "returns error" do
      assert {:error, :not_found} == Packages.fetch("undefined")
    end
  end
end
