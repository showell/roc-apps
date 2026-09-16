# Roc, as the nightly behaves

What the new Roc compiler's nightly builds do that is easy to trip over, for
anyone writing or emitting Roc in this repository. Where a behaviour has a
reduced program, `findings/` holds it.

## The compiler

- **Use roc-lang/nightlies**, the daily release build of the new compiler.
  roc-lang/roc's own releases page is the old compiler. A debug build of the
  checkout is for working on the compiler: its checker is quadratic in a file's
  literals, where the nightly's is linear.
- **A nightly from 2026-09-12 on does not run on this box.** Since roc-lang/roc
  `a02ff3b0ce`, type digests are SHA-256 computed with the CPU's SHA-256
  instructions, and `sha` is in the x86_64 Linux release build's CPU floor, so
  `nightly-2026-09-15-fe09c42` dies with SIGILL (exit 132) the first time it
  digests a type -- which `roc check` on four lines already does. This box's CPU
  has no `sha_ni`; GitHub's x64 and arm64 Linux runners do, and run that nightly.
  x86_64 macOS is exempt from the floor and computes the same digests with
  portable rounds, because Intel Macs are the same CPU generation as this box.
  `nightly-2026-09-11-793f9d8` is the last one that runs here, and a build of the
  checkout needs `src/base/sha256_rounds.zig` forced onto the portable rounds.
- roc-ray pins `nightly-2026-09-07-14d9829`. Its `0.10.0-rc3` release bundle is
  pinned to `nightly-2026-08-23-fb208ba`, and the 09-07 and 09-11 nightlies both
  reject that bundle's `Text.roc`.
- **Judge a build on the ✗ mark, never the exit code.** A warning exits
  non-zero, and a type error compiles into a crash at its site while the rest of
  the program runs.
- `roc check` reports only the file it is given; a broken import is silent.
- **A call whose arguments are known at compile time is evaluated at compile
  time, with no step limit** (roc-lang/roc#11334). `roc check` never finishes on
  a program whose opening calls a function that loops forever, and on a
  terminating program the check takes as long as the program's own work. A
  reduced program must still terminate (`findings/roc-check-hang/`).
- Roc deletes every `roc-*` directory in the system temp root when it runs, so a
  scratch directory must not use that prefix. It honours `TMPDIR`, which gives
  parallel builds their own.
- **Linking.** `x64win` is MSVC-ABI and looks for an installed Windows SDK, so it
  cannot link on Linux (`.github/workflows/windows.yml` builds on Windows).
  `arm64mac` and `x64mac` link on Linux against roc-ray's sysroot. The wasm dev
  backend writes a constant record's relocations out of offset order when field
  order and layout order differ (roc-lang/roc#11419,
  `findings/wasm-reloc-order/`).
- `ROC_LIR_DUMP=` (empty for every procedure) prints the LIR under source names.
  `roc build --debug` names wasm procedures only `roc__proc_<hex>`, and `perf`
  on a native build sees the same ids.
- The default Linux runtime prints "overflowed its stack memory" for any
  SIGSEGV, a read after free included.
- **The default platform gives every heap value its own `mmap`**
  (roc-lang/roc#11335). `strace -c` therefore counts allocations exactly and
  `strace -k` names the builtin that asked; the same property makes an
  allocation-heavy program several times slower than on a C allocator
  (`findings/roc-alloc-mmap/`).

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
- Record update is `{ ..r, f: v }`. `var $x` and `while` rebind in place.
- Only self tail calls are removed: two mutually recursive functions need a
  forwarder.
- `+` on a fixed-width integer crashes on overflow; the wrapping operations
  are named (`plus_wrap`, `shl_wrap`, ...). A bare fractional literal is a
  `Dec`.
- F64 has no `exp`, `log`, `floor` or `round`.
- `List.set` answers a `Try`. `List.sort_with` takes a comparator answering
  `Before`, `Same` or `After`.
- The Echo platform's `args` has no program name at index 0.
- A wasm platform's host export must also be named in `platform/main.roc`'s
  `exports:`, or it silently is not one.

## Speed and copying

- Building a list by concatenating onto a recursion is quadratic. An
  accumulator loop with `List.append` is linear; `List.concat(acc, [x])` is
  about 50 times slower than `List.append`.
- **A write is in place only when nothing else refers to the list**, and
  nothing reports a copy. The shapes that copy:
  1. `List.set(l, i, v) ?? l`: the fallback names `l`, so every store copies.
     Write `?? crash("...")`; reads before the store are free.
  2. `List.update(xs, i, f)`: the element handed to `f` is not unique, so a
     nested list is copied per write. Take it out with `List.replace`, write
     it, put it back.
  3. A value threaded down a recursion and handed back makes the caller's next
     store copy (`findings/threaded-record-copy/`). A recursive function that
     only reads the value does not.
  4. A helper given a record together with a value read from that record, when
     the caller passes a freshly updated record and the store is in its own
     function (`findings/helper-arg-copy/`). Let the helper read the field.
  5. A run loop that hands its `var` record to the step itself, rather than a
     fresh update such as `{ ..$m, steps: $m.steps + 1 }`.
  6. A field taken out in one statement and written back in another. Take it
     out, write it and put it back inside the record update:
     `{ ..m, devices: Devices.poke_into(m.devices, a, v) }`.
- **To tell copying from writing,** hold the number of writes fixed and vary the
  size of what is written into: flat is in place, linear is a copy
  (`tests/copycheck.sh`). One number says nothing.
- Updating one field copies the record around it, inline sub-records included.
  A large part behind a list of one costs nothing to carry. A `Box` carried
  untouched costs the same, but every write re-boxes, one allocation per write,
  so it suits parts never written after they are made.
- The dev backend's code is mostly stack moves (86% of the instructions in one
  hot function). LLVM (`--opt=speed`) ran BASIC's slowest program 2.7 times
  faster, building in 1,420 s where the dev backend takes 6 s; Safari on roc-ray
  builds with LLVM in 12 s.
