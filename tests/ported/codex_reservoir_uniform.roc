# reservoir-uniform
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/reservoir-uniform.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     counts:      58 40 57 42 49 59 52 41 39 55 58 63 43 54 52 46 56 51 48 37
#     expected ea: 50
#     min:         37
#     max:         63
#     total:       1000
#     all sampled: True
#     within 2x:   True

app [main!] { cdx: "./codex/main.roc" }

import cdx.Reservoir
import cdx.Text

# ReservoirUniformTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

rut_items : I64
rut_items = 20

rut_cap : I64
rut_cap = 5

rut_trials : I64
rut_trials = 200

rut_stream : I64, I64, List(I64) -> List(I64)
rut_stream = |i, n, acc| (if (i >= n) { acc } else { rut_stream((i + 1), n, List.append(acc, i)) })

rut_zeros : I64, I64, List(I64) -> List(I64)
rut_zeros = |i, n, acc| (if (i >= n) { acc } else { rut_zeros((i + 1), n, List.append(acc, 0)) })

rut_tally_one : List(I64), List(I64), I64, I64 -> List(I64)
rut_tally_one = |counts, sample, i, n| (if (i >= n) { counts } else { ({
	v = (List.get(sample, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	rut_tally_one((List.set(counts, I64.to_u64_wrap(v), ((List.get(counts, I64.to_u64_wrap(v)) ?? crash("list-at out of range")) + 1)) ?? crash("list-set-at past the end")), sample, (i + 1), n)
}) })

rut_run : List(I64), List(I64), I64, I64 -> List(I64)
rut_run = |counts, stream, t, n| (if (t >= n) { counts } else { ({
	rs = Reservoir.reservoir_add_all(Reservoir.reservoir_new(rut_cap), stream, ((t * 7919) + 13), 0, rut_items)
	s = Reservoir.reservoir_items(rs)
	rut_run(rut_tally_one(counts, s, 0, U64.to_i64_wrap(List.len(s))), stream, (t + 1), n)
}) })

rut_min : List(I64), I64, I64, I64 -> I64
rut_min = |xs, i, n, acc| (if (i >= n) { acc } else { ({
	v = (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	rut_min(xs, (i + 1), n, (if (v < acc) { v } else { acc }))
}) })

rut_max : List(I64), I64, I64, I64 -> I64
rut_max = |xs, i, n, acc| (if (i >= n) { acc } else { ({
	v = (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	rut_max(xs, (i + 1), n, (if (v > acc) { v } else { acc }))
}) })

rut_sum : List(I64), I64, I64, I64 -> I64
rut_sum = |xs, i, n, acc| (if (i >= n) { acc } else { rut_sum(xs, (i + 1), n, (acc + (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

rut_fmt : List(I64), I64, I64, List(U8) -> List(U8)
rut_fmt = |xs, i, n, acc| (if (i >= n) { acc } else { ({
	sep = (if (i == 0) { [] } else { [2] })
	rut_fmt(xs, (i + 1), n, List.concat(List.concat(acc, sep), Text.show_int((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))
}) })

# --- Entry ---

main! = |_args| {
	stream = rut_stream(0, rut_items, [])
	counts = rut_run(rut_zeros(0, rut_items, []), stream, 0, rut_trials)
	lo = rut_min(counts, 0, rut_items, 999999)
	hi = rut_max(counts, 0, rut_items, 0)
	tot = rut_sum(counts, 0, rut_items, 0)
	line!(Text.printed(List.concat([24, 16, 25, 18, 14, 19, 69, 2, 2, 2, 2, 2, 2], rut_fmt(counts, 0, rut_items, []))))
	line!(Text.printed(List.concat([13, 36, 31, 13, 24, 14, 13, 22, 2, 13, 15, 69, 2], Text.show_int(I64.div_trunc_by((rut_trials * rut_cap), rut_items)))))
	line!(Text.printed(List.concat([26, 17, 18, 69, 2, 2, 2, 2, 2, 2, 2, 2, 2], Text.show_int(lo))))
	line!(Text.printed(List.concat([26, 15, 36, 69, 2, 2, 2, 2, 2, 2, 2, 2, 2], Text.show_int(hi))))
	line!(Text.printed(List.concat([14, 16, 14, 15, 23, 69, 2, 2, 2, 2, 2, 2, 2], Text.show_int(tot))))
	line!(Text.printed(List.concat([15, 23, 23, 2, 19, 15, 26, 31, 23, 13, 22, 69, 2], (if (lo > 0) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
	line!(Text.printed(List.concat([27, 17, 14, 20, 17, 18, 2, 5, 36, 69, 2, 2, 2], (if (hi <= (lo * 2)) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
	Ok({})
}
