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

import cdx.CceText
import cdx.Maybe
import cdx.Pair

# WhenGenericField -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
ProbeOp : [OpScan(CceText), OpFilter(CceText, I64)]

lookup_like : I64 -> Pair.Pair(I64, Maybe.Maybe(ProbeOp))
lookup_like = |k| (if (k == 1) { Pair.make_pair(10, Just(OpScan("emp"))) } else { Pair.make_pair(20, None) })

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
			line!(CceText.printed((match b1 {
				Just(_p) => "b1-hit"
				None => "b1-miss"
			})))
			line!(CceText.printed((match r1.snd {
				Just(_p) => "i1-hit"
				None => "i1-miss"
			})))
			line!(CceText.printed((match b2 {
				Just(_p) => "b2-hit"
				None => "b2-miss"
			})))
			line!(CceText.printed((match r2.snd {
				Just(_p) => "i2-hit"
				None => "i2-miss"
			})))
		})
	})
	Ok({})
}
