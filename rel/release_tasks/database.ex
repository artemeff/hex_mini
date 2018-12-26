defmodule ReleaseTasks.Database do
  require Logger

  def run do
    start_applications([:logger, :telemetry, :ecto, :ecto_sql])
    prepare_repos(ecto_repos())
    :init.stop()
  end

  defp ecto_repos do
    Application.get_env(:hex_mini, :ecto_repos, [])
  end

  defp start_applications(apps) do
    Enum.each(apps, fn app ->
      {:ok, _} = Application.ensure_all_started(app)
    end)
  end

  defp prepare_repos(repos) do
    Enum.each(repos, fn(repo) ->
      {:ok, _apps} = repo.__adapter__.ensure_all_started(repo, :temporary)

      case repo.start_link(repo.config) do
        {:ok, _pid} -> storage_up(repo)
        {:error, {:already_started, _pid}} -> storage_up(repo)
        error -> halt(1, error)
      end
    end)
  end

  defp storage_up(repo, tries \\ 0)
  defp storage_up(_repo, 10) do
    halt(1, "storage_up reached max tries")
  end
  defp storage_up(repo, tries) do
    case repo.__adapter__.storage_up(repo.config) do
      :ok ->
        migrate_repo(repo)
      {:error, :already_up} ->
        migrate_repo(repo)
      {:error, reason} ->
        Logger.error("storage up error #{inspect reason}")
        :timer.sleep(2000)
        storage_up(repo, tries + 1)
    end
  end

  defp migrate_repo(repo, tries \\ 0)
  defp migrate_repo(_repo, 20) do
    halt(1, "migrate_repo reached max tries")
  end
  defp migrate_repo(repo, tries) do
    Ecto.Migrator.run(repo, migrations_path(repo), :up, all: true)
  rescue
    exception ->
      Logger.error("migrate repo error #{inspect exception}")
      :timer.sleep(2000)
      migrate_repo(repo, tries + 1)
  end

  defp halt(status, reason) do
    Logger.error(inspect(reason))
    :init.stop(status)
  end

  defp migrations_path(repo) do
    Application.app_dir(repo.config[:otp_app],
      "priv/#{repo |> Module.split |> List.last |> Macro.underscore}/migrations")
  end
end
