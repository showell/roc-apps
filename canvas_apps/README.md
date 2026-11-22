# Canvas apps

Small interactive Roc programs. Each runs as a page in a browser.

There are a few kinds. `safari` is a driving screensaver. `snake`, `pong` and
`breakout` are arcade games. `particles` is a fountain of sprites that follows
the pointer. `camera` is a world larger than the window, with a camera over it
and a HUD that stays put. `workshop` is a pixel paint program. `trick_or_treat`
and `thanksgiving` are movies you can scrub. Each `*_widget` is a small page
for the Safari tutorial, built from Safari's own modules: some you drag, some
are fixed pictures. Each app's `<Name>App.roc` says what it is.

`snake`, `pong`, `breakout`, `camera`, `particles` and `workshop` are roc-ray's
own examples, by Luke Boswell, adapted to this scheme (below).

    canvas_apps/build.sh snake           the page, on the dev channel at :9210/snake/
    canvas_apps/build.sh snake release   the page as --opt=speed wasm, which site/publish.sh requires

    node canvas_apps/web/page_check.mjs snake
    KEYS=3:Space DRAG=200,100,200,500 node canvas_apps/web/page_check.mjs pong
    node canvas_apps/web/camera_check.mjs
    node canvas_apps/web/text_check.mjs raster

`ARCHITECTURE.md` says how an app runs, and which parts are JavaScript.

The ported games once also built as native programs on roc-ray, from the same
files. We stopped verifying native builds after some compiler churn, and the
page is the one end now.

## Layout

