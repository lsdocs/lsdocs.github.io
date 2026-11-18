# Phase 13, part 1: protocol renames

## Intent

Name the build's hooks by where they sit in the pipeline, so plugin
authors can see at a glance which event they hook into. "site" keeps one
meaning: the project being built (`SiteInfo`, `[site]`).

## The names

| New | Who answers | Runs | Old |
|---|---|---|---|
| `parse` | parsers | per document | `parse` |
| `parse/transform/each` | transformers | per document; reads only | `transform/collect` |
| `parse/transform/all` | transformers | once; may add documents | `transform/collected` |
| `render/transform/each` | transformers | per document; changes the tree | `transform/apply` |
| `render` | renderers | per document | `render` |
| `render/transform/all` | renderers | once; files no single page makes | `render/site` |
| `host/parse` | the host | on request from a plugin | `site/parse` |

"Per document" is the only unit; "per source file" is not used.

## Goals

- Rename the methods in the protocol (`request::*` types, their method
  strings, params and result type names), the Rust SDK, the Python and
  Node.js SDKs, the host, every first-party plugin, `schema/`,
  `fixtures/` (`nur gen`), `spec/wire.md`, the docs site, `AGENTS.md`
  and `ROADMAP.md`.
- Behavior is unchanged: same passes, same order, same caching.

## Non-goals

- The `.config/` work (part 2) and themes (part 3).
- Compatibility aliases: nothing is published, so old names go.

## Constraints

- `PROTOCOL_VERSION` stays `1.0-rc.0` (a release candidate; renames are
  allowed before 1.0).
- `nur ci` passes; Python and Node port tests still render the sample
  site byte-identically.

## Approaches

- **Rename everywhere, no aliases** (chosen): one consistent vocabulary;
  the cost is a wide mechanical diff.
- Aliases for the old names: needless while nothing is published.
- A redesign into two root methods with sub-methods dispatched by the
  host: discussed; the step list maps one-for-one onto today's, so only
  the names change.

## Left to the builder

SDK method names follow the protocol (Rust `Transformer::read`,
`conclude`, `apply` or names derived from the new methods; Python/Node
decorator and capability field names likewise), chosen for each
language's idiom and recorded in `ROADMAP.md` under Phase 13.
