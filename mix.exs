defmodule Download.Mixfile do
  use Mix.Project

  @project_url "https://github.com/asiniy/download"
  @version "0.0.2"

  def project do
    [
      app: :download,
      version: @version,
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      source_url: @project_url,
      homepage_url: @project_url,
      description: "Downloads remote file and stores it in the filesystem",
      package: package(),
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: elixirc_paths() ++ []
  defp elixirc_paths(_),     do: elixirc_paths()
  defp elixirc_paths,        do: ["lib"]

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [applications: [:httpoison]]
  end

  defp deps do
    [
      {:httpoison, ">= 0.9.0"},
      {:exvcr, "~> 0.8", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev},
    ]
  end

  defp package() do
    [
      name: :download,
      files: ["lib/**/*.ex", "mix.exs"],
      maintainers: ["Alex Antonov"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub"        => @project_url,
        "Author's blog" => "http://asiniy.github.io/"
      }
    ]
  end
end
