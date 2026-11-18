# Phase 13 Plugin Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Plugin settings move from `lsdocs.toml`'s `options` into files each plugin reads under `.config/`.

**Architecture:** The host passes `.config/`'s path and the instance name at `initialize`; the plugin reports the files it read (`config_files`), which the host digests into its cache keys. The Rust SDK loads a plugin's settings once at `initialize` through a loader the plugin registers, and hands the loaded value to the syntax/capability closures and to `Context::settings()` (replacing `options()`), so existing plugin code changes little.

**Tech Stack:** Rust workspace (`toml` crate is already a workspace dependency), pyo3, napi-rs, nur.

**Spec:** `docs/superpowers/specs/2026-11-18-phase-13-plugin-config-design.md`

## Global Constraints

- `PROTOCOL_VERSION` stays `"1.0-rc.0"`; `nur gen` after protocol changes.
- `.config/` is next to `lsdocs.toml` (the site root), else the working directory; the host enforces no layout inside it.
- First-party plugins read `.config/lsdocs/<instance>/settings.toml` (parser-rst: `.config/lsdocs/<instance>/docutils.conf`); a missing file means defaults; unknown keys are errors.
- An `options` key in `lsdocs.toml` is an error saying settings moved to the plugin's own files under `.config/`.
- Sample-site snapshots unchanged (its settings move to files with the same values); Python/Node toc ports still byte-identical.
- `nur ci` passes at the end of every task; branch `feat/phase-13-config`, ff-merged into `main`, pushed.

## Review Focus

- A config file created after a cached build (missing → present) must invalidate that plugin's cache: test in Task 1 (`config_file_changes_invalidate_cached_results`).
- A plugin that reads no files reports no `config_files` and caches as before (covered by existing cache tests passing unchanged).
- A malformed `settings.toml` (bad TOML, unknown key) fails `initialize` with an error naming the file: test in Task 1 (`bad_settings_name_the_file`).
- Out-of-process plugins get `config` and return `config_files` over the wire: the in-process/stdio/pipe comparison in `crates/cli/tests/build.rs` must pass with the sample site's settings in files.
- `serve` restarts plugins when a file under `.config/` changes: test in Task 1 (`serve_restarts_on_config_change`, in `crates/cli/tests/serve.rs`).

---

### Task 1: Protocol, config, host, Rust SDK, Rust plugins, sites

**Files:**
- Modify: `crates/protocol/src/lib.rs` (`InitializeParams`, `InitializeResult`, new `ConfigInfo`)
- Modify: `crates/config/src/lib.rs` (drop `options` from the plugin entry and resolved plugin; pointed error)
- Modify: `crates/host/src/plugin.rs`, `crates/host/src/lib.rs`, `crates/host/src/cache.rs`
- Modify: `crates/cli/src/serve.rs`, `crates/cli/src/main.rs` (pass the `.config/` path)
- Modify: `crates/plugin-sdk/src/lib.rs` (+ new `crates/plugin-sdk/src/config.rs`), `crates/sdk-dynamic/src/lib.rs`, bindings' Rust glue (compile only)
- Modify: every first-party plugin reading options (`apidoc-plugin`, `sphinx-addons`, `render-html`, `transform-toc`, `transform-links`, `transform-highlight`; `parser-rst` keeps `file_access` working via settings for now, Task 2 replaces it)
- Create: `examples/sample-site/.config/lsdocs/{sphinx,toc,links}/settings.toml` (the instance names in its `lsdocs.toml`; values from its current `options`), `docs/.config/lsdocs/{python,typescript,rust,c,cpp}/settings.toml`
- Modify: `examples/sample-site/lsdocs.toml`, `docs/lsdocs.toml` (remove `options`), `tools/gen/src/examples.rs`
- Test: `crates/config/src/lib.rs` tests, `crates/plugin-sdk/src/config.rs` tests, `crates/cli/tests/build.rs`, `crates/cli/tests/serve.rs`

