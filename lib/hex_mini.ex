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
    case Application.fetch_env(:hex_mini, :packages_path) do
      {:ok, value} ->
        value

      :error ->
        Path.join(priv_dir(), "packages")
    end
  end

  def packages_path(file) do
    Path.join([packages_path() | List.wrap(file)])
  end

  def priv_dir do
    :code.priv_dir(:hex_mini)
  end
end
