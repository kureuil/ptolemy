# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :tequila,
  ecto_repos: [Tequila.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :tequila, TequilaWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "SGZJ0hkMdugmDvjqOsnRTuuamqHppdo9PhAp7m6r6IiBqSWcch2sptmce5cFkHQf",
  render_errors: [view: TequilaWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Tequila.PubSub, adapter: Phoenix.PubSub.PG2]

# Add support for multiple locales in UI elements
config :tequila, TequilaWeb.Gettext, default_locale: "fr", locales: ~w(en fr)

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :tequila, :redis_url, System.get_env("REDIS_URL") || "redis://localhost:6379/0"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
