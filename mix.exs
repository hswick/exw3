defmodule ExW3.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_w3,
      version: "0.6.1",
      elixir: "~> 1.10",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "ex_w3",
      source_url: "https://github.com/Metalink-App/ex_w3",
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
      {:ethereumex, "~> 0.7.0"},
      {:ex_keccak, "~> 0.2"},
      {:ex_abi, "~> 0.5.5"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:jason, "~> 1.2"}
    ]
  end

  defp description do
    "A high level Ethereum JSON RPC Client for Elixir"
  end

  defp package do
    [
      name: "ex_w3",
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["William Leong"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/Metalink-App/ex_w3"}
    ]
  end
end
