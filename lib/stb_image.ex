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

  @doc """
  Decodes image at the given `filename`.

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
  def from_file(filename, opts \\ [])
      when (is_binary(filename) or is_list(filename)) and is_list(opts) do
    filename = if is_binary(filename), do: String.to_charlist(filename), else: filename
    type = opts[:type] || :u8
    channels = opts[:channels] || 0
    StbImage.Nif.from_file(filename, channels, type)
  end

  @doc """
  Decodes image from `buffer` in memory.

  ## Options

    * `:channels` - The number of desired channels.
      Use `0` for auto-detection. Defaults to 0.

    * `:type` - The type of the data. Defaults to `:u8`.
      Must be one of `:u8`, `:u16`, `:f32`.

  ## Example

      {:ok, buffer} = File.read("/path/to/image")
      {:ok, img, shape, type, channels} = StbImage.from_memory(buffer)
      {h, w, c} = shape

      # If you know the image is a 4-channel image and auto-detection failed
      {:ok, img, shape, type, channels} = StbImage.from_file("/path/to/image", channels: 4)
      {h, w, c} = shape

  """
  def from_memory(buffer, opts \\ []) when is_binary(buffer) and is_list(opts) do
    type = opts[:type] || :u8
    channels = opts[:channels] || 0
    StbImage.Nif.from_memory(buffer, channels, type)
  end

  @doc """
  Decodes GIF image from `filename`.

  ## Example

      {:ok, frames, shape, delays} = StbImage.gif_from_file("/path/to/image")
      {h, w, 3} = shape

      # GIFs always have channels == :rgb and type == :u8
      # delays is a list that has n elements, where n is the number of frames

  """
  def gif_from_file(filename) when is_binary(filename) or is_list(filename) do
    with {:ok, buffer} <- File.read(filename) do
      gif_from_memory(buffer)
    end
  end

  @doc """
  Decodes GIF image from `buffer` in memory.

  ## Example

      {:ok, buffer} = File.read("/path/to/image")
      {:ok, frames, shape, delays} = StbImage.gif_from_memory(buffer)
      {h, w, 3} = shape

      # GIFs always have channels == :rgb and type == :u8
      # delays is a list that has n elements, where n is the number of frames

  """
  def gif_from_memory(buffer) when is_binary(buffer), do: StbImage.Nif.gif_from_memory(buffer)

  @to_file_exts ~w(jpg png bmp tga)a

  @doc """
  Saves image to `filename`.

  The format of the file is taken to the filename extension.
  Only .jpg, .png, .bmp, and .tga are supported. You can also
  pass the `:extension` as an atom option.

  This function also requires the `height`, `width`, and
  number of `channels` to be given.

  Returns `:ok` if suceeds.

  Make sure the directory you intent to write the file to
  exists, otherwise it will return an `{:error, reason}`
  tuple.
  """
  def to_file(filename, data, height, width, channels, opts \\ [])
      when is_binary(data) and is_integer(width) and width > 0 and is_integer(height) and
             height > 0 and is_integer(channels) and channels > 0 and
             is_list(opts) do
    extension = opts[:extension] || extname!(filename)

    if extension not in @to_file_exts do
      badext!(extension)
    end

    filename = if is_binary(filename), do: String.to_charlist(filename), else: filename
    StbImage.Nif.to_file(filename, extension, data, height, width, channels)
  end

  @doc """
  Encodes image to an in-memory binary.

  ## Example

      {:ok, buffer} = StbImage.to_memory(:png, img, height, width, channels)

  """
  def to_memory(extension, data, height, width, channels)
      when is_binary(data) and is_integer(width) and width > 0 and is_integer(height) and
             height > 0 and is_integer(channels) and channels > 0 do
    if extension not in @to_file_exts do
      badext!(extension)
    end

    StbImage.Nif.to_memory(extension, data, height, width, channels)
  end

  defp extname!(filename) do
    case Path.extname(filename) do
      ".jpg" -> :jpg
      ".png" -> :png
      ".bmp" -> :bmp
      ".tga" -> :tga
      _ -> badext!(filename)
    end
  end

  defp badext!(ext) do
    raise ArgumentError,
          "trying to save image to file with unsupported extension #{ext}. " <>
            "Please set the :extension option to one of #{inspect(@to_file_exts)}"
  end
end
