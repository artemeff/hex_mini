defmodule HexMini.Repo.Migrations.CreatePackages do
  use Ecto.Migration

  def change do
    create table(:packages) do
      add :name, :string
      add :owners, {:array, :string}

      timestamps()
    end

    create unique_index(:packages, [:name])
  end
end
