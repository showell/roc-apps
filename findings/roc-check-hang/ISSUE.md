# Compile-time evaluation has no step limit: `roc check` never finishes on a program that loops forever

`roc check` and `roc build` do not terminate on this seven-line program. No
diagnostic, no timeout: 100% of one core, 80 MB flat, killed after ten
minutes.

```roc
app [main!] {}

loop_forever = |n| if n < 0 { 0 } else { loop_forever(n) }

main! = |_args| {
	echo!(I64.to_str(loop_forever(1)))
	Ok({})
}
```

Take the argument from `args` instead of writing it as a literal and both
finish at once, which says the compiler is evaluating the call because the
argument is known:

```roc
main! = |args| {
	seed = List.len(args)
	echo!(I64.to_str(loop_forever(U64.to_i64_wrap(seed))))
	Ok({})
}
```

| program | `roc check` | `roc build` |
|---|---|---|
| `loop_forever(1)` | never finishes | never finishes |
| `loop_forever(List.len(args))` | 34 ms | 190 ms |
| `loop_forever` defined, never called | 23 ms | |

Compile-time evaluation is clearly deliberate, and the time it takes tracks
the work the program does:

| program | `roc check` |
|---|---|
| `count(1_000_000, 0)` | 60 ms |
| `count(4_000_000, 0)` | 146 ms |
| `count(16_000_000, 0)` | 487 ms |

```roc
count = |n, acc| if n <= 0 { acc } else { count(n - 1, acc + n) }
```

That is fine until the program does not stop, and then the compiler does
not either. The value SIZE looks bounded already: #10297's list-growing
program checks in 42 ms here rather than reaching 45 GB, and a loop of
8,000,000 steps that carries a `List` is not evaluated at all (83 ms). It
is the step count that is unbounded.

**Version.** `nightly-2026-09-11-793f9d8`, the release tarball from
roc-lang/nightlies (`roc_nightly-linux_x86_64-2026-09-11-793f9d8`),
x86-64 Linux.

**Where we hit it.** We compile a Codex corpus to Roc, and one program
took 2.7 seconds to `roc check` and 3 ms to run: the compiler was playing
the whole-tree tic-tac-toe search the program does, and the run was fast
because the answer was already a constant. Reducing that program is what
produced the loop above.
