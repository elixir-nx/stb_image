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
end
