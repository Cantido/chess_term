import Config

config :logger,
  backends: [{LoggerFileBackend, :debug_log}]

config :logger, :debug_log,
  path: "tmp/debug.log",
  level: :debug
