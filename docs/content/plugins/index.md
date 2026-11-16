---
title: Built-in plugins
nav_order: 2
---

# Built-in plugins

These plugins ship with lsdocs and run inside it. Add one with
`builtin = "<name>"`; `lsdocs init` adds them all, in this order.

## parser-markdown

Parses `.md` and `.markdown` files: CommonMark with tables, task lists,
footnotes, definition lists, math, alerts and heading ids, plus YAML or
TOML front matter (see [Writing pages](../guide/writing.md)).

## parser-rst

Parses `.rst` files with a port of docutils' parser and transforms (see
[reStructuredText](../guide/restructuredtext.rst)).

| Option | Default | Meaning |
|---|---|---|
| `file_access` | `true` | Let `include`, `raw :file:` and `csv-table :file:` read files. A page is parsed again when a file it read changes. |

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

| Option | Default | Meaning |
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

| Option | Default | Meaning |
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

| Option | Default | Meaning |
|---|---|---|
| `paths` | (required) | Files and directories, relative to the site directory; `{ path = "src/index.ts", module = "my-package" }` names a module. |
| `output` | `"api/js"` | Where the pages go. |

It takes the other options of `apidoc-python` too (`private`,
`doc_format`, `doc_style`, `primary`). This site's
[TypeScript API](../api/typescript/index.md) is made by it.

## transform-toc

Adds a table of contents to each page, after its first title: links to
the page's sections.

| Option | Default | Meaning |
|---|---|---|
| `depth` | `3` | The deepest heading level listed. |

## transform-links

Checks links between pages, resolves `:ref:` labels, fills in the text of
empty links, and can list the pages linking to each page.

| Option | Default | Meaning |
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

| Option | Default | Meaning |
|---|---|---|
| `languages` | all | The languages to highlight. |
| `aliases` | none | Extra names for known languages: `{ jsonc = "json" }`. |

## render-html

Writes each page as HTML in a page template, and `sitemap.xml` when the
site has an absolute `base_url`.

| Option | Default | Meaning |
|---|---|---|
| `template` | built-in theme | A [minijinja](https://docs.rs/minijinja) page template, relative to the site directory. |
| `heading_anchors` | `true` | Add a `#` link to each heading with an id. |
| `sitemap` | `true` | Write `sitemap.xml`. |

Templates see `content` (the page body, as HTML), `page.title`,
`page.source`, `page.metadata`, `page.root` (the relative path to the
site root), `page.nav` (from transform-nav) and `site.title` and
`site.base_url`. The `link` filter turns a link to a source file into a
link to its output: `{{ item.url | link }}`.
