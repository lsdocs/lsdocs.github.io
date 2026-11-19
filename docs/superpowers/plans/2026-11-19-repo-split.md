# Repository Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The monorepo's parts become sibling repositories under `C:\dev\` (GitHub org `lsdocs`), each passing its own `nur ci`, linked by Cargo git dependencies.

**Architecture:** Changes every repository needs (the `sdk-dynamic` rename, built-ins behind features) land in the monorepo first, so they are tested together. A nu script (`nur split <repo>`) extracts each repository with `git filter-repo` from a path map, then adds a shared skeleton (mise, nurfile tasks, CI, AGENTS.md). Until the user creates and pushes the GitHub repositories, repositories build against their local siblings through `nur link` (`[patch]` entries in an untracked `.cargo/config.toml`); dependency declarations are already the final git URLs.

**Tech Stack:** nushell + nur, git-filter-repo (installed with `uv tool install git-filter-repo`), Cargo git dependencies and `[patch]`, mise, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-11-19-repo-split-design.md`

## Global Constraints

- Repositories live at `C:\dev\<repo>`; git URLs are `https://github.com/lsdocs/<repo>`; dependencies are `{ git = "https://github.com/lsdocs/<repo>", branch = "main" }` with `Cargo.lock` committed.
- Never delete, overwrite or write into `C:\dev\lsdocs-legacy-attempt`, `C:\dev\lsdocs-org`, or the monorepo's history; the monorepo (`C:\dev\claude\lsdocs`) is only added to (Tasks 1-2), never rewritten.
- Nothing is published; nothing is pushed anywhere without the user's go-ahead (Task 9 pushes, after asking).
- Crate names stay, except `lsdocs-sdk-dynamic` -> `lsdocs-plugin-sdk-bindings`.
- Every repository: `nurfile` (`nur ci` = what CI runs), `mise.toml`, `rust-toolchain.toml`, `rustfmt.toml`, `.gitattributes`, `.editorconfig`, both licenses, the workspace lints, `AGENTS.md`, README with "Known limitations" and "TODO" sections.
- `rust-version` per crate as today (1.89 base; apidoc languages 1.97); `PROTOCOL_VERSION` stays `"1.0-rc.0"`.
- Conventional Commits, LF, ASCII-only docs/comments; no unwrap/expect/panic outside tests.

## Review Focus

