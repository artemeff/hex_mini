defmodule HexMini.Repo.Migrations.CreateChangelog do
  use Ecto.Migration

  def change do
    create table(:changelog) do
      add :package_id, references("packages")
      add :release_id, references("releases")

      add :user, :string, null: false
      add :action, :string, null: false

      timestamps(updated_at: false)
    end
  end
end
