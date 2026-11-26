---
title: HTML markup
nav_order: 4
---

# HTML markup

`render-html` writes a document's body as HTML whose classes and data
attributes are a contract with themes, so a theme's stylesheet and
scripts can rely on them. Classes and custom elements it adds are prefixed
`lsd-`. Its `data-` attributes (`data-kind`, `data-label`,
`data-language`, `data-lines`, ...) are not prefixed. Code blocks keep
the `language-*` class, and the `highlight` and `hl-*` classes come from
the `transform-highlight` plugin, also unprefixed. Standard attributes
(`id`, `href`, `role`, `aria-label`) are used as HTML defines them. Plain
elements (paragraphs, lists, block quotes, links, emphasis, inline code,
`hr`, `br`, `img`) carry no class.

This page lists what each node kind becomes. The pages' template
(`page.html`, see [built-in plugins](../plugins/index.md)) wraps the
body, which is the template's `content`.

## Structure

| Node | Markup |
|---|---|
| section | `<section id="...">` around its children. |
| heading | `<h1>` to `<h6>`, with its `id`. With the `heading_anchors` setting (on by default) it ends with ` <a class="lsd-anchor" href="#id" aria-label="Link to this section">#</a>`. A section's title links to the section's id. |
| paragraph, list, list item, block quote, thematic break | `p`, `ul`/`ol` (with `start`), `li`, `blockquote`, `hr`. A task list item starts with a disabled `<input type="checkbox">`. |
| definition list | `<dl class="lsd-definition-list">` with `dt` and `dd`. |
| table | `<div class="lsd-table"><table>...</table></div>`. The wrapper is what scrolls. Cells are `th` (header rows) or `td`; alignment is a `style="text-align: ..."` on the cell. |
| figure | `<figure class="lsd-figure" id="...">` with its image and a `<figcaption>`. |

## Code

A code block is a `figure` around the `pre`, inside a `<lsd-copy>`
element (which a script can turn into a block with a copy button):

```html
<lsd-copy><figure class="lsd-code" id="ex" data-language="python"
    data-linenos data-line-start="5" data-lines="1,3-4"><figcaption
    class="lsd-code-title">Caption</figcaption><pre><code
    class="language-python">...</code></pre></figure></lsd-copy>
```

| Part | Meaning |
|---|---|
| `class="lsd-code"` | Every code block. |
| `data-language` | The language, if there is one. |
| `data-linenos` | Present when line numbers were asked for (`linenos`, or MkDocs' `linenums=N`). `data-line-start` is the first line's number, if it is not 1. |
| `data-lines` | The highlighted (emphasized) lines, as written: `1,3-4` (from `emphasize-lines`, or MkDocs' `hl_lines="1 3-4"` with commas for spaces). |
| `id` | The figure's name (`:name:` of `code-block`). |
| `figcaption.lsd-code-title` | The title bar, before the `pre`, when the block has a caption (`:caption:`) or a title (`title="..."` in a fence's info string, as in MkDocs). It holds whichever one there is; with both, the title in `<strong>` and the caption in a `<p>` under it: `<figcaption class="lsd-code-title"><strong>a.py</strong><p>Caption</p></figcaption>`. |

Values in a fence's info string may be quoted (`title="my file.py"`) to
hold spaces.

The default theme's script draws the line numbers and highlighted lines
from these attributes: it adds an `aria-hidden` `<span
class="lsd-linenos">` gutter before the `pre`, and paints the
highlighted lines as a background gradient set in the figure's
`--lsd-code-lines` property. Neither is part of `render-html`'s output.

When `transform-highlight` knew the language, the `pre` is its own: `<pre
class="highlight"><code class="language-rust">...</code></pre>`, with
tokens in `<span class="hl-...">`s (the default theme colors them).

## Admonitions

```html
<div class="lsd-admonition" data-kind="warning">
<p class="lsd-admonition-title">Warning</p>
...
</div>
```

`data-kind` is the admonition's kind: `note`, `warning`, `tip` and the
others the parsers make, and Sphinx's `versionadded`, `deprecated`,
`seealso` and `todo`. The title is its own, or the kind with a capital.

## Tabs

`tab-set` and `tab-item` directives (the `extras` plugin) become a custom
element with one panel per tab:

```html
<lsd-tabs class="lsd-tabs">
<div class="lsd-tab" data-label="Rust" role="group" aria-label="Rust">
...
</div>
</lsd-tabs>
```

Without a script the panels are plain blocks, one after the other (the
default theme shows each `data-label` above its panel). A script builds
the tab buttons from the `data-label`s and shows one panel at a time.

## API items

The API documentation framework wraps each documented item in
`<div class="lsd-api-item" data-kind="function" data-scope="pkg.name">`:
`data-kind` is the item's kind (`function`, `class`, ...) and
`data-scope` the qualified name of the item, when known. Its heading has
the kind in `<em class="lsd-api-kind">`.

## Footnotes

A reference is `<sup class="lsd-footnote-ref"><a href="#fn-1"
id="fnref-1">1</a></sup>`. Consecutive definitions share one block:

```html
<div class="lsd-footnotes" role="doc-endnotes">
<div class="lsd-footnote" id="fn-1">
<p class="lsd-footnote-label"><a href="#fnref-1">1</a></p>
...
</div>
</div>
```

## Math

`<span class="lsd-math lsd-math-inline">\(...\)</span>`, or
`lsd-math-display` with `\[...\]`, for client-side typesetting.

## Other custom nodes

A `custom` node (a node kind a plugin makes up, such as `toc`,
`backlinks`, `centered` or `hlist`) is a `<div class="lsd-KIND">` around
its children, so the table of contents is `lsd-toc` and the list of
backlinks `lsd-backlinks`. With `html_tag` set, the element is that one
(a `p`, `h2`, `section`, `aside` or `nav`); with an `id` attribute it has
that id. An inline custom node (attribute `inline: true`) is a `span`, or
its `html_tag` (`em`, `kbd`, `abbr`, ...), with the same class scheme
(`lsd-api-kind`, `lsd-abbr`, ...) and its `title`.

A block custom node with a text `content` attribute that no plugin
handled (a directive nobody declared, say) is a `<div class="lsd-KIND">`
holding a warning admonition, then its children:

```html
<div class="lsd-KIND">
<div class="lsd-admonition" data-kind="warning">
<p class="lsd-admonition-title">Unknown doc tree node "KIND"</p>
<lsd-copy><figure class="lsd-code" data-language="json">
<figcaption class="lsd-code-title">argument</figcaption>...</figure></lsd-copy>
<lsd-copy><figure class="lsd-code" data-language="json">
<figcaption class="lsd-code-title">options</figcaption>...</figure></lsd-copy>
<lsd-copy><figure class="lsd-code">
<figcaption class="lsd-code-title">content</figcaption>...</figure></lsd-copy>
</div>
</div>
```

The code blocks hold the node's `argument` and `options` as JSON (each
only when set) and its `content` as written.

Raw HTML nodes are written as they are.
