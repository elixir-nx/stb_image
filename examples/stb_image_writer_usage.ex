defmodule StbImageExample do
  @image_to_save <<241, 145, 126, 255, 136, 190, 78, 255, 68, 122, 183, 255, 244, 196, 187, 255,
  190, 205, 145, 255, 144, 184, 200, 255>>
  def load_png_file(name, format, data, width, height, num_channels) do
    StbImage.to_file(name, format, data, width, height, num_channels)
  end

  def example do
    load_png_file(Path.join(__DIR__, "example_png.png"), "png", @image_to_save, 3, 2, 4)
  end
end
