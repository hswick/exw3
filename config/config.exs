# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :ethereumex,
  client_type: :ipc,
  url: "http://localhost:8545",
  ipc_path:
    System.get_env(
      "IPC_PATH",
      "#{System.user_home!()}/.local/share/io.parity.ethereum/jsonrpc.ipc"
    )

# Include environment specific configurations
# e.g Include test.exs for test environment
import_config "#{Mix.env()}.exs"
