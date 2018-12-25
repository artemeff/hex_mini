defmodule HexMini.Repo.Migrations.CreateRequirements do
  use Ecto.Migration

  def change do
    create table(:requirements) do
      add :release_id, references("releases")

      add :app, :string, null: false
      add :optional, :boolean, null: false
      add :repository, :string, null: false
      add :requirement, :string, null: false

      timestamps(updated_at: false)
    end

    create index(:requirements, [:release_id])
  end
end
