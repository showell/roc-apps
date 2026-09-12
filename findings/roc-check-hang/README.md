# `roc check` and `roc build` do not terminate on a program that does not

**Filed as [roc-lang/roc#11334](https://github.com/roc-lang/roc/issues/11334),
2026-09-12.** `ISSUE.md` is the text as posted.

**Corrected 2026-09-12.** The first reading of this, written earlier the
same day, said the cost was type checking and grew with the number of call
sites into mutually recursive functions. **That was wrong.** The measurement
below is what it actually is.

## What happens

`spins.roc` is seven lines. `roc check` on it does not finish: killed at ten
minutes, 100% of one core, 80 MB flat, no diagnostic.

```roc
app [main!] {}

loop_forever = |n| if n < 0 { 0 } else { loop_forever(n) }

main! = |_args| {
	echo!(I64.to_str(loop_forever(1)))
	Ok({})
}
```

`finishes.roc` is the same program with the argument taken from `args`
instead of written as a literal, and it checks in 34 ms and builds in
190 ms. So the compiler is EVALUATING the call, because its argument is
known, and the evaluation has no step limit.

## The measurements

    roc --version
    Roc compiler version nightly-2026-09-11-793f9d8

The release tarball from roc-lang/nightlies
(`roc_nightly-linux_x86_64-2026-09-11-793f9d8`), x86-64 Linux, on an
otherwise idle 8 GB box.

| program | `roc check` | `roc build` |
|---|---|---|
| `loop_forever(1)`, the argument a literal | never finishes | never finishes |
| `loop_forever(List.len(args))` | 34 ms | 190 ms |
| `loop_forever` defined but never called | 23 ms | |
| `count(1_000_000, 0)`, terminating | 60 ms | |
| `count(4_000_000, 0)` | 146 ms | |
| `count(16_000_000, 0)` | 487 ms | |
| a loop of 8,000,000 steps carrying a `List` | 83 ms | |

The middle rows are the same finding from the other side: check time
tracks the number of steps the program itself takes, because the compiler
is running it. The last row is the shape that issue #10297 reported as an
OOM; on this nightly it is not evaluated at all, so the value size is
bounded now and the step count is not.

## Where it came from

An emitted Codex program in our corpus took 2.7 seconds to `roc check` and
3 ms to run. The 2.7 seconds is the compiler playing a whole-tree
tic-tac-toe search, which is what that program does; the run is 3 ms
because the answer was already a constant by then. Inlining its modules
into one file, which should change nothing, turned the seconds into a
hang, and that turned out to be because the inlining made a helper answer
a constant, which made the search never terminate -- a program bug in the
reduction, which is exactly the case this reports.

## Reducing

`reduce.py` shrinks a file while checking at every step that it still
spins, so nothing it leaves behind is incidental.

    findings/roc-check-hang/reduce.py hang.roc 15

`hang.roc` is the 29-line starting point and `smallest.roc` is where that
run stopped; `spins.roc` is the hand-reduced seven lines above.
