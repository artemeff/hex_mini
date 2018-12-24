use Mix.Config
use HexMini.Config

config :hex_mini,
  public_key: public_key_env("PUBLIC_KEY"),
  private_key: public_key_env("PRIVATE_KEY"),
  # TODO rename to something like LIBRARY_PATH, DATA_PATH
  # TODO do not use packages_path, use data_path and append `packages`
  packages_path: path_env("PACKAGES_PATH", "/var/lib/hex_mini/packages"),
  credentials: credentials_env("CREDENTIALS_PATH")
