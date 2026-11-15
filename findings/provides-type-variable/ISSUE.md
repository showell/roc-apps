# A platform `provides` function whose type has a type variable checks clean, then crashes with "hit a runtime error" when the host calls it

A function a platform provides to its host, whose type holds a type
variable, passes `roc check` and `roc build` with no errors and no
warnings. When the host calls it, the compiled code crashes with "hit a
runtime error". Giving it a concrete type fixes it.

`platform/main.roc`:

```roc
platform ""
	requires {
		[Model : model] for program : {
			init : {} -> Box(model),
		}
	}
	exposes []
	packages {}
	provides {
		"roc_init": init_for_host,
		"roc_release": release_for_host,
	}
	targets: {
		x64musl: {
			inputs: [app],
			output: Archive,
		},
	}

init_for_host = program.init

release_for_host : Box(model) -> {}
release_for_host = |_model| {}
```

`app/main.roc`:

```roc
app [Model, program] { pf: platform "../platform/main.roc" }

Model : { seconds : F32 }

program = {
	init: |{}| Box.box({ seconds: 0.0 }),
}
```

The host is a few lines of Zig: it calls `roc_init`, then `roc_release`
with the box it got, printing a line after each, and provides `roc_alloc`,
`roc_realloc`, `roc_dealloc`, `roc_crashed`, `roc_dbg` and
`roc_expect_failed`. `roc_crashed` prints its message and exits 1.

```zig
extern fn roc_init() callconv(.c) ?*anyopaque;
extern fn roc_release(model: ?*anyopaque) callconv(.c) void;

pub fn main() void {
    const model = roc_init();
    std.debug.print("roc_init gave a box\n", .{});
    roc_release(model);
    std.debug.print("roc_release returned\n", .{});
}
```

```
$ roc check app/main.roc
No errors found in 39ms for app/main.roc
$ roc build app/main.roc --target=x64musl --opt=dev --output=app.a
0 errors and 0 warnings found in 10ms while successfully building:
$ ./host   # linked with app.a
roc_init gave a box
roc crashed: hit a runtime error
```

## What changes it

Only `release_for_host`'s annotation changed:

| annotation | `roc check` | run |
|---|---|---|
| `Box(model) -> {}` | clean | hit a runtime error |
| `model -> {}` | clean | hit a runtime error |
| `Box(a) -> {}` (a variable the `requires` doesn't name) | clean | hit a runtime error |
| no annotation | clean | hit a runtime error |
| `Box(Model) -> {}` | clean | runs |

So any provided function whose type is still polymorphic seems to be
compiled as a runtime error, with no diagnostic. We'd expect either an
error at check time ("a provided function must have a concrete type"), or
for `model` to be resolved to the app's `Model`, which the `requires`
binds it to.

## Versions

Linux x86-64, the release tarballs from roc-lang/nightlies, on Roc's dev
backend: `nightly-2026-10-29-a0a9fc2`, `nightly-2026-10-30-0602c5f`,
`nightly-2026-11-03-34bd006`, `nightly-2026-11-07-ad3a5d2`,
`nightly-2026-11-11-7679cc5` and `nightly-2026-11-15-f25da45` all do the
same. On `nightly-2026-11-15-f25da45`, `--opt=speed` also builds it
cleanly.

## Where we hit it

A screensaver platform hands its host the app's model as a `Box`, and the
host gives the last one back to a `release_model_for_host` so Roc can free
it. Written `Box(model) -> {}`, the host's shutdown crashed; written
`Box(Model) -> {}`, it ran.
