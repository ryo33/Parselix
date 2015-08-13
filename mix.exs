defmodule Parselix.Mixfile do
  use Mix.Project

  def project do
    [app: :parselix,
     name: "Parselix",
     source_url: "https://github.com/ryo33/Parselix",
     version: "0.1.0",
     description: "A Parser Combinator Library",
     package: [
       contributors: ["ryo33"],
       licenses: ["MIT"],
       links: %{
         "GitHub" => "https://github.com/ma2gedev/hex_sample",
         "Document" => "http://hexdocs.pm/parselix/0.1.0/"
       }
     ],
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
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
    [{:earmark, "~> 0.1.17", only: :dev},
     {:ex_doc, "~> 0.8.1", only: :dev}]
  end
end
