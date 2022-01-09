# ImgDecode

A tiny Elixir library for image decoding task.

Currently available backends

- [stb_image](https://github.com/nothings/stb/blob/master/stb_image.h).
- [image_rs](https://github.com/image-rs/image).

| OS               | Build Status |
|------------------|--------------|
| Ubuntu 20.04     | [![CI](https://github.com/cocoa-xu/img_decode/actions/workflows/linux.yml/badge.svg)](https://github.com/cocoa-xu/img_decode/actions/workflows/linux.yml) |
| macOS 11         | [![CI](https://github.com/cocoa-xu/img_decode/actions/workflows/macos.yml/badge.svg)](https://github.com/cocoa-xu/img_decode/actions/workflows/macos.yml) |

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `img_decode` to your list of dependencies in `mix.exs`:

Use `stb_image` as backend
```elixir
def deps do
  [
    {:img_decode, "~> 0.1.0", github: "cocoa-xu/img_decode", sparse: "stb_image"}
  ]
end
```

Or use `image_rs` as backend
```elixir
def deps do
  [
    {:img_decode, "~> 0.1.0", github: "cocoa-xu/img_decode", sparse: "image_rs"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/img_decode](https://hexdocs.pm/img_decode).

