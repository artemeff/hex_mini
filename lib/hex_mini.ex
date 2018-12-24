defmodule HexMini do
  def start_endpoint? do
    Application.get_env(:hex_mini, :server, true)
  end

  def credentials do
    Application.get_env(:hex_mini, :credentials, [])
  end

  def public_key do
    Application.get_env(:hex_mini, :public_key)
  end

  def private_key do
    Application.get_env(:hex_mini, :private_key)
  end

  def packages_path do
    Path.join(data_dir(), "packages")
  end

  def packages_path(file) do
    Path.join([packages_path() | List.wrap(file)])
  end

  def data_dir do
    case Application.fetch_env(:hex_mini, :data_path) do
      {:ok, path} -> path
      :error -> :code.priv_dir(:hex_mini)
    end
  end
end
