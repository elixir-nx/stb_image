defmodule StbImage.Nif do
  @moduledoc false

  @on_load :load_nif
  def load_nif do
    nif_file = '#{:code.priv_dir(:stb_image)}/stb_image_nif'

    case :erlang.load_nif(nif_file, 0) do
      :ok -> :ok
      {:error, {:reload, _}} -> :ok
      {:error, reason} -> IO.puts("Failed to load nif: #{reason}")
    end
  end

  def from_file(_filename, _desired_channels, _type), do: :erlang.nif_error(:not_loaded)
  def from_memory(_buffer, _desired_channels, _type), do: :erlang.nif_error(:not_loaded)
  def gif_from_memory(_gif_filename), do: :erlang.nif_error(:not_loaded)
  def to_file(_filename, _extension, _data, _width, _height, _channels), do: :erlang.nif_error(:not_loaded)
  def to_memory(_extension, _data, _width, _height, _channels), do: :erlang.nif_error(:not_loaded)
end
