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

  @types [:u8, :u16, :f32]

  @doc """
  Decode image from a given file

  - `filename`. Path to the image.

  ## Example

      {:ok, img, shape, type, channels} = StbImage.from_file("/path/to/image")
      {h, w, c} = shape

  """
  def from_file(filename), do: from_file(filename, 0, :u8)

  @doc """
  Decode image from a given file

  - `filename`. Path to the image.
  - `desired_channels`. `0` for auto-detection. Otherwise, the number of desired channels.

  ## Example

      # if you know the image is a 4-channel image and auto-detection failed
      {:ok, img, shape, type, channels} = StbImage.from_file("/path/to/image", 4)
      {h, w, c} = shape

  """
  def from_file(filename, desired_channels) do
    from_file(filename, desired_channels, :u8)
  end

  @doc """
  Decode image from a given file

  - `filename`. Path to the image.
  - `desired_channels`. `0` for auto-detection. Otherwise, the number of desired channels.
  - `type`. Specify format for each channel. `:u8`, `:u16` or `:f32`.

  ## Example

      # Use 0 for auto-detecting number of channels
      # but specify each channel is in float (32-bit)
      {:ok, img, shape, type, channels} = StbImage.from_file("/path/to/image", 0, :f32)
      {h, w, c} = shape

  """
  def from_file(filename, desired_channels, type)
      when is_binary(filename) and is_integer(desired_channels) and desired_channels >= 0 and
             type in @types do
    StbImage.Nif.from_file(filename, desired_channels, type)
  end

  @doc """
  Decode image from buffer in memory

  - `buffer`. Buffered raw file data in memory.

  ## Example

      # image buffer from a file or perhaps download from Internet
      {:ok, buffer} = File.read("/path/to/image")
      # decode the image from memory
      {:ok, img, shape, type, channels} = StbImage.from_memory(buffer)
      {h, w, c} = shape

  """
  def from_memory(buffer), do: from_memory(buffer, 0, :u8)

  @doc """
  Decode image from buffer in memory

  - `buffer`. Buffered raw file data in memory.
  - `desired_channels`. `0` for auto-detection. Otherwise, the number of desired channels.

  ## Example

      # image buffer from a file or perhaps download from Internet
      {:ok, buffer} = File.read("/path/to/image")
      # decode the image from memory
      # and specify it is a 4-channel image
      {:ok, img, shape, type, channels} = StbImage.from_memory(buffer, 4)
      {h, w, c} = shape

  """
  def from_memory(buffer, desired_channels) do
    from_memory(buffer, desired_channels, :u8)
  end

  @doc """
  Decode image from buffer in memory

  - `buffer`. Buffered raw file data in memory.
  - `desired_channels`. `0` for auto-detection. Otherwise, the number of desired channels.
  - `type`. Specify format for each channel. `:u8`, `:u16` or `:f32`.

  ## Example

      # image buffer from a file or perhaps download from Internet
      {:ok, buffer} = File.read("/path/to/image")
      # decode the image from memory
      # and specify it is a 3-channel image and each channel is in uint8_t
      {:ok, img, shape, type, channels} = StbImage.from_memory(buffer, 3, :u8)
      {h, w, c} = shape

  """
  def from_memory(buffer, desired_channels, type)
      when is_binary(buffer) and is_integer(desired_channels) and desired_channels >= 0 and
             type in @types do
    StbImage.Nif.from_memory(buffer, desired_channels, type)
  end

  @doc """
  Decode GIF image from a given file

  - `filename`. Path to the GIF image.

  ## Example

      {:ok, frames, shape, delays} = StbImage.gif_from_file("/path/to/image")
      {h, w, 3} = shape
      # GIFs always have channels == :rgb and type == :u8
      # delays is a list that has n elements, where n is the number of frames

  """
  def gif_from_file(filename) do
    with {:ok, buffer} <- File.read(filename) do
      gif_from_memory(buffer)
    end
  end

  @doc """
  Decode image from buffer in memory

  - `buffer`. Path to the image.

  ## Example

      {:ok, buffer} = File.read("/path/to/image")
      {:ok, frames, shape, delays} = StbImage.gif_from_memory(buffer)
      {h, w, 3} = shape
      # delays is a list that has n elements, where n is the number of frames

  """
  def gif_from_memory(buffer), do: StbImage.Nif.gif_from_memory(buffer)
end
