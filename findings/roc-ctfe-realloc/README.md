# Compile-time evaluation panics: "compile-time RocOps reallocated unknown pointer"

**Filed as [roc-lang/roc#11590](https://github.com/roc-lang/roc/issues/11590),
2026-09-22.** `ISSUE.md` is the text as posted.

`main.roc` aborts `roc run` on nightly 2026-09-19 with the panic above;
`runtime.roc` is the same program with the key read from `args`, and it
prints `1`. Both print `1` on 09-12; both die with SIGILL on 09-15.

It is `tests/ladder.sh`'s `trie-prefix-test` (codex/test/trie-prefix-test),
reduced by hand from rocemit's output: the Codex chapters folded into one
file, then one simplification at a time, keeping each that still panicked.
