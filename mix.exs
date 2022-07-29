defmodule StbImage.MixProject do
  use Mix.Project

  @version "0.5.2"
  @github_url "https://github.com/elixir-nx/stb_image"

  def project do
    [
      app: :stb_image,
      version: @version,
      elixir: "~> 1.12",
      compilers: [:elixir_make] ++ Mix.compilers(),
      deps: deps(),
      name: "StbImage",
      description: "A tiny image reader/writer library using stb_image as the backend",
      docs: docs(),
      package: package(),
      make_makefile: make_makefile()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:elixir_make, "~> 0.6"},
      {:nx, "~> 0.1", optional: true},
      {:ex_doc, "~> 0.23", only: :docs, runtime: false}
    ]
  end

  defp docs do
    [
      main: "StbImage",
      source_ref: "v#{@version}",
      source_url: @github_url
    ]
  end

  defp package() do
    [
      name: "stb_image",
      files: ~w(3rd_party/stb c_src lib mix.exs README* LICENSE* Makefile),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @github_url}
    ]
  end

  defp make_makefile() do
    case :os.type() do
      {:win32, _} -> 
        cond do
          System.find_executable("nmake") -> "Makefile.win"
          System.find_executable("make") -> "Makefile.mingw"
          true -> "Makefile.win"
        end
      _ -> "Makefile"
    end
  end
end
