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
| `file_access` | `true` | Let `include`, `raw :file:` and `csv-table :file:` read files. While on, results are not cached, since they depend on other files. |

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
| `file_access` | `true` | Let `literalinclude` read files. While on, results are not cached. |
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
