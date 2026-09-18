# safari

Safari, our driving screensaver, as Roc: the chapter modules emitted from the
Codex source by rust-codex-compiler's `rocemit`, the spec apps that grade them
against the Codex verdicts, and the edges that run them. On the web, a wasm
platform and app run them in the browser page the Codex version used; natively,
roc-ray does (`ray/README.md`). The first Roc-only flair is a Roc on the fifth
tree on the right of every segment.

## The Roc is the program now

**Retired 2026-09-18, Steve's call:** "the Roc program is the new program going
forward. We should never re-emit Roc from Codex at this point. That's no longer
worth the trouble."

`roc/*.roc` is source, hand-edited like any other Roc. `emitted.sh` and
`retest.sh` refuse to run, because the first of them deleted every file whose
header said it was emitted -- which is now the program. safari-codex is still
the Codex program and still emits the zig, the wasm and the C#; it just does
not emit this.

The files changed since are `DepthSort.roc`, `Render.roc`, `ItemDraw.roc`,
`RocBird.roc` and `SafariRide.roc`, and their headers say what they are. **The
rest still carry the old "Do not edit" line**, which is now untrue of all of
them; they will be corrected as they are touched, or in one sweep.

## The map

| where | what | written by |
|---|---|---|
| `roc/*.roc` | one type module per Codex chapter, whole, as written; one app per spec (`*Spec.roc`) | `rocemit`, via `emitted.sh` |
| `roc/SafariRide.roc` | the screensaver for any platform: the ride between frames, the history for stepping back, and what a frame shows (commands after blit expansion, roll, sky colours, sun) | hand |
| `roc/RocBird.roc` | the bird | hand |
| `roc/Brush.roc` | a command's paint decoded once, a flat colour or one of the blitter's gradients, and `shade`, the colour it gives a scene point; Raster uses it, and roc-ray's shader does the same arithmetic | hand |
| `roc/Shapes.roc` | a frame as shapes a drawing platform fills itself, each with its brush: convex polygons, ear-clipped triangles wound for raylib, discs, rectangles; the blitter's sky and clipped sun | hand |
| `roc/Raster.roc` | a frame painted into 960x600 pixels in Roc, as blitter.js paints the canvas: backdrop, sun, commands, under the roll; nonzero fills, no anti-aliasing | hand |
| `roc/SafariApp.roc` | the wasm edge of SafariRide: the model boxed for the page, the frame packed into the blitter's words, the readouts | hand |
| `roc/FrameBench.roc` | a native loop over the frame, for `perf` | hand |
| `roc/RasterFrame.roc` | one frame painted natively and printed as hex with its hash; `ray/pixels_png.mjs` turns that into a PNG | hand |
| `roc/ShapesFrame.roc` | the check on Shapes: Raster paints the frame itself and again from Shapes' pieces with their brushes, and the pixels that differ are counted | hand |
| `wasm/` | the platform: `platform/main.roc` provides the page's sixteen exports over `Box(Model)`; `platform/host.zig` is the host; `build.zig` builds it against the roc checkout; `drive_smoke.mjs` drives the built module from Node as the page does (first frame, readouts, ms per step, `back`); `frame_hash.mjs` hashes every frame's bytes and readouts over a fixed ride, so a change that should move no pixel is held to that; `run_wasm.mjs` runs any Roc module's `wasm_main` with logged `env` imports | hand |
| `web/` | the page: a copy of safari-codex's `blitter.js`, and its `index.html` | hand |
| `build.sh` | host + app + page into the dev channel, `http://<box>:9210/safari/` | hand |
| `emitted.sh` | THE GATE: every unit emitted, chapter identity checked, roc run two at a time, output against the verdict; a compile error is a FAIL | hand |
| `retest.sh` | the targeted sweep: emit all, diff against the tracked Roc, run only what changed | hand |
| `../docs/codex-subset.md` | the forms safari uses, counted over the 54 IRs | hand |

The units come from `~/showell_repos/safari-codex/units/` (`<Spec>.codex`
resolved, `<Spec>.expected` the verdict the Rust interpreter froze).

`roc/` is generated and committed. A full `emitted.sh` rewrites every emitted
file and leaves the hand-written ones, which carry no rocemit header; a diff
there is a change in what the emitter says.

## The loop

    safari/emitted.sh              # 54 units, ~10-27 s; the gate before a commit of safari/roc
    safari/retest.sh               # after a rocemit change: only what changed
    safari/build.sh                # host + app + page -> dev, http://<box>:9210/safari/, ~15 s
    node safari/wasm/drive_smoke.mjs ~/build/roc-apps/next/safari/safari.wasm 120   # frame bytes, stages, ms per frame
    node safari/wasm/frame_hash.mjs ~/build/roc-apps/next/safari/safari.wasm        # every frame's hash, and their digest
    site/publish.sh safari         # when dev looks right: staging, http://<box>:9200/safari/
