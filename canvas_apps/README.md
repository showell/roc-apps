# Canvas apps

Small interactive Roc programs that run two ways from one set of files: as a
native program on roc-ray, and as a page in a browser.

Twenty-one of them, covering a few different kinds of program. `safari` is a
driving screensaver. `snake`, `pong` and `breakout` are arcade games.
`particles` is a fountain of four thousand sprites that follows the pointer.
`camera` is a world larger than the window, with a camera over it and a HUD
that stays put. `workshop` is a pixel paint program you drag on.
`trick_or_treat` is a movie you can scrub. `cat_widget` is a small page for
the Safari tutorial: drag across it and the cat's crossing plays under the
pointer, from Safari's own modules. `sky_widget`, `bird_widget` and `beacon_widget`
are three more: drag the clock and the sun sets, drag the gap and the bird
flies, drag the clock and two masts blink opposite each other. `route_widget`
is a still map of the whole route with one segment's record read out,
`bends_widget` is a still picture of three bends side by side, `step_widget` plays the ride forward and reads it back, `rehearsal_widget`
clicks through one step's twelve tries at a lean, `stills_widget` lays out
every pose of the cat and the bird and shows the one clicked large, with its
polygons counted, `gaze_widget` drags the rider past the pig that catches
the eye, `tree_widget` is a still picture of three conifers at the three
distances where their crowns differ, `frame_widget` is a still of step 1,570 of the ride
with the layers its address names, and `shapes_widget` is a still picture
of a triangle and a rectangle, for the book to quote the code under it.

Six of the twenty-one — all but `safari`, `trick_or_treat` and the widgets — are
roc-ray's own examples, by Luke Boswell, taken with only small changes to fit this scheme.

**The native side runs on roc-ray 0.12.0** (`23eec6e`), with the
repository's pinned nightly; roc-ray names no compiler of its own. It shows
that one set of files can run on roc-ray and as a page. The page is the side
we check most: the safari gate and every page build judge it, while the
native side is checked by `roc check` here and by the Windows workflow,
which builds every app and runs it headless.

    canvas_apps/build.sh snake       the page,   http://<box>:9210/snake/
    canvas_apps/build.sh snake release   the page as `--opt=speed` wasm, which site/publish.sh requires
    canvas_apps/native.sh snake      the native program
    TARGET=x64win canvas_apps/native.sh snake     for Windows

    node canvas_apps/web/page_check.mjs snake
    KEYS=3:Space DRAG=200,100,200,500 node canvas_apps/web/page_check.mjs pong
    node canvas_apps/web/camera_check.mjs
    node canvas_apps/web/text_check.mjs raster

`ARCHITECTURE.md` says how an app runs, and what isn't Roc.

## Layout

| | |
|---|---|
| `snake/` | everything about one app: its two app roots, its `page.html`, and its rules and drawing, which cannot tell which runner is running them |
| `snake/main.roc` | the app on roc-ray, reaching the runner as `native.CanvasAppRunner` |
| `snake/web.roc` | the app as a page, on `web/platform/`, through `lib.WasmApp` |
| `lib/` | a package every app shares: `CanvasApp` `WasmApp` `Shapes` `Brush` `Input` `Keys` `Mouse` `Math` `Camera` `Font` `Random` `Trig` `BrushGlsl` `Eye` `ConvexCut` `RgbColor` `ArgbColor` |
| `web/` | the page's end: the wasm platform and host, `build.zig` and `options.zig` (the host object, rebuilt by every page build), `canvas_app_runner.js`, `shapes_canvas.js`, `page_check.mjs`, `mini_canvas.mjs`, `mini_font.mjs`, `camera_check.mjs`, `text_check.mjs` |
| `native/` | roc-ray's end, as a package: `CanvasAppRunner.roc` |
| `widget_kit/` | what the tutorial's widgets share, as a package: `ScrubWidget` lays out the picture and the text, and `VcrButtons` runs a widget's one number with a video recorder's buttons. It sits above `lib/` and Safari's `game` package, because it speaks in `Fraction`s and no other app wants it |

An app's own directory holds a `<Name>App.roc` with the `CanvasApp` value in
it, a `page.html`, and whatever rules and drawing it needs.

**The app root is `main.roc`**, as in roc-ray's own examples, so tooling that
walks up the tree looking for it finds the native app. `web.roc` beside it is
the page's root. Both import the app's own modules as siblings, and reach
everything else as a package: `lib/` for the vocabulary, and `native/` for the
runner. `native/` is a package that declares roc-ray in its own header,
because it imports roc-ray's modules and a package may only see a platform it
names; `lib/` declares none, because both platforms use it.

