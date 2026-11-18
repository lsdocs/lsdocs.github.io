# Phase 13 Protocol Renames Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the build's protocol methods to `parse/transform/each`, `parse/transform/all`, `render/transform/each`, `render/transform/all` and `host/parse`, everywhere, with behavior unchanged.

**Architecture:** A mechanical rename. The protocol's `requests!` macro holds the method strings and type names; everything else (host, Rust SDK, `sdk-dynamic`, bindings, plugins, generated schema and fixtures, docs) follows. The Rust workspace must compile as one, so all Rust lands in Task 1; the Python and Node layers and the prose follow.

**Tech Stack:** Rust workspace, pyo3 (Python SDK), napi-rs (Node SDK), nushell `nur` tasks.

**Spec:** `docs/superpowers/specs/2026-11-18-phase-13-protocol-renames-design.md`

## Global Constraints

- `PROTOCOL_VERSION` stays `"1.0-rc.0"`.
- No aliases or shims for old names.
- Behavior unchanged: same passes, order, caching; sample-site snapshots unchanged.
- Python and Node `transform-toc` ports still render the sample site byte-identically.
- `nur ci` passes at the end of every task; one branch `feat/phase-13-renames`, ff-merged to `main`, pushed.
- Don't touch the user's uncommitted edits to `docs/lsdocs.toml` and `nurfile` (stash or leave unstaged; never commit them).

## The names (decided)

| Old | New |
|---|---|
| method `transform/collect` | `parse/transform/each` |
| method `transform/collected` | `parse/transform/all` |
| method `transform/apply` | `render/transform/each` |
| method `render/site` | `render/transform/all` |
| method `site/parse` | `host/parse` |
| `request::TransformCollect`, `TransformCollectParams`, `TransformCollectResult` | `request::ParseTransformEach`, `ParseTransformEachParams`, `ParseTransformEachResult` |
| `request::TransformCollected`, `TransformCollectedParams`, `TransformCollectedResult` | `request::ParseTransformAll`, `ParseTransformAllParams`, `ParseTransformAllResult` |
| `request::TransformApply`, `TransformApplyParams`, `TransformApplyResult` | `request::RenderTransformEach`, `RenderTransformEachParams`, `RenderTransformEachResult` |
| `request::RenderSite`, `RenderSiteParams`, `RenderSiteResult` | `request::RenderTransformAll`, `RenderTransformAllParams`, `RenderTransformAllResult` |
| `request::SiteParse`, `SiteParseParams` | `request::HostParse`, `HostParseParams` |
| `TransformCapability.collect: bool` (wire `collect`) | `each: bool` (wire `each`) |
| `RenderCapability.site: bool` (wire `site`) | `all: bool` (wire `all`) |
| Rust SDK `Transformer::COLLECTS`, `collect`, `generate`, `apply` | `Transformer::READS`, `read`, `conclude`, `apply` |
| Rust SDK `Renderer::SITE`, `render_site` | `Renderer::RENDERS_ALL`, `render_all` |
| Rust SDK `Plugin::collect`, `generate`, `apply`, `render_site` (in-process entry points) | `Plugin::read`, `conclude`, `apply`, `render_all` |
| Python `@plugin.collect`, `@plugin.render_site` | `@plugin.read`, `@plugin.render_all` (`@plugin.transform` stays: it is the apply hook) |
| Node handler keys `collect`, `renderSite`; capability `{ nodes, collect }` | `read`, `renderAll`; `{ nodes, each }` |

Unchanged: `parse`, `render`, `initialize`, `shutdown`, `Context::parse` / `EventSink::parse` (they now send `host/parse`), and data field names such as `collected` in the apply params (data, not a method).

## Review Focus

- A plugin declaring `transform: { nodes: [...] }` without `each` must still get only `render/transform/each` — pinned by the existing host tests; check they still assert it after the rename.
- Out-of-process plugins (stdio, pipe) must answer the new method strings: `crates/cli/tests/build.rs` compares in-process/stdio/pipe output byte for byte; it must pass unchanged.
- The no-SDK Python plugin `examples/plugins/txt-parser` speaks raw method strings: update it, and `crates/cli/tests/no_sdk_plugin.rs` must pass.
- Leftover old strings in error messages (`phase_error("render/site", ...)`) would mislead users: Task 4's grep catches them.
- Fixture file names under `fixtures/` derive from method names: `nur gen` must delete stale ones (check `git status` shows removals, not only additions).

---

### Task 1: Rust: protocol, SDK, host, plugins, generated files

**Files:**
- Modify: `crates/protocol/src/lib.rs` (the `requests!` list, the param/result structs, `TransformCapability`, `RenderCapability`, module docs)
- Modify: `crates/plugin-sdk/src/lib.rs`, `crates/plugin-sdk/src/links.rs` (if it names them), `crates/sdk-dynamic/src/*.rs`
- Modify: `crates/host/src/lib.rs`, `crates/host/src/plugin.rs`, `crates/host/src/cache.rs`
- Modify: every `plugins/*/src` using the old types or trait items; `crates/apidoc-plugin/src/lib.rs`
- Modify: `bindings/plugin/python/src/lib.rs`, `bindings/plugin/node/src/lib.rs` (Rust glue only; exported names they pass to Python/JS change in Tasks 2-3)
- Modify: `tools/gen/src/*.rs`, `examples/plugins/txt-parser/*`
- Regenerate: `schema/`, `fixtures/` (`nur gen`)

