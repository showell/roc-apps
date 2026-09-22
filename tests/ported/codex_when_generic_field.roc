# when-generic-field
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/when-generic-field.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     b1-hit
#     i1-hit
#     b2-miss
#     i2-miss

app [main!] { cdx: "./codex/main.roc" }

import cdx.Maybe
import cdx.Pair
import cdx.Text

# WhenGenericField -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
ProbeOp : [OpScan(List(U8)), OpFilter(List(U8), I64)]

lookup_like : I64 -> Pair.Pair(I64, Maybe.Maybe(ProbeOp))
lookup_like = |k| (if (k == 1) { Pair.make_pair(10, Just(OpScan([13, 26, 31]))) } else { Pair.make_pair(20, None) })

eq_ProbeOp : ProbeOp, ProbeOp -> Bool
eq_ProbeOp = |ex, ey| (match ex {
	OpScan(exf0) => (match ey {
		OpScan(eyf0) => (exf0 == eyf0)
		_ => False
	})
	OpFilter(exf0, exf1) => (match ey {
		OpFilter(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	({
		r1 = lookup_like(1)
		b1 = r1.snd
		r2 = lookup_like(2)
		b2 = r2.snd
		({
			line!(Text.printed((match b1 {
				Just(_p) => [32, 4, 73, 20, 17, 14]
				None => [32, 4, 73, 26, 17, 19, 19]
			})))
			line!(Text.printed((match r1.snd {
				Just(_p) => [17, 4, 73, 20, 17, 14]
				None => [17, 4, 73, 26, 17, 19, 19]
			})))
			line!(Text.printed((match b2 {
				Just(_p) => [32, 5, 73, 20, 17, 14]
				None => [32, 5, 73, 26, 17, 19, 19]
			})))
			line!(Text.printed((match r2.snd {
				Just(_p) => [17, 5, 73, 20, 17, 14]
				None => [17, 5, 73, 26, 17, 19, 19]
			})))
		})
	})
	Ok({})
}
