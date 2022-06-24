defmodule StbImage do
  @moduledoc """
  Tiny module for image encoding and decoding.

  The following formats are supported and have type u8:

    * JPEG baseline & progressive (12 bpc/arithmetic not supported, same as stock IJG lib)
    * PNG 1/2/4/8/16-bit-per-channel
    * TGA
    * BMP non-1bpp, non-RLE
    * PSD (composited view only, no extra channels, 8/16 bit-per-channel)
    * GIF (always reports as 4-channel)
    * PIC (Softimage PIC)
    * PNM (PPM and PGM binary only)

  The following formats are supported and have type f32:

    * HDR (radiance rgbE format) (type is f32)

  There are also specific functions for working with GIFs.
  """

  @doc """
  The `StbImage` struct.

  It has the following fields:

    * `:data` - a blob with the image bytes in HWC (heigth-width-channels) order
    * `:shape` - a tuple with the `{height, width, channels}`
    * `:type` - the type unit in the binary (`{:u, 8}` or `{:f, 32}`)

  The number of channels correlates directly to the color mode.
  1 channel is greyscale, 2 is greyscale+alpha, 3 is RGB, and
  4 is RGB+alpha.
  """
  defstruct [:data, :shape, :type]

  defguardp is_path(path) when is_binary(path) or is_list(path)
  defguardp is_dimension(d) when is_integer(d) and d > 0

  @doc """
  Creates a StbImage directly.

  `data` is a binary blob with the image bytes in HWC
  (heigth-width-channels) order. `shape` is a tuple
  with the `heigth`, `width`, and `channel` dimensions.

  ## Options

    * `:type` - The type of the data. Defaults to `{:u, 8}`.
      Must be one of `{:u, 8}` or `{:f, 32}`. The `:u8` and
      `:f32` convenience atom syntax is also available.

  """
  def new(data, {h, w, c} = shape, opts \\ [])
      when is_binary(data) and is_dimension(h) and is_dimension(w) and c in 1..4 do
    type = type(opts[:type] || :u8)

    if byte_size(data) == h * w * c * bytes(type) do
      %StbImage{data: data, shape: shape, type: type}
    else
      raise ArgumentError,
            "cannot create StbImage because the number of bytes does not match the shape and type"
    end
  end

  @compile {:no_warn_undefined, Nx}

  @doc """
  Converts a `StbImage` to a Nx tensor.

  It accepts the same options as `Nx.from_binary/3`.
  """
  def to_nx(%StbImage{data: data, type: type, shape: shape}, opts \\ []) do
    data
    |> Nx.from_binary(type, opts)
    |> Nx.reshape(shape, names: [:height, :width, :channels])
  end

  @doc """
  Creates a `StbImage` from a Nx tensor.

  The tensor is expected to have the shape `{h, w, c}`
  and one of the supported types (u8/f32).
  """
  def from_nx(tensor) when is_struct(tensor, Nx.Tensor) do
    new(Nx.to_binary(tensor), tensor_shape(Nx.shape(tensor)), type: tensor_type(Nx.type(tensor)))
  end

  defp tensor_type({:u, 8}), do: {:u, 8}
  defp tensor_type({:f, 32}), do: {:f, 32}

  defp tensor_type(type),
    do: raise(ArgumentError, "unsupported tensor type: #{inspect(type)} (expected u8/f32)")

  defp tensor_shape({_, _, c} = shape) when c in 1..4,
    do: shape

  defp tensor_shape(shape),
    do:
      raise(
        ArgumentError,
        "unsupported tensor shape: #{inspect(shape)} (expected height-width-channel)"
      )

  @doc """
  Reads image from file at `path`.

  ## Options

    * `:channels` - The number of desired channels.
      Use `0` for auto-detection. Defaults to 0.

  ## Example

      {:ok, img} = StbImage.read_file("/path/to/image")
      {h, w, c} = img.shape
      data = img.data

      # If you know that the image is a 4-channel image and auto-detection failed
      {:ok, img} = StbImage.read_file("/path/to/image", channels: 4)
      {h, w, c} = img.shape
      img = img.data

  """
  def read_file(path, opts \\ []) when is_path(path) and is_list(opts) do
    channels = opts[:channels] || 0

    case StbImage.Nif.read_file(path_to_charlist(path), channels) do
      {:ok, img, shape, bytes} ->
        {:ok, %StbImage{data: img, shape: shape, type: bytes_to_type(bytes)}}

      {:error, reason} ->
        {:error, List.to_string(reason)}
    end
  end

  @doc """
  Raising version of `read_file/2`.
  """
  def read_file!(buffer, opts \\ []) do
    case read_file(buffer, opts) do
      {:ok, img} -> img
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @doc """
  Reads image from `binary` representing an image.

  ## Options

    * `:channels` - The number of desired channels.
      Use `0` for auto-detection. Defaults to 0.

  ## Example

      {:ok, buffer} = File.read("/path/to/image")
      {:ok, img} = StbImage.read_binary(buffer)
      {h, w, c} = img.shape
      img = img.data

      # If you know that the image is a 4-channel image and auto-detection failed
      {:ok, img} = StbImage.read_binary(buffer, channels: 4)
      {h, w, c} = img.shape
      img = img.data

  """
  def read_binary(buffer, opts \\ []) when is_binary(buffer) and is_list(opts) do
    channels = opts[:channels] || 0

    case StbImage.Nif.read_binary(buffer, channels) do
      {:ok, img, shape, bytes} ->
        {:ok, %StbImage{data: img, shape: shape, type: bytes_to_type(bytes)}}

      {:error, reason} ->
        {:error, List.to_string(reason)}
    end
  end

  @doc """
  Raising version of `read_binary/2`.
  """
  def read_binary!(buffer, opts \\ []) do
    case read_binary(buffer, opts) do
      {:ok, img} -> img
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @doc """
  Reads GIF image from file at `path`.

  ## Example

      {:ok, frames, delays} = StbImage.read_gif_file("/path/to/image")
      frame = Enum.at(frames, 0)
      {h, w, 3} = frame.shape

  """
  def read_gif_file(path) when is_binary(path) or is_list(path) do
    with {:ok, binary} <- File.read(path) do
      read_gif_binary(binary)
    end
  end

  @doc """
  Decodes GIF image from a `binary` representing a GIF.

  ## Example

      {:ok, buffer} = File.read("/path/to/image")
      {:ok, frames, delays} = StbImage.read_gif_binary(buffer)
      frame = Enum.at(frames, 0)
      {h, w, 3} = frame.shape

  """
  def read_gif_binary(binary) when is_binary(binary) do
    with {:ok, frames, shape, delays} <- StbImage.Nif.read_gif_binary(binary) do
      stb_frames = for frame <- frames, do: %StbImage{data: frame, shape: shape, type: {:u, 8}}

      {:ok, stb_frames, delays}
    end
  end

  @encoding_formats ~w(jpg png bmp tga hdr)a
  @encoding_formats_string Enum.map_join(@encoding_formats, ", ", &inspect/1)

  @doc """
  Writes image to the file at `path`.

  The supported formats are #{@encoding_formats_string}.

  The format is determined from the file extension, if possible.
  You can also pass it explicitly via the `:format` option.

  Returns `:ok` on success and `{:error, reason}` otherwise.

  Make sure the directory you intend to write the file to exists.
  Otherwise, an error is returned.

  ## Options

    * `:format` - one of the supported image formats

  """
  def write_file(%StbImage{data: data, shape: shape, type: type}, path, opts \\ []) do
    {height, width, channels} = shape
    format = opts[:format] || format_from_path!(path)
    assert_write_type_and_format!(type, format)

    case StbImage.Nif.write_file(path_to_charlist(path), format, data, height, width, channels) do
      :ok -> :ok
      {:error, reason} -> {:error, List.to_string(reason)}
    end
  end

  @doc """
  Raising version of `write_file/3`.
  """
  def write_file!(image, path, opts \\ []) do
    case write_file(image, path, opts) do
      :ok -> :ok
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @doc """
  Encodes image to a binary.

  The supported formats are #{@encoding_formats_string}.

  ## Example

      img = StbImage.new(raw_img, {h, w, channels})
      binary = StbImage.to_binary(img, :png)

  """
  def to_binary(%StbImage{data: data, shape: shape, type: type}, format) do
    assert_write_type_and_format!(type, format)
    {height, width, channels} = shape

    case StbImage.Nif.to_binary(format, data, height, width, channels) do
      {:ok, binary} -> binary
      {:error, reason} -> raise ArgumentError, "#{reason}"
    end
  end

  @doc """
  Resizes the image into the given `output_h` and `output_w`.

  ## Example

      img = StbImage.new(raw_img, {h, w, channels})
      StbImage.resize(raw_img, div(h, 2), div(w, 2))

  """
  def resize(
        %StbImage{data: data, shape: {height, width, channels}, type: type},
        output_h,
        output_w
      )
      when is_dimension(output_h) and is_dimension(output_w) do
    case StbImage.Nif.resize(data, height, width, channels, output_h, output_w, bytes(type)) do
      {:ok, output_pixels} ->
        %StbImage{data: output_pixels, shape: {output_h, output_w, channels}, type: type}

      {:error, reason} ->
        raise ArgumentError, "#{reason}"
    end
  end

  defp assert_write_type_and_format!(type, format) when format in [:png, :jpg, :bmp, :tga] do
    if type != {:u, 8} do
      raise ArgumentError, "incompatible type (#{inspect(type)}) for #{inspect(format)}"
    end
  end

  defp assert_write_type_and_format!(type, format) when format in [:hdr] do
    if type != {:f, 32} do
      raise ArgumentError, "incompatible type (#{inspect(type)}) for #{inspect(format)}"
    end
  end

  defp assert_write_type_and_format!(_, format) do
    raise ArgumentError,
          "got an unsupported encoding format #{inspect(format)}, " <>
            "the format must be one of #{inspect(@encoding_formats)}"
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

      ".hdr" ->
        :hdr

      ext ->
        raise "could not determine a supported encoding format for file #{inspect(path)} with extension #{inspect(ext)}, " <>
                "please specify a supported :format option explicitly"
    end
  end

  defp path_to_charlist(path) when is_list(path), do: path
  defp path_to_charlist(path) when is_binary(path), do: String.to_charlist(path)

  defp type(:u8), do: {:u, 8}
  defp type(:f32), do: {:f, 32}
  defp type({:u, 8}), do: {:u, 8}
  defp type({:f, 32}), do: {:f, 32}

  defp bytes({_, s}), do: div(s, 8)

  defp bytes_to_type(1), do: {:u, 8}
  defp bytes_to_type(4), do: {:f, 32}
end
