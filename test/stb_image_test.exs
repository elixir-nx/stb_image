defmodule StbImageTest do
  use ExUnit.Case, async: true

  doctest StbImage

  defp to_from_nx(img) do
    img
    |> StbImage.to_nx()
    |> tap(fn %Nx.Tensor{names: [:height, :width, :channels]} -> :ok end)
    |> StbImage.from_nx()
  end

  test "decode png from file" do
    img = StbImage.read_file!(Path.join(__DIR__, "test.png"))
    assert img.type == {:u, 8}
    assert img.shape == {2, 3, 4}

    assert img.data ==
             <<241, 145, 126, 255, 136, 190, 78, 255, 68, 122, 183, 255, 244, 196, 187, 255, 190,
               205, 145, 255, 144, 184, 200, 255>>

    assert StbImage.new(img.data, img.shape) == img
    assert StbImage.new(img.data, img.shape, type: :u8) == img
    assert StbImage.new(img.data, img.shape, type: {:u, 8}) == img
    assert to_from_nx(img) == img
  end

  test "decode jpg from file" do
    img = StbImage.read_file!(Path.join(__DIR__, "test.jpg"))
    assert img.type == {:u, 8}
    assert img.shape == {2, 3, 3}

    assert img.data ==
             <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
               124>>

    assert StbImage.new(img.data, img.shape) == img
    assert StbImage.new(img.data, img.shape, type: :u8) == img
    assert StbImage.new(img.data, img.shape, type: {:u, 8}) == img
    assert to_from_nx(img) == img
  end

  test "decode hdr from file" do
    img = StbImage.read_file!(Path.join(__DIR__, "test.hdr"))
    assert img.type == {:f, 32}
    assert img.shape == {384, 768, 3}
    assert is_binary(img.data)

    assert StbImage.new(img.data, img.shape, type: :f32) == img
    assert StbImage.new(img.data, img.shape, type: {:f, 32}) == img
    assert to_from_nx(img) == img
  end

  test "decode png from memory" do
    {:ok, binary} = File.read(Path.join(__DIR__, "test.png"))
    img = StbImage.read_binary!(binary)
    assert img.type == {:u, 8}
    assert img.shape == {2, 3, 4}

    assert img.data ==
             <<241, 145, 126, 255, 136, 190, 78, 255, 68, 122, 183, 255, 244, 196, 187, 255, 190,
               205, 145, 255, 144, 184, 200, 255>>

    assert StbImage.new(img.data, img.shape) == img
    assert to_from_nx(img) == img
  end

  test "decode jpg from memory" do
    {:ok, binary} = File.read(Path.join(__DIR__, "test.jpg"))
    img = StbImage.read_binary!(binary)
    assert img.type == {:u, 8}
    assert img.shape == {2, 3, 3}

    assert img.data ==
             <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
               124>>

    assert StbImage.new(img.data, img.shape) == img
    assert to_from_nx(img) == img
  end

  test "decode hdr from memory" do
    {:ok, binary} = File.read(Path.join(__DIR__, "test.hdr"))
    img = StbImage.read_binary!(binary)
    assert img.type == {:f, 32}
    assert img.shape == {384, 768, 3}
    assert is_binary(img.data)

    assert StbImage.new(img.data, img.shape, type: {:f, 32}) == img
    assert to_from_nx(img) == img
  end

  test "decode gif" do
    {:ok, frames, delays} = StbImage.read_gif_file(Path.join(__DIR__, "test.gif"))
    assert delays == [200, 200]

    assert Enum.all?(frames, &(&1.type == {:u, 8}))
    assert Enum.all?(frames, &(&1.shape == {2, 3, 3}))

    assert Enum.map(frames, & &1.data) ==
             [<<180, 128, 70, 255, 171, 119>>, <<61, 255, 65, 143, 117, 255>>]
  end

  for ext <- ~w(bmp png tga jpg hdr)a do
    @ext ext

    test "decode #{@ext} from file matches decode from binary" do
      img = StbImage.read_file!(Path.join(__DIR__, "test.#{@ext}"))
      assert StbImage.read_binary(File.read!(Path.join(__DIR__, "test.#{@ext}"))) == {:ok, img}
    end

    test "decode #{@ext} from file and encode to file" do
      img = StbImage.read_file!(Path.join(__DIR__, "test.#{@ext}"))
      save_at = "tmp/save_test.#{@ext}"

      try do
        File.mkdir_p!("tmp")
        :ok = StbImage.write_file!(img, save_at)
        assert StbImage.read_file(save_at) == {:ok, img}
      after
        File.rm!(save_at)
      end
    end

    test "decode #{@ext} from file and encode to binary" do
      img = StbImage.read_file!(Path.join(__DIR__, "test.#{@ext}"))

      encoded = StbImage.to_binary(img, @ext)
      assert StbImage.read_binary(encoded) == {:ok, img}
    end
  end

  test "resize png" do
    img = StbImage.read_file!(Path.join(__DIR__, "test.png"))
    resized_img = StbImage.resize(img, 4, 6)
    assert resized_img.shape == {4, 6, 4}
    assert resized_img.type == img.type
  end

  test "resize jpg" do
    img = StbImage.read_file!(Path.join(__DIR__, "test.jpg"))
    resized_img = StbImage.resize(img, 4, 6)
    assert resized_img.shape == {4, 6, 3}
    assert resized_img.type == img.type
  end

  test "resize hdr" do
    img = StbImage.read_file!(Path.join(__DIR__, "test.hdr"))
    resized_img = StbImage.resize(img, 192, 384)
    assert resized_img.shape == {192, 384, 3}
    assert resized_img.type == img.type
  end

  describe "errors" do
    test "read_file" do
      assert StbImage.read_file("unknown.jpg") == {:error, "could not open file"}

      assert_raise ArgumentError, "could not open file", fn ->
        StbImage.read_file!("unknown.jpg")
      end
    end

    test "read_binary" do
      assert StbImage.read_binary("") == {:error, "cannot decode image"}

      assert_raise ArgumentError, "cannot decode image", fn ->
        StbImage.read_binary!("")
      end
    end
  end
end
