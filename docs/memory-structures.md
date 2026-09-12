# Should memory be a persistent structure instead?

*Raised by Steve, 2026-09-12, while the array version was working. Not
urgent; recorded because it goes at the root rather than the symptom.*

## The complaint

What we shipped is an array-of-arrays: a fixed page table of 16,384
entries, each an unwritten `[]` or a 4 KB page. A write is:

    take the page out of the table    (List.replace, leaves a placeholder)
    write the byte                    (List.set, in place if unique)
    put the page back                 (List.set, in place if unique)

That is O(1) **when the refcount cooperates** and O(page) when it does
not, and *which one you get is invisible*. There is no diagnostic, the
type says nothing, and the two spellings differ by one mention of a name.
We have now been bitten twice:

- `List.set(l, i, v) ?? l` — the fallback names the list, so it is live
  past the set. 137.8 s of CPU against 3.5 s on the real module.
- `List.update(pages, p, |page| ...)` — the closure's page is not
  uniquely owned, so every byte copied 4 KB. 3.47 s against 0.32 s.

Neither was visible in the source. `tests/copycheck.sh` exists because
the only way to know is to measure the slope.

## The alternative

A **persistent structure** — a hash array mapped trie, or Elm's `Dict`
and `Array` — is O(log N) per update **always**, by construction, with no
dependence on what the refcount happens to be. Structural sharing is the
mechanism rather than an optimisation the compiler might or might not
apply.

The trade, stated plainly:

| | array of pages | persistent trie |
|---|---|---|
| best case | O(1) | O(log N) |
| worst case | O(page) = 4,096 | O(log N) |
| which one you get | invisible | always the same |
| 262 KB fill, measured | 0.32 s CPU (good case) | not measured |

**The argument for switching is not speed, it is predictability.** A
32-way trie bounds the copy at 32 elements per level, so the bad case
costs a few hundred bytes instead of four kilobytes, and the good case
costing more is a price for never falling off the cliff. At the scale a
BASIC program works at — a 64 KB space, a few thousand pokes — log N is
free.

## And for sparse memory, something more targeted

A trie keyed by *address* rather than an array indexed by page is a
better fit than either:

- No page table to size, so no 64 MB cap and no "address outside the
  space" asymmetry (today a read past the end answers 0 and a write
  crashes — see the cold review's finding 1).
- An untouched address costs nothing at all, where today an unmapped
  page still costs its entry in a 16,384-long table.
- `alloc-bytes` starting at 6 MB stops being a special case worth a
  paragraph of comment.

## What would decide it

Extend `tests/copycheck.sh` with a trie probe and compare three things on
the same 262,144-byte fill: the shipped array, a 32-way persistent trie,
and the array with uniqueness deliberately broken. If the trie lands
within about 3x of the good case, it is worth taking, because the third
column is what we are actually buying.

Nothing here is blocked on it. The array version is correct and fast
today, and the instrument tells us the moment it stops being.
