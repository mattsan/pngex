defmodule Pngex.MixProject do
  use Mix.Project

  def project do
    [
      app: :pngex,
      version: "0.1.1",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      description: """
      A library for generating PNG images.
      """
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "README.md",
        "examples.livemd"
      ],
      main: "readme",
      groups_for_functions: [
        Guards: &(&1[:guard] == true)
      ]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{github: "https://github.com/mattsan/pngex"}
    ]
  end
end
