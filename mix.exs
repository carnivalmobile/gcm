defmodule GCM.Mixfile do
  use Mix.Project

  @description """
  GCM library to send pushes through GCM
  """

  def project do
    [app: :gcm,
     version: "1.3.0",
     elixir: "~> 1.0",
     name: "GCM",
     description: @description,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     package: package,
     docs: [main: "GCM", readme: "README.md",
            source_url: "https://github.com/carnivalmobile/gcm"]]
  end

  def application do
    [applications: [:httpoison]]
  end

  defp deps do
    [{ :httpoison, "~> 0.7" },
     { :poison, "~> 1.5 or ~> 2.0" },
     { :meck, "~> 0.8", only: :test},
     { :earmark, "~> 0.1.17", only: :docs },
     { :ex_doc, "~> 0.8.0", only: :docs }]
  end

  defp package do
    [ maintainers: ["Eduardo Gurgel Pinho"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/carnivalmobile/gcm"} ]
  end
end
