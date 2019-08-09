defmodule GCM.Mixfile do
  use Mix.Project

  @description """
  GCM library to send pushes through GCM
  """

  def project do
    [app: :gcm,
     version: "1.5.1",
     elixir: "~> 1.2",
     name: "GCM",
     description: @description,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package(),
     docs: [main: "GCM", readme: "README.md",
            source_url: "https://github.com/carnivalmobile/gcm"]]
  end

  def application do
    [applications: [:httpoison]]
  end

  defp deps do
    [{ :httpoison, "~> 1.0" },
     { :poison, "~> 3.1" },
     { :meck, "~> 0.8", only: :test},
     { :earmark, "~> 1.0", only: :dev },
     { :ex_doc, "~> 0.13", only: :dev }]
  end

  defp package do
    [ maintainers: ["Eduardo Gurgel Pinho"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/carnivalmobile/gcm"} ]
  end
end
