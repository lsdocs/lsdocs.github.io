# Splitting the lsdocs workspace into repositories

## Intent

lsdocs is one Cargo workspace: data crates, protocol, RPC, SDK, host,
CLI, 14 plugins, two parsers' libraries and their Python/Node bindings,
the docs site, the sample site and the bench. Working on one part means
building, testing and CI-ing all of it. Split it into repositories in
the GitHub organization `lsdocs`, so each part has fast CI and a small
working set.

## Decided (with the user)

- **Why:** faster CI and dev workflows; one repository is cumbersome when
  working on one part.
- **Nothing is published** (crates.io, PyPI, npm). Repositories depend on
  each other with Cargo **git dependencies**. Breaking changes are fine;
  `PROTOCOL_VERSION` stays `"1.0-rc.0"`.
- **Approach 1 (layered repositories):** every repository depends only on
  repositories below it; the `lsdocs` binary keeps its built-in
  (in-process) plugins, as git dependencies.
- **The map** (below), including: protocol, spec and schemas in their own
  repository, doctree in its own; the plugin SDK and its bindings in one;
  the apidoc framework in one and each language in its own; each parser a
  Cargo workspace with its bindings; one repository per plugin; bench in
  its own; the sample site dropped; a site for the whole organization,
  `lsdocs.github.io`, which also serves the schemas; the schemas are also
  attached to the protocol repository's releases.
- **`lsdocs-sdk-dynamic` is renamed `lsdocs-plugin-sdk-bindings`.**
- **nur** is the task runner in every repository; **mise** pins the dev
  tools.
- **Notes in commit messages must survive:** each repository's README
  gets "Known limitations" and "TODO" sections.
- **Location:** clones live in `C:\dev\<repo>`. `C:\dev\lsdocs-org` is the
  existing `lsdocs/.github` repository. **Never touch
  `C:\dev\lsdocs-legacy-attempt`.**
- The user creates the GitHub repositories (and approves each push).

## The map

Each row depends only on rows above it (git dependencies on
`https://github.com/lsdocs/<repo>`).

| Repository | Contents (from the monorepo) |
|---|---|
| `lsdocs-doctree` | `crates/doctree` |
| `lsdocs-protocol` | `crates/config`, `crates/protocol`, `tools/gen`, `spec/`, `schema/`, `fixtures/`, `nur test fixtures` |
| `lsdocs-plugin-sdk` | `crates/rpc`, `crates/plugin-sdk`, `crates/sdk-dynamic` (renamed `lsdocs-plugin-sdk-bindings`), `bindings/plugin/{python,node}` |
| `lsdocs-rst` | `crates/rst`, `plugins/parser-rst`, `bindings/rst/{python,node}`, the conformance cases, `scripts/rst-*.py`, `nur gen rst` / `nur fuzz rst` |
| `lsdocs-markdown` | `plugins/parser-markdown` |
| `lsdocs-apidoc` | `crates/apidoc`, `crates/apidoc-plugin` |
| `lsdocs-apidoc-python`, `-typescript`, `-rust`, `-clang` | one language package each (`apidoc-clang` with `examples/clang-sample`) |
| `lsdocs-sphinx-addons`, `lsdocs-extras`, `lsdocs-render-html`, `lsdocs-transform-toc`, `-links`, `-nav`, `-highlight` | one plugin each (`render-html` with its themes and `nur gen theme` / `nur test theme`) |
| `lsdocs` | `crates/host`, `crates/cli`, end-to-end tests, `examples/plugins/txt-parser`, `ROADMAP.md`, `HISTORY.md` |
| `lsdocs-bench` | `nur bench` and its generated site |
| `lsdocs.github.io` | `docs/` without the API reference (which moves to the repositories it documents), plus the schemas, served |

Dropped: `examples/sample-site` (its snapshot tests are replaced, below).

## Design

### Extraction

- Each repository is made from the monorepo with `git filter-repo`,
  keeping only its paths (and renames), so its history and every commit
  message that touched its files come along. The monorepo
  (`C:\dev\claude\lsdocs`, remote gitlab.com/2bndy5/lsdocs) is left as it
  is, an archive; nothing in it is deleted. The core repository is made the
  same way, into `C:\dev\lsdocs`.
