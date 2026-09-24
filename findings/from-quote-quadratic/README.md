# Checking a constant of `from_quote` literals grows faster than quadratically

Reported as roc-lang/roc#11666.

`T :: List(U8)` defines `from_quote`, so a string literal where a `T` is
wanted is a `T` (`T.roc`). `gen.py` writes one top-level constant holding N
literals, `words : List(T) = ["w0", "w1", ...]`, or the same as `List(Str)`.

`./run.sh`, on nightly-2026-09-22-e494788, a fresh cache each time:

    str     100 literals   check   0.03 s   LLVM build   0.27 s
    str     800 literals   check   0.06 s   LLVM build   0.30 s
    quote   100 literals   check   0.20 s   LLVM build   0.39 s
    quote   200 literals   check   0.57 s   LLVM build   0.47 s
    quote   400 literals   check   2.83 s   LLVM build   0.61 s
    quote   800 literals   check  20.24 s   LLVM build   1.10 s

Doubling the literals multiplies `roc check` by 3 to 7. `roc run`, whose
default is the dev backend, and `roc build --opt=dev` and `--opt=interpreter`
take what `roc check` takes (21 s at 800). `roc build` defaults to LLVM
(`--opt=speed`), which grows linearly: 1.1 s at 800.

The same 400 literals as 400 separate constants (`w0 : T`, `w0 = "w0"`,
...) take 0.78 s under `roc run`; built inside a function, so nothing is
evaluated at compile time, `roc check` takes 0.30 s.

Found through rocemit, which writes a Codex text literal as a Roc string of
its own `Text` type; the ported tests' literals are mostly a few per
expression, so they pay about a third more compile time rather than this.
