# A helper given a record and something read from it makes the next store copy

**Reduced, not reported** (Steve's call). Nightly `2026-09-11-793f9d8`, dev
backend, default platform, where every heap value is its own `mmap`
([roc-lang/roc#11335](https://github.com/roc-lang/roc/issues/11335)).

Found reducing the BASIC machine's POKE, which copied the whole path of its
16 MB persistent vector on every store. The reduction started from a program
that does not copy and added one ingredient of the machine at a time
(154 builds), then cut back to the smallest program that still copies.
`run.sh` builds and counts the variants here.

| variant | what differs from `copies/` | mmap for 10,000 stores |
|---|---|---|
| `copies` | `d = settle(m, m.fuel)`, then the store on `d` | 50,006 |
| `const-arg` | `d = settle(m, 0)` | 10 |
| `no-helper` | the store on `m`, no `settle` | 10 |
| `union-copies` | no `Vec`: a two-tag union holding lists | 20,001 |
| `union-no-helper` | the same, the store on `m` | 3 |

`settle` is `|m, _x| m`: what the helper does does not matter.

**The copy needs all four of these; taking away any one stops it:**

1. **A helper given the record and a second argument read from that record**
   (`settle(m, m.fuel)`). A constant stops it; binding the read to a name
   first, reversing the arguments or reading another field does not.
2. **The caller passes a freshly updated record** (`{ ..$m, fuel: ... }`).
3. **The store is in its own function.** Inlining it stops the copy.
4. **The store goes through a union of more than one tag holding lists** --
   the vector's tree. A plain list, a record around a list, a one-tag union
   or a list of lists do not copy.

A five-level vector copies five nodes a store, a two-level one two: every node
on the path is shared when it is written.

**Hypothesis, not verified:** reading a field of the record after passing it
makes the compiler treat the record as borrowed across the call, so the record
the helper returns shares its vector with that reference.

In the BASIC machine (`basic/roc/Machine.roc`), `enter_for` was given the
machine and a frame built from `m.pc + 1`; reading `m.pc` inside instead took
"FOR entered again" from 2 allocations an iteration to 0 (`basic/controls/`).
