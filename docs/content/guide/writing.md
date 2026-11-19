---
nav_order: 3
---

# Writing pages

Pages are Markdown (`.md`, `.markdown`) or reStructuredText (`.rst`) files
under the source directory. Both produce the same document tree, so links,
tables of contents and the navigation work the same way in either. See
[reStructuredText](restructuredtext.rst) for what is particular to it.

## Markdown

Markdown is CommonMark with the common extensions:

- tables, task lists (`- [x] done`) and strikethrough;
- footnotes (`text[^1]` and `[^1]: the note`);
- definition lists (a term, then `: definition`);
- math: `$x^2$` inline and `$$x^2$$` on its own line;
- alerts, which become admonitions:

  ```md
  > [!NOTE]
  > Notes, tips, warnings and the like.
  ```

- explicit heading ids: `## Install {#setup}`.

Raw HTML is passed through to the HTML output.

## Directives and roles

Directives and roles from plugins, such as Sphinx's from `sphinx-addons`,
are written as MyST writes them. A directive is a fenced block whose
language is `{name}`: the rest of the first line is its argument, then
come its options, as `:name: value` lines or YAML between `---` lines,
then its content. In reStructuredText, the same directive is written as
usual:

``````{tab-set}
`````{tab-item} Markdown
````md
```{versionadded} 2.0
:class: important

The *new* option.
```
````
`````
`````{tab-item} reStructuredText
```rst
.. versionadded:: 2.0
   :class: important

   The *new* option.
```
`````
``````

A role is `{name}` right before inline code: `` {kbd}`Ctrl+C` ``,
`` {ref}`the setup <setup>` ``. A plugin says which directives and roles
it handles; a `{name}` fence no plugin handles is kept for plugins as a
`custom` node, and an unknown role stays text and code.

Content in tabs is a `tab-set` directive of `tab-item`s, each with its
label as the argument (`sphinx-addons`). Tab sets are linked: choosing a
label in one shows it in every tab set of the page that has it.

```````{tab-set}
``````{tab-item} Markdown
`````md
````{tab-set}
```{tab-item} Rust
Rust's way.
```
```{tab-item} Python
Python's way.
```
````
`````
``````
``````{tab-item} reStructuredText
```rst
.. tab-set::

   .. tab-item:: Rust

      Rust's way.

   .. tab-item:: Python

      Python's way.
```
``````
```````

## Front matter

A Markdown page may start with YAML between `---` lines (or TOML between
`+++` lines). In reStructuredText, a field list at the very top of the
page does the same (`:title: Custom title`). Keys the built-in plugins
read:

| Key | Meaning |
|---|---|
| `title` | The page title, instead of its first heading. |
| `nav_title` | The title in the navigation. |
| `nav_order` | Sort key among the pages of a directory; pages without one come after, by file name. |
| `nav_exclude` | `true` leaves the page out of the navigation. |
| `nav_children` | The pages below this one in the navigation, in order (source paths, relative to the page or, with a leading `/`, to the source directory). On the root `index` page, it makes the navigation follow these lists instead of the directories. |
| `sitemap` | `false` leaves the page out of the sitemap. |

Every key is available to page templates as `page.metadata`. The host
sets `generated: true` on pages a plugin generates (API pages, the
index), which have no source file; the default theme gives them no
edit link.

## Sections and ids

A heading starts a section, which holds everything up to the next heading
of the same or a higher level. Sections get ids from their titles
(`## Getting started` is `getting-started`), unless the page gives one, so
`page.md#getting-started` links to it. Ids are unique within a page:
a second `## Example` is `example-1`.

## Links

Link to other pages by their source path, relative to the page:
`[setup](../guide/getting-started.md#install)`. lsdocs points the link at
the page's output, and reports links to files or anchors that do not exist.
A link without text, such as `[](getting-started.md)`, shows the title of
the page or section it points to.

The navigation follows the source directories: a directory's `index` page
names and links its section of the navigation.
