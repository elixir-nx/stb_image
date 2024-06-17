defmodule StbImage.MixProject do
  use Mix.Project

  @app :stb_image
  @version "0.6.10-dev"
  @github_url "https://github.com/elixir-nx/stb_image"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.13",
      deps: deps(),
      name: "StbImage",
      description: "A tiny image reader/writer library using stb_image as the backend",
      docs: docs(),
      package: package(),
      compilers: [:elixir_make] ++ Mix.compilers(),
      make_precompiler: {:nif, CCPrecompiler},
      make_precompiler_url: "#{@github_url}/releases/download/v#{@version}/@{artefact_filename}",
      make_precompiler_filename: "stb_image_nif",
      make_precompiler_nif_versions: [versions: ["2.16"]]
    ]
  end

  def application do
    [
      env: [
        kino_render_encoding: :png,
        kino_render_max_size: {8192, 8192},
        kino_render_tab_order: [:image, :raw]
      ],
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # compilation
      {:cc_precompiler, "~> 0.1"},
      {:elixir_make, "~> 0.8"},
      # optional
      {:nx, "~> 0.4", optional: true},
      {:kino, "~> 0.7", optional: true},
      # docs
      {:ex_doc, "~> 0.29", only: :docs, runtime: false}
    ]
  end

  defp docs do
    [
      main: "StbImage",
      source_ref: "v#{@version}",
      source_url: @github_url
    ]
  end

  defp package do
    [
      name: "stb_image",
      files:
        ~w(3rd_party/stb c_src lib mix.exs README* LICENSE* Makefile Makefile.win checksum.exs),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @github_url}
    ]
  end
end
