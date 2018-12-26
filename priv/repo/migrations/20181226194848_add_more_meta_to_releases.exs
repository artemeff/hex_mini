defmodule HexMini.Repo.Migrations.AddMoreMetaToReleases do
  use Ecto.Migration

  def change do
    alter table(:releases) do
      add :app, :string, null: false
      add :description, :text, null: false
      add :files, {:array, :string}, null: false
      add :licenses, {:array, :string}, null: false
      add :build_tools, {:array, :string}, null: false

      add :elixir, :string
      add :maintainers, {:array, :string}
      add :links, {:map, :string}
      add :extra, :map
    end
  end
end
