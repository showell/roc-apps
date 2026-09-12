# bloom-spread
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/bloom-spread.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     fp-int-1024=5
#     fp-int-1021=5
#     fill-pct-1024=31
#     fill-pct-1021=31
#     fp-text-1024=7
#     fp-text-1021=2

app [main!] { cdx: "./codex/main.roc" }

import cdx.BloomFilter

# BloomSpread -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

fill_int : BloomFilter.BloomFilter, I64, I64 -> BloomFilter.BloomFilter
fill_int = |bf, i, n| (if (i >= n) { bf } else { fill_int(BloomFilter.bloom_add(bf, (i * 7919)), (i + 1), n) })

fp_int : BloomFilter.BloomFilter, I64, I64, I64 -> I64
fp_int = |bf, i, n, acc| (if (i >= n) { acc } else { fp_int(bf, (i + 1), n, (acc + (if BloomFilter.bloom_contains(bf, (1000000 + (i * 7919))) { 1 } else { 0 }))) })

run_int : I64 -> I64
run_int = |m| fp_int(fill_int(BloomFilter.bloom_new(m, 4), 0, 100), 0, 500, 0)

fill_pct : I64 -> I64
fill_pct = |m| BloomFilter.bloom_false_positive_rate(fill_int(BloomFilter.bloom_new(m, 4), 0, 100))

fill_text : BloomFilter.BloomFilter, I64, I64 -> BloomFilter.BloomFilter
fill_text = |bf, i, n| (if (i >= n) { bf } else { fill_text(BloomFilter.bloom_add_text(bf, I64.to_str((i * 7919))), (i + 1), n) })

fp_text : BloomFilter.BloomFilter, I64, I64, I64 -> I64
fp_text = |bf, i, n, acc| (if (i >= n) { acc } else { fp_text(bf, (i + 1), n, (acc + (if BloomFilter.bloom_contains_text(bf, I64.to_str((1000000 + (i * 7919)))) { 1 } else { 0 }))) })

run_text : I64 -> I64
run_text = |m| fp_text(fill_text(BloomFilter.bloom_new(m, 4), 0, 100), 0, 500, 0)

# --- Entry ---

main! = |_args| {
	line!(Str.concat("fp-int-1024=", I64.to_str(run_int(1024))))
	line!(Str.concat("fp-int-1021=", I64.to_str(run_int(1021))))
	line!(Str.concat("fill-pct-1024=", I64.to_str(fill_pct(1024))))
	line!(Str.concat("fill-pct-1021=", I64.to_str(fill_pct(1021))))
	line!(Str.concat("fp-text-1024=", I64.to_str(run_text(1024))))
	line!(Str.concat("fp-text-1021=", I64.to_str(run_text(1021))))
	Ok({})
}
