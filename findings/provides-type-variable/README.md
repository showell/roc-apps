# A provided function with a type variable checks clean and crashes when called

A platform function that the host calls, whose type holds a type
variable, passes `roc check` with no errors and no warnings and builds
with none. The built archive answers the host's call with "hit a runtime
error". Naming the type concretely fixes it.

This is a draft for upstream in `ISSUE.md`, not filed. It was found in
roc-screensaver's platform on 2026-11-15, where
`release_model_for_host : Box(model) -> {}` crashed the host and
`Box(Model) -> {}` did not.

## The program

- `platform/main.roc` requires `[Model : model] for program : { init : {}
  -> Box(model) }` and provides two functions: `roc_init`, which is
  `program.init`, and `roc_release`, which is
  `release_for_host : Box(model) -> {}`, a function that ignores its
  argument.
- `app/main.roc` sets `Model : { seconds : F32 }` and boxes one.
- `host/main.zig` calls `roc_init`, then `roc_release` with the box, and
  prints a line after each. It provides the Roc runtime functions from a
  fixed buffer, because the program allocates once and never frees.
- `build.zig` builds the app into an archive with `roc build
  --target=x64musl --opt=dev --output=...` and links it under the host.

## Running it

From this folder, with the Roc to test:

    zig build run -Droc=$HOME/tools/roc-nightly-2026-11-03-34bd006/roc

It prints:

    roc_init gave a box
    roc crashed: hit a runtime error

and exits 1. `roc check main.roc` from `app/` says "No errors found",
and the `roc build` the build runs says "0 errors and 0 warnings".

## What each form does

On `nightly-2026-11-03-34bd006`, the roc-apps pin, with only
`release_for_host`'s annotation changed:

| `release_for_host`'s annotation | `roc check` | run |
|---|---|---|
| `Box(model) -> {}` | clean | hit a runtime error |
| `model -> {}` | clean | hit a runtime error |
| `Box(a) -> {}`, a variable the `requires` never names | clean | hit a runtime error |
| none | clean | hit a runtime error |
| `Box(Model) -> {}` | clean | `roc_release returned` |

So the trigger is a provided function whose type is still polymorphic.
The `Box` and the `requires` variable are only where we met it.

## Each nightly

The program as it is here (`Box(model) -> {}`), built and run with each:

| nightly | `roc check` | run |
|---|---|---|
| `nightly-2026-10-29-a0a9fc2` | clean | hit a runtime error |
| `nightly-2026-10-30-0602c5f` | clean | hit a runtime error |
| `nightly-2026-11-03-34bd006` (the pin) | clean | hit a runtime error |
| `nightly-2026-11-07-ad3a5d2` | clean | hit a runtime error |
| `nightly-2026-11-11-7679cc5` | clean | hit a runtime error |
| `nightly-2026-11-15-f25da45` (the newest, 2026-11-15) | clean | hit a runtime error |

On `nightly-2026-11-15-f25da45`, `roc build --opt=speed` builds it with 0
errors and 0 warnings as well. Filed as roc-lang/roc#13113 (2026-11-16,
https://github.com/roc-lang/roc/issues/13113, reproduced that day on
`nightly-2026-11-15-f25da45`). No issue in roc-lang/roc matched, searched
2026-11-15 and again 2026-11-16; the nearest are #10770 (a runtime error in a generic host
signal, closed) and #12851 (a `provides` annotation naming an undeclared
type segfaults the compiler, closed).

## The workaround

Annotate every function a platform provides with concrete types. Where the
type is the app's, use the name the `requires` gives it, `Box(Model)`, not
its variable `model`.