- A build with two copies of one lsdocs crate (a `[patch]` applied in one repository but not in a dependency's, or a path and a git source side by side) must fail CI, not compile oddly: every repository's `nur ci` runs `nur check-dupes` (Task 2), tested in `scripts/tests/split.nu` (`dupes_are_reported`).
- `nur split` aimed at an existing directory (e.g. `C:\dev\lsdocs-legacy-attempt`) must refuse before touching anything: test `refuses_an_existing_target` (Task 2).
- A repository that only builds because of local `[patch]` entries (a misspelled git URL, a repository name not in the map) must be caught before pushing: `nur check-git-deps` (Task 2) validates every lsdocs dependency against the map; test `git_deps_must_name_mapped_repos`.
- The toc ports must still match the Rust plugins byte for byte on the new fixture site (Task 4's port tests).
- No roadmap TODO area may be left without a home: `nur split notes` (Task 2) lists each `### ` area under the roadmap's TODO list with its target repository, failing on an unmapped one; test `every_todo_area_has_a_repo`.

---

### Task 1: Pre-split changes in the monorepo

**Files:**
- Rename: `crates/sdk-dynamic` -> `crates/plugin-sdk-bindings` (package `lsdocs-plugin-sdk-bindings`, lib `lsdocs_plugin_sdk_bindings`); update `Cargo.toml`, `bindings/plugin/*/Cargo.toml`, their `use` lines, `scripts/check-deps.nu`, `AGENTS.md`
- Modify: `crates/cli/Cargo.toml`, `crates/cli/src/main.rs` (every built-in plugin optional, behind a feature named after its builtin: `parser-markdown`, `parser-rst`, `sphinx-addons`, `extras`, `transform-toc`, `transform-links`, `transform-nav`, `transform-highlight`, `render-html`, plus the existing `apidoc-*`; all in `default`)
- Modify: `crates/cli/tests/*.rs` (gate tests needing plugins with `#![cfg(feature = "...")]` or per-test `#[cfg]`), `nurfile` (`nur test` also runs `cargo test -p lsdocs --no-default-features`)

**Interfaces:**
- Produces: features as listed; `lsdocs --no-default-features` builds and its unit tests pass with no builtins (`Builtins` empty; `lsdocs init`'s starter config unchanged).

- [ ] **Step 1:** Branch `chore/pre-split`. Test `cli::builtins_follow_features` in `crates/cli/src/main.rs`: with default features, the builtin names equal the current list (`apidoc-c, apidoc-cpp, apidoc-python, apidoc-rust, apidoc-typescript, extras, parser-markdown, parser-rst, render-html, sphinx-addons, transform-highlight, transform-links, transform-nav, transform-toc`).
- [ ] **Step 2:** `cargo test -p lsdocs --no-default-features`; expected: compile failure (plugins not optional yet).
- [ ] **Step 3:** Implement the features and the rename; `nur check-deps` rule key renamed.
- [ ] **Step 4:** `nur ci` and `cargo test -p lsdocs --no-default-features`; expected PASS.
- [ ] **Step 5:** Commit `refactor: rename sdk-dynamic, built-ins behind features`; ff-merge, push `main` (standing rule).

### Task 2: The split tooling

**Files:**
- Create: `tools/split/repos.nuon` (the map: per repository `name`, `paths` (monorepo paths kept), `renames` (`{from: to}` applied by filter-repo), `deps` (repository names it depends on), `todo_areas` (roadmap TODO headings it owns), `features` (`python`, `node`, `nightly`, `libclang`, `pages`: what its mise/CI need))
- Create: `tools/split/skeleton/` (templates: `mise.toml`, `nurfile.common.nu` with `link`, `unlink`, `bump`, `check-dupes`, `check-git-deps`, `.github/workflows/ci.yml`, `.github/workflows/pages.yml` (for `pages`), `AGENTS.md` common part, `.gitignore` including `.cargo/config.toml`), copies of `rust-toolchain.toml`, `rustfmt.toml`, `.gitattributes`, `.editorconfig`, licenses, `deny.toml`
- Create: `scripts/split.nu`, `scripts/tests/split.nu`; Modify: `nurfile` (`nur split <repo>`, `nur split notes`, `nur test scripts` runs the new tests)

**Interfaces:**
- Produces: `nur split <repo> [--dest C:\dev]`: refuses if `<dest>/<repo>` exists; clones the monorepo to it, runs `git filter-repo --force` with `--path` per `paths` and `--path-rename` per `renames`, then adds the skeleton (rendered for the repository's `features` and `deps`) and writes a workspace `Cargo.toml` whose lsdocs dependencies are git URLs from `deps`, committed as `chore: split from lsdocs <monorepo short sha>`; it does not push and sets no remote except `origin = https://github.com/lsdocs/<repo>`.
- Produces (in every split repository's nurfile): `nur link <path>` (adds `[patch."https://github.com/lsdocs/<name>"]` with a `path` for each crate of the checkout at `<path>` to `.cargo/config.toml`), `nur unlink [name]`, `nur bump [crate]` (`cargo update -p`), `nur check-dupes` (fails if `cargo tree -d -e normal,build` lists any `lsdocs-*` crate), `nur check-git-deps` (fails unless every `lsdocs-*` dependency is `git = "https://github.com/lsdocs/<repo>"` with `<repo>` in the map and owning that crate), all run by `nur ci` except link/unlink/bump.
- Produces: `nur split notes`: prints `area -> repo` for every `### ` heading under `## TODO list` in `ROADMAP.md`; fails on an area no repository lists.

- [ ] **Step 1:** Tests in `scripts/tests/split.nu`: `refuses_an_existing_target` (a temp dir that exists -> error, dir untouched), `git_deps_must_name_mapped_repos` (a manifest with `git = "https://github.com/lsdocs/nope"` -> error naming `nope`), `dupes_are_reported` (sample `cargo tree -d` text with `lsdocs-protocol v0.1.0 (https://...)` -> error), `every_todo_area_has_a_repo` (a roadmap with an unmapped area -> error naming it), `the_map_covers_every_crate` (every workspace member's manifest path is in exactly one repository's `paths`, except `examples/sample-site` and `docs/`'s API settings, which are dropped).
- [ ] **Step 2:** `nur test scripts`; expected FAIL.
- [ ] **Step 3:** Implement; install `git-filter-repo` (`uv tool install git-filter-repo`) and list it in the monorepo AGENTS.md's "Needs" (the skeleton's `mise.toml` does not need it).
- [ ] **Step 4:** `nur test scripts` PASS; dry run `nur split lsdocs-doctree --dest <scratch>` and inspect: history only touches `crates/doctree`, skeleton present, `cargo build` works; delete the scratch copy.
- [ ] **Step 5:** Commit `feat(scripts): nur split`; ff-merge, push `main`.

### Task 3: Bottom layer: `lsdocs-doctree`, `lsdocs-protocol`

**Files (new repositories):** `C:\dev\lsdocs-doctree`, `C:\dev\lsdocs-protocol` (with `tools/gen`, `spec/`, `schema/`, `fixtures/`, `scripts/check-fixtures.nu`, a release workflow on `v*` tags attaching `schema.tar.gz`); both with an `api/` site (`pages`: apidoc-rust over their crates)

- [ ] **Step 1:** `nur split lsdocs-doctree`; `nur split lsdocs-protocol`; in `lsdocs-protocol`, `nur link ../lsdocs-doctree`.
- [ ] **Step 2:** In each: README with Known limitations / TODO (from the roadmap areas `repos.nuon` assigns, the "Protocol and host" items that concern the protocol, and the commit-body pass: `git log --format=%B -- .` read for notes still open); AGENTS.md (layout, tasks, wire format rules for protocol).
- [ ] **Step 3:** `nur ci` in each; expected PASS (protocol: `nur gen` leaves `schema/` and `fixtures/` unchanged, `nur test fixtures` passes).
- [ ] **Step 4:** Commit in each `docs: README, AGENTS.md`.

### Task 4: `lsdocs-plugin-sdk`

**Files:** `C:\dev\lsdocs-plugin-sdk`: `crates/{rpc,plugin-sdk,plugin-sdk-bindings}`, `bindings/{python,node}` (from `bindings/plugin/*`), the uv workspace root (`pyproject.toml`, `uv.lock` for its one Python member), `fixtures/site/` (new: a small site with headings to three levels, a code block, a link, two pages), `nurfile` with `test python` / `test node` / `gen node`, `api/` site config (`pages`: apidoc-python, -typescript, -rust over its own crates)

**Interfaces:**
- Consumes: Task 2's skeleton; `lsdocs` binary for the port tests: `nur test python` / `node` run `cargo install --git https://github.com/lsdocs/lsdocs --root <cache> lsdocs` with `--config` patches pointing this repository's crates at the checkout (and, while unpushed, `nur link`-style patches for all siblings), then set `LSDOCS_BIN`.

- [ ] **Step 1:** `nur split lsdocs-plugin-sdk`; `nur link` doctree and protocol.
- [ ] **Step 2:** Port tests render `fixtures/site/` with the Python/Node toc ports and with the Rust `transform-toc`, asserting byte-identical output (replacing the sample site); see them pass with a locally built `lsdocs` (from the monorepo for now, `LSDOCS_BIN`).
- [ ] **Step 3:** README sections (SDK bindings' TODO area, "Plugin SDK bindings" items), AGENTS.md (bindings rules from today's AGENTS.md), API site builds without warnings (`nur docs`).
- [ ] **Step 4:** `nur ci` PASS (including `test python`, `test node`, `check-dupes`, `check-git-deps`).
- [ ] **Step 5:** Commit.

### Task 5: Parsers: `lsdocs-rst`, `lsdocs-markdown`

**Files:** `C:\dev\lsdocs-rst` (`crates/rst`, `plugins/parser-rst`, `bindings/{python,node}` from `bindings/rst/*`, `scripts/rst-*.py`, conformance cases, `nur gen rst`, `nur fuzz rst`, `DOCUTILS`/`PILLOW` pins, `api/` site), `C:\dev\lsdocs-markdown`

- [ ] **Step 1:** `nur split` both; `nur link` their dependencies.
- [ ] **Step 2:** README sections: `lsdocs-rst` gets the "`lsdocs-rst`", "`lsdocs-rst` bindings" and "`parser-rst`" areas plus `plugins/parser-rst/README.md`'s known differences; markdown the Markdown items of "`sphinx-addons` and syntax extensions" (colon fences, `(label)=`).
- [ ] **Step 3:** `nur ci` PASS in each (rst: conformance cases, Python/Node binding tests; `nur gen rst` unchanged output).
- [ ] **Step 4:** Commit.

### Task 6: API docs: `lsdocs-apidoc` and the four languages

**Files:** `C:\dev\lsdocs-apidoc` (`crates/apidoc`, `crates/apidoc-plugin`), `C:\dev\lsdocs-apidoc-{python,typescript,rust,clang}` (clang with `examples/clang-sample` and its `api/` site)

- [ ] **Step 1:** `nur split` each; `nur link` dependencies.
- [ ] **Step 2:** `apidoc-rust`'s `the_nightly_is_named_the_same_everywhere` reads this repository's README, `mise.toml` and CI workflow only; `mise.toml` pins the nightly (`nightly-2026-11-14`).
- [ ] **Step 3:** README sections; `nur ci` PASS in each (rust needs the nightly, clang libclang; both documented in README).
- [ ] **Step 4:** Commit.

### Task 7: Plugins

**Files:** `C:\dev\lsdocs-{sphinx-addons,extras,render-html,transform-toc,transform-links,transform-nav,transform-highlight}`; render-html keeps `themes/` with `nur gen theme` / `nur test theme` and gains snapshot tests over `tests/site/` (new, small: admonition, code block, tab set, footnote, two levels of headings, nav) rendering through the plugin with `lsdocs_plugin_sdk::testing`, no CLI.

- [ ] **Step 1:** `nur split` each; `nur link` dependencies.
- [ ] **Step 2:** render-html: snapshot test `renders_the_test_site` for both themes, recorded with insta and read.
- [ ] **Step 3:** README sections ("`sphinx-addons` and syntax extensions" non-Markdown items, `extras`, "Rendering"); `nur ci` PASS in each.
- [ ] **Step 4:** Commit.

### Task 8: Core `lsdocs`, `lsdocs-bench`, `lsdocs.github.io`

**Files:** `C:\dev\lsdocs` (`crates/host`, `crates/cli`, `examples/plugins/txt-parser`, `tests/site/` (new fixture site replacing `examples/sample-site` for the end-to-end tests), `ROADMAP.md` (phases and decisions kept; TODO areas replaced by links to the repositories' TODO sections), `HISTORY.md`, CI with two jobs: `cargo test --no-default-features` and the end-to-end job with default features); `C:\dev\lsdocs-bench` (`scripts/bench.nu` and its test, depending on `lsdocs` by git); `C:\dev\lsdocs.github.io` (`docs/` minus API reference and the apidoc instances in `lsdocs.toml` / `.config/`, `nur docs` installing `lsdocs` with `cargo install --git`, fetching `schema.tar.gz` from `https://github.com/lsdocs/lsdocs-protocol/releases/latest/download/` into `site/schema/`, links to each repository's API pages at `https://lsdocs.github.io/<repo>/`, its build-without-warnings check moved from `docs_site.rs`)

- [ ] **Step 1:** `nur split` each; `nur link` every dependency.
- [ ] **Step 2:** `lsdocs`: end-to-end tests on `tests/site/` (in-process, stdio, pipe byte for byte; cache; serve), `docs_site.rs` removed.
- [ ] **Step 3:** `lsdocs.github.io`: until a protocol release exists, `nur docs` stops with "no lsdocs-protocol release yet: push a v* tag there" unless `--no-schema` is given; build PASS with `--no-schema`.
- [ ] **Step 4:** `nur ci` PASS in all three; READMEs, AGENTS.md.
- [ ] **Step 5:** Commit.

### Task 9: Verify the org and hand over the pushes

- [ ] **Step 1:** `nur split notes` in the monorepo: every TODO area mapped; spot-check that each repository's README TODO covers its areas.
- [ ] **Step 2:** In every repository: `nur unlink`, then list what it would fetch (`nur check-git-deps` PASS); `git log --oneline | head -3` shows the split commit.
- [ ] **Step 3:** In the final report (not in `C:\dev\lsdocs-org`, which the user owns), give the order to create and push the repositories (bottom up: doctree, protocol, plugin-sdk, rst, markdown, apidoc, apidoc-*, plugins, lsdocs, bench, lsdocs.github.io), the command per repository (`git push -u origin main`), and the `v0.1.0` tag for `lsdocs-protocol`. Push only the ones the user says to, in that order, then run each pushed repository's `nur ci` with `nur unlink` to confirm the git dependencies resolve.
- [ ] **Step 4:** Record the split in the monorepo's `ROADMAP.md` (the decision, the map, where each part went) and `AGENTS.md` (this repository is an archive), commit, push `main`.
