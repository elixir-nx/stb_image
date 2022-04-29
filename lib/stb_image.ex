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
  The `StbImage` struct.

  It has the following fields:

    * `:data` - a blob with the image bytes in HWC (heigth-width-channels) order
    * `:shape` - a tuple with the `{height, width, channels}`
    * `:type` - the type unit in the binary (u8/u16/f32)
    * `:color_mode` - the color mode as `:l`, `:la`, `:rgb`, or `:rgba`

  """
  defstruct [:data, :shape, :type, :color_mode]

  @doc """
  Creates a StbImage directly.

  `data` is a binary blob with the image bytes in HWC
  (heigth-width-channels) order. `shape` is a tuple
  with the `heigth`, `width`, and `channel` dimensions.

  ## Options

    * `:color_mode` - the color mode. One is automatically
      inferred from the number of channels.

    * `:type` - The type of the data. Defaults to `:u8`.
      Must be one of `:u8`, `:u16`, `:f32`.

  """
  def new(data, {h, w, c} = shape, opts \\ []) when is_binary(data) and is_integer(h) and h > 0 and is_integer(w) and w > 0  and c in 1..4 do
    color_mode = opts[:color_mode] || elem({:l, :la, :rgb, :rgba}, c - 1)
    type = opts[:type] || :u8

    if byte_size(data) == h * w * c * bytes(type) do
      %StbImage{data: data, shape: shape, color_mode: color_mode, type: type}
    else
      raise ArgumentError, "cannot create StbImage because number of bytes do not match shape and type"
    end
  end

  defp bytes(:u8), do: 1
  defp bytes(:u16), do: 2
  defp bytes(:f32), do: 4

  @compile {:no_warn_undefined, Nx}
  @compile {:no_warn_undefined, Nx.Type}

  @doc """
  Converts a `StbImage` to a Nx tensor.

  It accepts the same options as `Nx.from_binary/3`.
  """
  def to_nx(%StbImage{data: data, type: type, shape: shape}, opts \\ []) do
    data
    |> Nx.from_binary(Nx.Type.normalize!(type), opts)
    |> Nx.reshape(shape)
  end

  @doc """
  Creates a `StbImage` from a Nx tensor.

  The tensor is expected to have shape `{h, w, c}`
  and one of the supported types.
  """
  def from_nx(tensor) when is_struct(tensor, Nx.Tensor) do
    new(Nx.to_binary(tensor), tensor_shape(Nx.shape(tensor)), type: tensor_type(Nx.type(tensor)))
  end

  defp tensor_type({:u, 8}), do: :u8
  defp tensor_type({:u, 16}), do: :u16
  defp tensor_type({:f, 32}), do: :f32
  defp tensor_type(type), do: raise ArgumentError, "unsupported tensor type: #{inspect(type)}"

  defp tensor_shape({_, _, _} = shape), do: shape
  defp tensor_shape(shape), do: raise ArgumentError, "unsupported tensor shape: #{inspect(shape)}"

  @doc """
  Decodes image from file at `path`.

  ## Options

    * `:channels` - The number of desired channels.
      Use `0` for auto-detection. Defaults to 0.

    * `:type` - The type of the data. Defaults to `:u8`.
      Must be one of `:u8`, `:u16`, `:f32`.

  ## Example

      {:ok, img} = StbImage.from_file("/path/to/image")
      {h, w, c} = img.shape
      data = img.data

      # If you know the image is a 4-channel image and auto-detection failed
      {:ok, img} = StbImage.from_file("/path/to/image", channels: 4)
      {h, w, c} = img.shape
      img = img.data

  """
  def from_file(path, opts \\ []) when is_path(path) and is_list(opts) do
    type = opts[:type] || :u8
    channels = opts[:channels] || 0

    with {:ok, img, shape, type, channels} <-
           StbImage.Nif.from_file(path_to_charlist(path), channels, type) do
      {:ok, %StbImage{data: img, shape: shape, type: type, color_mode: channels}}
    end
  end

  @doc """
  Decodes image from `binary` representing an image.

  ## Options

    * `:channels` - The number of desired channels.
      Use `0` for auto-detection. Defaults to 0.

    * `:type` - The type of the data. Defaults to `:u8`.
      Must be one of `:u8`, `:u16`, `:f32`.

  ## Example

      {:ok, buffer} = File.read("/path/to/image")
      {:ok, img} = StbImage.from_binary(buffer)
      {h, w, c} = img.shape
      img = img.data

      # If you know the image is a 4-channel image and auto-detection failed
      {:ok, img} = StbImage.from_file("/path/to/image", channels: 4)
      {h, w, c} = img.shape
      img = img.data

  """
  def from_binary(buffer, opts \\ []) when is_binary(buffer) and is_list(opts) do
    type = opts[:type] || :u8
    channels = opts[:channels] || 0

    with {:ok, img, shape, type, channels} <- StbImage.Nif.from_binary(buffer, channels, type) do
      {:ok, %StbImage{data: img, shape: shape, type: type, color_mode: channels}}
    end
  end

  @doc """
  Decodes GIF image from file at `path`.

  ## Example

      {:ok, frames, delays} = StbImage.gif_from_file("/path/to/image")
      frame = Enum.at(frames, 0)
      {h, w, 3} = frame.shape

      # GIFs always have channels == :rgb and type == :u8
      # delays is a list that has n elements, where n is the number of frames

  """
  def gif_from_file(path) when is_binary(path) or is_list(path) do
    with {:ok, binary} <- File.read(path) do
      gif_from_binary(binary)
    end
  end

  @doc """
  Decodes GIF image from a `binary` representing a GIF.

  ## Example

      {:ok, buffer} = File.read("/path/to/image")
      {:ok, frames, delays} = StbImage.gif_from_binary(buffer)
      frame = Enum.at(frames, 0)
      {h, w, 3} = frame.shape

      # GIFs always have channels == :rgb and type == :u8
      # delays is a list that has n elements, where n is the number of frames

  """
  def gif_from_binary(binary) when is_binary(binary) do
    with {:ok, frames, shape, delays} <- StbImage.Nif.gif_from_binary(binary) do
      stb_frames =
        for frame <- frames, do: %StbImage{data: frame, shape: shape, type: :u8, color_mode: :rgb}

      {:ok, stb_frames, delays}
    end
  end

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
  def to_file(%StbImage{data: data, shape: shape, type: type}, path, opts \\ []) do
    assert_write_type!(type)
    {height, width, channels} = shape
    format = opts[:format] || format_from_path!(path)
    assert_encoding_format!(format)
    StbImage.Nif.to_file(path_to_charlist(path), format, data, height, width, channels)
  end

  @doc """
  Encodes image to a binary.

  The supported formats are #{@encoding_formats_string}.

  ## Example
      img = StbImage.new(raw_img, {h, w, channels})
      {:ok, binary} = StbImage.to_binary(img, :png)

  """
  def to_binary(%StbImage{data: data, shape: shape, type: type}, format) do
    assert_write_type!(type)
    {height, width, channels} = shape
    assert_encoding_format!(format)
    StbImage.Nif.to_binary(format, data, height, width, channels)
  end

  defp assert_write_type!(:u8), do: :ok

  defp assert_write_type!(type) do
    raise ArgumentError, "StbImage can only write to_file/to_binary images with u8 type, got: #{inspect(type)}"
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
