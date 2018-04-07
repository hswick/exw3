defmodule ExW3.Mixfile do
  use Mix.Project

  def project do
    [app: :exw3,
     version: "0.0.1",
     elixir: "~> 1.1-dev",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :ethereumex]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:ethereumex, "~> 0.3.2"},
      {:abi, "~> 0.1.8"},
      {:poison, "~> 3.1"},
      {:hexate,  ">= 0.6.0"}
    ]
  end
end
