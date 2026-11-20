# The roc-ray end, kept for posterity

This package is the canvas apps' native runner. `CanvasAppRunner.roc` opens a
raylib window through [roc-ray](https://github.com/lukewilliamboswell/roc-ray)
and paints an app's frames; each app's `main.roc` hands its `CanvasApp` value
to it. `../README.md`, "The roc-ray end", says how it paints.

**It is frozen.** This folder and every app's `main.roc` stay at the roc-ray
release they were written for, at the repository's pinned nightly; a newer
nightly needs a newer roc-ray. The code sweeps pass them by. `check.shale`
type-checks every `main.roc` at the pin, and the Windows and macOS workflows
build them.

The page (`../web/`) is the end we keep current.
