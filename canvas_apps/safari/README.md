# safari

The driving screensaver, as a canvas app: a rider on a motorcycle, a route of
nineteen segments through fields, forests and towns, and animals that cross
when they like. It runs as a page and as a native program on roc-ray, like the
other canvas apps (`../README.md`).

    canvas_apps/build.sh safari       the page, http://<box>:9210/safari/
    canvas_apps/native.sh safari      the native program

Space pauses. Left and Right step back and forward through the ride's history —
a frame at a time while paused, faster while it runs. Enter jumps to the next
intersection. R starts the drive again.

## Where it came from

Safari began as a Codex program, the language of
[Cobblestone](https://github.com/damiant3/Cobblestone), and its chapter modules
were emitted as Roc by rust-codex-compiler's `rocemit`, one module per Codex
chapter. **The Roc is the program now**, edited here like any other Roc. The
Codex program is still the Codex program in `safari-codex`, which emits the
zig, the wasm and the C#; it does not emit this.

Every module that began as an emission says so in its header.

## The map

| | |
|---|---|
| `SafariApp.roc` | the `CanvasApp` value: the keys, the pause, and the frame leaned by the rider's roll |
| `SafariRide.roc` | the drive for any platform: the ride between frames, the history for stepping back, and what a frame shows — the commands, the roll, the sky colours, the sun |
| `SafariShapes.roc` | a frame as shapes: the sky's gradient, the grass, the sun and its glow, and every command |
| `SafariBrush.roc` | a command's paint read once into a `Brush.Fill` |
| `Safari.roc` and the chapter modules | the world, the route, the rider, the animals, the scenery, and how each is drawn |
| `RocBird.roc` | the bird, the first thing here that was never Codex |
| `*Spec.roc` | the 54 spec apps that graded each chapter against the Codex verdicts |

**The rider's lean is a camera.** The whole frame, backdrop and all, turns by
minus the roll about the middle of the screen, so the world banks into a turn.
`SafariApp.frame` puts that in front of the frame as a `View(World(...))` mark,
and both runners paint it the way they paint any camera.

## The native proof tools

Five modules that check the frame without a screen: `Raster.roc` paints a frame
into 960×600 pixels in Roc, `RasterFrame.roc` prints one frame's pixels as hex
with a hash (`pixels_png.mjs` turns that into a PNG), `ShapesFrame.roc` paints
the frame from its shapes and from its commands and counts the pixels that
differ, `StepBack.roc` checks that one step back goes back exactly one step at
depths either side of the history's cap, and `FrameBench.roc` is a loop over
the frame for `perf`.

They, and the spec apps, are not built by `build.sh` or `native.sh`.
`emitted.sh` and `retest.sh`, which emitted and graded the spec apps, refuse to
run: the modules they would rewrite are source now.
