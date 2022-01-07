defmodule ImgDecode.Nif do
  @moduledoc false

  @on_load :load_nif
  def load_nif do
    nif_file = '#{:code.priv_dir(:img_decode)}/imgdecode'

    case :erlang.load_nif(nif_file, 0) do
      :ok -> :ok
      {:error, {:reload, _}} -> :ok
      {:error, reason} -> IO.puts("Failed to load nif: #{reason}")
    end
  end

  def from_file(_filename, _desired_channels, _type), do: :erlang.nif_error(:not_loaded)
  def from_memory(_buffer, _desired_channels, _type), do: :erlang.nif_error(:not_loaded)
end
