---
title: Other languages
nav_order: 4
---

# Plugins in other languages

A plugin is any program that speaks the [protocol](../reference/protocol.md)
on its standard input and output. That takes a MessagePack library (or a
small codec of your own) and four things:

1. **Framing.** Every message is a 4-byte big-endian length, then that
   many bytes of MessagePack.
2. **Messages.** A request is `[0, id, method, [params]]`, its response
   `[1, id, error, result]` (`error` is nil on success), a notification
   `[2, method, [params]]`. Params are always wrapped in an array.
3. **The handshake.** Answer the `initialize` request with the protocol
   version, your plugin's name and version, and its capabilities:

   ```json
   {"protocol_version": "1.0-rc.0",
    "plugin": {"name": "txt-parser", "version": "1.0.0"},
    "capabilities": {"parse": {"extensions": ["txt"]}}}
   ```

4. **The phases** your capabilities claim: here, answer each `parse`
   request (`{"source", "text"}`) with `{"document": ...}`. Answer
   `shutdown` with nil, and exit on the `exit` notification or when stdin
   closes.

Keep stdout for the protocol: write logs to stderr.

## A complete example

`examples/plugins/txt-parser/txt_parser.py` in the repository is a
parser for `.txt` files in about 200 lines of standard-library Python,
MessagePack codec included, written from the specification alone. The
test suite builds a site with it.

## Checking your implementation

- The JSON Schemas in `schema/` describe every message and the document
  tree, for generating types.
- `fixtures/` has an encoded example of each message, with a JSON twin:
  decoding the `.msgpack` file must give the `.json` one.
- `lsdocs build --trace-rpc` logs every message exchanged, as JSON.
