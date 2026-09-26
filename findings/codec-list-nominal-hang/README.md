# The compiler hangs on a custom-coded, `List`-backed nominal type inside a derived container

**Filed as [roc-lang/roc#11727](https://github.com/roc-lang/roc/issues/11727),
2026-09-26.** `ISSUE.md` is the text as posted.

`hangs.roc` defines `Blob := List(U8)` with its own `parser_for` and parses
`{ b : Blob }` with `Json.parse`. `roc check` passes in tens of milliseconds; `roc`
and `roc build` spin (one core, resident memory flat at 67 MB) and don't
finish. `works.roc` is the same program with `Blob := { bytes : List(U8) }`,
and it runs.

    roc check hangs.roc   # No errors found
    roc hangs.roc         # never finishes
    roc works.roc         # alone: True / in record: True

Same on `nightly-2026-09-22-e494788` and `nightly-2026-09-25-1ab6804`.
`ISSUE.md` has the table of variations: a `List(Str)` backing, and a list
or a tuple instead of a record, hang too, while a `Str` backing and `Blob`
parsed on its own don't.

Found 2026-09-26 building `cbor-pets/`: `roc test` on it spun the same way
until `ImageBlob` moved its bytes into a record, which is the workaround it
carries.
