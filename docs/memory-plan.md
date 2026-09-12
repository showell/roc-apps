# A plan for `peek-byte` and `poke-byte`

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
poke a literal address, the largest of which is 20,536 -- a kernel test
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

**`Mem.roc` is hand-written**, beside `Device.roc`: a `List(U8)` and a
bump pointer, `load`/`store` for 1, 2, 4 and 8 bytes little-endian, and
`alloc` that extends the list and answers the old top. Sixty lines.

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
4. `diskfacts-unpack-large`, which is the 262 KB fill, as the performance
   probe.
5. The sweep, and a count of what moved from memory to the next blocker.
