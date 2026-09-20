# JsGlue

`roc glue` generates platform-facing bindings from the compiler's own type
table. Roc ships `ZigGlue.roc`, `RustGlue.roc` and `CGlue.roc`; there is no
JavaScript one, so a page that wants a Roc value is told the layout by hand.

That is what `arcade/web/shapewire.js` is: a decoder written twice, once as
`ShapeWire.pack` in Roc and once as a reader in JavaScript, with nothing
checking that the two agree. Roc's own glue README argues against exactly this:

> platform code should consume generated glue instead of hand-rolling Roc ABI
> bindings

    roc glue glue/JsGlue.roc <out-dir> arcade/web/platform/main.roc

emits `roc_glue.js`: one reader per type the platform's provided functions
mention, each taking a `DataView` over the wasm memory and a byte offset. For
the arcade's platform that includes

    // List(t23)
    const read_t28 = (view, at) => {
      const start = view.getUint32(at, true);
      const length = view.getUint32(at + 4, true);
      ...
      for (let i = 0; i < length; i++) out.push(read_t23(view, start + i * 4));

which is the frame-decoding half of `shapewire.js`, generated rather than
written. Driven against a built `snake.wasm` it reads the same 3,820 words the
hand-written decoder does.

## What it covers, and what it does not

Scalars, `Bool`, `Unit`, `Box`, `List` and records, at 32-bit pointer width
because wasm is 32-bit. A type is emitted only when every part of it is
readable, so no reader ever references one that was skipped.

Not yet: tag unions, `Str`, `Dec` and the vector types. Tag unions are the
important gap — `Shapes.Shape` is one, so until they are covered the arcade
still packs its frames by hand. The compiler hands over everything needed
(`AbiTagUnionLayout` carries the discriminant offset and each variant's payload
layout); it is unwritten, not unavailable.

A `Box` of a type the platform never names — an app's own model — reads as the
pointer, because a handle is all a page can hold of it.
