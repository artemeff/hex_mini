defmodule HexMini.Packages do
  alias HexMini.Repo
  alias HexMini.Storage
  alias HexMini.Packages.{Changelog, Package, Release, Requirement}

  import Ecto.Query
  import Ecto.Changeset

  def changelog do
    Repo.all(
      from(c in Changelog,
        preload: [:release, :package],
        order_by: [desc: c.inserted_at],
        limit: 100))
  end

  def fetch(name) do
    query =
      from(pkg in Package,
        left_join: rls in Release, on: pkg.id == rls.package_id,
        left_join: rmt in Requirement, on: rls.id == rmt.release_id,
        preload: [releases: {rls, requirements: rmt}],
        order_by: [asc: rls.inserted_at],
        where: pkg.name == ^name)

    case Repo.one(query) do
      %Package{} = package -> {:ok, package}
      nil -> {:error, :not_found}
    end
  end

  def owners(name) do
    with {:ok, package} <- fetch_package(name) do
      {:ok, package.owners}
    end
  end

  def add_owner(name, current_user, owner_to_add) do
    with {:ok, package} <- fetch_package_and_check_owners(name, current_user),
         owners = Enum.uniq([owner_to_add | package.owners]),
         {:ok, package} <- update_owners(package, owners),
         {:ok, _} <- changelog_add_owner(package, current_user, owner_to_add)
    do
      {:ok, package}
    end
  end

  def delete_owner(name, current_user, owner_to_delete) do
    with {:ok, package} <- fetch_package_and_check_owners(name, current_user),
         [_ | _] = owners <- List.delete(package.owners, owner_to_delete),
         {:ok, package} <- update_owners(package, owners),
         {:ok, _} <- changelog_delete_owner(package, current_user, owner_to_delete)
    do
      {:ok, package}
    else
      [] -> {:error, :empty_owners}
      {:error, reason} -> {:error, reason}
    end
  end

  defp update_owners(package, new_owners) do
    package
    |> cast(%{"owners" => new_owners}, [:owners])
    |> validate_required([:owners])
    |> Repo.update
  end

  def publish(%{checksum: checksum, contents: _, metadata: meta}, tarball, user) do
    in_transaction(fn ->
      with {:ok, action, %Package{} = package} <- fetch_or_create_package(meta, user),
           changeset = release_changeset(package, meta, checksum, user),
           {:ok, %Release{} = release} <- Repo.insert(changeset),
           :ok <- Storage.store(package, release, tarball),
           {:ok, _} <- changelog_publish(package, release, user)
      do
        {:ok, action, package, release}
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp fetch_or_create_package(%{"name" => name, "version" => version}, owner) do
    case fetch_package(name) do
      {:ok, %Package{} = package} ->
        if owner in package.owners do
          check_release_existence(package, version)
        else
          {:error, :forbidden}
        end

      {:error, :not_found} ->
        create_package(name, owner)
    end
  end

  defp check_release_existence(%Package{} = package, version) do
    case Repo.get_by(Release, package_id: package.id, version: version) do
      %Release{} -> {:error, :already_released}
      nil -> {:ok, :update, package}
    end
  end

  defp create_package(name, owner) do
    changeset =
      %Package{}
      |> cast(%{"name" => name, "owners" => [owner]}, [:name, :owners])
      |> validate_required([:name, :owners])

    case Repo.insert(changeset) do
      {:ok, package} -> {:ok, :create, package}
      {:error, reason} -> {:error, reason}
    end
  end

  defp release_changeset(%Package{id: id}, metadata, checksum, user) do
    params = Map.merge(metadata, %{"package_id" => id, "checksum" => checksum, "owner" => user})

    %Release{}
    |> cast(params, [:package_id, :owner, :app, :version, :checksum, :description, :files,
                     :licenses, :build_tools, :elixir, :maintainers, :links, :extra])
    |> cast_assoc(:requirements, with: &requirement_changeset/2)
    |> validate_required([:package_id, :owner, :app, :version, :checksum, :description, :files,
                          :licenses, :build_tools])
  end

  defp requirement_changeset(%Requirement{} = requirement, params) do
    requirement
    |> cast(params, [:app, :requirement, :repository, :optional])
    |> validate_required([:app, :requirement, :repository, :optional])
  end

  defp changelog_publish(package, release, user) do
    Repo.insert(changelog_changeset("publish", package, user, release.id))
  end

  defp changelog_add_owner(package, user, new_owner) do
    Repo.insert(changelog_changeset("owner_add", package, user, nil, %{user: new_owner}))
  end

  defp changelog_delete_owner(package, user, deleted_owner) do
    Repo.insert(changelog_changeset("owner_delete", package, user, nil, %{user: deleted_owner}))
  end

  defp changelog_changeset(action, %Package{} = package, user, release_id, meta \\ %{}) do
    params = %{package_id: package.id, release_id: release_id,
               user: user, action: action, meta: meta}

    %Changelog{}
    |> cast(params, [:package_id, :release_id, :user, :action, :meta])
    |> validate_required([:package_id, :user, :action, :meta])
    |> validate_inclusion(:action, ["publish", "owner_add", "owner_delete"])
  end

  defp fetch_package(name) do
    case Repo.get_by(Package, name: name) do
      %Package{} = package -> {:ok, package}
      nil -> {:error, :not_found}
    end
  end

  defp fetch_package_and_check_owners(name, user) do
    with {:ok, %Package{} = package} <- fetch_package(name) do
      if user in package.owners do
        {:ok, package}
      else
        {:error, :forbidden}
      end
    end
  end

  defp in_transaction(fun) do
    case Repo.transaction(fun) do
      {:ok, result} -> result
      {:error, reason} -> {:error, reason}
    end
  end
end
