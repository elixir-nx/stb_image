# StbImage

A tiny image reader/writer library using [stb_image](https://github.com/nothings/stb/blob/master/stb_image.h) as the backend. [See the documentation](https://hexdocs.pm/stb_image).

There is an alternative library, [image_rs](https://github.com/cocoa-xu/image_rs), which uses [image_rs](https://github.com/image-rs/image) as the backend. That backend is implemented in Rust, so you will need a working Rust compiler. But the number of supported image formats is greater than `stb_image`.

## Installation

Add `stb_image` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:stb_image, "~> 0.6"}
  ]
end
```

This library also provides some precompiled binaries for the following platforms:

- macOS
  - x86_64-apple-darwin
  - aarch64-apple-darwin
- Linux
  - x86_64-linux-gnu
  - x86_64-linux-musl
  - aarch64-linux-gnu
  - aarch64-linux-musl
  - riscv64-linux-gnu
  - riscv64-linux-musl
- Windows
  - x86_64-windows-msvc

## License

   Copyright 2022 Cocoa Xu

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
