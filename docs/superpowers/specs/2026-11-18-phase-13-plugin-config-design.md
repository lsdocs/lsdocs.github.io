# Phase 13, part 2: per-plugin configuration in `.config/`

## Intent

Every plugin gets its own configuration, in files of its own, instead of
an `options` table in `lsdocs.toml`. Long inline tables are hard to write
and read (the docs site's apidoc entries showed it), and "everything is a
plugin" means each plugin owns its settings and their format: parser-rst
takes a docutils configuration, sphinx-addons and render-html files of
their own, and (part 3) each theme its settings.

## Decided (with the user)

- **`options` goes away** from `lsdocs.toml` entirely; it keeps `[site]`,
  `[build]` and the plugin list (name, builtin / command / runtime,
  transport settings).
- **Plugins read their own files**, in any format they choose. The host
  never opens them; it only says where they are.
- **The directory:** `.config/` next to `lsdocs.toml` (the site
  directory, which relative paths already start from); the working
  directory only when there is no config file.
- **The layout inside it is the plugin's business.** The host knows only
  `.config/`; it neither enforces nor computes a structure. The
  recommendation (in the docs, and what first-party plugins do) is
  `.config/<vendor>/<instance>/`, e.g. `.config/lsdocs/render-html/`,
  named after the plugin's `name` in `lsdocs.toml` so two instances of
  one plugin (`c` and `cpp`) have separate settings.
- **Changes take effect:** the plugin tells the host which files it read;
  the host digests them into that plugin's cache keys, and
  `lsdocs serve` watches `.config/`.

## Design

### Protocol

- `InitializeParams.options` is removed. It gains
  `config: ConfigInfo { dir: String, name: String }`: the absolute path
  of `.config/` (whether or not it exists) and the plugin's instance name
  (for plugins following the recommended layout).
- `InitializeResult` gains `config_files: Vec<String>` (omitted when
  empty): the files the plugin read its settings from, absolute or
  relative to `.config/`, including ones it looked for and did not find
  (so creating one counts as a change). The host digests them (contents,
  or "missing") into the plugin's cache keys, where `options` was.
- `PROTOCOL_VERSION` stays `1.0-rc.0`; schema and fixtures regenerate;
  `spec/wire.md` gets a "Configuration" section saying the above.

### Host

- `lsdocs-config` drops `options` (an `options` key is now an unknown
  field: an error, since `lsdocs.toml` rejects unknown keys). The error
  says where settings go now: "plugin `x`: `options` moved to the
  plugin's own files under `.config/` (see ...)" (my call: a pointed message, since
  every existing site hits it once).
- After `initialize`, the host digests the plugin's `config_files` (by
  path and contents, or as missing) and folds that into the plugin's
  cache key where `options` was.
- `lsdocs serve` restarts the plugins when anything under `.config/`
  changes, as it does when `lsdocs.toml` changes. Plugins read their
  settings once, at startup (my call: simpler than reloading, and serve
  already restarts on config changes).

### SDKs

- **Rust:** `Context::config() -> &ConfigInfo` (the `.config/` path and
  the instance name), and a helper for the recommended layout,
  `Context::settings::<T: DeserializeOwned + Default>(path: &str) ->
  PluginResult<T>`: reads `<.config>/<path>` as TOML (the plugin builds
  the path, e.g. `format!("lsdocs/{}/settings.toml", name)`),
  `T::default()` when missing, an error naming the file and the key on a
  bad or unknown key, and records the file for `config_files`.
  `Context::options()` is removed. How a plugin reads settings at
  startup and reports `config_files` is the SDK's to make easy (a hook
  run at `initialize`), left to the builder.
- **Python / Node:** `ctx.config` (`dir` and `name`) and a way to report
  the files read. No TOML helper (Python has `tomllib`; Node plugins pick
  a reader). `ctx.options` is removed.

### First-party plugins

Each reads `.config/lsdocs/<instance>/settings.toml` (my call on the file
name: one obvious name per plugin; unknown keys are errors, as the user
wants nothing silently ignored), with today's options as its keys and
today's defaults:

| Plugin | File | Keys |
|---|---|---|
| parser-rst | `docutils.conf` | docutils' INI format: `[general]`, `[parsers]`, `[restructuredtext parser]` sections; the settings `lsdocs_rst::Settings` has, plus `file_insertion_enabled` (replacing the `file_access` option) |
| sphinx-addons | `settings.toml` | today's options (`tags`, `todo_include_todos`, `numfig`, ...) |
| apidoc-* | `settings.toml` | today's options (`paths`, `output`, ...) |
| transform-toc, transform-links, transform-highlight, render-html | `settings.toml` | today's options |
| parser-markdown, transform-nav | none | (no options today) |

For parser-rst (my calls): settings lsdocs-rst knows are applied;
docutils settings it does not implement, in those sections, are a
warning naming the setting; other sections (writers, ...) are not the
parser's and are skipped, so a project's existing `docutils.conf` works
unchanged.

### Sites, tests, docs

- The docs site and the sample site move their options into
  `docs/.config/lsdocs/<instance>/settings.toml` (and the like); tests
  that build sites with options write those files.
- `lsdocs init` writes no `.config/` (defaults apply).
- The docs: a "Configuration" page section on `.config/`; each plugin's
  options table becomes a `settings.toml` table with its path; the
  authoring guides show `config_dir` / `settings`.
- `AGENTS.md` and `ROADMAP.md` (13a: the theme-settings question becomes
  "a theme's settings live in render-html's directory").

## Goals

- No plugin setting in `lsdocs.toml`; every first-party plugin reads its
  own directory; config edits invalidate the cache and restart `serve`.

## Non-goals

- Themes (part 3), and render-html's theme settings.
- A config format for the host itself (`lsdocs.toml` stays).
- Compatibility with `options` (nothing is published).

## Anti-goals

- A setting silently ignored: unknown keys in a plugin's own files are
  errors (parser-rst's docutils settings it does not implement: warnings).

## Approaches

- **Plugins read their files; the host passes paths** (chosen by the
  user): any format, plugins own their settings; each SDK offers the
  path, Rust a TOML helper.
- The host reads `<name>.toml` and passes it as options: one format,
  host-side validation, but docutils settings would have to be TOML.
- Both: rejected as two places to look.

## Left to the builder

- Where in the host the directory digest lives (next to the cache key
  code in `crates/host/src/cache.rs` is the obvious place).
- How the serve watcher includes `.config/` (its `Snapshot` takes extra
  paths already).
- Exact error wording, beyond the `options` pointer above.
