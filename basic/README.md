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
catches. It is also a long series of small writes, which Roc makes in place
only when nothing else refers to what is written. **Where the code's shape
departs from the obvious, a comment says which copy it avoids**, and the
control ladder (below) is how each one was found.

## Laying it out

    basic/roc/Parse.roc     a listing as the program the machine runs: each statement parsed once
    basic/roc/Machine.roc   the machine: a read-only evaluator, the statements, the run loop, the doors
    basic/roc/Vec.roc       a persistent vector, 32-way: variables, arrays and memory
    basic/roc/Devices.roc   the terminal, screen, memory and framebuffer, behind one reference in the machine
    basic/roc/Twister.roc   the Mersenne Twister: a microcomputer's RND, as basic101 draws it
    basic/roc/Listing.roc   ECMA-55's check of each line and statement, before a run
    basic/roc/Program.roc   ECMA-55's check of the whole program: jumps, loops, DEFs, arrays
    basic/roc/BasicRun.roc  basic-run, the command: a listing and its replies in, the transcript out
    basic/roc/BasicCheck.roc  basic-check: basic-run with the fast path compared to the full evaluator
    basic/roc/CommandLine.roc  the texts on basic-run's and basic-check's command lines
    basic/roc/BasicApp.roc  the machine behind one box, for the page
    basic/wasm/             the page's platform and host
    basic/web/basic.html    the page: the REPL
    basic/web/index.html    the page about it: what it is, what Roc makes hard, what it stands on, where it could go
    basic/build.sh          the page and its module, into the dev channel
    basic/build-run.sh      basic-run and basic-check, built once (the dev backend)
    basic/corpus.sh         the corpus as the scripts read it: a program's listing and replies
    basic/run.sh            corpus programs through basic-run, one process each, timed
    basic/compare.sh        two runs' transcripts, byte for byte: the gate for a new interpreter
    basic/check-fast.sh     the corpus and the controls through basic-check and basic-run
    basic/controls/         the ladder: the smallest programs, each adding one thing
    basic/controls.sh       what one iteration of each allocates, against controls/expected.txt
    basic/pathological/     programs that stress one cost each, at scale
    basic/allocs.sh         their times and allocations
    basic/timings.sh        every corpus program timed, with the statements it ran and its allocations
    basic/controls-time.sh  what one statement of each kind costs, from the controls
    basic/stacks.py         which builtin asked for each allocation, from an strace trace
    basic/ladder.sh         run a corpus through run.sh, grade the transcripts, count
    basic/ledger-*.txt      the ladder's last grades, one line a program
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

**Built with the dev backend only**, the page too. The LLVM backend takes
about 24 minutes to build this interpreter, and what is slow here is the
shape of the code, which the dev backend shows the same.

**A heap allocation is an `mmap` call** on the default platform, so
`strace -c` counts allocations without timing anything. `controls.sh` runs
each control at 1,000 and at 10,000 iterations; the difference is what one
iteration allocates, and each control is held to 0 or to a number written
beside its reason. A change that makes a control start allocating names the
feature it broke, which a slow program alone does not.

**The fast path is held to the full evaluator.** A LET, an IF or an array
store whose expression can only produce a value takes a fast path that
carries no effects record, and hands anything else to the full evaluator.
`check-fast.sh` runs every corpus program and every control through
`basic-check`, which runs each such statement both ways from the same machine
and stops the program with `fast differs` where the two machines disagree.
It reports how many fast answers it compared, and any transcript that is not
basic-run's.

## The corpora

**`nbs/`** — the National Bureau of Standards' 208 Minimal BASIC test
programs. Most grade themselves: a conformant run never prints
`TEST FAILED`. The rest cannot say so on their own — an exception that must
be reported, a malformed program that must be rejected, a verdict only a
reader can resolve — and `nbs-reports.txt` says what each must show.

**`games/`** — 99 listings from *BASIC Computer Games* (David Ahl, 1978),
public domain, each with a capture of what a BASIC printed for the
keystrokes beside it, taken from the tests of
[basic101](https://github.com/wconrad/basic101), a BASIC-80 interpreter.
The captures are basic101's output, so the listings are basic101's too, and
the microcomputer dialect follows basic101 where the two differ: numbers to
seven digits, its messages for STOP, a missing line and running out of
replies, and its RND — the Mersenne Twister of Ruby's `Random.new(0)` —
which makes a game that calls `RND` gradeable byte for byte like the rest.
Two games never end; their `.options` name the output lines basic101's test
harness allowed, and they pass when the capture, less the harness's own last
line, is where the transcript starts.

## What Roc does not have

Each is something a real program needs and a synthetic benchmark does not:

- **No `exp`, no `log`, no `floor`, no `round` on `F64`.** So `EXP` is
  `pow` on e, `LOG` is an atanh series after a reduction by powers of two,
  and `INT` is truncation corrected downward.
- **No way to require a write in place.** Roc writes a list in place only
  when nothing else refers to it, and says nothing when it copies. The
  control ladder is how this code finds out, and the comments name each
  shape that copied.

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
