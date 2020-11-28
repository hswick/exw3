defmodule ExW3.MixProject do
  use Mix.Project

  def project do
    [
      app: :exw3,
      version: "0.4.4",
      elixir: "~> 1.10",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "exw3",
      source_url: "https://github.com/hswick/exw3",
      dialyzer: [
        remove_defaults: [:unknown]
      ]
    ]
  end

  def application do
    [applications: [:logger, :ex_abi, :ethereumex]]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:ethereumex, "~> 0.6.4"},
      {:ex_keccak, "~> 0.1.2"},
      {:ex_abi, "~> 0.5.1"},
      {:dialyxir, "~> 1.0.0-rc.5", only: [:dev], runtime: false},
      {:jason, "~> 1.2"}
    ]
  end

  defp description do
    "A high level Ethereum JSON RPC Client for Elixir"
  end

  defp package do
    [
      name: "exw3",
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Harley Swick"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/hswick/exw3"}
    ]
  end
end
