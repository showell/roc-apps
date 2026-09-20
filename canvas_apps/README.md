# Canvas apps

Small interactive Roc programs that run two ways from one set of files: as a
native program on roc-ray, and as a page in a browser.

Six of them, covering a few different kinds of program. `snake`, `pong` and
`breakout` are arcade games ported from roc-ray's own examples. `camera` is a
world larger than the window, with a camera over it and a HUD that stays put.
`workshop` is a pixel paint program you drag on. `trick_or_treat` is a movie
you can scrub, forked from `movies/halloween` — **that movie still exists and
is what prod serves**, so the two drift independently and an edit to one is not
an edit to the other.

    canvas_apps/build.sh snake       the page,   http://<box>:9210/snake/
    canvas_apps/native.sh snake      the native program
    TARGET=x64win canvas_apps/native.sh snake     for Windows

    node canvas_apps/web/page_check.mjs snake
    KEYS=3:Space DRAG=200,100,200,500 node canvas_apps/web/page_check.mjs pong
    node canvas_apps/web/camera_check.mjs

## Layout

| | |
|---|---|
| `snake_web.roc` | the app a browser runs — sits on `web/platform/`, uses `lib.WasmApp` |
| `snake_native.roc` | the app roc-ray runs — uses `native/CanvasAppRunner` |
| `snake/` | the program itself, and everything that is only about it, its `page.html` included. It cannot tell which runner is running it |
| `lib/` | a package every app shares: `CanvasApp` `WasmApp` `Shapes` `Brush` `Input` `Keys` `Mouse` `Math` `Color` `Camera` `Font` `Random` `Trig` `DeviceMath` `BrushGlsl` `View` |
| `web/` | the page's end: the wasm platform and host, `build.zig` and `options.zig` (the host object, rebuilt by every page build), `canvas_app_runner.js`, `shapewire.js`, `page_check.mjs`, `camera_check.mjs` |
| `native/` | roc-ray's end: `CanvasAppRunner.roc` |

An app's own directory holds a `<Name>App.roc` with the `CanvasApp` value in
it, a `page.html`, and whatever rules and drawing it needs.

**The two app files sit at the top rather than beside the app.** An app file is
where Roc's package root is, and a relative import may not climb above it.
`lib/` is reachable from anywhere because it is a package, and a package
reference is not a relative import. `native/CanvasAppRunner.roc` cannot be a
package, because a package cannot see a platform: it imports roc-ray's own
modules, and as a package module every roc-ray type comes back as an
unresolved type variable. So both app files live where everything they reach is
below them, and the file name says which is which.

**roc-ray is named in the source, not by a script.** `<name>_native.roc` says
`../../roc-ray/platform/main.roc`, so roc-ray has to be a sibling of
`roc-apps` on disk; nothing stages the app or rewrites that line on its way
into a build. `native.sh` checks it and says so when it is not there.

## Adding an app

Four files, and `build.sh` exits 2 if either the app file or the page is
missing:

    <name>_web.roc              5 lines: WasmApp.program(<Name>App.canvas_app)
    <name>_native.roc           5 lines: CanvasAppRunner.program(<Name>App.canvas_app)
    <name>/<Name>App.roc        the CanvasApp value
    <name>/page.html            loads three scripts, and sets window.SHOW first

The page's own part is one object, before the script tags:

```html
<script>
window.SHOW = { wasm: '<name>.wasm', loading: 'Loading…' };
</script>
<script src="roc_glue.js"></script>
<script src="shapewire.js"></script>
<script src="canvas_app_runner.js"></script>
```

Copy an existing `page.html`; `canvas_app_runner.js` throws if `window.SHOW` is
not set.

**The keys an app may read are a closed set of nineteen** (`lib/Keys.roc`): the
four arrows, `W` `A` `S` `D` `Q` `E` `C` `P` `R`, Space, Enter, and `1`–`4`.
Adding one touches four places — `Keys.Key` and `Keys.bit`, `KEY_BIT` in
`web/canvas_app_runner.js`, and `watched_keys` plus both match arms in
`native/CanvasAppRunner.roc` — so a key exists on both ends or on neither.

## What an app is

`lib/CanvasApp.roc` is the type. An app is a record of eight fields over its
own model:

