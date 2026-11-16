---
nav_order: 2
---

# Configuration

A site is configured by `lsdocs.toml`. Paths in it are relative to the
directory it is in, the **site directory**. Unknown keys are errors, so
typos are caught.

```toml
[site]
title = "My Docs"
base_url = "https://example.com/docs/"

[build]
source_dir = "docs"
output_dir = "site"

[[plugins]]
name = "markdown"
builtin = "parser-markdown"

[[plugins]]
name = "html"
builtin = "render-html"
options = { heading_anchors = false }
```

## `[site]`

| Key | Meaning |
|---|---|
| `title` | The site's title, shown by the HTML theme. |
| `base_url` | Where the site is served from. An absolute URL (`https://...`) also lets `render-html` write a sitemap. |
| `theme` | Reserved for themes; not used by the built-in plugins yet. |

## `[build]`

| Key | Default | Meaning |
|---|---|---|
| `source_dir` | `"docs"` | The directory holding the pages and other files. |
| `output_dir` | `"site"` | The directory the site is written to. |

The environment variables `LSDOCS_SOURCE_DIR`, `LSDOCS_OUTPUT_DIR` and
`LSDOCS_BASE_URL` override these settings, and the command-line flags
`--source-dir`, `--output-dir` and `--base-url` override both.

## `[[plugins]]`

Each entry adds a plugin. **Order matters**: the first parser that takes
a file's extension parses it, transformers run in the order listed, and
the first renderer renders the site.

| Key | Meaning |
|---|---|
| `name` | A unique name, used in messages. |
| `builtin` | A plugin that ships with lsdocs, run inside it (see [Built-in plugins](../plugins/index.md)). |
| `command` | A program to run, with its arguments: `["./my-plugin", "--fast"]`. |
| `runtime` | `"python"` with `module` (run as `python -m <module>`), or `"node"` with `entry` (run as `node <entry>`). |
| `transport` | `"stdio"` (the default) or `"pipe"`, for plugins run as programs. |
| `files` | Glob patterns limiting which source files the plugin handles, relative to the source directory: `["api/**"]`. |
| `options` | Anything the plugin accepts, passed to it when it starts. |

Each entry has exactly one of `builtin`, `command` and `runtime`. Plugins
run as programs start in the site directory. `LSDOCS_PYTHON` and
`LSDOCS_NODE` name the interpreters for the `python` and `node` runtimes.
