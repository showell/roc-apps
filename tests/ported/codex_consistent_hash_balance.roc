# consistent-hash-balance
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/consistent-hash-balance.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     nodes=4
#     entries=64
#     per-node= 40 42 47 71
#     min-share=40
#     max-share=71
#     every-node-used=yes

app [main!] { cdx: "./codex/main.roc" }

import cdx.ConsistentHash

# ConsistentHashBalance -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

ring : ConsistentHash.ConsistentHashRing
ring = build_ring(ConsistentHash.chr_new(16), 0, 4)

build_ring : ConsistentHash.ConsistentHashRing, I64, I64 -> ConsistentHash.ConsistentHashRing
build_ring = |r, i, n| (if (i >= n) { r } else { build_ring(ConsistentHash.chr_add_node(r, i), (i + 1), n) })

count_for : I64, I64, I64, I64 -> I64
count_for = |node, k, n, acc| (if (k >= n) { acc } else { count_for(node, (k + 1), n, (acc + (if (ConsistentHash.chr_get_node(ring, k) == node) { 1 } else { 0 }))) })

tally : I64, I64, Str -> Str
tally = |node, n, acc| (if (node >= n) { acc } else { tally((node + 1), n, Str.concat(Str.concat(acc, " "), I64.to_str(count_for(node, 0, 200, 0)))) })

lowest : I64, I64, I64 -> I64
lowest = |node, n, acc| (if (node >= n) { acc } else { ({
	c = count_for(node, 0, 200, 0)
	lowest((node + 1), n, (if (c < acc) { c } else { acc }))
}) })

highest : I64, I64, I64 -> I64
highest = |node, n, acc| (if (node >= n) { acc } else { ({
	c = count_for(node, 0, 200, 0)
	highest((node + 1), n, (if (c > acc) { c } else { acc }))
}) })

# --- Entry ---

main! = |_args| {
	line!(Str.concat("nodes=", I64.to_str(ConsistentHash.chr_node_count(ring))))
	line!(Str.concat("entries=", I64.to_str(ConsistentHash.chr_entry_count(ring))))
	line!(Str.concat("per-node=", tally(0, 4, "")))
	line!(Str.concat("min-share=", I64.to_str(lowest(0, 4, 1000))))
	line!(Str.concat("max-share=", I64.to_str(highest(0, 4, 0))))
	line!(Str.concat("every-node-used=", (if (lowest(0, 4, 1000) > 0) { "yes" } else { "no" })))
	Ok({})
}
