use Mix.Config

config :hex_mini,
  server: false,
  credentials: [{"ann@local", "ANN_KEY"}, {"bob@local", "BOB_KEY"}],
  public_key: File.read!("priv/keys/public_key.pem"),
  private_key: File.read!("priv/keys/private_key.pem")

config :hex_mini, HexMini.Repo,
  pool: Ecto.Adapters.SQL.Sandbox

config :logger,
  level: :warn
