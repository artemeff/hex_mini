defmodule HexMini.Packages.Release do
  use Ecto.Schema

  # TODO add more metadata https://github.com/hexpm/specifications/blob/master/package_metadata.md
  schema "releases" do
    belongs_to :package, HexMini.Packages.Package

    has_many :requirements, HexMini.Packages.Requirement

    field :owner, :string
    field :version, :string
    field :checksum, :binary

    timestamps()
  end
end
