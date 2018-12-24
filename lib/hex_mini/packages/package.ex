defmodule HexMini.Packages.Package do
  use Ecto.Schema

  schema "packages" do
    has_many :releases, HexMini.Packages.Release

    field :owners, {:array, :string}
    field :name, :string

    timestamps()
  end
end
