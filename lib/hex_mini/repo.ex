defmodule HexMini.Repo do
  use Ecto.Repo, otp_app: :hex_mini, adapter: Sqlite.Ecto2

  def init(_type, config) do
    {:ok, Keyword.put(config, :database, database_path(config))}
  end

  defp database_path(config) do
    case Keyword.fetch(config, :database_path) do
      {:ok, path} -> path
      :error -> Path.join([HexMini.priv_dir, "database", Keyword.fetch!(config, :database)])
    end
  end
end