- Paths are flattened where a repository holds one crate (e.g. the crate
  at the root, or under `crates/`), my call per repository; the workspace
  layout of multi-crate repositories keeps `crates/`, `plugins/`,
  `bindings/`.
- Order, bottom up: doctree, protocol, plugin-sdk, rst, markdown, apidoc,
  apidoc languages, plugins, lsdocs, bench, lsdocs.github.io. Each builds
  and passes its own `nur ci` against the repositories already pushed
  before the next one starts.

### Dependencies between repositories

- Git dependencies on the default branch (`branch = "main"`); each
  repository commits its `Cargo.lock`, which pins the revisions. Bumping a
  dependency is `cargo update -p <crate>` (a `nur bump` task).
- Working on two repositories at once: a `nur link <path>` task writes a
  `[patch."https://github.com/lsdocs/<repo>"]` entry pointing at the local
  checkout into an untracked `.cargo/config.toml`; `nur unlink` removes it.
- Shared `[workspace.dependencies]` versions are copied into each
  repository (no shared manifest); `cargo-deny`'s config is copied too.
- Each repository's own `rust-version` stays as today (workspace base 1.89,
  the apidoc languages 1.97).
- Crate names stay as they are (only `lsdocs-sdk-dynamic` is renamed), so
  `lsdocs-parser-rst` is a package of the `lsdocs-rst` repository,
  `lsdocs-parser-markdown` of `lsdocs-markdown`, `lsdocs-extras-plugin` of
  `lsdocs-extras` (my call).

### Tooling in each repository

