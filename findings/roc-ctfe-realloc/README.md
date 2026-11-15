# Compile-time evaluation panics: "compile-time RocOps reallocated unknown pointer"

**Filed as [roc-lang/roc#11590](https://github.com/roc-lang/roc/issues/11590),
2026-09-22.** `ISSUE.md` is the text as posted.

`main.roc` aborts `roc run` on nightly 2026-09-19 with the panic above;
`runtime.roc` is the same program with the key read from `args`, and it
prints `1`. Both print `1` on 09-12.

**The 09-15 nightly says nothing**, here or in the issue's first table: it
dies of SIGILL on any program on this box, a four-line hello-world
included, because it wants the CPU's SHA-256 instructions and this host
has no `sha_ni`. roc's e728698121 (Sep 16) chooses those rounds at runtime
instead, which is why 09-19 runs at all. The window for the panic is
therefore after 220fd47 (09-12) and at or before d025939 (09-19); the
correction is a comment on the issue.

It was reduced by hand from a larger trie test, one simplification at a time,
keeping each that still panicked.