```roc
CanvasApp(model) : {
    size : { width : F64, height : F64 },
    fps : I32,
    init : model,
    advance : model, Input.Snapshot, F32 -> model,
    frame : model -> List(Shapes.Shape),
    sounds : model -> U32,
    tones : List({ freq : I32, ms : I32 }),
    title : Str,
}
```

`advance` takes one step, given what the keyboard and pointer look like now and
how many seconds the step covers — always `1 / fps`, since each runner paces to
the app's own rate. `frame` answers what to draw. `sounds` answers a bit per
tone the last step set off, and `tones` says what each one sounds like, so a
runner never has to guess how many there are.

An app imports no platform, so the same value goes to either runner. Each app
names its value out loud:

```roc
program = WasmApp.program(SnakeApp.canvas_app)          # snake_web.roc
program = CanvasAppRunner.program(SnakeApp.canvas_app)  # snake_native.roc
```

## What a frame is

A list of `Shapes.Shape` in the app's own coordinates. Five shapes and two
marks:

| | |
|---|---|
| `Poly` | points and a `Brush.Fill` |
| `Disc` | centre, radius, a fill, and a rectangle it is kept inside |
| `Rect` | a box and a fill |
| `Pieces` | the triangles of one concave polygon, and a fill |
| `Image` | `cols × rows` of `Brush.Rgba`, stretched over a box without smoothing |
| `Blend` | `Over` or `Add` |
| `View` | `Screen`, or `World` with a camera's four settings |

An app writes `Poly` and lets `Shapes.cut` make `Pieces`: the native runner
calls it, because roc-ray fills convex polygons only, and the canvas does not,
because it fills a concave one itself.

A mark is not drawn. It changes how the shapes after it are painted, until the
next mark of its kind. `Blend(Add)` lights rather than paints. `View(World(c))`
puts the shapes after it in a camera's world and `View(Screen)` brings them
back to the window. A frame starts on the screen, painting over.

A `Brush.Fill` is `Skip`, a flat colour, or one of five gradients — `Span`,
`Radial`, `Linear`, `Ellipse`, `Glow` — each carrying its geometry in scene
coordinates, which is what lets every painter shade it the same way.

A thick line, a rounded rectangle and a ring are polygons, and `lib/Shapes.roc`
builds them, so no painter has to learn a stroke. `lib/Font.roc` draws a string
out of the same quads.

## Input

`Input.Snapshot` is a value: which keys are held, which were struck since the
last tick, and the pointer's position, buttons and wheel. Each runner builds
one — `CanvasAppRunner` from roc-ray's `Devices.Snapshot`, and on the page
`canvas_app_runner.js` packs seven numbers from the browser's events which
`lib/WasmApp.roc` turns into a snapshot. A test writes one down:

```roc
Input.none.with_key_down(KeyW)
```

`lib/Keys.roc`, `lib/Mouse.roc`, `lib/Math.roc`, `lib/Color.roc`,
`lib/Camera.roc` and `lib/Random.roc` mirror roc-ray's surface under roc-ray's
own names, so a program ported from an example keeps its rules and changes its
import lines.

It is `Input` rather than `Devices` because `CanvasAppRunner` imports both, and
two nominal types with the same qualified name are ambiguous to the compiler.
roc-ray calls a tick's whole input `App.Input`, so that is the name this takes.
`mouse` and `wheel` are fields rather than methods for the same reason the
names match at all: `input.mouse.position()` is how roc-ray is read.

## The roc-ray end

`native/CanvasAppRunner.roc` opens a window at the app's `size`, paces to its
`fps`, converts roc-ray's snapshot into an `Input.Snapshot`, and paints.

Painting walks the frame once and cuts it into runs at every mark, because
raylib takes a blend and a camera as scopes; each run is drawn inside the
scopes its marks named. A gradient goes through one fragment shader
(`lib/BrushGlsl.roc`) that does the brush arithmetic on the scene position; an
unclipped flat colour is drawn directly. The whole frame is painted into a render texture
at twice the window and scaled back down, which is where the anti-aliasing
comes from.

Escape closes the window and F shows the frame rate. Both are read straight off
roc-ray's snapshot and never enter an app's `Input.Snapshot`, so no app can
bind a key that behaves differently on the two ends.

**Sound is web-only.** An app reports its tones the same way on both ends; this
runner ignores what it reports.

## The web end

