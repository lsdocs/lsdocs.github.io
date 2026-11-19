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
```

with the plugins' settings in files of their own beside it (see
[Plugin settings](#plugin-settings)):

```toml
# .config/lsdocs/html/settings.toml
heading_anchors = false
```

## `[site]`

| Key | Meaning |
|---|---|
| `title` | The site's title, shown by the HTML theme. |
| `base_url` | Where the site is served from. An absolute URL (`https://...`) also lets `render-html` write a sitemap. |

## `[build]`

| Key | Default | Meaning |
|---|---|---|
| `source_dir` | `"docs"` | The directory holding the pages and other files. |
| `output_dir` | `"site"` | The directory the site is written to. |

The environment variables `LSDOCS_SOURCE_DIR`, `LSDOCS_OUTPUT_DIR` and
`LSDOCS_BASE_URL` override these settings, and the command-line flags
`--source-dir`, `--output-dir` and `--base-url` override both.

The HTML theme is not chosen here but in render-html's settings
(`theme = "plain"` in `.config/lsdocs/html/settings.toml`; see
[render-html](../plugins/index.md#render-html)); a `theme` key under
`[site]` is an error.

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

Each entry has exactly one of `builtin`, `command` and `runtime`. Plugins
run as programs start in the site directory. `LSDOCS_PYTHON` and
`LSDOCS_NODE` name the interpreters for the `python` and `node` runtimes.

## Plugin settings

A plugin's settings are not in `lsdocs.toml`: each plugin reads its own
files from the `.config/` directory next to it (or in the working
directory, without a config file), in whatever format it chooses. lsdocs'
own plugins read `.config/lsdocs/<name>/settings.toml`, `<name>` being
the plugin's `name` above, so two instances of one plugin keep separate
settings:

```toml
# .config/lsdocs/toc/settings.toml
depth = 2
```

parser-rst reads docutils' `docutils.conf` there instead (see
[Built-in plugins](../plugins/index.md#parser-rst)). Plugins read their
settings when they start; a change to a settings file is a change of
settings (cached results are not reused, and `lsdocs serve` restarts the
plugins). Paths in settings are relative to the site directory.