**Interfaces:**
- Produces: the names in the table above, exactly.

- [ ] **Step 1:** Create branch `feat/phase-13-renames`.
- [ ] **Step 2:** Add a protocol test `method_names` in `crates/protocol/src/lib.rs` tests asserting `request::ParseTransformEach::METHOD == "parse/transform/each"`, `ParseTransformAll::METHOD == "parse/transform/all"`, `RenderTransformEach::METHOD == "render/transform/each"`, `RenderTransformAll::METHOD == "render/transform/all"`, `HostParse::METHOD == "host/parse"`, and that `TransformCapability { each: true, .. }` serializes with key `each` and `RenderCapability { all: true, .. }` with key `all`.
- [ ] **Step 3:** Run `cargo test -p lsdocs-protocol method_names`; expected: compile FAIL (names don't exist).
- [ ] **Step 4:** Rename in the protocol, then fix every compile error across the workspace (`cargo check --workspace --all-targets`), renaming the SDK trait items and in-process entry points per the table, updating doc comments and error-message strings to the new method names.
- [ ] **Step 5:** Update `examples/plugins/txt-parser` method strings if it handles any renamed method.
- [ ] **Step 6:** Run `nur gen`; expected: `schema/` and `fixtures/` regenerated, `git status` shows old-named fixtures deleted.
- [ ] **Step 7:** Run `nur ci` minus Python/Node (`nur fmt --check; nur lint; nur test; nur test fixtures; nur check-deps`); expected: all pass, snapshots unchanged.
- [ ] **Step 8:** Commit `refactor(protocol): rename pipeline methods (Phase 13)`.

### Task 2: Python SDK

**Files:**
- Modify: `bindings/plugin/python/python/lsdocs_plugin/__init__.py`, `_native.pyi`, `testing.py`, `examples/transform_toc.py`, `tests/test_plugin.py`, `bindings/plugin/python/README.md` (if present)

**Interfaces:**
- Consumes: Task 1's Rust glue names.
- Produces: `Plugin.read` (decorator, as `collect` was), `Plugin.render_all` (as `render_site` was); `testing` helpers renamed to match (`testing.read` for `testing.collect`, `testing.render_all` for `testing.render_site`, where those exist).

- [ ] **Step 1:** Rename in the tests first (`tests/test_plugin.py`, example), run `nur test python plugin`; expected FAIL (no attribute `read`).
- [ ] **Step 2:** Rename in the package and stub.
- [ ] **Step 3:** Run `nur test python`; expected: PASS, including the byte-identical port test.
- [ ] **Step 4:** Commit `refactor(lsdocs-plugin): follow the renamed pipeline methods`.

### Task 3: Node SDK

**Files:**
- Modify: `bindings/plugin/node/index.js`, `index.d.ts`, `testing.js`, `testing.d.ts`, `examples/transform-toc.js`, `test/plugin.test.js`; regenerate `native.js` / `native.d.ts` (`nur gen node plugin`) if the `#[napi]` API changed in Task 1

**Interfaces:**
- Produces: handler keys `read`, `renderAll`; capability `transform?: { nodes?: string[]; each: boolean }`, `render?: { formats: string[]; all?: boolean }`.

- [ ] **Step 1:** Rename in the test and example; run `nur test node plugin`; expected FAIL.
- [ ] **Step 2:** Rename in the package and `.d.ts` files; regenerate native files if needed.
- [ ] **Step 3:** Run `nur test node`; expected: PASS, including the byte-identical port test and the type check.
- [ ] **Step 4:** Commit `refactor(@lsdocs/plugin): follow the renamed pipeline methods`.

### Task 4: Spec, docs, roadmap; final sweep

**Files:**
- Modify: `spec/wire.md`, `docs/content/**` (authoring guides, `reference/protocol.md`), `AGENTS.md`, `ROADMAP.md` (Phase 13: record the names and SDK names as decisions; replace `render/site` mentions in 13b), `HISTORY.md` untouched (it is history)

- [ ] **Step 1:** Rename in the prose.
- [ ] **Step 2:** Run the sweep; expected: no output.

```bash
git grep -nE "transform/collect|transform/apply|render/site|site/parse|TransformCollect|TransformApply|RenderSite|SiteParse|render_site|renderSite|COLLECTS" -- ':!HISTORY.md' ':!docs/superpowers'
```

- [ ] **Step 3:** Run full `nur ci`; expected: PASS, docs site builds without warnings.
- [ ] **Step 4:** Commit `docs: the renamed pipeline methods`, ff-merge `feat/phase-13-renames` into `main`, delete the branch, push `main`.
