# safari

The driving screensaver, as a canvas app: a rider on a motorcycle, a route of
nineteen segments through fields, forests and towns, and animals that cross
when they like. It runs as a page and as a native program on roc-ray, like the
other canvas apps (`../README.md`). **The page is the maintained side**; the
native program is the canvas apps' roc-ray spike, which proved the concept and
is not kept current.

    canvas_apps/build.sh safari       the page, http://<box>:9210/safari/
    canvas_apps/native.sh safari      the native program (the spike, not kept current)

Space pauses. Left and Right step back and forward through the ride's history —
a frame at a time while paused, faster while it runs. J jumps to the next
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
| `Tour.roc` | the whole journey for any platform: the current moment, the moments behind it for stepping back, and what a frame shows — the shapes, the roll, the sky colours, the sun |
| `SafariShapes.roc` | a frame as shapes: the sky's gradient, the grass, the sun and its glow, and the ride's shapes |
| `Paint.roc` | builders that turn screen points and colours into `Shapes.Shape`s, for the drawing modules |
| `SafariFrame.roc` | a frame painted into pixels in Roc, for the proof tools below |
| `RideMoment.roc` and the chapter modules | one moment of the ride, the world, the route, the rider, the animals, the scenery, and how each is drawn |
| `RocBird.roc` | the bird, the first thing here that was never Codex, with `BirdFlight.roc`, `BirdSighting.roc` and `BirdStills.roc` |
| `Animation.roc` | what the cat and the bird share: a rule that turns where the rider is into a stage, and a timeline that turns a stage into a moment |
| `CrossingReaction.roc` | what a segment's crossing does to the rider, the one place that matches on it for `Throttle` and `RideFocal` |
| `*Spec.roc` | the spec apps, each chapter's checks not yet moved into its module as `expect`s, graded by `gates/` |
| `gates/` | test code the game never runs: the gate, `run.shale`, and its lints; the specs' expected outputs; the proof tools and the modules only they use, which reach the game's modules through the package `game.roc` |

**The rider's lean is a camera.** The whole frame, backdrop and all, turns by
minus the roll about the middle of the screen, so the world banks into a turn.
`SafariApp.frame` puts that in front of the frame as a `View(World(...))` mark,
and both runners paint it the way they paint any camera.

## The native proof tools

Everything here lives in `gates/`. `SafariFrame.roc` paints a frame into exact pixels; its
header says what it is for, why the game paints differently, and which
generic modules it builds on.

Four programs check the frame without a screen: `RasterFrame.roc` prints one
frame's pixels as hex with a hash (`pixels_png.mjs` turns that into a PNG),
`ShapesFrame.roc` paints the frame with its polygons whole and again with them
cut into triangles, and counts the pixels that differ, `StepBack.roc` checks that one step back goes back exactly one step at
depths either side of the history's cap, and `FrameBench.roc` is a loop over
the frame for `perf`. RasterFrame and ShapesFrame write their hex through
`Hex.roc`.

They, and the spec apps, are not built by `build.sh` or `native.sh`; the gate
builds and judges them, from the roc-apps root:

    nice -n 19 shale canvas_apps/safari/gates/run.shale

On roc-apps' pinned nightly (`roc-version`, installed at
`~/tools/roc-<pin>/roc`), it runs `roc test` so that every `expect` in the
modules, and in `lib/`, passes exactly once. Then it builds each spec app and
compares its output with `gates/expected/<Spec>.expected`, and runs StepBack,
ShapesFrame and RasterFrame at the depths its script lists. `part=expects`,
`part=1`, `part=2` or `part=proof` runs one piece. The
expected files began as the Codex verdicts (safari-codex's `units/`) and are
safari's own now: when a spec's output rightly changes, its expected file
changes with it. The script's header has the rest.

`emitted.sh` and `retest.sh`, which emitted and graded the spec apps, refuse to
run: the modules they would rewrite are source now.
