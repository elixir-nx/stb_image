defmodule ImgDecode.Nif do
  @moduledoc false
  
  use Rustler, otp_app: :img_decode, crate: "img_decode"

  def from_file(_filename), do: :erlang.nif_error(:not_loaded)
  def from_memory(_buffer), do: :erlang.nif_error(:not_loaded)
end
