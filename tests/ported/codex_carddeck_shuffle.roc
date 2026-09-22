# carddeck-shuffle
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/carddeck-shuffle.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     counts:        39 30 32 31 28 39 26 31
#     min:           26
#     max:           39
#     every pos hit: True
#     within 3x:     True
#     alternations:  127
#     not a stripe:  True

app [main!] { cdx: "./codex/main.roc" }

import cdx.CardDeck
import cdx.Text

# CardDeckShuffleTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

cdt_fresh : I64, I64, List(I64) -> List(I64)
cdt_fresh = |i, n, acc| (if (i >= n) { acc } else { cdt_fresh((i + 1), n, List.append(acc, i)) })

cdt_pos_of : List(I64), I64, I64, I64 -> I64
cdt_pos_of = |xs, v, i, n| (if (i >= n) { (0 - 1) } else { (if ((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) == v) { i } else { cdt_pos_of(xs, v, (i + 1), n) }) })

cdt_zeros : I64, I64, List(I64) -> List(I64)
cdt_zeros = |i, n, acc| (if (i >= n) { acc } else { cdt_zeros((i + 1), n, List.append(acc, 0)) })

cdt_tally : I64, I64, List(I64) -> List(I64)
cdt_tally = |seed, trials, counts| (if (seed >= trials) { counts } else { ({
	deck = cdt_fresh(0, 8, [])
	shuffled = CardDeck.deck_shuffle(deck, seed)
	p = cdt_pos_of(shuffled, 0, 0, 8)
	(if (p < 0) { cdt_tally((seed + 1), trials, counts) } else { cdt_tally((seed + 1), trials, (List.set(counts, I64.to_u64_wrap(p), ((List.get(counts, I64.to_u64_wrap(p)) ?? crash("list-at out of range")) + 1)) ?? crash("list-set-at past the end"))) })
}) })

cdt_min : List(I64), I64, I64, I64 -> I64
cdt_min = |xs, i, n, acc| (if (i >= n) { acc } else { ({
	v = (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	cdt_min(xs, (i + 1), n, (if (v < acc) { v } else { acc }))
}) })

cdt_max : List(I64), I64, I64, I64 -> I64
cdt_max = |xs, i, n, acc| (if (i >= n) { acc } else { ({
	v = (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	cdt_max(xs, (i + 1), n, (if (v > acc) { v } else { acc }))
}) })

cdt_fmt : List(I64), I64, I64, List(U8) -> List(U8)
cdt_fmt = |xs, i, n, acc| (if (i >= n) { acc } else { ({
	sep = (if (i == 0) { [] } else { [2] })
	cdt_fmt(xs, (i + 1), n, List.concat(List.concat(acc, sep), Text.show_int((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))
}) })

cdt_two : I64 -> I64
cdt_two = |seed| ({
	deck = cdt_fresh(0, 2, [])
	shuffled = CardDeck.deck_shuffle(deck, seed)
	(List.get(shuffled, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
})

cdt_alt : I64, I64, I64 -> I64
cdt_alt = |seed, trials, acc| (if (seed >= trials) { acc } else { ({
	a = cdt_two(seed)
	b = cdt_two((seed - 1))
	cdt_alt((seed + 1), trials, (acc + (if (a == b) { 0 } else { 1 })))
}) })

# --- Entry ---

main! = |_args| {
	counts = cdt_tally(0, 256, cdt_zeros(0, 8, []))
	lo = cdt_min(counts, 0, 8, 999999)
	hi = cdt_max(counts, 0, 8, 0)
	alt = cdt_alt(1, 256, 0)
	line!(Text.printed(List.concat([24, 16, 25, 18, 14, 19, 69, 2, 2, 2, 2, 2, 2, 2, 2], cdt_fmt(counts, 0, 8, []))))
	line!(Text.printed(List.concat([26, 17, 18, 69, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2], Text.show_int(lo))))
	line!(Text.printed(List.concat([26, 15, 36, 69, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2], Text.show_int(hi))))
	line!(Text.printed(List.concat([13, 33, 13, 21, 30, 2, 31, 16, 19, 2, 20, 17, 14, 69, 2], (if (lo > 0) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
	line!(Text.printed(List.concat([27, 17, 14, 20, 17, 18, 2, 6, 36, 69, 2, 2, 2, 2, 2], (if (hi <= (lo * 3)) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
	line!(Text.printed(List.concat([15, 23, 14, 13, 21, 18, 15, 14, 17, 16, 18, 19, 69, 2, 2], Text.show_int(alt))))
	line!(Text.printed(List.concat([18, 16, 14, 2, 15, 2, 19, 14, 21, 17, 31, 13, 69, 2, 2], (if (alt < 200) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
	Ok({})
}
