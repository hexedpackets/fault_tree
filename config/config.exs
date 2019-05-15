# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :trot, router: FaultTree.Router

config :logger, level: :debug

import_config "#{Mix.env()}.exs"
