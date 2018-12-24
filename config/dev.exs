use Mix.Config

config :hex_mini,
  credentials: [{"admin", "ADMIN_KEY"}],
  public_key: File.read!("priv/keys/public_key.pem"),
  private_key: File.read!("priv/keys/private_key.pem")
