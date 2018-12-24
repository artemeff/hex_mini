defmodule HexMini.Repo.Migrations.CreateReleases do
  use Ecto.Migration

  def change do
    create table(:releases) do
      add :package_id, references("packages")

      add :owner, :string
      add :version, :string
      add :checksum, :binary

      timestamps()
    end

    create index(:releases, [:package_id])
    create unique_index(:releases, [:package_id, :version])
  end
end