**Interfaces:**
- Produces (protocol): `pub struct ConfigInfo { pub dir: String, pub name: String }`; `InitializeParams { protocol_version, host, site, config: ConfigInfo }` (no `options`); `InitializeResult { ..., #[serde(default, skip_serializing_if = "Vec::is_empty")] pub config_files: Vec<String> }`.
- Produces (SDK, `lsdocs_plugin_sdk::config`): `pub struct Loaded { pub settings: Value, pub files: Vec<String> }`; `pub fn toml_file(config: &ConfigInfo, relative: &str) -> Result<Loaded, String>` (reads `<dir>/<relative>` as TOML into a `Value`; missing → `Value::Null` with the file still listed; a parse error names the file); `pub fn recommended(config: &ConfigInfo, file: &str) -> String` → `format!("lsdocs/{}/{file}", config.name)`.
- Produces (SDK, `Plugin`): `pub fn settings(self, loader: impl Fn(&ConfigInfo) -> Result<Loaded, String> + Send + Sync + 'static) -> Self`; the loader runs once at `initialize` (in-process and served); its error fails `initialize`; `InitializeResult.config_files` = `Loaded.files`. `Plugin::syntax` and `capabilities_for` closures receive `&Value` (the loaded settings) instead of `&InitializeParams`. `Context::settings(&self) -> &Value` replaces `Context::options()`.
- Produces (SDK testing): `testing::context` / `context_with_parsers` take the settings `Value` where they took options.
- Produces (host): `PluginEntry`/resolved plugin has no `options`; `Session`/build takes the `.config/` path (`site_root.join(".config")`); cache key folds a blake3 digest of each `config_files` entry (path + contents, or path + "missing").

- [ ] **Step 1:** Branch `feat/phase-13-config`.
- [ ] **Step 2:** Write tests: config `options_key_is_an_error` (an entry with `options = {}` fails, message contains `.config`); SDK `config::tests::reads_toml_and_lists_missing_files` (missing file → `Null`, files == `["lsdocs/x/settings.toml"]`; present file → its table; bad TOML → error containing the file name); cli `config_file_changes_invalidate_cached_results` (build the sample site with cache, change `.config/lsdocs/toc/settings.toml` `depth`, rebuild: output changes); cli `bad_settings_name_the_file` (unknown key in `.config/lsdocs/sphinx/settings.toml` → build fails, stderr names the file); serve `serve_restarts_on_config_change` (edit a `.config` file → log says plugins restarted).
- [ ] **Step 3:** Run `cargo test --workspace`; expected: compile failures (names missing).
- [ ] **Step 4:** Implement per the Interfaces; plugins switch `ctx.options()` → `ctx.settings()`, `init.options` → the closure's `&Value`, and register `.settings(|c| config::toml_file(c, &config::recommended(c, "settings.toml")))`. Plugins whose options struct lacks `deny_unknown_fields` get it (unknown keys are errors). Move the sample site's and docs site's options into the files listed above; `tools/gen` examples use `config`/`config_files`.
- [ ] **Step 5:** `nur gen`; expected: `initialize.*` schema/fixtures change, nothing else.
- [ ] **Step 6:** `nur fmt --check; nur lint; nur test; nur test fixtures; nur check-deps`; expected: pass, snapshots unchanged.
- [ ] **Step 7:** Commit `feat(host): plugin settings in .config/ (Phase 13)`.

### Task 2: parser-rst reads `docutils.conf`

**Files:**
- Create: `plugins/parser-rst/src/conf.rs`
- Modify: `plugins/parser-rst/src/lib.rs` (loader; `file_insertion_enabled` replaces `file_access`), `crates/rst/src/settings.rs` only if a setting must be exposed (prefer not)
- Test: `plugins/parser-rst/src/conf.rs` tests

