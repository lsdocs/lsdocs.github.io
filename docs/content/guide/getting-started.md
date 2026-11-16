---
nav_order: 1
---

# Getting started

## Install

lsdocs is not published yet. Build it from a checkout of the repository
with a stable Rust toolchain:

```sh
cargo install --path crates/cli
```

This installs the `lsdocs` command.

## Create a site

```sh
lsdocs init my-docs
```

creates `my-docs/lsdocs.toml`, with the built-in plugins, and
`my-docs/docs/index.md`. Pages go under `docs/`, in Markdown (`.md`) or
reStructuredText (`.rst`); anything else there, such as images, is copied
to the output as it is.

## Build

```sh
lsdocs build
```

writes the site to `site/`. Problems in the pages, such as a link to a
missing file, are reported with their location; errors make the command
fail. `--config` points at another configuration file, and
`--output-dir`, `--source-dir` and `--base-url` override the
configuration.

Results are cached in `.lsdocs-cache/` next to the configuration, so
rebuilding unchanged pages is quick. `--no-cache` skips the cache.

## Serve

```sh
lsdocs serve
```

builds the site, serves it on <http://127.0.0.1:8000> (`--port` and
`--host` change that), and rebuilds and reloads the open page whenever a
source file, the configuration or a template changes.

## Troubleshooting

`-v` (or `-vv`) shows more of what lsdocs does, and `--trace-rpc` logs every
message exchanged with plugins, which helps when writing one.
