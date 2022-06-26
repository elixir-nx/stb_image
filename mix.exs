defmodule StbImage.MixProject do
  use Mix.Project

  @version "0.5.3"
  @github_url "https://github.com/elixir-nx/stb_image"

  def project do
    [
      app: :stb_image,
      version: version(),
      elixir: "~> 1.12",
      compilers: compilers(precompile_artefacts_available?()) ++ Mix.compilers(),
      deps: deps(),
      name: "StbImage",
      description: "A tiny image reader/writer library using stb_image as the backend",
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def version, do: @version
  def github_url, do: @github_url

  defp deps do
    [
      {:elixir_make, "~> 0.6"},
      {:elixir_precompiled_deployer, "~> 0.1.0", runtime: false},
      {:nx, "~> 0.1", optional: true},
      {:ex_doc, "~> 0.23", only: :docs, runtime: false}
    ]
  end

  defp docs do
    [
      main: "StbImage",
      source_ref: "v#{@version}",
      source_url: github_url()
    ]
  end

  defp package() do
    [
      name: "stb_image",
      files: ~w(3rd_party/stb c_src lib mix.exs README* LICENSE* Makefile),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => github_url()}
    ]
  end

  defp compilers({true, triplet}) do
    System.put_env("STB_IMAGE_PRECOMPILED_TRIPLET", triplet)

    [
      :elixir_precompiled_deployer
    ]
  end

  defp compilers(false) do
    [
      :elixir_make
    ]
  end

  @triplet_detection [
    :stb_image_host,
    {:env, "TARGET_ARCH", "TARGET_OS", "TARGET_ABI"},
    :uname
  ]
  @precompiled_artefacts [
    "x86_64-linux-gnu",
    "aarch64-linux-gnu",
    "arm-linux-gnueabihf",
    "riscv64-linux-gnu",
    "s390x-linux-gnu",
    "powerpc64le-linux-gnu",
    "x86_64-apple-darwin",
    "arm64-apple-darwin"
  ]
  @prefer_precompiled_by_default "YES"
  defp precompile_artefacts_available?() do
    precompiled_artefacts_available?(
      System.get_env("STB_IMAGE_PREFER_PRECOMPILED", @prefer_precompiled_by_default)
    )
  end

  defp precompiled_artefacts_available?("YES") do
    if System.tmp_dir() == nil do
      false
    else
      case guess_triplet(@triplet_detection) do
        nil ->
          false

        triplet when triplet in @precompiled_artefacts ->
          {true, triplet}

        _ ->
          false
      end
    end
  end

  defp precompiled_artefacts_available?("NO"), do: false

  defp guess_triplet([:stb_image_host | other]) do
    case System.get_env("STB_IMAGE_HOST") do
      nil -> guess_triplet(other)
      triplet -> triplet
    end
  end

  defp guess_triplet([{:env, arch_var, os_var, abi_var} | other]) do
    arch = System.get_env(arch_var)
    os = System.get_env(os_var)
    abi = System.get_env(abi_var)

    case {arch, os, abi} do
      {nil, _, _} -> guess_triplet(other)
      {_, nil, _} -> guess_triplet(other)
      {_, _, nil} -> guess_triplet(other)
      {_, _, _} -> "#{arch}-#{os}-#{abi}"
    end
  end

  defp guess_triplet([:uname | other]) do
    if System.find_executable("uname") != nil do
      with {arch, 0} <- System.cmd("uname", ["-m"]),
           [arch | _] <- String.split(arch, "\n") do
        case :os.type() do
          {:unix, :darwin} ->
            "#{arch}-apple-darwin"

          {:unix, :linux} ->
            case arch do
              "ppc64le" -> "powerpc64le-linux-gnu"
              "arm" -> "#{arch}-linux-gnueabihf"
              _ -> "#{arch}-linux-gnu"
            end

          _ ->
            guess_triplet(other)
        end
      else
        _ -> guess_triplet(other)
      end
    else
      guess_triplet(other)
    end
  end

  defp guess_triplet([]), do: nil
end
