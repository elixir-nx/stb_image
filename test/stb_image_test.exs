defmodule StbImageTest do
  use ExUnit.Case, async: true

  doctest StbImage

  test "decode png from file" do
    {:ok, img} = StbImage.from_file(Path.join(__DIR__, "test.png"))
    assert img.type == :u8
    assert img.shape == {2, 3, 4}

    assert img.data ==
             <<241, 145, 126, 255, 136, 190, 78, 255, 68, 122, 183, 255, 244, 196, 187, 255, 190,
               205, 145, 255, 144, 184, 200, 255>>

    assert StbImage.new(img.data, img.shape) == img
    assert StbImage.new(img.data, img.shape, type: :u8) == img
    assert img |> StbImage.to_nx() |> tap(fn %Nx.Tensor{} -> :ok end) |> StbImage.from_nx() == img
  end

  test "decode as f32" do
    {:ok, img} = StbImage.from_file(Path.join(__DIR__, "test.png"), type: :f32)

    assert img.type == :f32
    assert img.shape == {2, 3, 4}

    assert img.data ==
             <<17, 24, 98, 63, 177, 223, 147, 62, 42, 34, 89, 62, 0, 0, 128, 63, 34, 110, 128, 62,
               95, 0, 6, 63, 3, 51, 151, 61, 0, 0, 128, 63, 40, 156, 95, 61, 191, 65, 74, 62, 114,
               194, 246, 62, 0, 0, 128, 63, 3, 85, 104, 63, 224, 124, 15, 63, 6, 100, 1, 63, 0, 0,
               128, 63, 95, 0, 6, 63, 48, 98, 30, 63, 177, 223, 147, 62, 0, 0, 128, 63, 180, 163,
               145, 62, 93, 188, 249, 62, 84, 2, 22, 63, 0, 0, 128, 63>>

    assert StbImage.new(img.data, img.shape, type: :f32) == img
    assert img |> StbImage.to_nx() |> tap(fn %Nx.Tensor{} -> :ok end) |> StbImage.from_nx() == img
  end

  test "decode jpg from file" do
    {:ok, img} = StbImage.from_file(Path.join(__DIR__, "test.jpg"))
    assert img.type == :u8
    assert img.shape == {2, 3, 3}

    assert img.data ==
             <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
               124>>

    assert StbImage.new(img.data, img.shape) == img
    assert img |> StbImage.to_nx() |> tap(fn %Nx.Tensor{} -> :ok end) |> StbImage.from_nx() == img
  end

  test "decode png from memory" do
    {:ok, binary} = File.read(Path.join(__DIR__, "test.png"))
    {:ok, img} = StbImage.from_binary(binary)
    assert img.type == :u8
    assert img.shape == {2, 3, 4}

    assert img.data ==
             <<241, 145, 126, 255, 136, 190, 78, 255, 68, 122, 183, 255, 244, 196, 187, 255, 190,
               205, 145, 255, 144, 184, 200, 255>>

    assert StbImage.new(img.data, img.shape) == img
    assert img |> StbImage.to_nx() |> tap(fn %Nx.Tensor{} -> :ok end) |> StbImage.from_nx() == img
  end

  test "decode jpg from memory" do
    {:ok, binary} = File.read(Path.join(__DIR__, "test.jpg"))
    {:ok, img} = StbImage.from_binary(binary)
    assert img.type == :u8
    assert img.shape == {2, 3, 3}

    assert img.data ==
             <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
               124>>

    assert StbImage.new(img.data, img.shape) == img
    assert img |> StbImage.to_nx() |> tap(fn %Nx.Tensor{} -> :ok end) |> StbImage.from_nx() == img
  end

  test "decode gif" do
    {:ok, frames, delays} = StbImage.gif_from_file(Path.join(__DIR__, "test.gif"))
    frame = Enum.at(frames, 0)
    assert frame.shape == {2, 3, 3}
    assert 2 == Enum.count(frames)
    assert delays == [200, 200]

    assert [Enum.at(frames, 0).data, Enum.at(frames, 1).data] ==
             [<<180, 128, 70, 255, 171, 119>>, <<61, 255, 65, 143, 117, 255>>]
  end

  for ext <- ~w(bmp png tga jpg)a do
    @ext ext

    test "save image #{@ext} to file" do
      read = StbImage.from_file(Path.join(__DIR__, "test.#{@ext}"))
      {:ok, img} = read
      save_at = "tmp/save_test.#{@ext}"

      try do
        File.mkdir_p!("tmp")
        :ok = StbImage.to_file(img, save_at)
        assert StbImage.from_file(save_at) == read
      after
        File.rm!(save_at)
      end
    end

    test "encode image as #{@ext} in memory" do
      read = StbImage.from_file(Path.join(__DIR__, "test.#{@ext}"))
      {:ok, img} = read

      {:ok, encoded} = StbImage.to_binary(img, @ext)
      assert StbImage.from_binary(encoded) == read
    end
  end

  test "resize png" do
    {:ok, img} = StbImage.from_file(Path.join(__DIR__, "test.png"))
    {:ok, resized_img} = StbImage.resize(img, 4, 6)
    assert resized_img.shape == {4, 6, 4}
    assert resized_img.type == img.type
  end

  test "resize jpg" do
    {:ok, img} = StbImage.from_file(Path.join(__DIR__, "test.jpg"))
    {:ok, resized_img} = StbImage.resize(img, 4, 6)
    assert resized_img.shape == {4, 6, 3}
    assert resized_img.type == img.type
  end
end
