# safari

A screensaver of a ride, as a canvas app: a rider on a motorcycle, a route of
nineteen segments through fields, forests and towns, and animals that cross
when they like. It runs as a page and as a native program on roc-ray, like the
other canvas apps (`../README.md`). **The page is the maintained side**; the
native program is the canvas apps' roc-ray spike, which proved the concept and
is not kept current.

    canvas_apps/build.sh safari       the page, http://<box>:9210/safari/
    canvas_apps/build.sh safari release   the same page as release wasm, which is what publishes
    canvas_apps/native.sh safari      the native program (the spike, not kept current)

Space pauses. Left and Right step back and forward through the ride's history —
a frame at a time while paused, faster while it runs. J jumps to the next
bend. R starts the ride again.

## Where it came from

Safari began as a Codex program, the language of
[Cobblestone](https://github.com/damiant3/Cobblestone), and its chapter modules
were emitted as Roc by rust-codex-compiler's `rocemit`, one module per Codex
chapter. **The Roc is the program now**, edited here like any other Roc. The
Codex program is still the Codex program in `safari-codex`, which emits the
zig, the wasm and the C#; it does not emit this.

A module whose header says it was emitted still reads much as it was emitted.
The rest have been rewritten by hand.

## The map

| | |
|---|---|
| `SafariApp.roc` | the `CanvasApp` value: the keys, the pause, and the frame leaned by the rider's roll |
| `Tour.roc` | the whole ride for any platform: the current instant, the instants behind it for stepping back, and the current instant's `FrameView` |
| `FrameView.roc` | what the camera shows at one instant: the shapes, the sun, the sky colours and the roll |
| `Backdrop.roc` | a frame as shapes: the sky's gradient, the sun and its glow, the grass, and the ride's shapes |
| `Polygon.roc` | makers that turn screen points and colours into `Shapes.Shape` values, for the drawing modules |
| `HexColor.roc` | lib's `RgbColor`: its channels, packing them, and shading |
| `SafariFrame.roc` | a frame painted into pixels in Roc, for the proof tools below |
| `RideInstant.roc` and the chapter modules | one instant of the ride, the world, the route, the rider, the animals, the scenery, and how each is drawn |
| `PosedBird.roc` | the bird, the first thing here that was never Codex, with `BirdFlight.roc`, `CrossingSighting.roc` and `BirdStills.roc` |
| `Pipeline.roc` | the steps every kind of object takes through a frame: placed (`Geom.Placed`), sighted (`Pipeline.Sighted`), then rendered (`Rendered.roc`, a `Picture.roc` and its depth). `Conifer.roc`, `Billboard.roc`, `Tower.roc` and `LitTruck.roc` are among the kinds that go through it, and the depth sort orders the renderings |
| `Animation.roc` | what the cat and the bird share: a rule that turns where the rider is into a stage, and a timeline that turns a stage into an instant |
| `CrossingReaction.roc` | what a segment's crossing does to the rider, the one place that matches on it for `Throttle` and `RideFocal` |
| `gates/` | test code the game never runs: the tiers `fast.shale`, `run.shale` and `publish.shale`, and the lints; `CrossModuleExpects.roc`, the expects that need more than the module they check imports; the proof tools and the modules only they use. They reach the game's modules through the package `game.roc` |

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

They are not built by `build.sh` or `native.sh`; the gates build and judge
them, in three tiers, each run from the roc-apps root:

    nice -n 19 shale canvas_apps/safari/gates/fast.shale       each edit
    nice -n 19 shale canvas_apps/safari/gates/run.shale        before a push
    nice -n 19 shale canvas_apps/safari/gates/publish.shale    before the site moves

| Tier | Runs | Time |
|---|---|---|
| `fast.shale` | `roc check`, one test root, the one-file lints on changed files, one frame; stops at the first failure | about 10 s, or a minute and a half on a checkout's first run |
| `run.shale` | every lint, every expect, every widget's check and expects, the tutorial, the names in its prose, the proof tools, the dev page; reports every failure | two to three minutes |
| `publish.shale` | the merge gate and `check.shale` from cold caches, then the book, which builds safari's page and every widget's as release wasm | about six minutes |

The book of the tutorial, one page a chapter, builds into the dev channel at
`/tutorial/` with `nice -n 19 shale canvas_apps/safari/tutorial/book.shale`. It
runs on demand and at publish, and it needs roc-markdown beside this checkout.
It takes under a minute unless a widget's page needs rebuilding.

An agent runs the fast tier, and one merge gate runs at a time, because the box
has two cores. Each tier ends by naming what it didn't run.

The fast tier lints only the `.roc` files changed since the checkout's last
green, by the checks one file can answer. `lints.shale` names the ones that need
the whole tree. A count held above zero is reported there and doesn't fail.

On roc-apps' pinned nightly (`roc-version`, installed at
`~/tools/roc-<pin>/roc`), the merge gate runs the lints, then `roc test` so that
every `expect` in the modules, and in `lib/`, passes exactly once. Then it checks
and tests every widget, builds the tutorial, runs StepBack, ShapesFrame and
RasterFrame at the depths its script lists, and builds the page. `part=expects`,
`part=widgets`, `part=tutorial`, `part=proof` or `part=page` runs one piece. The
script's header has the rest.

The fast and merge tiers keep their Roc caches under
`~/build/roc-apps/safari-gate-caches/`, and `publish.shale` runs on empty ones.

An `expect` sits below the block of the module it checks. Where it needs a
module that one doesn't import, it sits in a module that sees both, such as
`BendView.roc` or `SceneShapes.roc`, or else in `gates/CrossModuleExpects.roc`.

`emitted.sh` and `retest.sh`, which emitted the Roc from Codex, refuse to run:
the modules they would rewrite are source now.
