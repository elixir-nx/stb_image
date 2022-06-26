defmodule StbImage.PrecompiledDeploy do
  require Logger

  def app_priv do
    "#{Mix.Project.app_path(Mix.Project.config())}/priv"
  end

  def deploy, do: download(System.get_env("STB_IMAGE_PRECOMPILED_TRIPLET", nil))

  defp download(triplet) when is_binary(triplet) do
    filename = "stb_image-#{triplet}-v#{StbImage.MixProject.version}"
    url = "#{StbImage.MixProject.github_url}/releases/download/v#{StbImage.MixProject.version}/#{filename}.zip"

    stb_image_nif_so = Path.join([app_priv(), "stb_image_nif.so"])

    with {:stb_image_so_exists, false} <- {:stb_image_so_exists, File.exists?(stb_image_nif_so)},
         {:download_artefacts, {:ok, zip_data}} <- {:download_artefacts, download_artefact(url)},
         {:unzip, {:ok, _}} <- {:unzip, :zip.unzip(zip_data, [{:cwd, String.to_charlist(app_priv())}])} do
          :ok
    else
      {:stb_image_so_exists, true} -> :ok
      {:download_artefacts, {:ssl_status, status}} ->
        Logger.error("Failed to start ssl: #{inspect(status)}")
      {:download_artefacts, {:inet_status, status}} ->
        Logger.error("Failed to start inet: #{inspect(status)}")
      {:download_artefacts, status} ->
        Logger.error("Failed to download artefact from #{url}: #{inspect(status)}")
      {:unzip, status} ->
        Logger.error("Failed to unzip downloaded artefact: #{inspect(status)}")
    end
  end

  defp download(nil) do
    Logger.error("cannot fetch environment variable STB_IMAGE_PRECOMPILED_TRIPLET. Corrupted install?")
  end

  defp download_artefact(url) do
    Logger.info("Downloading artefact from #{url}")

    http_opts = []
    opts = [body_format: :binary]
    arg = {url, []}

    with {:ssl_status, :ok} <- {:ssl_status, :ssl.start()},
         {:inet_status, :ok} <- {:inet_status, case :inets.start() do
          :ok -> :ok
          {:error, {:already_started, :inets}} -> :ok
          status -> status
        end} do
          case :httpc.request(:get, arg, http_opts, opts) do
            {:ok, {{_, 200, _}, _, body}} ->
              {:ok, body}

            status -> status
          end
    else
      status -> status
    end
  end
end

StbImage.PrecompiledDeploy.deploy()
