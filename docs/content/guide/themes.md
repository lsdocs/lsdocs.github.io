---
title: Themes
nav_order: 5
---

# Themes

`render-html` writes pages with a **theme**: templates, stylesheets and
scripts, plus a handful of settings. You choose a theme and set it up in
the plugin's settings file, `.config/lsdocs/<name>/settings.toml` (see
[Configuration](configuration.md#plugin-settings); `<name>` is the
instance name in `lsdocs.toml`, `html` here).

## Choosing a theme

```toml
# .config/lsdocs/html/settings.toml
theme = "default"
```

Two themes are built in:

- `default`: the flagship. A header bar, the site navigation on the left
  and the page's table of contents on the right (both in a drawer on
  narrow screens), light and dark color schemes, search, content tabs
  and copy buttons for code. It makes no requests to other sites unless
  its settings add them.
- `plain`: one stylesheet, the site navigation beside the page and the
  table of contents as a drop-down menu. It has no scripts and no
  settings.

Any other value is a **theme directory**, relative to the site directory
(see [Writing a theme](#writing-a-theme)).

### Browser support

The `default` theme uses current CSS and JavaScript, with no fallbacks:
CSS nesting, `light-dark()`, relative color syntax, `:has()`, import maps
and module workers. Evergreen browsers of 2024 and later have all of
them; older ones show a plainer page, or none of the theme's components.

Search needs the site served over http or https: a page opened from
`file://` cannot fetch the index or start the search worker. `lsdocs
serve` serves over http.

## The default theme's settings

A theme's settings go in the `theme_settings` table. Each must be one the
theme declares, and of the kind of its default, so a typo, or a string
where a list belongs, is an error.

```toml
# .config/lsdocs/html/settings.toml
theme = "default"

[theme_settings]
scheme = "auto"
primary = "teal"
accent = "deep-orange"
font_text = "Inter"
logo = "images/logo.svg"
favicon = "images/favicon.png"
extra_css = ["css/site.css"]
social = [
    { icon = "code", link = "https://example.com/repo" },
    { icon = "mail", link = "mailto:docs@example.com" },
]
footer = "Copyright 2026 Example"
edit_url = "https://example.com/repo/edit/main/docs/{path}"
```

| Setting | Default | Meaning |
|---|---|---|
| `scheme` | `"auto"` | The color scheme until the reader picks one with the header's button: `"auto"` (the system's), `"light"` or `"dark"`. |
| `primary` | `"indigo"` | The header's color and the links': a palette name (`red`, `pink`, `purple`, `deep-purple`, `indigo`, `blue`, `light-blue`, `cyan`, `teal`, `green`, `light-green`, `lime`, `yellow`, `amber`, `orange`, `deep-orange`, `brown`, `grey`, `blue-grey`, `black`, `white`), else any CSS color. |
| `accent` | `"indigo"` | The color of hovered links and focus; the same names. |
| `font_text`, `font_code` | `""` | Font family names; empty: the system's fonts. Nothing is downloaded: load a web font with `extra_css`. |
| `logo`, `favicon` | `""` | Paths from the site root (files in the source directory are copied to the output), or URLs. |
| `language` | `"en"` | The pages' `lang`, and the language of the theme's labels (English where it has none). |
| `extra_css`, `extra_js` | `[]` | Stylesheets and scripts added to every page: paths from the site root, or URLs. |
| `social` | `[]` | Footer links: `{ icon = "mail", link = "..." }`; `icon` is `link`, `mail`, `rss`, `chat` or `code`, else an image's path or URL. |
| `footer` | `""` | The footer's text (HTML). |
| `edit_url` | `""` | An edit-this-page link: a URL with `{path}` for the page's source path. Generated pages, such as API documentation, get none. |

The theme's stylesheets use cascade layers, so a stylesheet in
`extra_css` overrides them without out-specifying them. Colors, fonts and
sizes are `--lsd-` custom properties (`--lsd-primary`, `--lsd-bg`,
`--lsd-font-text`, ...) that it can set.

### Search

The header's search button, or `/` or Ctrl+K, opens a dialog. Results are
sections of pages, those whose titles match first; every word typed must
match the start of a word. Arrow keys move through the results and Enter
opens one. Every page is in the index, generated ones too; a page whose
front matter says `search: false` is left out.

### Content tabs

Tabs come from the `tab-set` and `tab-item` directives of the
`sphinx-addons` plugin. Tab sets whose items have the same labels are
linked: choosing a label in one chooses it in the others, and the choice
is remembered.

## Overrides

To change a part of a theme without copying it, point `overrides` at a
directory laid out like a theme, with `templates/` and `assets/`:

```toml
theme = "default"
overrides = "overrides"
```

Each file there replaces the theme's file of the same path, or adds a new
one. A template can extend the one it replaces, under the name
`theme/<path>`, and replace a single block. This replaces the default
theme's footer:

```jinja
{# overrides/templates/page.html #}
{% extends "theme/page.html" %}
{% block footer %}
<footer>Built with lsdocs: {{ site.title }}</footer>
{% endblock %}
```

The blocks a theme offers are in its `templates/`; those of the built-in
themes are under `plugins/render-html/themes/` in the lsdocs repository.
The `default` theme's include `title`, `head`, `scripts`, `header`, `nav`,
`toc`, `content`, `pager` and `footer`.

## Writing a theme

A theme is a directory:

```text
my-theme/
  theme.toml
  templates/
    page.html
  assets/
    css/theme.css
    js/theme.js
```

`theme.toml` declares the theme's settings and their defaults under
`[settings]`. There is no separate schema: a setting's kind is its
default's (string, number, boolean, list or table), and a site's value
must be of that kind. A top-level `search = true` asks `render-html` for
a search index.

```toml
# theme.toml
search = false

[settings]
accent = "#06c"
footer = ""
```

`templates/` holds [minijinja](https://docs.rs/minijinja) templates
(Jinja syntax, with `extends`, `block` and `include`). Every page is
rendered with `page.html`. A template sees:

| Name | What |
|---|---|
| `content` | The page body, as HTML. |
| `page.title`, `page.source`, `page.url` | The page's title, source path and output path. |
| `page.root` | The relative path from the page to the site root. |
| `page.metadata` | The page's metadata (front matter, and what transformers added). |
| `page.nav` | The navigation, from `transform-nav`. |
| `page.toc` | The page's table of contents, from `transform-toc`: a list of `id`, `title`, `level` and `children`. |
| `page.previous`, `page.next` | The neighboring pages (`title` and `source`). |
| `site.title`, `site.base_url` | From `lsdocs.toml`. |
| `theme` | The theme's settings: its defaults with the site's values. |
| `lsdocs.version` | The lsdocs version. |
| `search_index` | With `search = true`: the path from the site root of the search index, `_lsdocs/search.json`. |

Filters: `link` (a link in a page, such as a source path ending in `.md`,
to the URL of its output), `page_url` (a document's source path to its
URL relative to the current page) and `url` (a path from the site root to
a URL relative to the current page). The function `asset("css/theme.css")`
gives the URL of a file in `assets/`, relative to the page. Assets are
written to `_lsdocs/` with a hash of their contents in their names, so
they can be cached for good; `asset_importmap()` writes an import map
that maps the theme's JavaScript modules' plain URLs to the hashed ones,
so modules can import their neighbors by plain relative paths:

```jinja
<link rel="stylesheet" href="{{ asset('css/theme.css') }}">
{{ asset_importmap() }}
<script type="module" src="{{ asset('js/theme.js') }}"></script>
```

The body's markup is the same for every theme: sections, admonitions,
code blocks and the rest have classes and `data-` attributes that begin
with `lsd-`. [HTML markup](../reference/html-markup.md) lists them; it is
what a theme's stylesheet is written against.