**roc-ray is named in the source, not by a script.** `<name>/main.roc` and
`native/main.roc` both say `../../../roc-ray/platform/main.roc`, so roc-ray has
to be a sibling of `roc-apps` on disk; nothing stages the app or rewrites that
line on its way into a build. `native.sh` checks it and says so when it is not
there.

## Adding an app

A directory of five files, and `build.sh` exits 2 if `web.roc`, the page or
the shot is missing:

    <name>/main.roc             CanvasAppRunner.program(<Name>App.canvas_app)
    <name>/web.roc              WasmApp.program(<Name>App.canvas_app)
    <name>/<Name>App.roc        the CanvasApp value
    <name>/page.html            loads three scripts, and sets window.SHOW first
    <name>/shot.env             the keys and pointer that make its picture

Copy an existing app's `main.roc` and `web.roc`; they differ from each other
only in their platform, the runner they hand the value to, and one comment.
A tutorial widget lives only on a page, so it has no `main.roc`: `build.sh`
never reads one, `web.roc` is its one app root, and `native.sh` says there is
no app. Roc finds a module's packages by walking up to a `main.roc`, so checking
one of its modules alone takes `roc check --main=web.roc <Module>.roc`.

The page's own part is one object, before the script tags:

```html
<script>
window.SHOW = { wasm: '<name>.wasm', loading: 'Loading…' };
</script>
<script src="roc_glue.js"></script>
<script src="shapes_canvas.js"></script>
<script src="canvas_app_runner.js"></script>
```

Copy an existing `page.html`; `canvas_app_runner.js` throws if `window.SHOW` is
not set.

**A page says whether its app reads the pointer**, with `readsPointer: true` in
`window.SHOW`. The wasm can't tell the runner, and the runner needs to know what
a finger means: on such a canvas it's a drag (`touch-action: none`), and on any
other canvas it scrolls the page. `web/page_check.mjs` measures whether the
pointer changes what the app draws, and fails the build if the page says otherwise.

**A page with words to read sets `sharp: true`** in `window.SHOW`, as every widget
does. Its canvas then keeps one pixel for each pixel of the screen, whatever the
page's scale and the screen's density, and the runner hands `shapes_canvas.js`
the scale. The other pages keep a canvas of the app's own size, which spares a
game four times the fill on a high-density screen. `DENSITY=2` gives
`page_check.mjs` such a screen.

**The keys an app may read are a closed set of twenty** (`lib/Keys.roc`): the
four arrows, `W` `A` `S` `D` `Q` `E` `C` `J` `P` `R`, Space, Enter, and `1`–`4`.
Adding one touches four places — `Keys.Key` and `Keys.bit`, `KEY_BIT` in
`web/canvas_app_runner.js`, and `watched_keys` plus both match arms in
`native/CanvasAppRunner.roc` — so a key exists on both ends or on neither.

## In a page of prose

