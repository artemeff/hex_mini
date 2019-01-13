defmodule HexMini.Repo.Migrations.AddMetaToChangelog do
  use Ecto.Migration

  def change do
    alter table(:changelog) do
      add :meta, :map, default: "{}"
    end
  end
end
