# lsdocs.github.io

The documentation site of [lsdocs](https://github.com/lsdocs), built with
lsdocs: `docs/` (content in `docs/content`, plugin settings in
`docs/.config`). `nur docs` builds it into `docs/site`, with
lsdocs-protocol's JSON Schemas under `schema/`; `nur ci` checks it builds
without warnings. The API reference is built and published by the
repositories it documents; the site links to them.

## Known limitations

- The wire protocol page (`docs/content/reference/wire.md`) is generated
  by `nur docs` and `nur ci` from lsdocs-protocol's `spec/wire.md`, at its
  newest `lsdocs-protocol/v*` release tag (or the local clone, with
  `LSDOCS_ORG_DIR`): building the site needs network access to GitHub,
  and the page shows the released spec, not `main`'s.

## TODO

- [ ] Deployment to GitHub Pages (a workflow building `nur docs` on push).
