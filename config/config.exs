use Mix.Config

config :hex_mini,
  server: true,
  ecto_repos: [HexMini.Repo]

config :hex_mini, HexMini.Repo,
  database: "hex_mini_#{Mix.env}",
  hostname: "localhost",
  username: "postgres",
  password: "postgres"

config :logger,
  level: :debug

config :logger, :console,
  metadata: [:request_id]

import_config "#{Mix.env}.exs"