**Interfaces:**
- Produces: `pub(crate) fn read(text: &str, file: &str) -> Result<(lsdocs_rst::Settings, bool /* file_insertion_enabled */, Vec<String> /* warnings */), String>`; sections read: `general`, `parsers`, `restructuredtext parser`; other sections skipped; INI `key: value` and `key = value`, `#`/`;` comments, booleans as docutils reads them (`1/0, yes/no, true/false, on/off`), keys with `-` or `_` alike.

- [ ] **Step 1:** Tests `reads_known_settings` (`[general]\ntab-width: 4\n[restructuredtext parser]\npep_references = yes` → `tab_width == 4`, `pep_references`), `skips_writer_sections` (`[html writers]\nstylesheet: x` → defaults, no warnings), `warns_on_unimplemented` (`[general]\nsmart_quotes: yes` → one warning naming `smart_quotes`), `file_insertion` (`file_insertion_enabled: no` → false), `bad_value_names_the_file`.
- [ ] **Step 2:** Run `cargo test -p lsdocs-parser-rst conf`; expected FAIL.
- [ ] **Step 3:** Implement; the loader reads `lsdocs/<name>/docutils.conf` via `config::recommended`, warnings logged at initialize (`Loaded.settings` carries the parsed settings as JSON for `ctx.settings()`).
- [ ] **Step 4:** `nur test`; expected PASS.
- [ ] **Step 5:** Commit `feat(parser-rst): docutils settings from docutils.conf`.

### Task 3: Python SDK

**Files:** `bindings/plugin/python/python/lsdocs_plugin/{__init__.py,_native.pyi,testing.py}`, `bindings/plugin/python/src/lib.rs`, `tests/`, `examples/transform_toc.py`

**Interfaces:**
- Produces: `Plugin(..., settings=None)` where `settings` is a callable `(config: dict) -> tuple[Any, list[str]]` (value, files read), run at initialize; `ctx.config` (`{"dir", "name"}`); `ctx.settings` (the loaded value; replaces `ctx.options`); `testing.*(..., settings=...)` replaces `options=`.

- [ ] **Step 1:** Port test and plugin tests use `settings`; the toc port reads `depth` from `.config/lsdocs/toc/settings.toml` with `tomllib`; run `nur test python`; expected FAIL.
- [ ] **Step 2:** Implement; `nur test python`; expected PASS (port byte-identical).
- [ ] **Step 3:** Commit `feat(lsdocs-plugin): settings from .config/`.

### Task 4: Node SDK

**Files:** `bindings/plugin/node/{index.js,index.d.ts,testing.js,testing.d.ts}`, `src/lib.rs` (+ `nur gen node plugin`), `test/`, `examples/transform-toc.js`

**Interfaces:**
- Produces: `definePlugin({ settings?: (config: { dir: string; name: string }) => { value: unknown; files: string[] } })`; `ctx.config`, `ctx.settings` (replaces `ctx.options`); `testing` options `{ site, settings }`.

- [ ] **Step 1:** Tests and the toc port use `settings` (the port parses its small `settings.toml` by hand: one `depth = N` line, no TOML dependency); `nur test node`; expected FAIL.
- [ ] **Step 2:** Implement; `nur test node`; expected PASS.
- [ ] **Step 3:** Commit `feat(@lsdocs/plugin): settings from .config/`.

### Task 5: Spec and docs

**Files:** `spec/wire.md` (Configuration section; initialize params/result), `docs/content/guide/*` (a `.config/` section where configuration is described), `docs/content/plugins/index.md` (each options table titled with its file path), `docs/content/authoring/{rust,python,node}.md`, `docs/content/reference/protocol.md`, `AGENTS.md`, `ROADMAP.md`

- [ ] **Step 1:** Write the prose; sweep: `git grep -nE "ctx\.options|options = \{|init\.options" -- ':!HISTORY.md' ':!docs/superpowers'` → no output.
- [ ] **Step 2:** `nur ci`; expected PASS (docs site builds without warnings).
- [ ] **Step 3:** Commit `docs: plugin settings in .config/`, ff-merge, delete branch, push.
