---
title: Protocol
nav_order: 2
---

# The protocol

lsdocs talks to plugins with [msgpack-rpc](https://github.com/msgpack-rpc/msgpack-rpc/blob/master/spec.md)
messages, each framed by a 4-byte length, over the plugin's standard
input and output or a named pipe. The full specification is `spec/wire.md`
in the repository, with JSON Schemas for every message in `schema/` and
encoded examples in `fixtures/`.

## Version

The protocol is at **`1.0-rc.0`**, a release candidate. A release
candidate must match exactly, so plugins built against it are rebuilt for
the next candidate and for 1.0. From 1.0 on, plugins and lsdocs work
together when their major versions match: within a major version,
changes only add fields and features older peers can ignore.

## Methods

| Method | From | Purpose |
|---|---|---|
| `initialize` | lsdocs | Starts the session: site settings and options in, protocol version and capabilities out. |
| `initialized` | lsdocs | Notification: phase requests follow. |
| `parse` | lsdocs | A file's path and text in, a document out. |
| `parse/transform/each` | lsdocs | A document in, any data read from it out; the document is not changed. |
| `parse/transform/all` | lsdocs | Everything read, once, before any document is changed; documents the plugin generates from it out. |
| `render/transform/each` | lsdocs | A document in, the transformed document out. |
| `render` | lsdocs | A document in, the output bytes out. |
| `render/transform/all` | lsdocs | The rendered pages in, files no single page makes out (a sitemap). |
| `host/parse` | plugin | Text and a file extension in, the document lsdocs' parser for it makes out. |
| `shutdown`, `exit` | lsdocs | Ends the session. |
| `log`, `progress`, `diagnostics` | plugin | Notifications at any time. |
| `$/cancel` | either | Cancels a request. |

## Capabilities

| Capability | Says |
|---|---|
| `parse.extensions` | The file extensions the plugin parses. |
| `transform.nodes` | The node kinds it looks at; documents without any are not sent. |
| `transform.each` | Whether it wants `parse/transform/each` (and `parse/transform/all`). |
| `render.formats` | The output formats it writes. |
| `render.all` | Whether it wants `render/transform/all`. |
| `max_concurrency` | How many requests it handles at once. |
| `cache` | That its results may be cached, and a key for any other input. |
| `syntax` | The directives and roles it handles. lsdocs passes them to parsers, which make `custom` nodes of them for the plugin (see "Syntax extensions" in the specification). |
