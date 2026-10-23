defmodule StbImagePathValidationTest do
  use ExUnit.Case, async: true

  alias StbImage.Nif

  @tag :tmp_dir
  test "paths containing null bytes are rejected without truncation", %{tmp_dir: tmp_dir} do
    source = Path.join(__DIR__, "test.png")
    destination = Path.join(tmp_dir, "image.png")

    assert {:error, _} = Nif.read_file(source <> <<0>> <> "suffix", 0)
    assert {:error, _} = Nif.write_file(destination <> <<0>> <> "suffix", :png, <<0>>, 1, 1, 1)
    refute File.exists?(destination)
  end
end
