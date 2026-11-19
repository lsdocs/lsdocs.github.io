---
title: JavaScript
nav_order: 3
---

# Plugins in JavaScript

The `@lsdocs/plugin` package defines a plugin from an object with a handler
per phase (its API reference: [`@lsdocs/plugin`](https://lsdocs.github.io/lsdocs-plugin-sdk/),
generated from its type declarations). Types for every param, result and node are included, for
TypeScript or type-checked JavaScript:

```js
const { definePlugin } = require('@lsdocs/plugin')

function shout(nodes) {
  for (const node of nodes) {
    if (node.type === 'text') node.value = node.value.toUpperCase()
    if ('children' in node) shout(node.children)
  }
}

const plugin = definePlugin({
  name: 'shout',
  version: '0.1.0',
  transform: {
    nodes: ['text'],
    handler(params) {
      shout(params.document.children)
      return params.document
    },
  },
})

if (require.main === module) plugin.serve()
```

Use it from the site's configuration:

```toml
[[plugins]]
name = "shout"
runtime = "node"
entry = "shout.js"
```

lsdocs runs it as `node shout.js` (set `LSDOCS_NODE` to use another
Node.js).

## Handlers

The definition may have `parse` (`{ extensions, handler }`), `read`,
`transform` (a handler, or `{ nodes, handler }`), `render`
(`{ formats, handler }`) and `renderAll`. Handlers may be `async`, and
may return just the document (or, for `render`, a string or bytes).
`maxConcurrency` lets several requests run at once. The context has
`ctx.site`, `ctx.config` and `ctx.settings`, and `ctx.log`, `ctx.progress` and
`ctx.diagnostic`.

`configFiles: ['acme/{name}/settings.toml']` names the files the plugin
reads its settings from, under the site's `.config/` (`{name}` is its
name in `lsdocs.toml`); they are read when the session starts, and
`ctx.settings` maps each to its text (null if missing), for the plugin to
parse.

## Testing

`@lsdocs/plugin/testing` calls handlers in-process, as lsdocs would:
`parse(plugin, source, text)`, `apply(plugin, document)`,
`render(plugin, document)` and the like, each returning the result and
the events the handler sent.
