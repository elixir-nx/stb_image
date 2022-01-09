# NIF for Elixir.ImgDecode.Nif

## To build the NIF module:

- Your NIF will now build along with your project.

## To load the NIF:

```elixir
defmodule ImgDecode.Nif do
    use Rustler, otp_app: :image_elixir, crate: "imageelixir"

    # When your NIF is loaded, it will override this function.
    def from_file(_filename), do: :erlang.nif_error(:nif_not_loaded)
    def from_memory(_buffer), do: :erlang.nif_error(:nif_not_loaded)
end
```

