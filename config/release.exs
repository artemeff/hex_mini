use Mix.Config
use HexMini.Config

config :hex_mini,
  public_key: Config.ensure_public_key!(env!("HM_PUBLIC_KEY")),
  private_key: Config.ensure_private_key!(env!("HM_PRIVATE_KEY")),
  data_path: Config.ensure_path!(env("HM_DATA_PATH", "/var/lib/hex_mini")),
  credentials: Config.transform_credentials!(env_file!("HM_CREDENTIALS_FILE"))

config :hex_mini, HexMini.Repo,
  database: env("POSTGRES_DATABASE", "hex_mini_prod"),
  hostname: env("POSTGRES_HOSTNAME", "postgres"),
  username: env("POSTGRES_USERNAME", "postgres"),
  password: env("POSTGRES_PASSWORD", "")
