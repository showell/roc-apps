# Roc, as the nightly behaves

What the new Roc compiler's nightly builds do that is easy to trip over, for
anyone writing or emitting Roc in this repository. How the Roc is *written*
(Steve's style) is [roc-style.md](roc-style.md).

## The compiler

- **Use roc-lang/nightlies**, the daily release build of the new compiler.
  roc-lang/roc's own releases page is the old compiler. A debug build of the
  checkout is for working on the compiler: its checker is quadratic in a file's
  literals, where the nightly's is linear.
- **The repository builds with one Roc, the one `roc-version` names**
  (`0.1.0_RC1`, roc-lang/roc's release candidate, built from 15177e9),
  installed at `~/tools/roc-<pin>/roc`. In the
  glue API that `glue/JsGlue.roc` follows, provides entries carry
  `exported`, and functions are `RocErasedCallable`.
- **Judge a build on the ✗ mark, never the exit code.** A warning exits
  non-zero, and a type error compiles into a crash at its site while the rest of
  the program runs.
- **`roc check` on a root reports its imports' errors too** (checked at
  nightly-2026-10-29: a type error in an imported module, and an import of a
  module that doesn't exist, both fail the root's check). A file no root
  imports is checked only when it's named.
- **A call whose arguments are known at compile time is evaluated at compile
  time, with no step limit** (roc-lang/roc#11334). `roc check` never finishes on
  a program whose opening calls a function that loops forever, and on a
  terminating program the check takes as long as the program's own work. A
  reduced program must still terminate. The
  compiler now says what it is evaluating while it runs. An experiment that
  plays games from a constant seed must tie the seed to a run-time value
  (`seed + 0 * List.len(args)`), or `roc check` plays the games -- and on 09-07
  crashed doing it.
- **A headerless app runs on a built-in echo platform** whose `echo!` writes no
  newline.
- Older nightlies deleted every `roc-*` directory in the system temp root when
  they ran; the 10-29 pin doesn't (`roc check`, `roc test` and a build all left
  one alone). A scratch directory still shouldn't use that prefix. Roc honours
  `TMPDIR`, which gives parallel builds their own.
- **Linking.** `x64win` is MSVC-ABI and looks for an installed Windows SDK, so it
  cannot link on Linux. The wasm dev backend writes a constant record's relocations out of offset order when field
  order and layout order differ (roc-lang/roc#11419).
- `ROC_LIR_DUMP=` (empty for every procedure) prints the LIR under source names.
  `roc build --debug` names wasm procedures only `roc__proc_<hex>`, and `perf`
  on a native build sees the same ids.
- The default Linux runtime prints "overflowed its stack memory" for any
  SIGSEGV, a read after free included.

## The language

- No shadowing. A local named like a top-level definition is an error; a
  parameter named like one is a warning.
- In a module whose type shares its name (`Cat :: [].{ Cat : ... }`), a bare
  `Cat` is the module's own type, so type references are qualified.
- `${` interpolates inside a string; `\$` is a literal dollar.
- An effectful function's arrow is `=>`, in a signature and as a value, and its
  name ends in `!`. An effect under a `->` annotation is a type error; `=>`
  without `!` only warns.
- `:` may not be recursive; `:=` may.
- A nominal type has no structural `==`: attach `is_eq` in its declaration.
  `==` on a type variable needs `where [a.is_eq : a, a -> Bool]`.
- `targets`, `requires`, `provides`, `exposes`, `packages`, `platform` and
  `app` are reserved words in ordinary modules too.
- List patterns are `[]` and `[h, .. as t]`; `.. as _` is invalid.
- An alternatives pattern nested inside a tuple pattern, `(Stream, Post | Other)`, is "not yet implemented" at the 10-30 nightly. Spell out one arm per alternative (roc-style.md, "spell out the arms").
- Record update is `{ ..r, f: v }`. `var $x` and `while` rebind in place.
- Only self tail calls are removed: two mutually recursive functions need a
  forwarder.
- `+` on a fixed-width integer crashes on overflow; the wrapping operations
  are named (`plus_wrap`, `shl_wrap`, ...). A bare fractional literal is a
  `Dec`.
- F64 has no `exp` or `log`; `F64.e.pow(x)` is its `exp`. It rounds only into an integer type (`round_to_i64_try`, `floor_to_i64_try`, `ceiling_to_i64_try`), and `round` is `floor(x + 0.5)`, so 0.49999999999999994 rounds to 1.
- F64's `sin`, `cos`, `tan`, `atan`, `atan2` and `pow` are Roc's own fdlibm port, so they give the same bits on every target and backend.
- A helper defined outside a module's `X :: [].{ }` block must qualify the block's members (`TreeShapes.tree_outline`); a bare name is "not in scope".
- `List.reverse` doesn't exist at the 09-22 nightly; `fold_rev` with `append` does the job.
- A plain record literal type-checks where a nominal record (`P := { x : F64, y : F64 }`) is expected, even from another module; only a different nominal type is refused. So a nominal record stops a mix-up between two nominal types, not a hand-written literal. Use an opaque type (`::`) where no literal may pass. (Checked at the 09-22 nightly, 2026-11-03.)
- `List.set` answers a `Try`. `List.sort_with` takes a comparator answering
  `Before`, `Same` or `After`.
- The Echo platform's `args` has no program name at index 0.
- A wasm platform's host export must also be named in `platform/main.roc`'s
  `exports:`, or it silently is not one.

## Speed and copying

- Building a list by concatenating onto a recursion is quadratic. An
  accumulator loop with `List.append` is linear; `List.concat(acc, [x])` is
  about 50 times slower than `List.append`.
- **A write is in place only when nothing else refers to the value**, and
  nothing reports a copy. RC1 infers which uses only borrow, and in the
  release build (`--opt=speed`) proves some values unique and drops the
  run-time check; none of that leaves the compiler. A copy allocates the
  whole list (or dict) again on every write, so its time grows with the
  size of what is copied.
- **Every copy on RC1 is a use after a consume:** a write (`List.set`,
  `append`, `Dict.insert`, ...) takes the value, and something still reads
  the old one after it. Each shape below is a loop in
  `tools/copy_shapes/CopyShapes.roc`, named here in brackets, and `shale
  check.shale copy_shapes=1` holds what one more write allocates in the
  release, dev and boxy (`--opt=speed --specialize=no`) builds
  (`tools/copy_shapes/expected*.txt`).

  **Copies in every build:**
  1. The old list read after its write: `ys = xs.set(j, v) ?? xs`, then
     `xs.get(j)` (`get-after-set`). Read first (`set-restored`).
  2. A closure over the list called after the write (`closure-called-after`).
     Called inside the write's own arguments, it is free
     (`closure-called-before`).
  3. An inner list got, written and set back while the outer list still holds
     it (`nested-get-then-set`). `List.update` hands the element over unshared
     and is free (`nested-update`).
  4. The old dict read after an insert, even its `len` (`dict-length-after-insert`).
  5. A value got from a dict, written and inserted back while the dict still
     holds it (`dict-get-then-insert`). Take it out first, `get` then
     `remove` (`dict-take-then-insert`): free in the release and dev builds,
     three allocations a write in the boxy build.

  **Copies in the dev and boxy builds only,** where a helper stays a call that
  owns its arguments (the release build specializes it first):
  6. A helper that reads its list after writing it,
     `(xs.set(j, v) ?? xs, xs.len())` (`helper-length-after-set`). Read first
     (`helper-length-before-set`).
  7. A helper that reads the whole record inside the write of its field,
     `{ ..d, cells: d.cells.set(kept(d, j), v) ?? crash ... }`
     (`helper-reads-record`, BASIC's `Devices.poked`). Bind the index on the
     line before (`index-bound-before`).
  8. `?? xs` on a list whose entries hold a reference count, a list of
     strings (`str-list-restored`, and `host-args-list` on the command line's
     list). `?? crash` is free in every build (`str-list-or-crash`).

  **No longer copies on RC1** (the old nightlies copied each):
  - `List.set(l, i, v) ?? l` on a list of numbers (`set-restored`; also
    `?? []`, `set-or-empty`, and `?? crash`, `set-or-crash`): the compiler
    hands `l` back on the error path. Write `?? crash "..."` all the same:
    the fallback is a placeholder (roc-style.md, "Errors and failure"), and
    shape 8 copies.
  - `List.update` on a nested list (`nested-update`).
  - A field taken out in one statement and written back in another
    (`field-taken-out-first`).
  - A helper that hands the list back (`helper-returns-list`), and a list
    threaded down a recursion and back, which every shape here is.
  - An inner list taken out with `replace` and written inside the outer
    set's arguments (`nested-replace-then-set`, BASIC's `Vec.set_in`), a
    field handed to a helper inside its record's update
    (`field-through-helper`, the JS interpreter's `with_var` call), and a
    list of list-holding records set with `?? crash` (`record-list-or-crash`).
  - The list's length read after its write within one function, in a record
    built again or not (`record-length-after-set`, `append-length-after`). A `get`
    after the write copies (shape 1); the compiler doesn't say why `len`
    differs.

  Three more shapes the old nightlies copied don't on RC1, each measured on
  BASIC's controls in both builds: a helper given a record with a value read
  from it (BASIC's `enter_for`), a run loop that hands its `var` record to the
  step itself, and a statement's body written in a `match` arm rather than a
  function of its own.
- **To tell copying from writing,** hold the number of writes fixed and vary the
  size of what is written into: flat is in place, linear is a copy. One number
  says nothing. `tools/alloc_ladder.shale` holds a program's controls to what
  one more iteration allocates, run at two sizes, by counting `roc_alloc`
  calls with breakpoints; on RC1's default platform `strace` no longer sees an
  allocation. A new copying shape gets a loop in CopyShapes.roc and a line in
  its expected files.
- **The Unique marker, opt in** (`tools/copy_shapes/Unique.roc`). An
  opaque `Unique(a) :: a` whose closed API (`wrap`, `unwrap`, `len`, `get`,
  `set`, `append`, `update`, `take_from`) is the only way to reach the
  value, so a checker knows every write by name. The rule it asks for: a
  read (`len`, `get`) is free anywhere before the binding's next write; a
  write ends the binding, and the old one is never used again; a closure
  never captures one; a dict's value comes out through `take_from` (got,
  then removed), never `get`. It costs nothing in allocations: the
  `unique-*` copy shapes allocate as their bare twins do in every build
  (`unique-set` 0 a write, `unique-update` 0, `unique-take-from` 0 in the
  release and dev builds and 2 in the boxy build, as `dict-take-then-insert`
  costs 3 there). Its time is the bare list's in a program of its own (the
  copy-cliffs study, 405 to 508 ms against 417 to 428 ms for 50 million
  writes); inside the copy-shapes executable `unique-set` took about twice
  `set-or-crash`'s time (876 against 423 ms, load about 1, 2026-11-23),
  which the allocations don't explain. **It prevents nothing by itself:**
  `unique-get-after-set` copies on every write, as `get-after-set` does.
  The guarantee is Shale's `cookbook/roc/find_uses_after_a_consume.shale`'s,
  only where a gate runs it, and that recipe holds a Unique to the same
  rules as a bare list, no stricter: it knows the module's writes by name,
  and nothing more. BASIC's Vec and the JS heap stay as they are.
- Updating one field copies the record around it, inline sub-records included.
  A large part behind a list of one costs nothing to carry. A `Box` carried
  untouched costs the same, but every write re-boxes, one allocation per write,
  so it suits parts never written after they are made.
- The dev backend's code is mostly stack moves (86% of the instructions in one
  hot function). LLVM (`--opt=speed`) runs BASIC's programs about ten times
  faster (8 to 18 times on `basic/pathological/`, 2026-11-23), and BASIC's
  release build compiles in 60 to 90 s where the dev build takes a few.
