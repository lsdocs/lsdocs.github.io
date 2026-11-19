---
title: lsdocs
---

# lsdocs

lsdocs builds documentation sites from Markdown and reStructuredText. Every
step of a build is a **plugin**: parsers turn source files into document
trees, transformers rewrite the trees, and renderers write the output. The
first-party plugins cover a typical site; your own can be written in Rust,
Python, JavaScript, or any language that can read and write MessagePack.

- [Getting started](guide/getting-started.md): install lsdocs, create a
  site, build and serve it.
- [Configuration](guide/configuration.md): everything `lsdocs.toml`
  accepts.
- [Writing pages](guide/writing.md): what Markdown and reStructuredText
  give you.
- [Built-in plugins](plugins/index.md): the plugins that ship with lsdocs
  and their settings.
- [Writing plugins](authoring/index.md): how a build works and how to add
  to it, with guides for [Rust](authoring/rust.md),
  [Python](authoring/python.md), [JavaScript](authoring/node.md) and
  [other languages](authoring/other-languages.md).
- Reference: the [document tree](reference/document-tree.md), the
  [protocol](reference/protocol.md) and the [HTML markup](reference/html-markup.md)
  themes style.

## How a build works

1. lsdocs finds the files under the source directory.
2. It starts the configured plugins, in-process (built-in ones) or as
   child processes (yours), and asks each what it can do.
3. Each source file is **parsed** by the first parser that takes its
   extension. Other files are copied to the output as they are.
4. lsdocs gives sections and headings ids and resolves links between
   documents.
5. Each **transformer** runs over the documents in turn, in the order the
   configuration lists them.
6. The **renderer** writes each document, and any site-wide files such as a
   sitemap.

Because every parser produces the same tree, transformers and renderers
work with every source format.
