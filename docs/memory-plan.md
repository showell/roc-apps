# A plan for `peek-byte` and `poke-byte`

**DONE, 2026-09-12.** Whether the page array should be a persistent trie instead is [memory-structures.md](memory-structures.md). What it cost and what it moved is at the end; the
reasoning, with diagrams, is in the essay
[memory as a value](http://143.244.172.148:9100/notes/memory-as-a-value.md).

204 of the 526 refused programs are blocked first by a memory builtin.
This is what it would take, and what it would cost.

## What the builtins are

    peek-byte  : Integer, Integer -> Integer      base, offset
    peek-16    : Integer, Integer -> Integer
    peek-32    : Integer, Integer -> Integer
    peek-qword : Integer, Integer -> Integer
    poke-byte  : Integer, Integer, Integer -> Integer   base, offset, value
    poke-16    : ...
    poke-32    : ...
    poke-qword : ...
    alloc-bytes : Integer -> Integer              size -> base

The interpreter holds memory as a sparse map of 4 KB pages and reads zero
from anything unmapped. A poke answers 0 and is bound to a name nobody
reads; the write IS the point.

## What the programs do with them

Of the 204: 23 call `alloc-bytes` and poke into what it returns, and 6
poke a literal address, the largest of which is 786,432 -- a kernel test
laying out a capability table, not a hardware register. The rest take a
base from a caller. **Nothing in this set pokes a device.** The programs
that do talk to hardware are blocked on `port-out-32` and `uefi-read-key`
instead, and stay blocked.

So the address space can be a flat byte array that grows, with a bump
allocator on top, rather than the interpreter's page map. Reads past the
end answer zero, which is what the page map does for an unmapped page.

## The lowering

**The trigger is not the type.** Codex gives these builtins an EMPTY
effect row -- `alloc-bytes : (fn int empty int)` -- so a function that
pokes is pure as far as the type system is concerned, and
`fill : Integer, Integer -> Integer` writes 256 KB. The set of definitions
that touch memory has to be computed: a definition touches memory if it
calls one of the builtins, or calls a definition that does. That is one
closure over the call graph, the same shape as the type-recursion and
module-reachability closures the emitter already computes.

**The threading is the Device lowering, which already works.** A touching
definition takes the memory as its first parameter and answers it back
with its result:

    fill : Mem.Mem, I64, I64 -> (Mem.Mem, I64)

and `eff_expr` threads it through acts, lets, ifs and calls exactly as it
threads the GPU device today. Two extensions are needed:

1. **An effectful `let`.** `let p = poke-byte buf i v in fill buf (i + 1)`
   is the shape every fill loop takes, and the Device path refuses it
   today because a `[Device]` act never produced one.
2. **The trigger set**, from the closure above, in place of "the type
   carries `[Device]`".

**`Mem.roc` is written by rocemit** (a `const MEM` string in
`roc_emit.rs`), as `Device.roc` is: a byte store and a bump pointer,
`load`/`store` for 1, 2, 4 and 8 bytes little-endian, and `alloc` that
answers the old top and moves it. Under a hundred lines.

## What it costs, and what could go wrong

- **A fill loop writes a quarter of a million bytes.** `List.set` on a
  uniquely owned list writes in place, and the threading keeps it unique,
  which is exactly how the GPU kernels reached 15 ms a frame. If
  uniqueness is ever lost, every store copies the whole buffer and the
  program stops finishing, so this is the first thing to measure.
- **The compiler will run those loops**, since compile-time evaluation has
  no step limit (roc-lang/roc#11334). A 262,144-iteration fill at compile
  time is the slowest thing we would have asked of it.
- **Absolute addresses are capped.** A flat array cannot hold a poke at
  2^40 without a page map; nothing in this set does that, and a program
  that tried would read zero where the interpreter reads its own write.
  The cap is a named limit, not a silent one.
- **How many actually land is unknown.** 204 are blocked FIRST by memory;
  some will be blocked next by port I/O or processes. The honest estimate
  is "most of the 204, not all".

## The order

1. The call-graph closure and the effectful `let`, with the Device
   lowering generalised to take a trigger set. No new Roc yet.
2. `Mem.roc`, and the builtins mapped onto it.
3. One program end to end: `cap-heap-poke-pure` prints `42` and is four
   lines of memory work.
4. A 262 KB fill as the performance probe. (`diskfacts-unpack-large`, the
   unit this named, turned out to be refused for `block-read-sector`
   before it reaches any memory, so the probe is a standalone program.)
5. The sweep, and a count of what moved from memory to the next blocker.

## What happened

All five steps landed. Two things the plan did not anticipate, both from
the empty effect row letting a poke stand where a `[Device]` act could
not: a call that pokes can be an ARGUMENT, so it is lifted to a binding
ahead of the expression that reads it; and a call's state has to be read
AFTER its arguments are emitted, since one of them may have written.

**The plan proposed a flat byte array and what shipped is the page map**,
because `alloc-bytes` starts at 6 MB while literal pokes sit near zero: a
flat array is megabytes of zeros, and the compile-time evaluator
MATERIALISES a 64 MB `List.repeat` where `List.repeat([], 16384)` is
nearly free.

**A list still reachable after a write is copied**, so every `??` fallback
in `Mem.roc` crashes rather than answering the list it was setting: that
one spelling on the page table is 137.8 s of CPU against 3.5 s.

**And a nested list is not unique inside `List.update`**, which is the
plan's own top risk -- "if uniqueness is ever lost, every store copies the
whole buffer" -- and it shipped that way, undiagnosed, until a cold review
measured it. `put` now TAKES the page out of the table with `List.replace`,
writes it while it is genuinely its own, and puts it back: the
262,144-byte fill went from 3.5 s to 0.3 s of CPU.

A length check on the way to a store costs NOTHING, contrary to what this
document said before: `List.set` already calls `List.len` on the list it
then writes in place. `tests/copycheck.sh` is the standing instrument --
hold the write count fixed, vary the size, and read the slope.

Of the 204 units blocked first on a memory builtin: 24 pass, 1 fails on
our CCE-unit modelling, 1 diverges on `__heap-save`, 178 moved to the next
blocker; the numbers are as of 2026-09-12. Of those 178, 88 want hardware (`port-out-32`, `read-mmio-32`,
`net-send-raw`), 52 are our own named gaps (a short-circuit operand or a
match arm that pokes, a match under the threaded state), 14 write a list
parameter, 24 assorted. The ladder went 459 -> 483 of 1,017.

The corpus's memory users are, overwhelmingly, device drivers.
