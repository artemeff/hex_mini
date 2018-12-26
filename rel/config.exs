use Mix.Releases.Config,
    default_release: :default,
    default_environment: Mix.env

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :hex_mini
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :hex_mini
  set vm_args: "rel/vm.args"

  set config_providers: [
    {Mix.Releases.Config.Providers.Elixir, ["${RELEASE_ROOT_DIR}/etc/config.exs"]}
  ]

  set overlays: [
    {:copy, "config/release.exs", "etc/config.exs"}
  ]
end

release :hex_mini do
  set version: current_version(:hex_mini)
  set pre_start_hooks: "rel/hooks/pre_start"
  set applications: [
    :runtime_tools
  ]
end
