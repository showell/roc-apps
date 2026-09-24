# The first `roc build` after `roc run` makes a different binary, which crashes

**Not reduced, not reported.** Nightly `2026-09-23-c7852fd`, x86-64 Linux.
Found retesting `../roc-ctfe-realloc/runtime.roc` (the trie program, which
prints `1`), in a fresh copy of it:

    roc rt_copy.roc x                               prints 1
    roc build rt_copy.roc --output=a && ./a         "Roc application overflowed its stack memory" (31944 bytes)
    roc build rt_copy.roc --opt=speed --output=b    prints 1 (25696 bytes)
    roc build rt_copy.roc --output=c && ./c         prints 1 (25696 bytes)

Only the first default build after `roc run` differs, and it crashes every
time it runs. On `2026-09-19-d025939` the same first build also differs from
`--opt=speed` (33192 against 25952 bytes, and not `--opt=size`), but it
prints `1`. So the build cache seems to hand the first build something of the
run's, and on 09-23 that something is broken. Earlier in the same session a
`roc runtime.roc x` also overflowed once and printed `1` afterwards.
