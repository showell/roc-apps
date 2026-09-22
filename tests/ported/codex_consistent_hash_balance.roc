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
import cdx.Text

# ConsistentHashBalance -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

ring : ConsistentHash.ConsistentHashRing
ring = build_ring(ConsistentHash.chr_new(16), 0, 4)

build_ring : ConsistentHash.ConsistentHashRing, I64, I64 -> ConsistentHash.ConsistentHashRing
build_ring = |r, i, n| (if (i >= n) { r } else { build_ring(ConsistentHash.chr_add_node(r, i), (i + 1), n) })

count_for : I64, I64, I64, I64 -> I64
count_for = |node, k, n, acc| (if (k >= n) { acc } else { count_for(node, (k + 1), n, (acc + (if (ConsistentHash.chr_get_node(ring, k) == node) { 1 } else { 0 }))) })

tally : I64, I64, List(U8) -> List(U8)
tally = |node, n, acc| (if (node >= n) { acc } else { tally((node + 1), n, List.concat(List.concat(acc, [2]), Text.show_int(count_for(node, 0, 200, 0)))) })

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
	line!(Text.printed(List.concat([18, 16, 22, 13, 19, 77], Text.show_int(ConsistentHash.chr_node_count(ring)))))
	line!(Text.printed(List.concat([13, 18, 14, 21, 17, 13, 19, 77], Text.show_int(ConsistentHash.chr_entry_count(ring)))))
	line!(Text.printed(List.concat([31, 13, 21, 73, 18, 16, 22, 13, 77], tally(0, 4, []))))
	line!(Text.printed(List.concat([26, 17, 18, 73, 19, 20, 15, 21, 13, 77], Text.show_int(lowest(0, 4, 1000)))))
	line!(Text.printed(List.concat([26, 15, 36, 73, 19, 20, 15, 21, 13, 77], Text.show_int(highest(0, 4, 0)))))
	line!(Text.printed(List.concat([13, 33, 13, 21, 30, 73, 18, 16, 22, 13, 73, 25, 19, 13, 22, 77], (if (lowest(0, 4, 1000) > 0) { [30, 13, 19] } else { [18, 16] }))))
	Ok({})
}
