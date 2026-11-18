---
title: Python
nav_order: 2
---

# Plugins in Python

The `lsdocs-plugin` package (`import lsdocs_plugin`) registers handlers
by decorator (its API reference: [`lsdocs_plugin`](../api/python/lsdocs_plugin.md)
and [`lsdocs_plugin.testing`](../api/python/lsdocs_plugin.testing.md), generated
from its source). Each handler gets the request's params, as dicts shaped like
the protocol, and a context:

```python
from lsdocs_plugin import Plugin

plugin = Plugin("shout", "0.1.0")


@plugin.transform(nodes=["text"])
def shout(params, ctx):
    def walk(nodes):
        for node in nodes:
            if node["type"] == "text":
                node["value"] = node["value"].upper()
            walk(node.get("children", []))

    doc = params["document"]
    walk(doc["children"])
    return doc


if __name__ == "__main__":
    plugin.serve()
```

Use it from the site's configuration:

```toml
[[plugins]]
name = "shout"
runtime = "python"
module = "shout"
```

lsdocs runs it as `python -m shout` in the site directory (set
`LSDOCS_PYTHON` to use another interpreter).

## Handlers

| Decorator | Handles |
|---|---|
| `@plugin.parse(extensions=["txt"])` | Parsing; return the document, or `{"document", "diagnostics"}`. |
| `@plugin.read` | `parse/transform/each`: reads each document; return any value. |
| `@plugin.transform(nodes=[...])` | `render/transform/each`: changes each document; `params["collected"]` has what `read` returned for every document. Return the document. |
| `@plugin.render(formats=["html"])` | Rendering; return a `str` or `bytes`. |
| `@plugin.render_all` | Files no single page makes (`render/transform/all`); return a list of `{"path", "output"}`. |

Handlers may be `async def`; coroutines share one event loop. Handlers run
one at a time unless `Plugin("x", "1.0", max_concurrency=8)` lets more
overlap. The context has `ctx.site`, and sends logs, progress and
diagnostics.

A plugin's settings are files it reads from the site's `.config/`
directory: name them with `config_files`, `{name}` standing for the
plugin's name in `lsdocs.toml`. They are read when the session starts;
`ctx.settings` maps each to its text (None if missing), for the plugin to
parse, and `ctx.config` has `dir` and `name`:

```python
import tomllib

SETTINGS = "acme/{name}/settings.toml"
plugin = Plugin("shout", "0.1.0", config_files=[SETTINGS])

@plugin.read
def read(params, ctx):
    text = ctx.settings[SETTINGS.format(name=ctx.config["name"])]
    settings = tomllib.loads(text) if text else {}
    ...
```

## Testing

`lsdocs_plugin.testing` calls handlers in-process, as lsdocs would:

```python
from lsdocs_plugin import testing

result, events = testing.apply(plugin, {"source": "a.md", "children": [
    {"type": "text", "value": "hi"},
]})
assert result["document"]["children"][0]["value"] == "HI"
```
