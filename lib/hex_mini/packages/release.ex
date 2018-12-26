defmodule HexMini.Packages.Release do
  use Ecto.Schema

  schema "releases" do
    belongs_to :package, HexMini.Packages.Package

    has_many :requirements, HexMini.Packages.Requirement

    field :owner, :string

    field :app, :string
    field :version, :string
    field :checksum, :binary
    field :description, :string
    field :files, {:array, :string}
    field :licenses, {:array, :string}
    field :build_tools, {:array, :string}

    field :elixir, :string, default: nil
    field :maintainers, {:array, :string}, default: []
    field :links, {:map, :string}, default: %{}
    field :extra, :map, default: %{}

    timestamps()
  end
end
