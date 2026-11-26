---
title: Document tree
nav_order: 1
---

# The document tree

A document is a map with its `source` path (relative to the source
directory, with `/`), its `metadata` (front matter) and its `children`.
Nodes are maps with a `type` and that type's fields; every node may have a
`span`, the byte range (`start`, `end` exclusive) of the source it came
from. The JSON Schema is `schema/doctree/document.json` in the repository.

## Blocks

| Type | Fields | Children |
|---|---|---|
| `section` | `id` | A `heading`, then the section's content and subsections. |
| `heading` | `level` (1 to 6), `id` (only outside a section title) | Inlines. |
| `paragraph` | | Inlines. |
| `list` | `ordered`, `start` | `list_item`s. |
| `list_item` | `checked` (task lists) | Blocks. |
| `block_quote` | | Blocks. |
| `code_block` | `language`, `info`, `value` | |
| `table` | `align` (per column: `none`, `left`, `center`, `right`) | `table_row`s. |
| `table_row` | `header` | `table_cell`s. |
| `table_cell` | | Inlines or blocks. |
| `thematic_break` | | |
| `admonition` | `kind` (`note`, `warning`, ...), `title` | Blocks. |
| `definition_list` | | `definition_term`s, each followed by `definition_description`s. |
| `footnote_definition` | `label` | Blocks. |
| `figure` | `id` | An image (or other content), then an optional `caption`. |
| `math` | `value`, `display` | |
| `raw` | `format` (`html`), `value` | |

## Inlines

| Type | Fields | Children |
|---|---|---|
| `text` | `value` | |
| `emphasis`, `strong` | | Inlines. |
| `inline_code` | `value` | |
| `link` | `url`, `title`, `target` | Inlines (none: the target's title is filled in). |
| `image` | `url`, `alt`, `title` | |
| `line_break` | | |
| `footnote_reference` | `label` | |
| `anchor` | `id` | |

`math` and `raw` are also inlines.

## Custom nodes

`custom` nodes have a `kind`, free-form `attrs` and `children`:
plugin-defined content, such as diagrams, that other plugins turn into core
nodes or render. Transformers select them as `custom:<kind>`.

Parsers make some by convention:

- A directive (`.. name::` in reStructuredText, a ```` ```{name} ````
  fence in Markdown) is a `custom` node of its name, with the attributes
  `argument`, `options` and `content`. For directives a plugin declares,
  content that is markup is parsed into the children instead, and an
  argument that is markup is parsed into a first child of kind
  `directive_argument`.
- A role a plugin declares (`` :name:`text` ``, or `` {name}`text` `` in
  Markdown) is a `custom` node of kind `role` with the attributes `name`
  and `text`, and the text as its child.

Renderers draw a `custom` node they don't know as a block holding its
children, or, if its attribute `inline` is `true`, as an inline element
(`render-html` uses a `span`, or the element `html_tag` names, with
`title` as its title). `render-html` shows a block one with a text
`content` attribute (a directive nobody declared) in a warning, with its
`argument`, `options` and `content`, so they are not lost.

## Links between documents

A `link` may carry a `target`, saying where in the site it points:

- `document` (a source path) and `anchor`, or just an `anchor` in the same
  document: lsdocs fills these in for links by relative path;
- or a `label` to look up among the anchors of every document, which
  `transform-links` resolves.

Renderers link to the target's output, so the link works whatever the
target's source format.

## Ids

Parsers set only the ids authors wrote. lsdocs then gives every other
section, and every heading outside a section title, the slug of its title:
lowercase, letters and digits kept, every other run of characters one `-`,
made unique in the document with `-1`, `-2`, ...
