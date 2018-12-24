defmodule HexMini.Packages.Changelog do
  use Ecto.Schema

  schema "changelog" do
    belongs_to :package, HexMini.Packages.Package
    belongs_to :release, HexMini.Packages.Release

    field :user, :string
    field :action, :string

    timestamps(updated_at: false)
  end
end
