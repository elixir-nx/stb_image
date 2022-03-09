defmodule StbImage do
  @moduledoc """
  Documentation for `StbImage`.
  """

  @doc """
  Decode image from a given file

  - **filename**. Path to the image.

  ## Example
  ```elixir
  {:ok, img, shape, type, channels} = StbImage.from_file("/path/to/image")
  {h, w, c} = shape
  ```
  """
  def from_file(filename), do: from_file(filename, 0, :u8)

  @doc """
  Decode image from a given file

  - **filename**. Path to the image.
  - **desired_channels**. `0` for auto-detection. Otherwise, the number of desired channels.

  ## Example
  ```elixir
  # if you know the image is a 4-channel image and auto-detection failed
  {:ok, img, shape, type, channels} = StbImage.from_file("/path/to/image", 4)
  {h, w, c} = shape
  ```
  """
  def from_file(filename, desired_channels) do
    from_file(filename, desired_channels, :u8)
  end

  @doc """
  Decode image from a given file

  - **filename**. Path to the image.
  - **desired_channels**. `0` for auto-detection. Otherwise, the number of desired channels.
  - **type**. Specify format for each channel. `:u8`, `:u16` or `:f32`.

  ## Example
  ```elixir
  # Use 0 for auto-detecting number of channels
  # but specify each channel is in float (32-bit)
  {:ok, img, shape, type, channels} = StbImage.from_file("/path/to/image", 0, :f32)
  {h, w, c} = shape
  ```
  """
  def from_file(filename, desired_channels, type)
      when is_binary(filename) and desired_channels >= 0 and
             (type == :u8 or type == :u16 or type == :f32) do
    StbImage.Nif.from_file(filename, desired_channels, type)
  end

  @doc """
  Decode image from buffer in memory

  - **buffer**. Buffered raw file data in memory.

  ## Example
  ```elixir
  # image buffer from a file or perhaps download from Internet
  {:ok, buffer} = File.read("/path/to/image")
  # decode the image from memory
  {:ok, img, shape, type, channels} = StbImage.from_memory(buffer)
  {h, w, c} = shape
  ```
  """
  def from_memory(buffer), do: from_memory(buffer, 0, :u8)

  @doc """
  Decode image from buffer in memory

  - **buffer**. Buffered raw file data in memory.
  - **desired_channels**. `0` for auto-detection. Otherwise, the number of desired channels.

  ## Example
  ```elixir
  # image buffer from a file or perhaps download from Internet
  {:ok, buffer} = File.read("/path/to/image")
  # decode the image from memory
  # and specify it is a 4-channel image
  {:ok, img, shape, type, channels} = StbImage.from_memory(buffer, 4)
  {h, w, c} = shape
  ```
  """
  def from_memory(buffer, desired_channels) do
    from_memory(buffer, desired_channels, :u8)
  end

  @doc """
  Decode image from buffer in memory

  - **buffer**. Buffered raw file data in memory.
  - **desired_channels**. `0` for auto-detection. Otherwise, the number of desired channels.
  - **type**. Specify format for each channel. `:u8`, `:u16` or `:f32`.

  ## Example
  ```elixir
  # image buffer from a file or perhaps download from Internet
  {:ok, buffer} = File.read("/path/to/image")
  # decode the image from memory
  # and specify it is a 3-channel image and each channel is in uint8_t
  {:ok, img, shape, type, channels} = StbImage.from_memory(buffer, 3, :u8)
  {h, w, c} = shape
  ```
  """
  def from_memory(buffer, desired_channels, type)
      when is_binary(buffer) and desired_channels >= 0 and
             (type == :u8 or type == :u16 or type == :f32) do
    StbImage.Nif.from_memory(buffer, desired_channels, type)
  end

  @doc """
  Decode GIF image from a given file

  - **filename**. Path to the GIF image.

  ## Example
  ```elixir
  {:ok, frames, shape, delays} = StbImage.gif_from_file("/path/to/image")
  {h, w, 3} = shape
  # GIFs always have channels == :rgb and type == :u8
  # delays is a list that has n elements, where n is the number of frames
  ```
  """
  def gif_from_file(filename) do
    with {:ok, buffer} <- File.read(filename) do
      gif_from_memory(buffer)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Decode image from buffer in memory

  - **buffer**. Path to the image.

  ## Example
  ```elixir
  {:ok, buffer} = File.read("/path/to/image")
  {:ok, frames, shape, delays} = StbImage.gif_from_memory(buffer)
  {h, w, 3} = shape
  # delays is a list that has n elements, where n is the number of frames
  ```
  """
  def gif_from_memory(buffer), do: StbImage.Nif.gif_from_memory(buffer)
end
