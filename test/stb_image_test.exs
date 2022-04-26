defmodule StbImageTest do
  use ExUnit.Case, async: true

  doctest StbImage

  test "decode png from file" do
    {:ok, img, shape, type, channels} = StbImage.from_file(Path.join(__DIR__, "test.png"))
    assert type == :u8
    assert shape == {2, 3, 4}
    assert channels == :rgba

    assert img ==
             <<241, 145, 126, 255, 136, 190, 78, 255, 68, 122, 183, 255, 244, 196, 187, 255, 190,
               205, 145, 255, 144, 184, 200, 255>>
  end

  test "decode as u16" do
    {:ok, img, shape, type, channels} =
      StbImage.from_file(Path.join(__DIR__, "test.png"), type: :u16)

    assert type == :u16
    assert shape == {2, 3, 4}
    assert channels == :rgba

    assert img ==
             <<241, 241, 145, 145, 126, 126, 255, 255, 136, 136, 190, 190, 78, 78, 255, 255, 68,
               68, 122, 122, 183, 183, 255, 255>>
  end

  test "decode as f32" do
    {:ok, img, shape, type, channels} =
      StbImage.from_file(Path.join(__DIR__, "test.png"), type: :f32)

    assert type == :f32
    assert shape == {2, 3, 4}
    assert channels == :rgba

    assert img ==
             <<17, 24, 98, 63, 177, 223, 147, 62, 42, 34, 89, 62, 0, 0, 128, 63, 34, 110, 128, 62,
               95, 0, 6, 63, 3, 51, 151, 61, 0, 0, 128, 63, 40, 156, 95, 61, 191, 65, 74, 62, 114,
               194, 246, 62, 0, 0, 128, 63, 3, 85, 104, 63, 224, 124, 15, 63, 6, 100, 1, 63, 0, 0,
               128, 63, 95, 0, 6, 63, 48, 98, 30, 63, 177, 223, 147, 62, 0, 0, 128, 63, 180, 163,
               145, 62, 93, 188, 249, 62, 84, 2, 22, 63, 0, 0, 128, 63>>
  end

  test "decode jpg from file" do
    {:ok, img, shape, type, channels} = StbImage.from_file(Path.join(__DIR__, "test.jpg"))
    assert type == :u8
    assert shape == {2, 3, 3}
    assert channels == :rgb

    assert img ==
             <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
               124>>
  end

  test "decode png from memory" do
    {:ok, buffer} = File.read(Path.join(__DIR__, "test.png"))
    {:ok, img, shape, type, channels} = StbImage.from_memory(buffer)
    assert type == :u8
    assert shape == {2, 3, 4}
    assert channels == :rgba

    assert img ==
             <<241, 145, 126, 255, 136, 190, 78, 255, 68, 122, 183, 255, 244, 196, 187, 255, 190,
               205, 145, 255, 144, 184, 200, 255>>
  end

  test "decode jpg from memory" do
    {:ok, buffer} = File.read(Path.join(__DIR__, "test.jpg"))
    {:ok, img, shape, type, channels} = StbImage.from_memory(buffer)
    assert type == :u8
    assert shape == {2, 3, 3}
    assert channels == :rgb

    assert img ==
             <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
               124>>
  end

  test "decode gif" do
    {:ok, frames, shape, delays} = StbImage.gif_from_file(Path.join(__DIR__, "test.gif"))
    assert shape == {2, 3, 3}
    assert 2 == Enum.count(frames)
    assert delays == [200, 200]

    assert frames ==
             [<<180, 128, 70, 255, 171, 119>>, <<61, 255, 65, 143, 117, 255>>]
  end

  for ext <- ~w(bmp png tga jpg)a do
    @ext ext

    test "save image #{@ext} to file" do
      read = StbImage.from_file(Path.join(__DIR__, "test.#{@ext}"))
      {:ok, img, {height, width, num_channels}, _, _} = read
      save_at = "tmp/save_test.#{@ext}"

      try do
        File.mkdir_p!("tmp")
        :ok = StbImage.to_file(save_at, img, height, width, num_channels)
        assert StbImage.from_file(save_at) == read
      after
        File.rm!(save_at)
      end
    end

    test "encode image as #{@ext} in memory" do
      {:ok, img, {height, width, num_channels}, _, _} =
        read = StbImage.from_file(Path.join(__DIR__, "test.#{@ext}"))

      {:ok, encoded} = StbImage.to_memory(@ext, img, height, width, num_channels)
      assert StbImage.from_memory(encoded) == read
    end
  end
end
