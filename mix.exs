defmodule Pngex.MixProject do
  use Mix.Project

  def project do
    [
      app: :pngex,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme"
    ]
  end
end
