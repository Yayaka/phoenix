use Mix.Config

config :web, Web.Endpoint,
  on_init: {Web.Endpoint, :load_from_system_env, []},
  url: [host: System.get_env("HOST"), port: 80],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  cache_static_manifest: "priv/static/cache_manifest.json"
