# LLVM ends a `while $next != $d` loop early when the pass is a local closure

**Reduced, not reported.** Nightly `2026-09-07-14d9829`, native and wasm32,
default platform for the native program. `run.sh` builds `App.roc` both ways
and runs each:

    dev    passes 10: 0 1 2 3 4 5 6 7 8 9
    speed  passes 1: 0 1 1000 1000 1000 1000 1000 1000 1000 1000

The program relaxes distances along a chain until a pass changes nothing:

    var $d = start
    var $next = relax(start)
    while $next != $d { $d = $next; $next = relax($d) }

`relax` folds `List.set` over a list of edges. Each pass moves a value one
square, so it should take ten passes. The LLVM build stops after one here
(two in the wasm32 build of the same code). The pass seems to write into the
list `$d` still names, so the two compare equal. The dev backend is right.

**What it takes:**

- **`relax` is a local closure that captures the edges** and does the fold
  itself. The same fold as a top-level function, with the closure only
  forwarding `|d| relax_with(edges, d)`, is right under LLVM.
- **An earlier value is compared with a new one.** A pass that reports
  whether it changed anything (`{ d, changed }`), with the loop testing
  `changed`, is right under both backends.

**Found by** fasttrack's computer player: `Agent.distances` had this shape,
and in the LLVM page build every square but the last two of the base came
out "far". Nothing crashed; the computer just played badly, and tuning one
of its weights changed nothing. `fasttrack/web/backends_check.mjs` now
plays the LLVM and dev builds against each other on every build.
