defmodule ImgDecode.MixProject do
  use Mix.Project

  def project do
    [
      app: :img_decode,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make] ++ Mix.compilers(),
      description: description(),
      package: package(),
      deps: deps(),
      source_url: "https://github.com/cocoa-xu/img_decode"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description() do
    "A tiny Elixir library for image decoding task."
  end

  defp deps do
    [
      {:elixir_make, "~> 0.6"},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      name: "img_decode",
      files: ~w(c_src lib .formatter.exs mix.exs README* LICENSE* Makefile CMakeLists.txt),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/cocoa-xu/img_decode"}
    ]
  end
end
