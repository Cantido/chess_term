defmodule ChessTerm.MixProject do
  use Mix.Project

  def project do
    [
      app: :chess_term,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ChessTerm.Application, []}
    ]
  end

  defp deps do
    [
      {:lichess_elixir, path: "../lichess_elixir"},
      {:ratatouille, "~> 0.5.0"}
    ]
  end
end
