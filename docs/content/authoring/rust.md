---
title: Rust
nav_order: 1
---

# Plugins in Rust

The `lsdocs-plugin-sdk` crate has the traits, the document types and the
protocol. Implement `Parser`, `Transformer` or `Renderer`, put them in a
`Plugin`, and hand it to `lsdocs_plugin_sdk::main`:

```rust
use lsdocs_plugin_sdk::doctree::Node;
use lsdocs_plugin_sdk::protocol::{TransformApplyParams, TransformApplyResult};
use lsdocs_plugin_sdk::{Context, Plugin, PluginResult, Transformer};

/// Upper-cases every text node.
struct Shout;

impl Transformer for Shout {
    fn nodes(&self) -> Vec<String> {
        vec!["text".into()]
    }

    async fn apply(
        &self,
        mut params: TransformApplyParams,
        _ctx: &Context,
    ) -> PluginResult<TransformApplyResult> {
        shout(&mut params.document.children);
        Ok(TransformApplyResult {
            document: params.document,
            diagnostics: Vec::new(),
        })
    }
}

fn shout(nodes: &mut [Node]) {
    for node in nodes {
        match node {
            Node::Text(t) => t.value = t.value.to_uppercase(),
            other => {
                if let Some(children) = other.children_mut() {
                    shout(children);
                }
            }
        }
    }
}

fn main() -> std::process::ExitCode {
    lsdocs_plugin_sdk::main(Plugin::new("shout", "0.1.0").transformer(Shout).cacheable())
}
```

Build it and point the site at the program:

```toml
[[plugins]]
name = "shout"
command = ["target/release/shout"]
```

## The traits

- `Parser`: `extensions()` (without the dot) and `parse(params, ctx)`,
  which gets the file's `source` path and `text` and returns a
  `ParseResult` (the document and diagnostics).
- `Transformer`: `nodes()` (node kinds to select; empty for every
  document) and `apply`. Set `const COLLECTS: bool = true` and implement
  `collect` to gather data first: `apply` then finds a map from each
  document's source to what was collected in `params.collected`.
- `Renderer`: `formats()` and `render`, returning the output bytes and
  their file extension. Set `const SITE: bool = true` and implement
  `render_site` to add site-wide files.

The `Context` gives the site (`ctx.site()`) and the plugin's options
(`ctx.options()`), and sends logs (`ctx.info(...)`), progress and
diagnostics to lsdocs while a request runs.

`Plugin::cacheable()` lets lsdocs cache results that depend only on the
request, the site settings and the options; `cache_key` covers other
inputs, such as a template file.

## Testing

`lsdocs_plugin_sdk::testing` runs a plugin without lsdocs:
`testing::run_transform(&plugin, &initialize, documents)` runs the collect
and apply passes the way lsdocs does, and `testing::context` makes a
`Context` for calling `parse` or `render` directly.
