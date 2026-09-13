# BASIC, in Roc

A BASIC interpreter written by hand in Roc, a web page that runs it, and
the corpora that grade it.

The dialect is **ECMA-55 Minimal BASIC** — a published standard with a
published acceptance suite. The extensions past it are the ones the 1978
Creative Computing listings and the page need, and each is marked `EXT`
where it is implemented.

## Why this subject

A BASIC interpreter is a small program with an enormous state space: every
run is thousands of iterations of the same dispatch over a different
machine, and a wrong answer is a single wrong value that a graded corpus
catches. It is idiomatic Roc throughout, so whatever it turns up in the
compiler is already in the form a report needs.

## Laying it out

    basic/roc/Parse.roc     a listing as the program the machine runs: each statement parsed once
    basic/roc/Machine.roc   the machine: a read-only evaluator, the statements, the run loop, the doors
    basic/roc/Vec.roc       a persistent vector, 32-way: variables, arrays and memory
    basic/roc/Listing.roc   ECMA-55's check of each line and statement, before a run
    basic/roc/Program.roc   ECMA-55's check of the whole program: jumps, loops, DEFs, arrays
    basic/roc/BasicRun.roc  basic-run, the command: a listing and its replies in, the transcript out
    basic/roc/Basic.roc     the interpreter the page still runs
    basic/roc/Pages.roc     Basic.roc's memory and arrays
    basic/roc/BasicApp.roc  Basic.roc behind one boxed machine, for the page
    basic/wasm/             the page's platform and host
    basic/web/basic.html    the page
    basic/build.sh          the page and its module, into the preview
    basic/build-run.sh      basic-run, built once (the dev backend)
    basic/run.sh            corpus programs through basic-run, one process each, timed
    basic/compare.sh        two runs' transcripts, byte for byte: the gate for a new interpreter
    basic/controls/         the ladder: the smallest programs, each adding one thing
    basic/controls.sh       what one iteration of each allocates, against controls/expected.txt
    basic/pathological/     programs that stress one cost each, at scale
    basic/allocs.sh         their times and allocations
    basic/ladder.sh         run a corpus through run.sh, grade the transcripts, count
    basic/gen.py            one corpus program as its own Roc app (the ladder no longer uses it)
    basic/nbs-reports.txt   what each NBS program must show that its own verdict cannot
    basic/nbs-input/        replies for NBS programs whose corpus replies are placeholders
    basic/fetch.sh          the corpora, into ~/build/basic-corpus

## The doors

- **`run`** — a microcomputer's BASIC, as a batch: listing, keystrokes and
  a seed in, output text out. The games are graded through it.
- **`run_ecma`** — the same in ECMA-55: the listing is checked before its
  first statement, and TAB counts columns the standard's way. The NBS
  suite is graded through it.
- **`start` / `resume`** — the page's door. The machine suspends when it
  wants a line, sleeps, prints a line, or has run a few thousand
  statements; the page paints what it drew and resumes it.

`basic-run` is the batch doors as a command on Roc's default platform:
`basic-run ecma "<listing>" "<replies>"`, or `micro`. It is built once, and
each corpus program is its own process.

## Measuring it

**Built with the dev backend only.** The LLVM backend spends minutes on this
interpreter, and what is slow here is the shape of the code, which the dev
backend shows the same.

**A heap allocation is an `mmap` call** on the default platform, so
`strace -c` counts allocations without timing anything. `controls.sh` runs
each control at 1,000 and at 10,000 iterations; the difference is what one
iteration allocates, and each control is held to 0 or to a number written
beside its reason. A change that makes a control start allocating names the
feature it broke, which a slow program alone does not.

## The corpora

**`nbs/`** — the National Bureau of Standards' 208 Minimal BASIC test
programs. Most grade themselves: a conformant run never prints
`TEST FAILED`. The rest cannot say so on their own — an exception that must
be reported, a malformed program that must be rejected, a verdict only a
reader can resolve — and `nbs-reports.txt` says what each must show.

**`games/`** — 99 listings from *BASIC Computer Games* (David Ahl, 1978),
public domain, each with a capture of what a real BASIC printed for the
keystrokes beside it. A listing that calls `RND` cannot match byte for
byte, since the captured run had its own random numbers; the rest are
graded.

## What Roc does not have

Each is something a real program needs and a synthetic benchmark does not:

- **No `exp`, no `log`, no `floor`, no `round` on `F64`.** There is `abs`,
  `sqrt`, `sin`, `cos`, `tan`, `atan` and `pow`, and that is the list. So
  `EXP` is `pow` on e, `LOG` is an atanh series after a reduction by
  powers of two, and `INT` is truncation corrected downward.
- **No number parsing on `Str`.** No `to_f64`, no `to_i64`. A numeric
  literal is accumulated from its bytes as it is scanned.
- **No `List.walk`.** Every fold in here is an explicit recursion.

## Accepted past ECMA-55

The NBS suite's ERROR programs are malformed on purpose, and ECMA-55 lets
a processor either reject such a program or run it and document what it
does. The ECMA-55 door (`run_ecma`) rejects before the first statement;
these are the forms it runs instead, each a row marked `accepts` in
`nbs-reports.txt`:

- **Spaces before a line number** (P187) are skipped.
- **No space between a line number and its keyword**, or before THEN
  (P190: `250LET`, `10THEN`).
- **A sign after an operator** (P038: `4 ^ -2` is `4 ^ (-2)`).
- **Lowercase** (P204, P205): upper-cased outside quotes, kept inside.
- **`<`, `>`, `<=` and `>=` between strings** (P206): byte order.
- **A string of any length** in an INPUT reply (P112): ECMA-55's limit is
  at least 18 characters, and this one has none, so there is no string
  overflow to report.
- **THEN followed by a statement** rather than a line number, a quoted
  **prompt on INPUT**, `+` joining strings, and the extension statements
  and functions (POKE, PLOT, SLEEP, PEEK, CHR$ and the rest), which the
  check does not look inside.