An app's folder holds its `<Name>App.roc` (the `CanvasApp` value), `web.roc`
(the page's root), a `page.html`, a `shot.env`, and its own rules and drawing.
Everything outside the folder is a package:

- `lib/`: the vocabulary every app shares (shapes, brushes, input, fonts,
  cameras).
- `web/`: the page's end, a wasm platform and host and the JavaScript that runs
  it.
- `widget_kit/`: what the tutorial's widgets share. It sits above `lib/` and
  Safari's `game` package, because it speaks in `Fraction`s.

Read the modules for the rest.

**The app root is `web.roc`**, the page's. `lib/` declares no platform, so an
app's rules and drawing are platform-free.

## Adding an app

Four files:

    <name>/web.roc              WasmApp.program(<Name>App.canvas_app)
    <name>/<Name>App.roc        the CanvasApp value
    <name>/page.html            loads three scripts, and sets window.SHOW first
    <name>/shot.env             the keys and pointer that make its picture

`build.sh` exits 2 when `web.roc`, the page or the shot is missing. Copy an
existing app's roots: the two differ in their platform, their runner and one
comment. A widget lives on a page alone, so `web.roc` is its one root. Roc
finds a module's packages by walking up to a `main.roc`, so checking one of a
widget's modules takes `roc check --main=web.roc <Module>.roc`.

The page's own part is one object, before the script tags:

```html
<script>
window.SHOW = { wasm: '<name>.wasm', loading: 'Loading…' };
</script>
<script src="roc_glue.js"></script>
<script src="shapes_canvas.js"></script>
<script src="canvas_app_runner.js"></script>
```

Copy an existing `page.html`; `canvas_app_runner.js` throws when `window.SHOW`
is missing. Three more settings go in it:

- **`readsPointer: true`** for an app that reads the pointer. On its canvas a
  finger drags (`touch-action: none`); on the others it scrolls the page.
  `page_check.mjs` measures whether the pointer changes the picture, and fails
  the build when the page says otherwise.
- **`sharp: true`** for a page with words to read, as every widget has. Its
  canvas keeps a pixel for each pixel of the screen, at any scale and density.
  The other pages keep a canvas of the app's own size, which keeps a game's
  fill small on a dense screen. `DENSITY=2` gives `page_check.mjs` such a
  screen.
- **`opensAt`**, the words a page's address may name to open partway:
  `?start=grass` hands the app Right as many times as `grass` sits down that
  list, before the first frame. A book fence says it as
  ```` ```widget frame grass ````, and `SEARCH=` gives `page_check.mjs` the
  address.

**The keys an app may read are a fixed set** (`lib/Keys.roc`). A new key goes
in three places: `Keys.Key` and `Keys.bit`, and `KEY_BIT` in
`web/canvas_app_runner.js`.

## In a page of prose

An app goes in a page of prose as an iframe of its own page, sized by an
`aspect-ratio`, with `loading="lazy"`. `widget_kit/embed.js` makes the canvas
fill the frame, passes the wheel on to the prose, gives a clicked frame the
keyboard, and pauses a frame that is off the screen. `widget_kit/embed_trial.html`
tries it with the ride and two widgets.

## What an app is

`lib/CanvasApp.roc` is the type: a record over the app's own model.

```roc
CanvasApp(model) : {
    size : { width : F64, height : F64 },
    frames_a_second : U32,
    init : model,
    model_at_next_step : model, Input.Snapshot, F32 -> model,
    frame_shapes : model -> List(Shapes.Shape),
    sounds : model -> U32,
    tones : List(CanvasApp.Tone),
    title : Str,
}
```

`model_at_next_step` takes one step, given the keyboard and pointer now and the
seconds the step covers, always `1 / frames_a_second`. An app whose rules count
steps writes `CanvasApp.untimed_model_at_next_step(step)`, and its `step` takes
the model and the input alone. `frame_shapes` says what to draw. `sounds` sets a bit for each tone
the last step set off, and `tones` says what each sounds like.

An app is platform-free, and its page's root hands the value to the runner,
named out loud:

```roc
program = WasmApp.program(SnakeApp.canvas_app)          # snake/web.roc
```

## What a frame is

A list of `Shapes.Shape` in the app's own coordinates. A shape is a region and
a fill: `Triangle`, `Quad`, `Disc` or `Polygon`, each with any `Brush.Fill`.
`Image` is a grid of pixels stretched over a box, and `Text` a line of words.
`Blend` and `View` are marks: each changes how the shapes after it are painted,
until the next mark of its kind. `Blend(Add)` lights instead of painting;
`View(World(c))` puts the shapes after it in a camera's world and
`View(Screen)` brings them back. `Shapes.added_light_shapes` and
`Shapes.shapes_in_space` write the marks in pairs around a run of shapes.
`lib/Shapes.roc` documents each.

A quad or a polygon may be concave. The canvas fills it as it is; a painter
that fills only convex polygons cuts it into triangles with `ConvexCut`, as
Safari's frame proofs do.

A `Brush.Fill` is a flat colour or one of five gradients, each carrying its
geometry in scene coordinates, so every painter shades it the same way.
`lib/Brush.roc` has a maker for each, and `WidthShading` makes the gradient that
rounds a region across its width. `BrushShade.shade` gives the colour at one
point, for a painter on the CPU.

A thick line is a quad, a ring a band of quads, a rounded rectangle a polygon:
`lib/Shapes.roc` and `lib/CurvedShapes.roc` build them, so a painter needs
regions and fills alone. `lib/Font.roc` draws a string out of the same quads,
which is how the games write.

`Text` is for words that should read well, and the widgets use it. The canvas
sets it with `fillText` in the viewer's own fonts, a sans serif for `Prose` and
a monospace for `Code`. The viewer's machine measures the line, so
`Font.room_for` gives the room to leave, and a centred line says `Center`.
`Font.plotted_shapes` draws the same line as strokes.

## Input

`Input.Snapshot` is a value: the keys held, the keys struck since the last
tick, and the pointer's position, buttons and wheel. On the page,
`canvas_app_runner.js` packs seven numbers from the browser's events and
`lib/WasmApp.roc` turns them into one. The pointer comes from pointer events, so a finger or a pen is a
mouse with its left button down, and during a drag it may leave the canvas. A
test writes one down:

```roc
Input.none.with_key_down(KeyW)
```

`lib/Keys.roc`, `lib/Mouse.roc`, `lib/Math.roc`, `lib/Camera.roc` and
`lib/Random.roc` mirror roc-ray's surface under its own names, so a program
ported from one of Luke's examples keeps its rules and changes its imports.

## The web end

`web/platform/` is a Roc platform. Its `main.roc` declares what it needs from
an app and names lib's `Shapes.Shape` as a frame; `host.zig` is the wasm host
and holds the model and the current frame. `Frame.Shape` is a structural union,
so an app's frame unifies with it by shape and goes over unchanged.

**The frame reader is generated.** `build.sh` runs `roc glue` over the platform
with `glue/JsGlue.roc`, with the compiler that builds the wasm, and writes
`roc_glue.js` beside the page. It is a build output, untracked. A page binds
`RocGlue.frame` by name.

A page loads three scripts in order, then the wasm:

    roc_glue.js             reads a frame out of wasm memory
    shapes_canvas.js        paints shapes onto a canvas
    canvas_app_runner.js    the clock, the keyboard, the pointer, the speaker

**The `DataView` comes after `computeFrame()`.** Asking for a frame can grow
wasm memory, which detaches every view over the old buffer, so the view is
built after the call returns.

**The host holds one frame at a time** and hands the last back before asking
for the next, so Roc drops it with the layout it already has.
`lib/WasmApp.roc` supplies the platform's `release` for every app.

The clock is the app's: elapsed time is banked and steps are taken as they fall
due, so an app runs at its own rate. One animation frame takes up to four
steps; the cap keeps a tab back from the background from racing.

The speaker plays the tones `sounds` reports, one WebAudio oscillator each,
with a pip per tone in the corner. A browser starts audio after the first key
or click, so the audio context starts then.

A frame that throws stops the loop and shows the reason on the page and in the
console.

## The checks

**Every page build is checked and photographed.** `build.sh` ends by running
`page_check.mjs` with the input `<name>/shot.env` scripts (`KEYS=`, `DRAG=`,
`FRAMES=`), and saves the last frame beside the page as `shot.png`, the
landing page's picture. A page that fails the check fails the build.

`page_check.mjs` runs a built page as a browser would, against a canvas that
records its calls. It reads the page's own `<script src>` list, so a missing
script fails here. It reports frames, distinct pictures, canvas calls, fills
and a hash of everything drawn, and fails a page that draws only its
background or whose picture stays still. `FRAMES=` sets the length (a long
movie wants `FRAMES=1500`).

With `SHOT=<file>.png` the canvas also paints, through `mini_canvas.mjs`: a
software rasterizer for exactly the calls `shapes_canvas.js` and
`canvas_app_runner.js` make, supersampled, writing PNGs with node's zlib. It
throws on any other call. The input is scripted and the clock virtual, so a
build's shot is the same on every run, and a changed picture is a changed
program.

`camera_check.mjs` checks the canvas matrix `shapes_canvas.js` builds for a
view mark against the same map written geometrically,
`screen = zoom · R(rotation) · (world − target) + offset`.

`text_check.mjs` checks how `shapes_canvas.js` sets a line of type and scales
it. For a widget it also sets type on `mini_canvas.mjs` and looks at the ink,
in fonts `mini_font.mjs` reads from the system, so a widget's build needs
`fonts-liberation` and `fonts-dejavu-core` installed.

An app's `expect`s are the third check:

    cd canvas_apps/snake && roc test web.roc

## Build outputs

`build.sh` writes the page and its `shot.png` to the dev channel, or to `OUT=`.
It builds into a staging folder that replaces the page only when the build
passes, and a failed build prints its Roc or glue log. It takes `ROC=`, held
to the pin (`pinned-roc.sh`). Its header says the rest.

## Where the ported apps came from

`snake`, `pong`, `breakout`, `camera` and `particles` are roc-ray's examples of
the same names, and `workshop` is its `generated_assets`, the Pixel Workshop.
They are © 2024 Luke Boswell, under the UPL 1.0; `LICENSE-roc-ray`, kept with
them, is roc-ray's license. Each ported file's docstring says what changed. The
rules keep their arithmetic and change their imports; the drawing is
rewritten, because here a frame is a value.

`pong` and `breakout` also play with the pointer, and `workshop`'s palette
swatches respond to a click. `particles` follows the pointer once it moves over
the canvas, and travels upstream's recording figure until then.
