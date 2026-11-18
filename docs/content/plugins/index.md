---
title: Built-in plugins
nav_order: 2
---

# Built-in plugins

These plugins ship with lsdocs and run inside it. Add one with
`builtin = "<name>"`; `lsdocs init` adds them all, in this order.

Each reads its settings from `.config/lsdocs/<name>/settings.toml` next
to `lsdocs.toml`, `<name>` being its `name` there (so two instances keep
separate settings): the tables below list the keys. A missing file means
the defaults; an unknown key is an error. parser-rst reads docutils' own
`docutils.conf` instead. See [Configuration](../guide/configuration.md#plugin-settings).

## parser-markdown

Parses `.md` and `.markdown` files: CommonMark with tables, task lists,
footnotes, definition lists, math, alerts and heading ids, plus YAML or
TOML front matter (see [Writing pages](../guide/writing.md)).

## parser-rst

Parses `.rst` files with a port of docutils' parser and transforms (see
[reStructuredText](../guide/restructuredtext.rst)).

Its settings are docutils' own, in `.config/lsdocs/<name>/docutils.conf`
(docutils' INI format), so an existing `docutils.conf` works as it is:
the `[general]`, `[parsers]` and `[restructuredtext parser]` sections'
settings it implements (`tab_width`, `raw_enabled`, `pep_references`,
`rfc_references`, `id_prefix`, ...), and `file_insertion_enabled` (on by
default: let `include`, `raw :file:` and `csv-table :file:` read files;
a page is parsed again when a file it read changes). Other sections are
skipped; docutils settings it does not implement are a warning.

```ini
[restructuredtext parser]
pep_references: yes
file_insertion_enabled: no
```

## sphinx-addons

The directives and roles Sphinx adds to docutils, in reStructuredText and
in Markdown alike (as [MyST](../guide/writing.md#directives-and-roles)
writes them). List it before the other transformers, which see what it
makes.

- **Code:** `code-block` (`:caption:`, `:name:`, `:linenos:`,
  `:emphasize-lines:`, `:dedent:`), `literalinclude` (`:lines:`,
  `:start-after:`, `:end-before:` and the rest; the language defaults to
  the file's extension) and `highlight`.
- **Notes:** `versionadded`, `versionchanged`, `deprecated`,
  `versionremoved`, `seealso`, and `todo` / `todolist`.
- **Content:** `only`, `centered`, `hlist`, `glossary`, `sectionauthor`,
  `codeauthor`, `acks`, `rubric` (with `:heading-level:`),
  `tabularcolumns` (ignored) and `math` with `:label:`.
- **Index:** the `index` directive and role add entries (`single`,
  `pair`, `triple`, `see`, `seealso`) to a generated `genindex` page,
  which `` :ref:`genindex` `` links to.
- **Structure:** `toctree`, as a list of links to the pages it names and
  their sections. The pages a page's toctrees name become its children in
  the navigation (`nav_children`, for transform-nav), and `:numbered:`
  numbers their sections (`1.2. Title`).
- **Roles:** `ref`, `doc` (to a page in any format), `numref`, `term`,
  `eq`, `any`, `download`, and the inline roles `abbr`, `command`, `dfn`,
  `file`, `guilabel`, `kbd`, `mailheader`, `makevar`, `manpage`,
  `menuselection`, `mimetype`, `newsgroup`, `program`, `regexp`, `samp`
  and `index`.

| Setting | Default | Meaning |
|---|---|---|
| `file_access` | `true` | Let `literalinclude` read files. A page is transformed again when a file it read changes. |
| `tags` | `[]` | Tags `only` expressions test, besides `html`. |
| `todo_include_todos` | `false` | Show todos. |
| `numfig` | `false` | Number figures, tables and code blocks with a caption, for `numref`. |
| `numfig_format` | Sphinx's | `{ figure = "Fig. %s", table = "Table %s", code-block = "Listing %s" }` |
| `math_number_all` | `false` | Number every `math` directive. |
| `highlight_language` | none | The language of code blocks that name none. |
| `show_authors` | `false` | Show `sectionauthor` and `codeauthor`. |
| `manpages_url` | none | Where `manpage` links: `"https://man.example/{page}.{section}"`. |
| `extlinks` | `{}` | Roles that make links: `{ issue = { url = "https://github.com/o/r/issues/%s", caption = "#%s" } }`. |
| `toctree_nav` | `true` | Make toctrees the navigation (through `nav_children`). |

Domains (`py:function` and the like) are not supported yet.

## apidoc-python

Documents Python packages from their source code, without running or
importing them: a page per module (under `api/py`) with each class,
function, method, property, attribute and type alias, its signature and
its docstring. Docstrings are reStructuredText (or Markdown, with
`doc_format = "md"`), with Google, NumPy or Sphinx field list sections.
Names starting with `_` and names a module's `__all__` leaves out are
private and left out.

It also brings the `py` domain, in reStructuredText and Markdown alike:
`.. py:function:: name(args)` (and `py:class`, `py:method`,
`py:attribute`, `py:data`, ...) describes an item by hand, `.. py:auto::
pkg.name` places a generated one in a page, and `` :py:func:`name` ``
(`py:class`, `py:meth`, `py:attr`, `py:mod`, `py:obj`, ...) links to one.

| Setting | Default | Meaning |
|---|---|---|
| `paths` | (required) | Packages (directories) and modules (`.py`, `.pyi`) to document, relative to the site directory. |
| `output` | `"api/py"` | Where the pages go, under the source directory. |
| `private` | `false` | Document private items too. |
| `doc_format` | `"rst"` | The markup of docstrings: the extension of a parser (`rst`, `md`). |
| `doc_style` | `"auto"` | Docstring sections: `auto`, `plain`, `google`, `numpy`, `sphinx`, `tags`. |
| `primary` | `false` | Also take the roles without `py:` (`:func:`), as Sphinx's `primary_domain`. |

This site's [Python API](../api/python/index.md) is made by it.

## apidoc-typescript

Documents TypeScript and JavaScript from their source (`.ts`, `.tsx`,
`.d.ts`, `.js`, ...), types as written, without the type checker: what
each module exports (functions, classes, interfaces, type aliases, enums,
constants, namespaces), with TSDoc / JSDoc comments (Markdown, `@param`,
`@returns`, `@throws`, `@example`, `@deprecated`; `{@link Name}` links).
Members marked `private`, `#private` or `@internal` are left out. It
brings the `js` domain (`js:function`, `js:class`, `js:interface`,
`js:type`, ..., `js:auto`; roles `js:func`, `js:class`, `js:type`,
`js:obj`, ...).

| Setting | Default | Meaning |
|---|---|---|
| `paths` | (required) | Files and directories, relative to the site directory; `{ path = "src/index.ts", module = "my-package" }` names a module. |
| `output` | `"api/js"` | Where the pages go. |

It takes the other settings of `apidoc-python` too (`private`,
`doc_format`, `doc_style`, `primary`). This site's
[TypeScript API](../api/typescript/index.md) is made by it.

## apidoc-rust

Documents Rust crates from rustdoc's JSON output: it runs `cargo rustdoc`
for each crate with a nightly toolchain (the JSON output is unstable, so
the plugin names one that writes the format it reads: install it with
`rustup toolchain install nightly-2026-11-14`) and reads what rustdoc
wrote. Types, paths and re-exports are rustdoc's, so they are exact;
like `cargo doc`, it builds the crate's dependencies and runs its build
scripts and procedural macros.

A page per module (under `api/rs`) has each struct, enum, union, trait,
function, macro, constant, static and type alias, with fields, variants,
inherent methods, the traits a type implements and a trait's
implementors. Doc comments are rustdoc's Markdown: its sections
(`# Examples`, `# Panics`, `# Errors`, `# Safety`, `# Arguments`) are
parts of the item, not sections of the page; intra-doc links
(`` [`Point`] ``) become references to items the plugin documents, in
any of its crates, and links to other crates' rustdoc pages (the
standard library's, or docs.rs); code blocks are Rust, without their
hidden `# ` lines. Items of private modules are documented where they
are re-exported. It brings the `rs` domain (`rs:function`,
`rs:struct`, `rs:trait`, ..., `rs:auto`; roles `rs:fn`, `rs:struct`,
`rs:trait`, `rs:mod`, `rs:obj`, ...).

| Setting | Default | Meaning |
|---|---|---|
| `crates` | (required) | Crates, relative to the site directory: a crate's directory (or `Cargo.toml`), a JSON file rustdoc wrote, or `{ path, package, features, all_features, no_default_features }`. |
| `toolchain` | `"nightly-2026-11-14"` | The toolchain cargo runs with (`cargo +<toolchain>`); `""` for cargo as found. |
| `target_dir` | cargo's | Where cargo builds, relative to the site directory. |
| `output` | `"api/rs"` | Where the pages go. |

It takes the other settings of `apidoc-python` too (`private` passes
`--document-private-items`). This site's [Rust API](../api/rust/index.md)
is made by it.

## apidoc-c and apidoc-cpp

Document C and C++ from their headers with libclang, which parses them as
a compiler would: types and templates are clang's, nothing is compiled.
libclang (10 or later) is loaded when the plugin runs, so it must be
installed: see [Installing libclang](#installing-libclang).

Each header is a module (a page, under `api/c` or `api/cpp`), with what it
declares itself: namespaces (pages of their own), classes, structs and
unions with their fields, methods and constructors, enums, functions and
templates, variables and constants, typedefs and aliases (a typedef of an
anonymous struct is that struct) and macros. Overloads are one item with
each signature. Private and protected members are left out, as are
`detail` namespaces and comments tagged `@internal`.

Doc comments are Doxygen's (`/** */`, `///`, `//!`, `///<`), in
Markdown: `@param` / `\param`, `@return`, `@throws`, `@tparam`,
`@deprecated`, `@note` and the like become sections, `\code` blocks code,
`\c`, `\p`, `\b` and `\e` markup, and `\ref name` and `#name`
references. A header's `@file` comment documents its page; an override
without a comment shows the overridden method's.

They bring Sphinx's `c` and `cpp` domains: `c:function`, `c:struct`,
`c:member`, `c:macro`, `c:type`, ... and `cpp:class`, `cpp:function`,
`cpp:member`, `cpp:type`, `cpp:enum`, ..., with `auto`; roles `c:func`,
`c:struct`, `c:macro`, ..., `cpp:class`, `cpp:func`, `cpp:member`,
`cpp:any`, ....

| Setting | Default | Meaning |
|---|---|---|
| `paths` | (required) | Headers and directories, relative to the site directory; a directory is also an include directory. `{ path = "include/lib.h", module = "lib" }` names a module. |
| `args` | `[]` | Compiler arguments, after `-x c -std=c17` or `-x c++ -std=c++20`: `["-Ithird_party", "-DLIB_API=", "-std=c++17"]`. |
| `output` | `"api/c"`, `"api/cpp"` | Where the pages go. |

They take the other settings of `apidoc-python` too (`private`,
`doc_format`, `doc_style`, `primary`). This site's [C](../api/c/index.md)
and [C++](../api/cpp/index.md) samples are made by them.

### Installing libclang

| System | Command |
|---|---|
| Windows | `winget install LLVM.LLVM` |
| macOS | `xcode-select --install` (the Command Line Tools have it), or `brew install llvm` |
| Debian, Ubuntu | `sudo apt install libclang-dev` |
| Fedora | `sudo dnf install clang-devel` |
| Arch | `sudo pacman -S clang` |

lsdocs looks for it where these put it, and through `llvm-config`. If it
is elsewhere (Homebrew's `llvm` is not linked into the usual places), set
`LIBCLANG_PATH` to the directory holding it:
`LIBCLANG_PATH="$(brew --prefix llvm)/lib"`.

## transform-toc

Adds a table of contents to each page, after its first title: links to
the page's sections.

| Setting | Default | Meaning |
|---|---|---|
| `depth` | `3` | The deepest heading level listed. |

## transform-links

Checks links between pages, resolves `:ref:` labels, fills in the text of
empty links, and can list the pages linking to each page.

| Setting | Default | Meaning |
|---|---|---|
| `check` | `true` | Report links to missing files and anchors. |
| `backlinks` | `false` | Add a list of the pages linking here to each page. |
| `backlinks_title` | `"Pages linking here"` | The heading of that list. |

## transform-nav

Builds the site navigation, from the source directories, for each page:
the sidebar and the previous and next links. A directory's `index` page
names its section. Pages are ordered by `nav_order`, then file name;
`nav_title` and `nav_exclude` change a page's entry (see
[front matter](../guide/writing.md#front-matter)). If the root `index`
page lists its children in `nav_children` (as sphinx-addons does from
toctrees), the navigation follows those lists instead of the
directories.

## transform-highlight

Highlights code blocks whose language it knows, by name or file extension
(`rust`, `rs`, `toml`, ...), with CSS classes the theme colors.

| Setting | Default | Meaning |
|---|---|---|
| `languages` | all | The languages to highlight. |
| `aliases` | none | Extra names for known languages: `{ jsonc = "json" }`. |

## render-html

Writes each page as HTML in a page template, and `sitemap.xml` when the
site has an absolute `base_url`.

| Setting | Default | Meaning |
|---|---|---|
| `template` | built-in theme | A [minijinja](https://docs.rs/minijinja) page template, relative to the site directory. |
| `heading_anchors` | `true` | Add a `#` link to each heading with an id. |
| `sitemap` | `true` | Write `sitemap.xml`. |

Templates see `content` (the page body, as HTML), `page.title`,
`page.source`, `page.metadata`, `page.root` (the relative path to the
site root), `page.nav` (from transform-nav) and `site.title` and
`site.base_url`. The `link` filter turns a link to a source file into a
link to its output: `{{ item.url | link }}`.
