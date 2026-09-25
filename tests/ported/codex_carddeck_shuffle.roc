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
import cdx.CceText

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
	deck : List(I64)
	deck = cdt_fresh(0, 8, [])
	deck_shuffle_v1 : List(I64)
	deck_shuffle_v1 = CardDeck.deck_shuffle(deck, seed)
	shuffled : List(I64)
	shuffled = deck_shuffle_v1
	p : I64
	p = cdt_pos_of(shuffled, 0, 0, 8)
	(if (p < 0) { cdt_tally((seed + 1), trials, counts) } else { ({
		counts_v2 : List(I64)
		counts_v2 = (List.set(counts, I64.to_u64_wrap(p), ((List.get(counts, I64.to_u64_wrap(p)) ?? crash("list-at out of range")) + 1)) ?? crash("list-set-at past the end"))
		cdt_tally((seed + 1), trials, counts_v2)
	}) })
}) })

cdt_min : List(I64), I64, I64, I64 -> I64
cdt_min = |xs, i, n, acc| (if (i >= n) { acc } else { ({
	v : I64
	v = (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	cdt_min(xs, (i + 1), n, (if (v < acc) { v } else { acc }))
}) })

cdt_max : List(I64), I64, I64, I64 -> I64
cdt_max = |xs, i, n, acc| (if (i >= n) { acc } else { ({
	v : I64
	v = (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	cdt_max(xs, (i + 1), n, (if (v > acc) { v } else { acc }))
}) })

cdt_fmt : List(I64), I64, I64, CceText -> CceText
cdt_fmt = |xs, i, n, acc| (if (i >= n) { acc } else { ({
	sep : CceText
	sep = (if (i == 0) { "" } else { " " })
	cdt_fmt(xs, (i + 1), n, CceText.concat(CceText.concat(acc, sep), CceText.show_int((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))
}) })

cdt_two : I64 -> I64
cdt_two = |seed| ({
	deck : List(I64)
	deck = cdt_fresh(0, 2, [])
	deck_shuffle_v1 : List(I64)
	deck_shuffle_v1 = CardDeck.deck_shuffle(deck, seed)
	shuffled : List(I64)
	shuffled = deck_shuffle_v1
	(List.get(shuffled, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
})

cdt_alt : I64, I64, I64 -> I64
cdt_alt = |seed, trials, acc| (if (seed >= trials) { acc } else { ({
	a : I64
	a = cdt_two(seed)
	b : I64
	b = cdt_two((seed - 1))
	cdt_alt((seed + 1), trials, (acc + (if (a == b) { 0 } else { 1 })))
}) })

# --- Entry ---

main! = |_args| {
	cdt_tally_v1 = cdt_tally(0, 256, cdt_zeros(0, 8, []))
	counts = cdt_tally_v1
	lo = cdt_min(counts, 0, 8, 999999)
	hi = cdt_max(counts, 0, 8, 0)
	alt = cdt_alt(1, 256, 0)
	line!(CceText.printed(CceText.concat("counts:        ", cdt_fmt(counts, 0, 8, ""))))
	line!(CceText.printed(CceText.concat("min:           ", CceText.show_int(lo))))
	line!(CceText.printed(CceText.concat("max:           ", CceText.show_int(hi))))
	line!(CceText.printed(CceText.concat("every pos hit: ", (if (lo > 0) { "True" } else { "False" }))))
	line!(CceText.printed(CceText.concat("within 3x:     ", (if (hi <= (lo * 3)) { "True" } else { "False" }))))
	line!(CceText.printed(CceText.concat("alternations:  ", CceText.show_int(alt))))
	line!(CceText.printed(CceText.concat("not a stripe:  ", (if (alt < 200) { "True" } else { "False" }))))
	Ok({})
}
