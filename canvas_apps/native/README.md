# The roc-ray end, kept for posterity

This package is the native runner for the canvas apps: `CanvasAppRunner.roc`
opens a raylib window through [roc-ray](https://github.com/lukewilliamboswell/roc-ray)
and paints an app's frames, and each app's `main.roc` hands its `CanvasApp`
value to it. `../README.md`, "The roc-ray end", says how it paints.

**It is kept for posterity, and it isn't kept current.** The native builds
(this folder and every canvas app's `main.roc`) run on roc-ray 0.12.0
(`23eec6e`) at the repository's pinned nightly, `nightly-2026-11-03-34bd006`.
They don't build at newer Roc nightlies: roc-ray itself fails at the 11-15
nightly (as of 2026-11-18). They are out of the code sweeps, so a repo-wide
rewrite or hunt leaves them as they are. `check.shale` still type-checks every
`main.roc` at the pin, and the Windows and macOS workflows still build them.

The page (`../web/`) is the end we keep current.
