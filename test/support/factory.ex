defmodule HexMini.Factory do
  use ExMachina.Ecto, repo: HexMini.Repo

  def package_factory do
    %HexMini.Packages.Package{
      owners: ["john@doe"], name: "test_package",
      releases: [build(:release)]
    }
  end

  def release_factory do
    %HexMini.Packages.Release{
      version: "1.0.0", checksum: checksum(),
      requirements: [build(:requirement)]
    }
  end

  def requirement_factory do
    %HexMini.Packages.Requirement{
      app: "test_package_1", optional: false, repository: "hexpm", requirement: "~> 1.0 or ~> 2.0"
    }
  end

  def changelog_factory do
    %HexMini.Packages.Changelog{
      user: "john@doe", action: "publish"
    }
  end

  def publish_package_factory do
    %{
      checksum: checksum(),
      contents: [],
      metadata: publish_metadata_factory()
    }
  end

  def publish_metadata_factory do
    name = sequence(:publish_package_name_sequence, &("test_#{&1}"))

    %{
      "app" => name,
      "build_tools" => ["mix"],
      "description" => "Test Package",
      "elixir" => "~> 1.7",
      "files" => [],
      "licenses" => ["MIT"],
      "links" => %{},
      "name" => name,
      "version" => "1.0.0",
      "requirements" => %{
        "test_dependency_1" => %{
          "app" => "test_dependency_1",
          "optional" => false,
          "repository" => "hexpm",
          "requirement" => "~> 1.0 or ~> 2.0"
        },
        "test_dependency_2" => %{
          "app" => "test_dependency_2",
          "optional" => true,
          "repository" => "private",
          "requirement" => "~> 1.0"
        },
      }
    }
  end

  defp checksum do
    <<229, 10, 203, 121, 24, 176, 82, 45, 143, 83, 106, 237, 117, 206, 30, 52,
      237, 16, 160, 112, 196, 210, 131, 233, 46, 78, 193, 4, 61, 197, 36, 188>>
  end
end
