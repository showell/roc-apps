# The movies on roc-ray

Every movie under `movies/` runs as a native Windows and Linux program on
[roc-ray](https://github.com/lukewilliamboswell/roc-ray), Luke Boswell's raylib
platform for Roc, while the same Roc keeps running in the browser on our wasm
platform. The bulk of the code is shared; each platform has a thin edge.
`movies/README.md` is the layout; this is the roc-ray side of it.

## What is shared and what is not

| layer | files | platform |
|---|---|---|
| the screensaver itself | `movies/safari/*.roc` emitted from Codex by `rocemit` (one module per chapter) | any |
| the ride between frames, and what a frame shows | `movies/safari/SafariRide.roc` | any |
| what a command's paint means | `movies/safari/Brush.roc`: a flat colour or one of the blitter's gradients, and the colour it gives a point | any |
| a frame as shapes a platform can fill | `movies/safari/Shapes.roc`: convex polygons, ear-clipped triangles, discs, rectangles, each with its brush | any |
| a frame painted into pixels | `movies/safari/Raster.roc` | any |
| the web edge | `movies/safari/SafariApp.roc` (exports over a boxed model) and `web/blitter.js` (paints the canvas) | wasm |
| the roc-ray edge | `movies/safari/main.roc` and `player/MoviePlayer.roc`: each shape becomes one draw call, under a camera turned by the ride's roll | roc-ray |

No module under `movies/safari/` imports a platform. The roc-ray app is one file:
`init!`, `update!` for the keys, and `render!`.

## The files

| where | what |
|---|---|
| `build.sh` | an app for one target, from a roc-ray checkout's platform source, with the platform reference rewritten and the nightly roc-ray pins (09-07). A movie -- `movies/<name>/main.roc` -- is staged with `movie/` and `player/`; a plain app under `apps/` brings what its `modules` file names |
| `apps/hello/` | the smallest roc-ray app, proving a build end to end, and the only thing left under `apps/` |
| `player/` | `MoviePlayer.roc`: everything a player does, for any movie. `program` takes a `Movie.Movie` and names none |

`movie/` at the repository root is what the three of them share: `Movie` (the
type a player is a function of), `Shapes`, `Brush`, `BrushGlsl`, `ShapeWire`,
`Font`, and the arithmetic those need. It lived in Safari's own directory until
a second and a third movie arrived and had to stage a hundred and twenty files
of Safari to reach seven of them.

What stayed behind is the half that knows what Safari looks like:
`SafariShapes.roc` builds its sky, its grass and its sun and turns a Codex draw
command into a polygon, and `SafariBrush.roc` reads a brush out of one.
| `pixels_png.mjs` | the frame `movies/safari/RasterFrame.roc` or `ShapesFrame.roc` prints, as a PNG |
| `png_diff.mjs` | two screenshots compared pixel by pixel: how many differ, how many by more than a tolerance, the largest difference |
| `../.github/workflows/windows.yml` | the Windows executables, built on a hosted Windows runner, and each painter's screenshots from a real window on Mesa's llvmpipe; run by hand |
| `../.github/workflows/macos.yml` | the macOS executables, built and run headless on hosted Apple Silicon and Intel runners, which have no GPU; run by hand |

## Two painters

roc-ray fills every polygon, triangle and disc itself. It fills only convex
polygons, so `Shapes.cut` cuts the concave ones into triangles — which is the
player's business rather than the movie's, and the page does not ask for it. A
shape with a gradient goes through one fragment shader, whose modes do
`Brush.shade`'s arithmetic on the scene position.

It is anti-aliased by supersampling, since roc-ray offers no multisampling: the
frame is drawn into a render texture at twice the window's size and drawn down
with bilinear filtering, four samples a pixel. About 17 ms a frame headless on
the build box.

**There were three painters and now there is one.** `R` switched to Raster
painting the whole frame in Roc for roc-ray to show as a texture (34 ms a
frame), and `A` turned the anti-aliasing off. They existed to be compared, and
the comparison is settled. Raster is still here and `ShapesFrame` still checks
the two against each other — but no player shows pixels, so a movie is not
asked for them.

Keys: SPACE pauses and resumes, UP and DOWN step, J rides to the next scene,
D shows the frame rate, P saves a screenshot to `shots/`, ESCAPE quits.

## Building

    ray/build.sh safari                    # Linux, dev backend, into ~/build/roc-apps/ray/safari/
    OPT=speed ray/build.sh safari          # LLVM
    TARGET=x64win ray/build.sh safari      # Windows; links only where a Windows SDK is installed
    TARGET=arm64mac ray/build.sh safari    # Apple Silicon (x64mac: Intel); links here, runs only on a Mac

`build.sh` stages the app and the module directories its `modules` file names,
points the app's platform reference at a roc-ray checkout, and runs `roc build`.
It needs:

- roc-ray at `e100c95` (`main`), with its hosts built by
  `zig build -Doptimize=ReleaseFast` (a plain `zig build` is a Debug host, twice
  as slow here);
- Roc `nightly-2026-09-07-14d9829`, the nightly roc-ray pins.

The Windows executable is built by `.github/workflows/windows.yml` on a hosted
Windows runner, because Roc's `x64win` link needs an installed Windows SDK. It
builds `hello` and `safari`, runs both headless, and uploads them. Then it runs
Safari in a real hidden window on Mesa's llvmpipe with scripted keys, pausing at
four places on the route and saving each frame three ways (Shapes anti-aliased,
Shapes plain, Pixels), and uploads the screenshots as `safari-shots`.

The macOS executables are built by `.github/workflows/macos.yml` on hosted
Apple Silicon (`arm64mac`) and Intel (`x64mac`) runners, the two roc-ray's own
CI uses. Each job builds `hello` and `safari`, shows their code signatures, runs
both headless and uploads them. The runners have no GPU, so the drawing is
tested only on a real Mac.

## The checks

- `movies/safari/emitted.sh`: the 54 Codex specs, emitted and run in Roc against their
  verdicts.
- `wasm/frame_hash.mjs`: every frame's bytes and readouts over a fixed
  ride, so a refactor of the shared code is held to identical frames on the web.
- `movies/safari/RasterFrame.roc` with `ray/pixels_png.mjs`: one frame painted by
  Raster, as a PNG.
- `movies/safari/ShapesFrame.roc`: a frame painted with the commands' own
  polygons and with Shapes' pieces; 0 of 576,000 pixels differ.
