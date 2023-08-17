defmodule VintageNetSocketCan.MixProject do
  use Mix.Project

  def project do
    [
      app: :vintage_net_socket_can,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:muontrap, "~> 1.3.2"}
    ]
  end
end
