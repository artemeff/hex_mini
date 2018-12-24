defmodule HexMini.Repo.Migrations.CreateChangelog do
  use Ecto.Migration

  def change do
    create table(:changelog) do
      add :user, :string
      add :action, :string

      add :package_id, references("packages")
      add :release_id, references("releases")

      timestamps(updated_at: false)
    end
  end
end
