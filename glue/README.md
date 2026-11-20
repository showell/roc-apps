# JsGlue

`roc glue` generates platform-facing bindings from the compiler's own type
table. Roc ships glue specs for Zig, Rust and C; `JsGlue.roc` is the
JavaScript one. It reads a frame in `canvas_apps/` and a view in `fasttrack/`.

    roc glue glue/JsGlue.roc <out-dir> canvas_apps/web/platform/main.roc

It emits `roc_glue.js`: one reader per type the platform's provided functions
mention, each taking a `DataView` over the wasm memory and a byte offset.
`canvas_apps/build.sh` runs it on every page build, with the compiler that
builds the wasm, and copies the result beside the page. The output is a build
product, untracked.

## What it emits

A scalar is one call:

```js
const read_t38 = (view, at) => view.getFloat64(at, true);
```

A record is its fields at the compiler's offsets, in the compiler's order:

```js
const read_t41 = (view, at) => ({ a: read_t38(view, at + 0), b: read_t38(view, at + 8),
                                  g: read_t38(view, at + 16), r: read_t38(view, at + 24), });
```

A list is a pointer and a length, with the compiler's element stride:

```js
const read_t34 = (view, at) => {
  const start = view.getUint32(at, true);
  const length = view.getUint32(at + 4, true);
  const out = [];
  for (let i = 0; i < length; i++) out.push(read_t33(view, start + i * 208));
  return out;
};
```

A tag union is a discriminant and a payload at one address. A bare variant
reads as `{ tag }`, one with an unnamed payload as `{ tag, value }`, and one
with named fields as `{ tag, ...those }`:

```js
const read_t33 = (view, at) => {
  switch (view.getUint8(at + 200)) {
    case 0: return ({ tag: "Blend", value: read_t34(view, at + 0) });
    case 1: return ({ tag: "Disc", value: read_t35(view, at + 0) });
    ...
  }
};
```

Each provided function's result also gets a name taken from the function,
because **a type id is a position**: adding a function to a platform renumbers
every type after it. A page binds `RocGlue.frame`, which stays put.

```js
return { read_t1, ..., init: read_t25, advance: read_t31, frame: read_t34, ... };
```

## What it covers

Scalars, `Bool`, `Unit`, `Str`, `Box`, `List`, records and tag unions, at
32-bit pointer width, as wasm is. A type is emitted when every part of it is
readable, so every reader it references exists. `Dec` and the vector types are
outside its scope.

A `Str` is three words: bytes, capacity, length. A small one keeps its bytes
in the three words themselves and sets the high bit of the last byte, whose
low seven bits are its length. Either way the bytes are UTF-8, and `readStr`
decodes them with a `TextDecoder`.

A `Box` of a type the platform leaves unnamed, such as an app's own model,
reads as the pointer: a handle is what a page holds of it.

## The platform declares the real type

A generator emits what the type table carries, and the table carries what the
platform declares. `canvas_apps/web/platform/main.roc` says

```roc
frame : Box(model) -> List(Shapes.Shape)
```

and lib's `Shapes.roc` spells that type out, so the table holds every shape,
every brush and their exact layouts. A platform that flattened its frame to
`List(U32)` would get a reader for a list of integers.

## What it costs

A typed frame is larger in memory: a tag union is as wide as its widest
variant. It stays in wasm memory and is read in place, and on snake the typed
frame, read by generated code, is several times faster end to end than the
same frame packed into `List(U32)` and decoded by a custom reader.

## Freeing what was read

The host holds one frame at a time and lets go of the last one. Walking a
`List(Shape)` to decrement its elements' inner lists would teach the host the
tag union's layout, so the platform requires

```roc
release : List(Frame.Shape) -> {}
```

which `lib/WasmApp.roc` answers with `|_frame| {}`. The host hands the frame
back and Roc drops it with the layout it already has.
