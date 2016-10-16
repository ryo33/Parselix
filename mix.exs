defmodule Parselix.Mixfile do
  use Mix.Project

  def project do
    [app: :parselix,
     name: "Parselix",
     source_url: "https://github.com/ryo33/Parselix",
     version: "0.1.2",
     description: "A Parser Combinator Library",
     package: [
       contributors: ["ryo33"],
       licenses: ["MIT"],
       links: %{
         "GitHub" => "https://github.com/ryo33/Parselix",
       }
     ],
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:ex_doc, "~> 0.14", only: :dev}]
  end
end
