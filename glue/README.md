# JsGlue

`roc glue` generates platform-facing bindings from the compiler's own type
table. Roc ships `ZigGlue.roc`, `RustGlue.roc` and `CGlue.roc`; `JsGlue.roc` is
the JavaScript one, and it is what reads a frame in `canvas_apps/`.

    roc glue glue/JsGlue.roc <out-dir> canvas_apps/web/platform/main.roc

It emits `roc_glue.js`: one reader per type the platform's provided functions
mention, each taking a `DataView` over the wasm memory and a byte offset.
`canvas_apps/build.sh` runs it on every page build, with the same compiler that
builds the wasm, and copies the result beside the page. The output is never
checked in and never edited.

## What it emits

A scalar is one call:

```js
const read_t38 = (view, at) => view.getFloat64(at, true);
```

A record is its fields at the offsets the compiler committed to — which is the
compiler's order, not the source's:

```js
const read_t41 = (view, at) => ({ a: read_t38(view, at + 0), b: read_t38(view, at + 8),
                                  g: read_t38(view, at + 16), r: read_t38(view, at + 24), });
```

A list is a pointer and a length, with the element stride the compiler gave:

```js
const read_t34 = (view, at) => {
  const start = view.getUint32(at, true);
  const length = view.getUint32(at + 4, true);
  const out = [];
  for (let i = 0; i < length; i++) out.push(read_t33(view, start + i * 208));
  return out;
};
```

A tag union is a discriminant and a payload at one address. A variant with no
payload reads as `{ tag }`, one whose payload the source never named reads as
`{ tag, value }`, and one with named fields reads as `{ tag, ...those }`:

```js
const read_t33 = (view, at) => {
  switch (view.getUint8(at + 200)) {
    case 0: return ({ tag: "Blend", value: read_t34(view, at + 0) });
    case 1: return ({ tag: "Disc", value: read_t35(view, at + 0) });
    ...
  }
};
```

Alongside the numbered readers, each provided function's result also gets a
name taken from the function, because **a type id is a position**: adding one
function to a platform renumbers every type after it, and a page bound to
`read_t32` breaks. A page binds `RocGlue.frame`.

```js
return { read_t1, ..., init: read_t25, advance: read_t31, frame: read_t34, ... };
```

## What it covers

Scalars, `Bool`, `Unit`, `Box`, `List`, records and tag unions, at 32-bit
pointer width because wasm is 32-bit. A type is emitted only when every part of
it is readable, so no reader ever references one that was skipped. `Str`, `Dec`
and the vector types are not covered.

A `Box` of a type the platform never names — an app's own model — reads as the
pointer, because a handle is all a page can hold of it.

## The platform has to declare the real type

A generator can only emit what the type table carries, and the type table
carries what the platform declares. `canvas_apps/web/platform/main.roc` says

```roc
frame : Box(model) -> List(Frame.Shape)
```

and `Frame.roc` spells that type out, so the table holds every shape, every
brush and their exact layouts. A platform that flattened its frame to
`List(U32)` first would get a reader for a list of integers and nothing more,
however much of the type system the generator understood.

## What it costs

Measured on snake, one frame of 432 shapes, against the same app packing its
frame into `List(U32)` by hand and reading it with a hand-written decoder:

    packed by hand, read by hand    Roc 1.192   read 1.737   total 2.929 ms
    typed, read by generated code   Roc 0.336   read 0.205   total 0.541 ms

The frame is larger in memory — a tag union is as wide as its widest variant,
so each shape takes 208 bytes — and it never leaves wasm memory, so the cost of
that is the read time above.

## Freeing what was read

The host holds one frame at a time and has to let go of the last one. Walking a
`List(Shape)` to decrement its elements' inner lists would mean the host
knowing the tag union's layout, so instead the platform requires

```roc
release : List(Frame.Shape) -> {}
```

which `lib/WasmApp.roc` answers with `|_frame| {}`. The host hands the frame
back and Roc drops it with the layout it already has.
