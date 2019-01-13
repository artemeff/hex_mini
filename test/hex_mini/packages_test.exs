defmodule HexMini.PackagesTest do
  use HexMini.Case

  alias HexMini.{Repo, Packages, Storage}
  alias HexMini.Packages.Changelog

  describe "#owners/1" do
    test "returns package owners" do
      package = insert(:package)

      assert {:ok, package.owners} == Packages.owners(package.name)
    end

    test "returns error when package not found" do
      assert {:error, :not_found} == Packages.owners("undefined")
    end
  end

  describe "#add_owner/3" do
    test "adds owner to the package" do
      package = insert(:package)
      current_user = List.first(package.owners)

      assert {:ok, package} = Packages.add_owner(package.name, current_user, "new_owner")
      assert package.owners == ["new_owner", current_user]
    end

    test "don't duplicates owners" do
      package = insert(:package)
      current_user = List.first(package.owners)

      assert {:ok, package} = Packages.add_owner(package.name, current_user, current_user)
      assert package.owners == [current_user]
    end

    test "creates changelog" do
      package = insert(:package)
      current_user = List.first(package.owners)

      assert {:ok, package} = Packages.add_owner(package.name, current_user, "new_owner")
      assert [changelog] = Repo.all(Changelog)
      assert changelog.package_id == package.id
      assert changelog.user == current_user
      assert changelog.action == "owner_add"
      assert changelog.meta == %{"user" => "new_owner"}
    end

    test "returns forbidden error when current_user is not in owners" do
      package = insert(:package)

      assert {:error, :forbidden} == Packages.add_owner(package.name, "undefined", "new_owner")
    end

    test "returns error when package not found" do
      assert {:error, :not_found} == Packages.add_owner("undefined", "undefined", "new_owner")
    end
  end

  describe "#delete_owner/3" do
    test "removes owner from the package" do
      package = insert(:package, owners: ["owner1", "owner2"])

      assert {:ok, package} = Packages.delete_owner(package.name, "owner1", "owner2")
      assert package.owners == ["owner1"]
    end

    test "creates changelog" do
      package = insert(:package, owners: ["owner1", "owner2"])

      assert {:ok, package} = Packages.delete_owner(package.name, "owner1", "owner2")
      assert [changelog] = Repo.all(Changelog)
      assert changelog.package_id == package.id
      assert changelog.user == "owner1"
      assert changelog.action == "owner_delete"
      assert changelog.meta == %{"user" => "owner2"}
    end

    test "returns error when user tries to remove yourself (when he is the last one)" do
      package = insert(:package)
      current_user = List.first(package.owners)

      assert {:error, :empty_owners} == Packages.delete_owner(package.name, current_user, current_user)
    end

    test "returns forbidden error when current_user is not in owners" do
      package = insert(:package)

      assert {:error, :forbidden} == Packages.delete_owner(package.name, "undefined", "new_owner")
    end

    test "returns error when package not found" do
      assert {:error, :not_found} == Packages.delete_owner("undefined", "undefined", "new_owner")
    end
  end

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
