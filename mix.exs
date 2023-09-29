defmodule UeberauthDcapi.MixProject do
  use Mix.Project

  def project do
    [
      app: :ueberauth_dcapi,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      test_coverage: [tool: ExCoveralls],
      elixirc_paths: elixirc_paths(Mix.env())
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
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:earmark, "~> 1.4", only: [:dev, :docs]},
      {:ex_doc, "~> 0.30", only: [:dev, :docs]},
      {:excoveralls, "~> 0.17", only: :test},
      {:jason, "~> 1.0"},
      {:req, "~> 0.4"},
      {:ueberauth, "~> 0.10"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
