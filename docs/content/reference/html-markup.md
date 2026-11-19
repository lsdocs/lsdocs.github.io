---
title: HTML markup
nav_order: 3
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
    data-linenos data-line-start="5" data-lines="1,3-4"><pre><code
    class="language-python">...</code></pre><figcaption>Caption</figcaption></figure></lsd-copy>
```

| Part | Meaning |
|---|---|
| `class="lsd-code"` | Every code block. |
| `data-language` | The language, if there is one. |
| `data-linenos` | Present when line numbers were asked for. `data-line-start` is the first line's number, if it is not 1. |
| `data-lines` | The highlighted (emphasized) lines, as written: `1,3-4`. |
| `id` | The figure's name (`:name:` of `code-block`). |
| `figcaption` | The caption (`:caption:`), after the `pre`. |

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

Raw HTML nodes are written as they are.
