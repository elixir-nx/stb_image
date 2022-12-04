## Release with Precompilation Binaries

The overall steps to release `StbImage` with its precompilation binaries are:

1. `git tag NEW_VERSION`
2. `git push --tags` and wait for workflows to run
3. `mix elixir_make.checksum`
4. `mix hex.publish`
