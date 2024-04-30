defmodule VintageNetSocketCAN.MixProject do
  use Mix.Project

  def project do
    [
      app: :vintage_net_socket_can,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "VintageNetSocketCAN",
      source_url: "https://github.com/gworkman/vintage_net_socket_can",
      docs: [
        main: "VintageNetSocketCAN"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:vintage_net, "~> 0.11"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
