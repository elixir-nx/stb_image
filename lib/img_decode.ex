defmodule ImgDecode do
  @moduledoc """
  Documentation for `ImgDecode`.
  """

  @doc """
  Decode image from a given file

  - @param filename. Path to the image.
  """
  def from_file(filename), do: from_file(filename, 0, :u8)

  @doc """
  Decode image from a given file

  - @param filename. Path to the image.
  - @param desired_channels. 0 for auto-detection. Otherwise, the number of desired channels.
  """
  def from_file(filename, desired_channels) do
    from_file(filename, desired_channels, :u8)
  end

  @doc """
  Decode image from a given file

  - @param filename. Path to the image.
  - @param desired_channels. 0 for auto-detection. Otherwise, the number of desired channels.
  - @param type. Specify format for pixel. :u8, :u16 or f32.
  """
  def from_file(filename, desired_channels, type) when is_binary(filename) and desired_channels >= 0 and (type == :u8 or type == :u16 or type == :f32) do
    ImgDecode.Nif.from_file(filename, desired_channels, type)
  end

  @doc """
  Decode image from buffer in memory

  - @param buffer. Buffered raw file data in memory.
  """
  def from_memory(buffer), do: from_memory(buffer, 0, :u8)

  @doc """
  Decode image from buffer in memory

  - @param buffer. Buffered raw file data in memory.
  - @param desired_channels. 0 for auto-detection. Otherwise, the number of desired channels.
  """
  def from_memory(buffer, desired_channels) do
    from_memory(buffer, desired_channels, :u8)
  end

  @doc """
  Decode image from buffer in memory

  - @param buffer. Buffered raw file data in memory.
  - @param desired_channels. 0 for auto-detection. Otherwise, the number of desired channels.
  - @param type. Specify format for pixel. :u8, :u16 or f32.
  """
  def from_memory(buffer, desired_channels, type) when is_binary(buffer) and desired_channels >= 0 and (type == :u8 or type == :u16 or type == :f32) do
    ImgDecode.Nif.from_memory(buffer, desired_channels, type)
  end
end
