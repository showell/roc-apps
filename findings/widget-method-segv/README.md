# A method call on a nominal record crashes the wasm build

`roc build web.roc --target=wasm32` (dev or speed) segfaults the compiler on
`nightly-2026-11-03-34bd006`, and still on `nightly-2026-11-07-ad3a5d2`, for
three of the tutorial widgets: beacon, bird and sky. `roc check` on the same
apps is clean, and the crash comes about 3 s into the build:

```
Segmentation fault (SIGSEGV) in the Roc compiler.
No compiler work was recorded on thread ... (main).
```

## What it takes

`WidgetPage.picture_shapes` in `canvas_apps/widget_kit/WidgetPage.roc`, a
function in a package module, builds a record literal annotated as
`FrameView`, a nominal record type (`:=`) from another package, and calls one
of that type's own functions on it as a method:

```roc
view : FrameView
view = { backdrop, ride_shape_lists: [ride_shapes], roll: Angle.upright }
view.framed_shapes(World({ ... }))
```

The widgets that call `picture_shapes` from a function crash. `tree_widget`
calls it only from a top-level constant, which compile-time evaluation folds,
and builds. Writing the same call as `FrameView.framed_shapes(view, World(...))`
builds, and so does inlining `framed_shapes`' body. Destructuring the argument
or not makes no difference. Safari's own `view.framed_shapes(...)`, on a view
that `FrameView.frame_view_at` returns, builds.

No reduced program yet: the next step is a two-package app with one nominal
record and one method call on a literal of it.

## Where it came from

Commit `7b2b1527` moved the building of the `FrameView` from each widget into
`picture_shapes`, which then called `framed_shapes` as a method. The module
call is the workaround, with a comment beside it, since `methods.shale` would
otherwise turn it back into the method form (it judges by `roc check`, which
passes).
