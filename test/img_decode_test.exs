defmodule ImgDecodeTest do
  use ExUnit.Case
  doctest ImgDecode

  test "decode png from file" do
    {:ok, img, shape, type} = ImgDecode.from_file(Path.join(__DIR__, "test.png"))
    assert type == :u8
    assert shape == {3, 2, 3}
    assert img == <<248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248,
             248, 248, 248>>
  end

  test "decode jpg from file" do
    {:ok, img, shape, type} = ImgDecode.from_file(Path.join(__DIR__, "test.jpg"))
    assert type == :u8
    assert shape == {3, 2, 3}
    assert img == <<248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248,
             248, 248, 248>>
  end

  test "decode png from memory" do
    {:ok, buffer} = File.read(Path.join(__DIR__, "test.png"))
    {:ok, img, shape, type} = ImgDecode.from_memory(buffer)
    assert type == :u8
    assert shape == {3, 2, 3}
    assert img == <<248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248,
             248, 248, 248>>
  end

  test "decode jpg from memory" do
    {:ok, buffer} = File.read(Path.join(__DIR__, "test.jpg"))
    {:ok, img, shape, type} = ImgDecode.from_memory(buffer)
    assert type == :u8
    assert shape == {3, 2, 3}
    assert img == <<248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248,
             248, 248, 248>>
  end
end