- `nurfile` with the tasks that apply (`ci`, `fmt`, `lint`, `test`, and the
  repository's own: `gen`, `gen rst`, `gen theme`, `gen node`, `test
  python`, `test node`, `link`, `bump`); `nur ci` runs what CI runs.
- `mise.toml` pinning what the repository needs: Rust (stable, and the
  nightly `apidoc-rust` runs), nushell and nur, uv and Python, Node (no
  more fnm detection in the nurfiles), cargo-deny. libclang stays a system
  install (documented in `lsdocs-apidoc-clang`'s README).
- `rust-toolchain.toml`, `rustfmt.toml`, `.gitattributes`,
  `.editorconfig`, the licenses (`Apache-2.0 OR MIT`), and the workspace
  lints, copied.
- `AGENTS.md`: the parts of today's that apply, plus the repository's own
  layout and tasks.
- `scripts/check-deps.nu` is kept only where a repository has several
  crates; the cross-repository layering is enforced by the map itself
  (a repository cannot depend on one above it without a cycle).
- CI: a GitHub Actions workflow per repository running `nur ci` through
  mise, path-filtered where a repository has optional parts (the SDK's
  Python/Node jobs), with Cargo's git and registry caches kept between
  runs. In `lsdocs`, the host and CLI unit tests run in one job without
  the built-in plugins (`--no-default-features`, made possible by putting
  every built-in behind a default feature), and the end-to-end tests in a
  second job with them (my call: keeps the core's feedback fast although
  the full binary clones every plugin repository).
- The protocol repository's release workflow runs on a `v*` tag pushed by
  the user and attaches `schema.tar.gz` (my call); the site fetches it
  over plain HTTPS from `releases/latest/download/`, so no token is
  needed, and fails with a clear message until a first release exists.

### Tests that span repositories

- `lsdocs` keeps the end-to-end tests (`crates/cli/tests`): a small
  fixture site in the repository replaces the sample site, built
  in-process, over stdio and over a pipe, compared byte for byte.
  `docs_site.rs` moves to `lsdocs.github.io` as its own build check; each
  repository with API pages checks its own site builds without warnings.
- The sample site's HTML snapshots move to `lsdocs-render-html`, against
  a small site of its own rendered by the plugin (no CLI).
- The Python/Node toc ports (in `lsdocs-plugin-sdk`) need an `lsdocs`
  binary: they run when `LSDOCS_BIN` is set and skip otherwise (as
  today). `nur test python` / `node` there install `lsdocs` from git into
  a cache with a `[patch]` pointing its SDK dependency at the checkout
  under test, so the binary uses the SDK being tested (my call). They
  render a small fixture site kept in `lsdocs-plugin-sdk` (replacing the
  sample site), against the Rust `transform-toc` and `render-html` the
  binary has built in.
- `apidoc-rust`'s test that the nightly is named the same everywhere
  checks the files of its own repository (README, `mise.toml`, CI) (my
  call).
- `apidoc-clang` keeps `examples/clang-sample` for its tests and its own
  API pages.

### Notes and roadmap

- Each repository's README has **Known limitations** (what it does not do
  or does differently, e.g. `parser-rst`'s `docutils.conf` differences)
  and **TODO** (what is open). They are seeded from the roadmap's TODO
  list (by area), the existing READMEs' lists, and a best-effort pass over
  each repository's commit bodies for notes still open (a note touching
  several areas goes to each); the full messages stay in each
  repository's history regardless (my call).
- Files copied rather than extracted (nurfile, AGENTS.md, CI, config
  files) are added in one commit per repository whose message names the
  monorepo commit the split was made from (my call).
- `ROADMAP.md` in `lsdocs` keeps the phases and decisions, plus the open
  organization-level items; its per-area TODO entries move to the
  repositories and are replaced by links. `HISTORY.md` stays in `lsdocs`.

### lsdocs.github.io and API pages

- Today's `docs/` site without its API reference: the guides, the plugin
  pages, the protocol reference. Built by an `lsdocs` installed from git
  (`cargo install --git`, the CLI's default features), with the same
  `.config/` minus the apidoc instances. It serves `schema/`, fetched from
  the protocol repository's latest release by its build task (my call).
- **API pages move to the repositories they document** (decided with the
  user): each repository with a public API builds its own pages, hosted
  from its `gh-pages` branch, and the organization site links to them:
  - `lsdocs-plugin-sdk`: the Python and Node plugin SDKs and the Rust
    SDK (`apidoc-python`, `apidoc-typescript`, `apidoc-rust` on its own
    crates);
  - `lsdocs-rst`: the Python and Node `lsdocs-rst` bindings (and the Rust
    crate);
  - `lsdocs-protocol`, `lsdocs-doctree`: their Rust crates;
  - `lsdocs-apidoc-clang`: `clang-sample`, as its example.
  The API pages documented the SDK together with the protocol and doctree
  crates it re-exports; after the split each site documents its own
  crates and links to the others (my call).
- These sites need `lsdocs` with its built-in plugins. Until releases
  exist, their build tasks install it with `cargo install --git`; later,
  binaries from GitHub releases (with cargo-binstall) replace that
  (decided with the user; not part of this work).
- Each site's CI builds it; deployment (GitHub Pages) is set up by the
  user.

## Goals

- Every repository builds and passes `nur ci` alone, cloning only the
  repositories it depends on (via Cargo), with tools from mise.
- `lsdocs build` and `lsdocs serve` behave as today: same built-ins; the
  organization site and the API sites together cover today's docs site.
- No note from a commit message or the roadmap is lost.

## Non-goals

- Publishing anything; versioning policy; a release process beyond the
  protocol repository's schema archive.
- Changing what the binary ships (it keeps the built-in plugins).
- An integration repository (approach 3); it can come later.

## Anti-goals

- A repository depending on one above it (cycle), or two copies of an SDK
  crate in one build (a `[patch]` that is half applied).
- Deleting or rewriting anything in the monorepo, `C:\dev\lsdocs-org` or
  `C:\dev\lsdocs-legacy-attempt`.
- Pushing anywhere without the user's go-ahead.

## Approaches

- **Layered repositories, git dependencies, built-ins kept** (chosen):
  no product change; each repository's CI builds itself and pinned
  dependencies; `nur link` makes cross-repository work cheap.
- **No built-ins**: plugins as separate executables; fastest core CI but a
  product change (install step, no in-process runs). Not chosen.
- **Layered plus an integration repository**: keeps repositories lean but
  adds one more repository whose pins go stale. Deferred.

## Left to the builder

- Per-repository directory layout (flattening single-crate repositories).
- Exact nur task names beyond those above; the CI workflow details.
- Which tests of `crates/cli/tests` need the fixture site and how small it
  can be.
- The order of repositories within a layer.
