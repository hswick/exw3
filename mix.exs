defmodule ExW3.MixProject do
  use Mix.Project

  @source_url "https://github.com/hswick/exw3"
  @version "0.6.1"

  def project do
    [
      app: :exw3,
      version: @version,
      elixir: "~> 1.10",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      name: "exw3",
      dialyzer: [
        remove_defaults: [:unknown]
      ],
      preferred_cli_env: [
        docs: :docs,
        "hex.publish": :docs
      ]
    ]
  end

  def application do
    [applications: [:logger, :ex_abi, :ethereumex]]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :docs, runtime: false},
      {:ethereumex, "~> 0.7.0"},
      {:ex_keccak, "~> 0.2"},
      {:ex_abi, "~> 0.5.4"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:jason, "~> 1.2"}
    ]
  end

  defp package do
    [
      name: "exw3",
      description: "A high level Ethereum JSON RPC Client for Elixir",
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Harley Swick"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      extras: [
        LICENSE: [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      assets: "assets",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end
end
