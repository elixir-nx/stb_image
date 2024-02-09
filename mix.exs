defmodule StbImage.MixProject do
  use Mix.Project

  @version "0.6.5"
  @github_url "https://github.com/elixir-nx/stb_image"

  def project do
    [
      app: :stb_image,
      version: @version,
      elixir: "~> 1.12",
      deps: deps(),
      name: "StbImage",
      description: "A tiny image reader/writer library using stb_image as the backend",
      docs: docs(),
      package: package(),
      make_executable: make_executable(),
      make_makefile: make_makefile(),
      compilers: [:elixir_make] ++ Mix.compilers(),
      make_precompiler: {:nif, CCPrecompiler},
      make_precompiler_url: "#{@github_url}/releases/download/v#{@version}/@{artefact_filename}",
      make_precompiler_filename: "stb_image_nif",
      make_precompiler_nif_versions: [versions: ["2.16", "2.17"]]
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
      {:cc_precompiler, "~> 0.1.0"},
      {:elixir_make, "~> 0.7.0"},
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

  defp package() do
    [
      name: "stb_image",
      files: ~w(3rd_party/stb c_src lib mix.exs README* LICENSE* Makefile checksum.exs),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @github_url}
    ]
  end

  defp make_executable() do
    case :os.type() do
      {:win32, _} -> "nmake"
      _ -> "make"
    end
  end

  defp make_makefile() do
    case :os.type() do
      {:win32, _} -> "Makefile.win"
      _ -> "Makefile"
    end
  end
end
