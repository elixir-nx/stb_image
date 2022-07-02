defmodule StbImage.Nif do
  @moduledoc false

  version = Mix.Project.config()[:version]
  use FennecPrecompile,
    otp_app: :stb_image,
    force_build: false,
    base_url: "https://github.com/elixir-nx/stb_image/releases/download/v#{version}",
    version: version,
    nif_filename: "stb_image_nif"

  def read_file(_path, _desired_channels),
    do: :erlang.nif_error(:not_loaded)

  def read_binary(_buffer, _desired_channels),
    do: :erlang.nif_error(:not_loaded)

  def read_gif_binary(_gif_path),
    do: :erlang.nif_error(:not_loaded)

  def write_file(_path, _format, _data, _height, _width, _channels),
    do: :erlang.nif_error(:not_loaded)

  def to_binary(_format, _data, _height, _width, _channels),
    do: :erlang.nif_error(:not_loaded)

  def resize(
        _input_pixels,
        _input_height,
        _input_width,
        _num_channels,
        _output_h,
        _output_w,
        _type
      ),
      do: :erlang.nif_error(:not_loaded)
end
