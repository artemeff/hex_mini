defmodule HexMini.Repo.Migrations.CreateRequirements do
  use Ecto.Migration

  def change do
    create table(:requirements) do
      add :release_id, references("releases")

      add :app, :string
      add :optional, :boolean
      add :repository, :string
      add :requirement, :string

      timestamps(updated_at: false)
    end

    create index(:requirements, [:release_id])
  end
end
