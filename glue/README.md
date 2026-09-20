# JsGlue

`roc glue` generates platform-facing bindings from the compiler's own type
table. Roc ships `ZigGlue.roc`, `RustGlue.roc` and `CGlue.roc`; there is no
JavaScript one, so a page that wants a Roc value is told the layout by hand.

That is what `canvas_apps/web/shapewire.js` is: a decoder written twice, once as
`ShapeWire.pack` in Roc and once as a reader in JavaScript, with nothing
checking that the two agree. **This spec does not fix that today**, and the
section below says why not — the reason is our own flattening, not a gap in the
generator. Roc's own glue README argues against exactly this:

> platform code should consume generated glue instead of hand-rolling Roc ABI
> bindings

    roc glue glue/JsGlue.roc <out-dir> canvas_apps/web/platform/main.roc

emits `roc_glue.js`: one reader per type the platform's provided functions
mention, each taking a `DataView` over the wasm memory and a byte offset. For
canvas_apps's platform that includes

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

Tag unions, as of 2026-09-20. Not yet: `Str`, `Dec` and the vector types.

## Tag unions are NOT what stands between this and shapewire.js

An earlier version of this file said they were — that `Shapes.Shape` is a tag
union, so covering tag unions would let canvas_apps stop packing frames by hand.
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
in `lib/ShapeWire.roc` and `canvas_apps/web/shapewire.js` that no generator saw. The
eight generated lines are the part nobody has ever got wrong.

**What would actually pay: declaring the real type.** This was built and
measured on snake, end to end, on 2026-09-20. The platform declares
`frame : Box(model) -> List(Frame.Shape)`, `build.sh` runs `roc glue`, the page
loads the generated `roc_glue.js`, and `shapewire.js` loses its decoder
entirely -- 263 lines down to 167, painting only. `page_check` passes with
identical canvas-call and fill counts.

**The app needed no changes at all.** `lib/Shapes.roc`'s `Shape` is a
structural union, so it unifies with the platform's by shape rather than by
name; only `GameApp` stopped calling `pack`.

    snake, one frame, 432 shapes        Roc      read     total     bytes
    flat: ShapeWire.pack + shapewire   1.223    1.572     2.795    23,424
    typed: List(Shape) + roc_glue      0.596    1.975     2.571    89,856

So: the Roc side HALVES, because packing was about half of it. Reading is 26%
slower, because a generated reader chases pointers and builds records where the
hand-written one scanned a flat array. Net 8% faster, which is noise next to
what else changed.

**The frame is 3.8x bigger on the wire**, and that is structural, not
incidental: a tag union is as wide as its widest variant, so every shape
occupies 208 bytes whether it is a `Blend` (1 byte of payload) or a `Disc`
(200). The flat wire spends what each shape needs.

**The typed frame is more faithful.** The flat wire narrows every number to F32
on the way across; the typed one carries F64. The same fill comes out as
`rgba(255,231,163,0.5099999904632568)` flat and exactly `0.51` typed.

**The catch, and it is the real one: the host cannot release the value.**
Freeing a `List(Shape)` means decrementing each element's inner lists, which
means the HOST knowing the tag union's layout -- in Zig, by hand, the very
thing this spec exists to stop doing in JavaScript. The experiment leaks
deliberately: 135 MB over 800 frames. Roc's glue platform has `HostRcPlan` for
exactly this, so the answer is probably "generate the host side too", but
nothing here does that yet. **Generating the reader is half the problem.**

The experiment lives in scratch and is not adopted. What came back from it into
this repo is tag-union support, which is real and tested against a real frame.

Until then, `canvas_apps/web/camera_check.mjs` is the compensating control — one
hand-written decode checked against an independently written formula — and it
covers one mark out of the wire's eleven words.

A `Box` of a type the platform never names — an app's own model — reads as the
pointer, because a handle is all a page can hold of it.

A `Box` of a type the platform never names — an app's own model — reads as the
pointer, because a handle is all a page can hold of it.
