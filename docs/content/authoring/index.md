---
title: Writing plugins
nav_order: 3
---

# Writing plugins

A plugin takes part in one or more phases of a build:

- A **parser** turns a source file into a document tree. It handles files
  by extension.
- A **transformer** rewrites document trees. It may first **collect**
  data from every document (headings for an index, titles for links),
  then **apply** its change to each document with everything collected.
- A **renderer** turns each document into an output file, and may write
  site-wide files, such as a sitemap, once every page is rendered.

Plugins written as programs talk to lsdocs over their standard input and
output (or a pipe) with MessagePack messages. The SDKs for
[Rust](rust.md), [Python](python.md) and [JavaScript](node.md) handle
that, so a plugin is a handful of functions; in [any other
language](other-languages.md), the [protocol](../reference/protocol.md) is
small enough to implement directly.

## The document tree

Every parser produces the same kind of tree (see the
[document tree reference](../reference/document-tree.md)): a document with
a `source` path, `metadata` (front matter), and `children`, a list of
nodes. Each node is a map with a `type` (`section`, `paragraph`, `text`,
`link`, ...) and the fields of that type; most have `children`. Content
under a title is a `section` whose first child is the title's `heading`.

What has no node type of its own is a `custom` node with a `kind` and
free-form `attrs`: a transformer can turn a Markdown code block in the
`mermaid` language into a `custom` node of kind `mermaid`, and a renderer
can draw it. Transformers select the documents they want by node kind,
such as `heading` or `custom:mermaid`: lsdocs sends them only documents
containing one.

## What lsdocs does for you

- **Ids.** After parsing, every section without an id gets one from its
  title, unique in the document. Parsers set only the ids authors wrote.
- **Links.** A link to another document by its relative path gets a
  `target` naming the document (and anchor); renderers use it to link to
  the output. `transform-links` checks links and resolves labels.
- **Order and parallelism.** Documents are processed in parallel, up to
  the plugin's `max_concurrency` requests at once, but results are
  gathered in source order, so builds are reproducible.
- **Caching.** A plugin whose output depends only on its input, the site
  settings and its options can say so; lsdocs then reuses its results
  across builds.

## Diagnostics

Every result may carry diagnostics: a severity (`error` fails the build,
`warning`, `info`, `hint`), a message, and where the problem is (the
source file and a byte span in it). Report problems with the content this
way; fail the request only when the plugin itself cannot go on.

## Settings

A plugin reads its own settings, from files under the site's `.config/`
directory, in any format: lsdocs tells it where that directory is and
the plugin's name in `lsdocs.toml` when it starts (with the site's
title, base URL, directories and file list), and the plugin says which
files it read, so lsdocs can tell when they change. The recommended
layout is `.config/<vendor>/<name>/`, as lsdocs' own plugins use
`.config/lsdocs/<name>/settings.toml`. Read paths in settings relative to
the site directory (`site.root`), not the working directory.
