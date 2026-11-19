# lsdocs.github.io

The documentation site of [lsdocs](https://github.com/lsdocs), built with
lsdocs: `docs/` (content in `docs/content`, plugin settings in
`docs/.config`). `nur docs` builds it into `docs/site`, with
lsdocs-protocol's JSON Schemas under `schema/`; `nur ci` checks it builds
without warnings. The API reference is built and published by the
repositories it documents; the site links to them.

## Known limitations

- The protocol reference names `spec/wire.md` without showing it: the spec
  lives in lsdocs-protocol.

## TODO

- [ ] Publish the wire spec as a page (or generate one from it) and link
      it.
- [ ] Deployment to GitHub Pages (a workflow building `nur docs` on push).