`web/platform/` is a Roc platform. `main.roc` declares what it needs from an
app; `Frame.roc` declares what a frame is; `host.zig` is the wasm host and
holds the model and the current frame.

```roc
frame : Box(model) -> List(Frame.Shape)
```

Because `Frame.Shape` is a structural union, `lib/Shapes.roc`'s `Shape`
unifies with it by shape rather than by name, and an app hands its frame over
unchanged.

**The frame reader is generated.** `build.sh` runs `roc glue` over that
platform with `glue/JsGlue.roc`, using the same compiler that builds the wasm,
and writes `roc_glue.js` beside the page. It is never checked in and never
edited. It holds one reader per type — scalars, records at the compiler's own
field offsets, lists with the compiler's element stride, tag unions switching
on the discriminant — plus a name for each provided function's result, so a
page binds `RocGlue.frame` rather than a numbered type.

A page loads three scripts in order and the wasm:

    roc_glue.js             reads a frame out of wasm memory
    shapewire.js            paints shapes onto a canvas
    canvas_app_runner.js    the clock, the keyboard, the pointer, the speaker

**One call for a frame.** `computeFrame()` asks Roc for a new frame and answers
the address of the Roc list. The `DataView` over wasm memory is built after
that call and on its own line, because asking for a frame can grow wasm memory,
and growing it detaches every view over the old buffer.

**The host frees nothing.** The platform requires a `release`, and
`lib/WasmApp.roc` answers it once for every app with `|_frame| {}` — no app
file mentions it. The host holds one frame at a time and hands the last one
back before asking for the next, so Roc drops it using the layout it already
has.

The clock is the app's: elapsed time is banked and steps are taken as they fall
due, so an app runs at its own `fps` whatever the display does. One animation
frame may take up to four steps or none, four being where the bank is capped so
a tab that was in the background does not then race.

The speaker plays the tones `sounds` reports, one WebAudio oscillator each at
the pitch and length `tones` gives, with a pip per tone in the corner. A
browser will not start audio until the page has been typed in or clicked, so
the context is made on the first key or button.

A frame that throws stops the loop and puts the reason on the page and in the
console.

## The checks

`page_check.mjs` runs a built page the way a browser would, against a canvas
that records instead of painting, reading the page's own `<script src>` list so
a script that was never copied fails here rather than in a browser.
`KEYS=3:Space` presses keys and `DRAG=80,80,500,500` drags the pointer, so an
app that waits for input is driven. It reports frames, how many were distinct
pictures, canvas calls, fills, and a hash of everything drawn so one run can be
compared with another. It fails if the page drew nothing but its background, or
if the picture never changed.

`camera_check.mjs` hands `shapewire.js` a view mark and checks the canvas
matrix it builds against the same map written the geometric way,
`screen = zoom · R(rotation) · (world − target) + offset`, at four cameras and
four points.

An app's `expect`s are the third check, and the compiler runs them:

    roc test canvas_apps/snake_web.roc

## Where things are

    ~/build/roc-apps/next/<name>/                 the page, served at :9210/<name>/
    ~/build/roc-apps/canvas_apps/<name>/          the native binary
    ~/build/roc-apps/gen/canvas_apps/<name>-web.log   what to read when a page build fails

`build.sh` clears the page directory first, so yesterday's files cannot be
served beside today's. Both scripts take `ROC=` and `build.sh` takes `ZIG=`,
both pinned by default to the versions roc-ray pins; `native.sh` takes `OUT=`,
`TARGET=` and `OPT=`. `page_check.mjs` takes `FRAMES=` (default 30), which a
long movie wants: `FRAMES=1500`.

## Where each app came from

`snake`, `pong`, `breakout`, `camera` and `workshop` are ports of roc-ray's
examples of the same names, except `workshop`, which is `generated_assets`.
`trick_or_treat` is a fork of this repo's own `movies/halloween`.

Each ported file says in its own docstring what changed in it and why, which is
the copy to trust: a summary here would go stale the first time one of them is
edited. The shape of the change is the same throughout — the rules keep their
arithmetic and change their import lines, and the drawing is rewritten, because
upstream draws into a `Draw.Frame` and here a frame is a value.

Two things these have that upstream does not: `pong` and `breakout` can be
played with the pointer as well as the keys (`Controls.aim`), and `workshop`'s
palette swatches respond to a click, which is what their hover highlight
offers.
