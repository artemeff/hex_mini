defmodule HexMini.Packages.Requirement do
  use Ecto.Schema

  schema "requirements" do
    belongs_to :release, HexMini.Packages.Release

    field :app, :string
    field :optional, :boolean
    field :repository, :string
    field :requirement, :string

    timestamps(updated_at: false)
  end
end
