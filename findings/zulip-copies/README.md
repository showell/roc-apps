# `--opt=speed` copies a list that `--opt=dev` writes in place

**Reduced, not reported.** Steve decides whether it goes to the Roc Zulip; the
draft question is `:9100/notes/zulip-stack-moves-question.md`.

`run.sh` builds every variant with LLVM and with the dev backend and measures
how the time scales: 10,000 writes into `num`, a `List(F64)` in a record, at
list sizes of 286, 4,096 and 65,536. The default platform gives every heap
value its own `mmap`, so a copy per write shows as thousands of calls; 3 is
startup alone.

    findings/zulip-copies/run.sh
    ROC=<another roc> findings/zulip-copies/run.sh

## The copy (nightly-2026-09-11-793f9d8 and nightly-2026-09-12-220fd47, the same)

| `thread/` variant | what differs from T1 | `--opt=speed` @286 / @4,096 / @65,536 | `--opt=dev` |
|---|---|---|---|
| `T1_walk_returns` | `threaded-record-copy`'s `h_recursive_returns_m`, sized: a recursive walk hands the record back, the record also holds `scr : List(U8)` and `out : List(Str)`, and the write is inline in the tail call | 0.03 / 0.15 / 1.9 s, 5,003 mmap | 0.00 s, 3 mmap |
| `T0_no_walk` | no walk | 0.00 s, 3 mmap | 0.00 s, 3 |
| `T4_walk_reads` | the walk only reads the record | 0.00 s, 3 | 0.00 s, 3 |
| `T2_one_list` | the record is only `num` and `pc` | 0.00 s, 3 | 0.00 s, 3 |
| `T3_write_in_helper` | the record update in its own function | 0.00 s, 3 | 0.00 s, 3 |
| `T5_bytes_only` | `scr` kept, `out` gone | 0.03 / 0.15 / 1.9 s, 5,003 | 0.00 s, 3 |
| `T6_strs_only` | `out` kept, `scr` gone | 0.03 / 0.16 / 1.9 s, 5,003 | 0.00 s, 3 |
| `T7_one_byte_walk` | a one-byte text, so the walk recurses once a step | 0.03 / 0.15 / 1.9 s, 5,003 | 0.00 s, 3 |

**Under LLVM every other write copies the whole list; under dev none does.**
The copy needs all three of these:
1. **a recursive function given the record that hands it back;**
2. **a second refcounted field in the record** (a list of any element);
3. **the write inline in the tail call's argument.**

A first probe written from scratch, a state record of one list and a counter
written through a helper, did not copy under either backend, which is what
`T2` and `T3` say.

nightly-2026-09-15-fe09c42 does not run on this machine (SIGILL on `check`
and `build`; the CPU has AVX2, not AVX-512).

## Records carried by value

`record_width.py <K>` writes a loop that carries one record of K `F64` fields
and updates two a step. 20 million steps:

| | 4 fields | 32 fields | 256 fields |
|---|---|---|---|
| `--opt=speed` | 0.05 s | 0.05 s | 0.05 s |
| `--opt=dev` | 0.19 to 0.21 s | 0.19 to 0.20 s | 24.9 to 26.3 s |

## Related

- `../threaded-record-copy/`, the program `T1` comes from.
- `../helper-arg-copy/`, a copy that needs a helper given the record and a
  value read from it (measured on dev).
- roc-lang/roc #10218 and #10920, both closed before these nightlies.
