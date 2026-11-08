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

## The reduced program

Three files, no packages, no platform. It crashes `roc main.roc`, `roc build`
(native, dev or speed) and the wasm32 build alike, so it isn't wasm-only, and
`roc check main.roc` is clean:

```roc
# View.roc
View := { n : U64, m : U64 }.{
	shown : View -> List(Str)
	shown = |_view| [greeting]
}

greeting : Str
greeting = "hi"
```

```roc
# Page.roc
import View

Page :: [].{
	greet : U64 -> List(Str)
	greet = |n| {
		view : View
		view = { n, m: 0 }
		view.shown()
	}
}
```

```roc
# main.roc
import Page

main! = |args| {
	echo!(Str.join_with(Page.greet(args.len()), ","))
	Ok({})
}
```

Each of these makes it build: `View.shown(view)` in place of `view.shown()`; a
maker in place of the annotated record literal; `greet` in the root module;
`shown` returning `greeting` bare instead of in a list; a `shown` that uses no
top-level constant. A constant inside the type's block, or from another
module, still crashes. So the trigger is a method call on an annotated
nominal-record literal, from a module other than the root, into a method whose
body puts a top-level constant in a list literal. In the widgets that is
`FrameView.backdrop_shapes`, which returns `[Grass.grass_shape]`.

"No compiler work was recorded" means none of the framed stages (parse,
canonicalize, check, the post-check pipeline, the backends) was running: it
dies on the main thread after checking, outside every framed stage. Compile-time
constant evaluation is the suspect; that's a guess. A release nightly has no
developer diagnostics, so a debug or `-Ddev-diagnostics` build is the next
step. No upstream issue matches (closest: roc-lang/roc #12919, #12194).

## Where it came from

Commit `7b2b1527` moved the building of the `FrameView` from each widget into
`picture_shapes`, which then called `framed_shapes` as a method. The module
call is the workaround, with a comment beside it, since `methods.shale` would
otherwise turn it back into the method form (it judges by `roc check`, which
passes).
