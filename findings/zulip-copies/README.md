# A list write that copies or not depending on `--opt`

**Reduced, not reported.** Steve's plan: a roc-lang/roc issue with the
details and this directory, and a short Zulip question that points at it.

On the default platform every heap value is its own `mmap`, so a copy per
write shows as thousands of calls; 2 or 3 is startup alone. Every build below
is a native x86-64 ELF (`file`), and dev and LLVM builds of each program print
the same result.

    findings/zulip-copies/run.sh          # thread/ variants and RecordWidth, dev and LLVM
    ROC=<another roc> findings/zulip-copies/run.sh

## T1: LLVM copies on every other write, dev on none

`thread/T1_walk_returns` (threaded-record-copy's `h_recursive_returns_m`, with
the list's size from the command line): 10,000 writes into `num`, a `List(F64)`
in a record `{ num, scr : List(U8), out : List(Str), pc }`. Before each write a
recursive `walk` hands the record back; the write is inline in `spin`'s tail
call.

| build, list of 65,536 | time | mmap |
|---|---|---|
| `--opt=dev` | 0.007 s | 3 |
| `--opt=speed` | 1.91 s | 5,003 |
| `--opt=size` | 1.93 s | 5,003 |

At 286, 4,096 and 65,536 elements the LLVM build takes 0.03, 0.15 and 1.9 s:
the copy count is fixed and each copy grows with the list. The same on
nightly-2026-09-11-793f9d8, nightly-2026-09-12-220fd47, and a local Debug build
of roc at `68267dd`. nightly-2026-09-15-fe09c42 dies with SIGILL on this CPU.

| variant | what differs from T1 | dev | LLVM |
|---|---|---|---|
| `T0_no_walk` | no walk | 3 | 3 |
| `T4_walk_reads` | the walk only reads the record | 3 | 3 |
| `T2_one_list` | no other list in the record | 3 | 3 |
| `T3_write_in_helper` | the record update in a helper | 3 | 3 |
| `T5_bytes_only` | only `scr` beside `num` | 3 | 5,003 |
| `T6_strs_only` | only `out` beside `num` | 3 | 5,003 |
| `T7_one_byte_walk` | the walk recurses once a step | 3 | 5,003 |
| `T8_runtime_index` | the written index from the command line | 3 | 5,003 |
| `T9_while_loop` | a `while` over `var $m` instead of recursion | **10,003** | **10,003** |

`T8` rules out the range proof. `T9` copies every write on BOTH backends: a
different shape, not a test of the recursion.

## The earlier findings, dev against LLVM

| program | dev | LLVM |
|---|---|---|
| `threaded-record-copy` a, b, c, g | 10,001 | 10,001 |
| `threaded-record-copy` h (T1's origin) | 2 | 5,001 |
| `threaded-record-copy` d, e, f, i, j | 2 | 2 |
| `helper-arg-copy` copies | 50,006 | 10 |
| `helper-arg-copy` union-copies | 20,001 | 3 |
| `helper-arg-copy` const-arg | 10 | 50,006 |
| `helper-arg-copy` no-helper, union-no-helper | 10, 3 | 10, 3 |

**Neither backend is the one that copies.** Each copies in shapes the other
writes in place, and some shapes copy under both.

## Where the difference shows: the final LIR

`lir/` holds `ROC_LIR_DUMP` output for T1 (dev, speed) and T3 (speed), and
`spin` extracted from each.

- **dev:** `spin`'s step reads `num` out of the record `walk` returned,
  increments it, **decrements the record, then `list_set`s**. The record was
  the other reference, so `num` is unique at the write.
- **speed:** `spin`'s body holds the step twice.
  - The first copy is dev's order: increment, release the record, `list_set`
    (`spin-speed.txt` lines 43, 44, 47).
  - The second copy is increment, **`list_set`, then release the record**
    (lines 126, 129, 131). The record still holds `num` at the write, so its
    count is 2 and `list_set` copies.

That is every other write.

## What differs between the two pipelines

roc at `793f9d8`, `src/cli/main.zig` lines 11775-11800 and 11901-11916: the
same LIR pipeline, four settings by optimization level (`inline_mode` is
`.wrappers` for all three).

| setting | dev | speed, size |
|---|---|---|
| `spec_constr_clone_inlining` | `.iterator_fusion` | `.all_calls` |
| `list_in_place_map` | off | on |
| `tag_reachability` | off | on |
| `prove_ranges` | off | on |

**The leading suspect is SpecConstr.**
`src/postcheck/monotype_lifted/spec_constr.zig` "specializes recursive direct
calls whose arguments are known constructor shapes". Under `.all_calls` a
worker "can flatten a callee's whole call tree into its body".
- T1's `spin` calls itself with a record literal. That is the shape SpecConstr
  specializes, and the duplicated step in the speed LIR is what such a worker
  would look like.
- T3 passes a helper's result instead, and does not copy.

**Not yet proven.** No environment variable changes the setting. The proof is
roc rebuilt with `specConstrCloneInliningForOpt(.speed)` answering
`.iterator_fusion`, and T1 run again. The local checkout at `68267dd`
reproduces the copy and has the same function, so the one-line patch applies
there.

## Records carried by value (the first thesis)

`record_width.py <K>`: a loop carrying one record of K `F64` fields, 20
million steps.

| | 4 fields | 32 fields | 256 fields |
|---|---|---|---|
| `--opt=speed` | 0.05 s | 0.05 s | 0.05 s |
| `--opt=dev` | 0.19 to 0.21 s | 0.19 to 0.20 s | 24.9 to 26.3 s |

## Related

- `../threaded-record-copy/`, `../helper-arg-copy/`.
- roc-lang/roc #10218 and #10920, both closed before these nightlies.
- `dig-2026-09-15.log`, the run behind the dev-against-LLVM tables.
