# Bug-hunting Roc with a compiler's test suite

This repository points a second language's test suite at Roc. When we file
an issue on roc-lang/roc we link here, because the first question is
reasonably "what is Codex, and why are you running its tests?"

## What Cobblestone and Codex are

[Cobblestone](https://github.com/damiant3/Cobblestone) is one person's
from-scratch software stack: a language called **Codex**, a self-hosted
compiler for it, an operating system that boots on bare metal, and about
seventy applications written in it. Codex is a pure, statically typed,
effect-tracked functional language with an unusual amount of machinery
around it -- an effect row on every arrow, integers with declared bounds
and an overflow mode, proofs, linear types -- and it compiles through
"plugs" to a couple of dozen targets, including x86-64, ARM, RISC-V,
WebAssembly, WGSL and about twenty other languages.

None of that is the point here. The point is `codex/test/`: **641 small
programs, 597 of them beside a file holding exactly what the program must
print.** They were written to catch a compiler's own mistakes, so they
are unusually direct: arithmetic to a fixed answer, a list built and read
back, a record updated, a sum type matched, text encoded, a checksum
computed. No frameworks, no I/O beyond printing, no cleverness.

## What we do with them

We wrote a Codex-to-Roc emitter (`rocemit`, in
[rust-codex-compiler](https://github.com/showell/rust-codex-compiler)),
which reads the typed intermediate representation of a Codex program and
writes Roc modules: one Roc module per Codex chapter, every definition
annotated. Then `tests/ladder.sh` emits each of the 597 programs, runs it
with `roc run`, and diffs the output against the file Cobblestone records.

Three outcomes matter, and we count them apart:

- **PASS** -- the emitted Roc prints exactly what the Codex prints.
- **REFUSED** -- our emitter declined a Codex form it has not built yet,
  by name. That is our gap, not Roc's, and it is the work queue.
- **FAIL** -- the program compiled and printed the wrong thing, or the
  compiler did something we did not expect. **This is the interesting
  column, and it is where the issues come from.**

A fourth, **DIVERGES**, names a program whose verdict pins something the
port cannot reproduce, with the reason written down: two of them because a
Codex list is written in place, so a program that writes a list through
one name and reads it through another cannot be ported, and one because
its verdict records a rounding quirk in Codex's own decimal printer. We
name those rather than counting them as failures.

## Why this finds things

An emitted program is not idiomatic Roc and was not written by anyone
with Roc in mind. It is a few hundred lines of mechanically produced code
that exercises one narrow behaviour and must print one exact thing. That
turns out to be a good shape for finding compiler bugs:

- the programs are **dense**: deep recursion, big literal tables, long
  chains of arithmetic on declared bounds, in files nobody hand-wrote;
- they are **exactly verified**: a wrong answer is a diff, not a feeling,
  so a miscompilation cannot hide behind "looks right";
- there are **hundreds of them**, so a shape that appears once in a
  hand-written test suite appears fifty times here;
- and they are **not tuned to Roc**, so they walk into corners that
  someone writing a Roc test would naturally walk around.

We check every finding against the Codex side before reporting it: the
same program is run by Cobblestone's own compiler, so we can tell "Roc is
wrong" from "our emitter is wrong", and we say which. So far the count is
lopsided in the honest direction -- most of what the corpus catches is
ours. Emitting real arithmetic alone caught three of our own bugs before
it caught anything else: a record field with declared bounds was not
clamped where the record is built, two Codex names differing only in case
became one Roc name, and reals printed the shortest round-trip decimal
where Codex prints the integer part in full and truncates the fraction. Every issue we file
carries the exact nightly, the timings, and a reduced program that stands
alone.

## What we have filed

- [#11334](https://github.com/roc-lang/roc/issues/11334) -- compile-time
  evaluation has no step limit, so `roc check` never finishes on a program
  that loops forever.
- [#11335](https://github.com/roc-lang/roc/issues/11335) -- the default
  platform's allocator makes one `mmap` per heap value and one `munmap`
  per free.

## Where the pieces are

| | |
|---|---|
| `tests/ladder.sh` | emit all 597, run them, diff against the verdicts |
| `tests/ledger.txt` | the current standing, one line per program |
| `tests/verdicts.sh` | the three capture artifacts in the verdict files, stripped once |
| `tests/package.py` | the passing programs as a Roc package, for a possible contribution |
| `findings/` | one directory per issue: the reproducer, the measurements, the text as filed |
| `safari/`, `gpu/`, `games/` | three Codex applications emitted to Roc and run in the browser |

The emitter is not a general Codex-to-Roc compiler and does not try to be.
It covers what the corpus needs, refuses the rest by name, and grows when
a refusal is worth removing.
