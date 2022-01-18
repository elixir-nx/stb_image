# StbImage-Elixir

A tiny Elixir library for image decoding task using [stb_image](https://github.com/nothings/stb/blob/master/stb_image.h) as the backend.

There is an alternative version of this repo, [image_rs](https://github.com/cocoa-xu/image_rs), which uses [image_rs](https://github.com/image-rs/image) as the backend. 
That backend is implemented in Rust, so you will need a working Rust compiler. But the number of supported image formats are more than the `stb_image` backend.

| OS               | Build Status |
|------------------|--------------|
| Ubuntu 20.04     | [![CI](https://github.com/cocoa-xu/stb_image/actions/workflows/linux.yml/badge.svg)](https://github.com/cocoa-xu/stb_image/actions/workflows/linux.yml) |
| macOS 11         | [![CI](https://github.com/cocoa-xu/stb_image/actions/workflows/macos.yml/badge.svg)](https://github.com/cocoa-xu/stb_image/actions/workflows/macos.yml) |

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `stb_image` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:stb_image, "~> 0.1.1", github: "cocoa-xu/stb_image"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/stb_image](https://hexdocs.pm/stb_image).

