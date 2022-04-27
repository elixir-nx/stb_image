defmodule StbImage do
  @moduledoc """
  Tiny image encoding and decoding.

  The following formats are supported:

    * JPEG baseline & progressive (12 bpc/arithmetic not supported, same as stock IJG lib)
    * PNG 1/2/4/8/16-bit-per-channel
    * TGA
    * BMP non-1bpp, non-RLE
    * PSD (composited view only, no extra channels, 8/16 bit-per-channel)
    * GIF (always reports as 4-channel)
    * HDR (radiance rgbE format)
    * PIC (Softimage PIC)
    * PNM (PPM and PGM binary only)

  There are also specific functions for working with GIFs.
  """

  defguardp is_path(path) when is_binary(path) or is_list(path)

  @doc """
  Decodes image from file at `path`.

  ## Options

    * `:channels` - The number of desired channels.
      Use `0` for auto-detection. Defaults to 0.

    * `:type` - The type of the data. Defaults to `:u8`.
      Must be one of `:u8`, `:u16`, `:f32`.

  ## Example

      {:ok, img, shape, type, channels} = StbImage.from_file("/path/to/image")
      {h, w, c} = shape

      # If you know the image is a 4-channel image and auto-detection failed
      {:ok, img, shape, type, channels} = StbImage.from_file("/path/to/image", channels: 4)
      {h, w, c} = shape

  """
  def from_file(path, opts \\ []) when is_path(path) and is_list(opts) do
    type = opts[:type] || :u8
    channels = opts[:channels] || 0
    StbImage.Nif.from_file(path_to_charlist(path), channels, type)
  end

  @doc """
  Decodes image from `binary`.

  ## Options

    * `:channels` - The number of desired channels.
      Use `0` for auto-detection. Defaults to 0.

    * `:type` - The type of the data. Defaults to `:u8`.
      Must be one of `:u8`, `:u16`, `:f32`.

  ## Example

      {:ok, buffer} = File.read("/path/to/image")
      {:ok, img, shape, type, channels} = StbImage.from_binary(buffer)
      {h, w, c} = shape

      # If you know the image is a 4-channel image and auto-detection failed
      {:ok, img, shape, type, channels} = StbImage.from_file("/path/to/image", channels: 4)
      {h, w, c} = shape

  """
  def from_binary(buffer, opts \\ []) when is_binary(buffer) and is_list(opts) do
    type = opts[:type] || :u8
    channels = opts[:channels] || 0
    StbImage.Nif.from_binary(buffer, channels, type)
  end

  @doc """
  Decodes GIF image from file at `path`.

  ## Example

      {:ok, frames, shape, delays} = StbImage.gif_from_file("/path/to/image")
      {h, w, 3} = shape

      # GIFs always have channels == :rgb and type == :u8
      # delays is a list that has n elements, where n is the number of frames

  """
  def gif_from_file(path) when is_binary(path) or is_list(path) do
    with {:ok, binary} <- File.read(path) do
      gif_from_binary(binary)
    end
  end

  @doc """
  Decodes GIF image from `binary`.

  ## Example

      {:ok, buffer} = File.read("/path/to/image")
      {:ok, frames, shape, delays} = StbImage.gif_from_binary(buffer)
      {h, w, 3} = shape

      # GIFs always have channels == :rgb and type == :u8
      # delays is a list that has n elements, where n is the number of frames

  """
  def gif_from_binary(binary) when is_binary(binary), do: StbImage.Nif.gif_from_binary(binary)

  @encoding_formats ~w(jpg png bmp tga)a
  @encoding_formats_string Enum.map_join(@encoding_formats, ", ", &inspect/1)

  @doc """
  Saves image to the file at `path`.

  The supported formats are #{@encoding_formats_string}.

  The format is determined from the file extension if possible,
  you can also pass it explicitly via the `:format` option.

  Returns `:ok` on success and `{:error, reason}` otherwise.

  Make sure the directory you intent to write the file to exists,
  otherwise an error is returned.

  ## Options

    * `:format` - one of the supported image formats

  """
  def to_file(path, data, height, width, channels, opts \\ [])
      when is_path(path) and is_binary(data) and is_integer(width) and width > 0 and
             is_integer(height) and height > 0 and is_integer(channels) and channels > 0 and
             is_list(opts) do
    format = opts[:format] || format_from_path!(path)
    assert_encoding_format!(format)
    StbImage.Nif.to_file(path_to_charlist(path), format, data, height, width, channels)
  end

  @doc """
  Encodes image to a binary.

  The supported formats are #{@encoding_formats_string}.

  ## Example

      {:ok, binary} = StbImage.to_binary(:png, img, height, width, channels)

  """
  def to_binary(format, data, height, width, channels)
      when is_atom(format) and is_binary(data) and is_integer(width) and width > 0 and
             is_integer(height) and height > 0 and is_integer(channels) and channels > 0 do
    assert_encoding_format!(format)
    StbImage.Nif.to_binary(format, data, height, width, channels)
  end

  defp format_from_path!(path) do
    case Path.extname(path) do
      ".jpg" ->
        :jpg

      ".jpeg" ->
        :jpg

      ".png" ->
        :png

      ".bmp" ->
        :bmp

      ".tga" ->
        :tga

      ext ->
        raise "could not determine a supported encoding format for file #{inspect(path)} with extension #{inspect(ext)}, " <>
                "please specify a supported :format option explicitly"
    end
  end

  defp assert_encoding_format!(format) do
    unless format in @encoding_formats do
      raise ArgumentError,
            "got an unsupported encoding format #{inspect(format)}, " <>
              "the format must be one of #{inspect(@encoding_formats)}"
    end
  end

  defp path_to_charlist(path) when is_list(path), do: path
  defp path_to_charlist(path) when is_binary(path), do: String.to_charlist(path)
end
