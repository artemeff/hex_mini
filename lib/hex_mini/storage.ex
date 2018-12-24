defmodule HexMini.Storage do
  alias HexMini.Packages.{Package, Release}

  def store(%Package{} = package, %Release{} = release, tarball) do
    tarball_dir = HexMini.packages_path([package.name])
    tarball_file = HexMini.packages_path([package.name, release.version])

    unless File.exists?(tarball_dir) && File.dir?(tarball_dir) do
      :ok = File.mkdir_p(tarball_dir)
    end

    File.write(tarball_file, tarball)
  end

  def fetch_path(name, version) do
    HexMini.packages_path([name, version])
  end
end
