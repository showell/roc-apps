# How a canvas app runs

A canvas app is a Roc value: its size, its pace, how it advances, and what a frame looks like. The app's rules and drawing are pure Roc, and they can't tell which runner is running them. Everything that touches a screen, a clock or a keyboard is outside the app.

## In a browser

Each tick goes round this loop:

1. `web/canvas_app_runner.js` paces the clock and gathers the keys and the pointer.
2. It calls into the app's wasm, which advances the model and answers a list of `lib/Shapes.roc` shapes.
3. `roc_glue.js` reads those shapes out of wasm memory. `roc glue` generates it from `web/platform/Frame.roc` at every build, so it's never edited.
4. `web/shapes_canvas.js` paints them on a canvas.

| Layer | Language | Knows about |
|---|---|---|
| The app, such as `safari/` | Roc | Its own world, and how it looks as shapes |
| `lib/` | Roc | Shapes, input, and the `CanvasApp` type, for every app |
| `web/platform/` | Roc and Zig | The wasm platform and its small host |
| `roc_glue.js` | JS, generated | The layout of a frame in wasm memory |
| `web/canvas_app_runner.js` | JS | The clock, the keyboard, the pointer |
| `web/shapes_canvas.js` | JS | The browser's canvas |

The JS knows nothing about any one app. The app knows nothing about the canvas.

## Natively

The same app also builds on roc-ray: `<app>/main.roc` hands the value to `native/CanvasAppRunner.roc`, in place of `web.roc` and `lib.WasmApp`. The rules and drawing are unchanged.

## How it's checked

Roc can't run a canvas, so the JS has its own checks. `web/page_check.mjs` runs every built page against a stand-in canvas. Safari's gate paints frames with `safari/gates/ShapesPixels.roc`, the Roc twin of `shapes_canvas.js`, and compares exact pixel hashes.

`README.md` covers the layout and how to add an app.