A canvas app goes in a page of prose as an iframe of its own page, sized by an
`aspect-ratio`, with `loading="lazy"` so it costs nothing until the reader
comes near. `widget_kit/embed.js` makes the canvas fill the frame, passes the
wheel on to the prose, gives a clicked or tapped frame the keyboard, and stops a
frame that's off the screen. `canvas_app_runner.js` is unchanged, and each app is
still a page of its own. A page that opens partway lists the words its address
may name as `opensAt` in `window.SHOW`: `?start=grass` hands the app Right as
many times as `grass` is places down that list, before the first frame. A book
fence says it as ```` ```widget frame grass ````, and `SEARCH=` gives
`page_check.mjs` the address. `widget_kit/embed_trial.html` tries it with the ride
and two widgets; copied with `embed.js` to `~/build/roc-apps/next/embed_trial/`
it shows on the dev channel, beside the apps it frames.

## What an app is

`lib/CanvasApp.roc` is the type. An app is a record of eight fields over its
own model:

```roc
CanvasApp(model) : {
    size : { width : F64, height : F64 },
    fps : I32,
    init : model,
    model_at_next_step : model, Input.Snapshot, F32 -> model,
    frame_shapes : model -> List(Shapes.Shape),
    sounds : model -> U32,
    tones : List({ freq : I32, ms : I32 }),
    title : Str,
}
```

`model_at_next_step` takes one step, given what the keyboard and pointer look like now and
how many seconds the step covers — always `1 / fps`, since each runner paces to
the app's own rate. An app whose rules count steps writes
`model_at_next_step: CanvasApp.untimed_model_at_next_step(step)`, and its `step` takes no seconds at
all. `frame_shapes` answers what to draw. `sounds` answers a bit per tone the last
step set off, and `tones` says what each one sounds like, so a runner never has
to guess how many there are.

An app imports no platform, so the same value goes to either runner. Each app
names its value out loud:

```roc
program = CanvasAppRunner.program(SnakeApp.canvas_app)  # snake/main.roc
program = WasmApp.program(SnakeApp.canvas_app)          # snake/web.roc
```

## What a frame is

A list of `Shapes.Shape` in the app's own coordinates. Five shapes and two
marks:

| | |
|---|---|
| `Poly` | coordinates and a `Brush.Fill` |
| `Disc` | centre, radius, a fill, and a rectangle it is kept inside |
| `Rect` | a box and a fill |
| `Image` | `cols × rows` of `Brush.Rgba`, stretched over a box without smoothing |
| `Text` | a line of words, its baseline, a size, `Prose` or `Code`, `Left` or `Center`, and a colour |
| `Blend` | `Over` or `Add` |
| `View` | `Screen`, or `World` with a camera's four settings |

An app writes `Poly`, any polygon. The native runner has `ConvexCut` cut each
concave one into triangles, a type of its own that no app builds, because
roc-ray fills convex polygons only. The canvas fills a concave one itself.

A mark is not drawn. It changes how the shapes after it are painted, until the
next mark of its kind. `Blend(Add)` lights rather than paints. `View(World(c))`
puts the shapes after it in a camera's world and `View(Screen)` brings them
back to the window. A frame starts on the screen, painting over. An app writes
the marks in pairs around a run of shapes, with `Shapes.added_light` and
`Shapes.in_space`.

A `Brush.Fill` is a flat colour or one of five gradients — `Span`,
`Radial`, `Linear`, `Ellipse`, `Glow` — each carrying its geometry in scene
coordinates, which is what lets every painter shade it the same way.

A thick line, a rounded rectangle and a ring are polygons, and `lib/Shapes.roc`
builds them, so no painter has to learn a stroke. `lib/Font.roc` draws a string
out of the same quads, which is how the games write.

`Text` is for words that should read well, and the widgets use it. The canvas
sets it with `fillText` in the viewer's own fonts, a sans serif for `Prose` and a
monospace for `Code`, so a page loads no font. The viewer's machine measures the
line, so Roc can't know its width: `Font.room_for` is the room to leave, and a
line that must sit in the middle says `Center`. The native runner draws
`Font.plotted`, the same line as strokes. `ShapesPixels`, which paints only what
the ride draws, refuses one.

## Input

`Input.Snapshot` is a value: which keys are held, which were struck since the
last tick, and the pointer's position, buttons and wheel. Each runner builds
one — `CanvasAppRunner` from roc-ray's `Devices.Snapshot`, and on the page
`canvas_app_runner.js` packs seven numbers from the browser's events which
`lib/WasmApp.roc` turns into a snapshot. The pointer is read through pointer
events, so a finger or a pen is a mouse with its left button down, and during a
drag the position may be off the canvas. A test writes one down:

```roc
Input.none.with_key_down(KeyW)
```

`lib/Keys.roc`, `lib/Mouse.roc`, `lib/Math.roc`,
`lib/Camera.roc` and `lib/Random.roc` mirror roc-ray's surface under roc-ray's
own names, so a program ported from an example keeps its rules and changes its
import lines.

It is `Input` rather than `Devices` because `CanvasAppRunner` imports both, and
two nominal types with the same qualified name are ambiguous to the compiler.
roc-ray calls a tick's whole input `App.Input`, so that is the name this takes.
`mouse` and `wheel` are fields rather than methods for the same reason the
names match at all: `input.mouse.position()` is how roc-ray is read.

## The roc-ray end

The native side is a spike, not kept current (see the top of this file).
`native/CanvasAppRunner.roc` opens a window at the app's `size`, paces to its
`fps`, converts roc-ray's snapshot into an `Input.Snapshot`, and paints.

Painting walks the frame once and cuts it into runs at every mark, because
raylib takes a blend and a camera as scopes; each run is drawn inside the
scopes its marks named. A gradient goes through one fragment shader
(`lib/BrushGlsl.roc`) that does the brush arithmetic on the scene position; a
flat colour is drawn directly. The whole frame is painted into a render texture
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
    shapes_canvas.js            paints shapes onto a canvas
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

**Every page build is checked and photographed.** `build.sh` ends by running
`page_check.mjs` with the input `<name>/shot.env` scripts — `KEYS=`, `DRAG=`,
`FRAMES=` — and `SHOT=` set, which saves the page's last frame beside it as
`shot.png`. That is the picture on the landing page, and it is never older than
the wasm it shows. A page that fails the check fails the build.

`page_check.mjs` runs a built page the way a browser would, against a canvas
that records instead of painting, reading the page's own `<script src>` list so
a script that was never copied fails here rather than in a browser.
`KEYS=3:Space` presses keys and `DRAG=80,80,500,500` drags the pointer, so an
app that waits for input is driven. It reports frames, how many were distinct
pictures, canvas calls, fills, and a hash of everything drawn so one run can be
compared with another. It fails if the page drew nothing but its background, or
if the picture never changed.

With `SHOT=<file>.png`, every canvas is also a real one: `mini_canvas.mjs`, a
dependency-free software rasterizer for exactly the canvas calls `shapes_canvas.js`
and `canvas_app_runner.js` make — paths, nonzero fill, linear and concentric
radial gradients, clip, the additive composite, images, lines of type —
supersampled for anti-aliasing, with PNGs through node's own zlib. The real painter runs
unchanged against it, and it throws on anything outside that list rather than
painting something plausible. Painting is slow next to recording, so only the
last four callbacks paint; each of the runner's draws clears first, so the last
is a whole frame. It is ported from angry-gopher's `mini_canvas.ts`, which does
the same for the driving game's cat.

Because the input is scripted and the clock is virtual, a shot is the same on
every run of the same build, so a changed picture is a changed program.

`camera_check.mjs` hands `shapes_canvas.js` a view mark and checks the canvas
matrix it builds against the same map written the geometric way,
`screen = zoom · R(rotation) · (world − target) + offset`, at four cameras and
four points.

`text_check.mjs` runs on every page build. It checks what `shapes_canvas.js` asks
a canvas for a line of type, and how a scale reaches the canvas's matrix. For a
widget it also sets type on `mini_canvas.mjs` and looks at the ink. A shot's type
comes from `mini_font.mjs`, which reads a sans serif and a monospace from
`/usr/share/fonts` to stand in for the viewer's, so a widget's page build needs
`fonts-liberation` and `fonts-dejavu-core` installed, and stops without them. Its
letters are close to a browser's in size and color, not the same letters.

An app's `expect`s are the third check, and the compiler runs them:

    cd canvas_apps/snake && roc test web.roc

## Where things are

    ~/build/roc-apps/next/<name>/                 the page and its shot.png, served at :9210/<name>/
    ~/build/roc-apps/canvas_apps/<name>/          the native binary
    ~/build/roc-apps/gen/canvas_apps/<name>-web.log   what to read when a page build fails

`build.sh` clears the page directory first, so yesterday's files cannot be
served beside today's. Both scripts take `ROC=` and `build.sh` takes `ZIG=`,
both pinned by default to the versions roc-ray pins; `native.sh` takes `OUT=`,
`TARGET=` and `OPT=`. `page_check.mjs` takes `FRAMES=` (default 30), which a
long movie wants: `FRAMES=1500`.

## Where each app came from

| app | from |
|---|---|
| `snake`, `pong`, `breakout`, `camera`, `particles` | roc-ray's examples of the same names |
| `workshop` | roc-ray's `generated_assets`, the Pixel Workshop |
| `safari` | this repository's own screensaver, which began as a Codex program; `safari/README.md` |
| `trick_or_treat`, and every `*_widget` | this repository's own |

The roc-ray examples were taken at commit `e100c95`. Each ported file says in its own docstring what changed in it and why,
which is the copy to trust. The shape of the change is the same throughout: the
rules keep their arithmetic and change their import lines, and the drawing is
rewritten, because upstream draws into a `Draw.Frame` and here a frame is a
value.

What these have that upstream does not: `pong` and `breakout` can be played with
the pointer as well as the keys, and `workshop`'s palette swatches respond to a
click, which is what their hover highlight offers. `particles` follows upstream's
interactive controls, and travels upstream's recording figure until the pointer
has moved over the canvas.
