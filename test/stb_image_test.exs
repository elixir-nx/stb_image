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
    assert Enum.all?(frames, &(&1.shape == {2, 3, 4}))

    assert Enum.at(frames, 0).data ==
             <<180, 128, 70, 255, 171, 119, 61, 255, 65, 143, 117, 255, 222, 170, 112, 255, 205,
               153, 95, 255, 88, 166, 140, 255>>

    assert Enum.at(frames, 1).data ==
             <<241, 145, 126, 255, 136, 190, 78, 255, 68, 122, 183, 255, 244, 196, 187, 255, 190,
               205, 145, 255, 144, 184, 200, 255>>
  end

  test "decode gif dispose mode previous" do
    {:ok, frames, delays} =
      StbImage.read_gif_file(Path.join(__DIR__, "test_dispose_mode_previous.gif"))

    assert delays == [70, 70, 70, 70]

    assert Enum.all?(frames, &(&1.type == {:u, 8}))
    assert Enum.all?(frames, &(&1.shape == {2, 2, 4}))

    assert Enum.at(frames, 0).data ==
             <<255, 255, 255, 255, 255, 255, 255, 255, 128, 128, 128, 255, 255, 255, 255, 255>>

    assert Enum.at(frames, 1).data ==
             <<128, 128, 128, 255, 255, 255, 255, 255, 255, 255, 255, 255, 240, 240, 240, 255>>

    assert Enum.at(frames, 2).data ==
             <<0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255>>

    assert Enum.at(frames, 3).data ==
             <<255, 255, 255, 255, 0, 0, 0, 255, 255, 255, 255, 255, 200, 200, 200, 255>>
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

  test "read/write file with UTF-8 characters in filename" do
    try do
      File.cp(Path.join(__DIR__, "test.png"), Path.join(__DIR__, "テスト.png"))

      img = StbImage.read_file!(Path.join(__DIR__, "テスト.png"))
      assert img.type == {:u, 8}
      assert img.shape == {2, 3, 4}

      assert img.data ==
               <<241, 145, 126, 255, 136, 190, 78, 255, 68, 122, 183, 255, 244, 196, 187, 255,
                 190, 205, 145, 255, 144, 184, 200, 255>>

      assert StbImage.new(img.data, img.shape) == img
      assert StbImage.new(img.data, img.shape, type: :u8) == img
      assert StbImage.new(img.data, img.shape, type: {:u, 8}) == img
      assert to_from_nx(img) == img

      save_at = Path.join(__DIR__, "セーブ.png")
      :ok = StbImage.write_file!(img, save_at)
      assert StbImage.read_file(save_at) == {:ok, img}
    after
      File.rm_rf(Path.join(__DIR__, "テスト.png"))
      File.rm_rf(Path.join(__DIR__, "セーブ.png"))
    end
  end

  describe "nx" do
    test "implements lazy container" do
      img = StbImage.read_file!(Path.join(__DIR__, "test.png"))
      assert StbImage.to_nx(img) == Nx.Defn.jit(& &1).(img)
    end
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

  describe "desired channels" do
    test "decode RGBA image as is" do
      img = StbImage.read_file!(Path.join(__DIR__, "test-rgba.png"))
      assert {18, 30, 4} == img.shape
    end

    test "decode RGBA image, request 3 channels" do
      img = StbImage.read_file!(Path.join(__DIR__, "test-rgba.png"), channels: 3)
      assert {18, 30, 3} == img.shape
    end

    test "decode RGBA image, request 2 channels" do
      img = StbImage.read_file!(Path.join(__DIR__, "test-rgba.png"), channels: 2)
      assert {18, 30, 2} == img.shape
    end

    test "decode RGBA image, request 1 channel" do
      img = StbImage.read_file!(Path.join(__DIR__, "test-rgba.png"), channels: 1)
      assert {18, 30, 1} == img.shape
    end

    test "decode RGBA image, request 0 channels" do
      img = StbImage.read_file!(Path.join(__DIR__, "test-rgba.png"), channels: 0)
      assert {18, 30, 4} == img.shape
    end

    test "decode RGBA image, requested channels exceeds maximum channels available in the image" do
      assert_raise ArgumentError, "cannot decode image", fn ->
        StbImage.read_file!(Path.join(__DIR__, "test-rgba.png"), channels: 5)
      end
    end
  end

  describe "bad files" do
    test "JPEG with bad maker" do
      file = Path.join(__DIR__, "stb-issue-1608.jpg")
      binary = File.read!(file)

      assert StbImage.read_file(file) == {:error, "cannot decode image"}
      assert StbImage.read_binary(binary) == {:error, "cannot decode image"}

      assert_raise ArgumentError, "cannot decode image", fn ->
        StbImage.read_file!(file)
      end

      assert_raise ArgumentError, "cannot decode image", fn ->
        StbImage.read_binary!(binary)
      end
    end
  end

  describe "GIF" do
    test "only restores background when dispose is 2 or 3" do
      file = Path.join(__DIR__, "stb-issue-1688-horse.gif")
      binary = File.read!(file)

      {:ok, frames, _} = StbImage.read_gif_binary(binary)
      assert 34 == Enum.count(frames)

      decoded = Enum.at(frames, 5)
      # StbImage.write_file!(decoded, Path.join(__DIR__, "stb-issue-1688-horse-5.png"))
      decoded = StbImage.to_binary(decoded, :png)

      {:ok, expected_img} = StbImage.read_file(Path.join(__DIR__, "stb-issue-1688-expected.png"))
      expected = StbImage.to_binary(expected_img, :png)

      assert decoded == expected
    end
  end
end
