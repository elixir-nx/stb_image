defmodule ImgDecode.MixProject do
  use Mix.Project

  @github_url "https://github.com/cocoa-xu/stb_image"
  def project do
    [
      app: :stb_image,
      version: "0.1.2",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make] ++ Mix.compilers(),
      description: description(),
      package: package(),
      deps: deps(),
      source_url: @github_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description() do
    "A tiny Elixir library for image decoding task using stb_image as the backend."
  end

  defp deps do
    [
      {:elixir_make, "~> 0.6"},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      name: "stb_image",
      files: ~w(c_src lib .formatter.exs mix.exs README* LICENSE* Makefile 3rd_party/stb/stb_image.h),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @github_url}
    ]
  end
end
