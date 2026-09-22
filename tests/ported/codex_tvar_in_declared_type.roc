# tvar-in-declared-type
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/tvar-in-declared-type.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     73

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# ProbeTvarInDeclared -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Pair(a) : { fst : a, snd : a }

pair_swap : Pair(a) -> Pair(a)
pair_swap = |p| { fst: p.snd, snd: p.fst }

# --- Entry ---

main! = |_args| {
	({
		q = pair_swap({ fst: 3, snd: 7 })
		line!(Text.printed(Text.show_int(((q.fst * 10) + q.snd))))
	})
	Ok({})
}
