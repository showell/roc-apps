# JsGlue

`roc glue` generates platform-facing bindings from the compiler's own type
table. Roc ships `ZigGlue.roc`, `RustGlue.roc` and `CGlue.roc`; there is no
JavaScript one, so a page that wants a Roc value is told the layout by hand.

That is what `arcade/web/shapewire.js` is: a decoder written twice, once as
`ShapeWire.pack` in Roc and once as a reader in JavaScript, with nothing
checking that the two agree. **This spec does not fix that today**, and the
section below says why not — the reason is our own flattening, not a gap in the
generator. Roc's own glue README argues against exactly this:

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

Not yet: tag unions, `Str`, `Dec` and the vector types. The compiler hands over
everything needed for tag unions (`AbiTagUnionLayout` carries the discriminant
offset and each variant's payload layout); they are unwritten, not unavailable.

## Tag unions are NOT what stands between this and shapewire.js

An earlier version of this file said they were — that `Shapes.Shape` is a tag
union, so covering tag unions would let the arcade stop packing frames by hand.
**That is backwards, and worth spelling out because it is an easy thing to keep
believing.**

`Shapes.Shape` never crosses the boundary. The platform declares
`frame : Box(model) -> List(U32)`, so the type table sees a list of unsigned
32-bit integers and nothing else — run the spec and the provided functions come
back as `roc_frame : t31 -> t32` with `t32 = List(t27)`, `t27 = U32`.
`ShapeWire.pack` has already destroyed the type before the compiler looks. A
JsGlue with perfect tag-union support would generate *exactly what it generates
today* for this platform.

So the generated reader is the eight-line RocList walk, and the 67 lines of
wire layout in `shapewire.js` — which kinds exist, which brush carries how many
floats, that a view mark is a lens and an image is `cols × rows` words of
`0xAARRGGBB` — are invisible to it. Those 67 lines grew by three words after
this file was first written (blend, view, image), each a coordinated hand-edit
in `lib/ShapeWire.roc` and `arcade/web/shapewire.js` that no generator saw. The
eight generated lines are the part nobody has ever got wrong.

**What would actually pay: declaring the real type.** If the platform provided
`frame : Box(model) -> List(Shapes.Shape)`, the table would carry the whole
vocabulary, generated readers would walk the tag union and its nested records
and lists, and both `ShapeWire.pack` and those 67 lines would be deleted rather
than checked. Tag unions in JsGlue are a prerequisite for that, not a
substitute for it. The open question is cost: the page would chase pointers
through wasm memory instead of scanning one flat array, and Roc would allocate
per shape rather than once per frame. Neither has been measured.

Until then, `arcade/web/lens_check.mjs` is the compensating control — one
hand-written decode checked against an independently written formula — and it
covers one mark out of the wire's eleven words.

A `Box` of a type the platform never names — an app's own model — reads as the
pointer, because a handle is all a page can hold of it.

A `Box` of a type the platform never names — an app's own model — reads as the
pointer, because a handle is all a page can hold of it.
