# match-in-record-field
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/match-in-record-field.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     field-match 1

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.KvStore
import cdx.Maybe

# MatchInRecordField -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Pair := { p_a : I64, p_b : I64 }.{
	is_eq : Pair, Pair -> Bool
	is_eq = |a, b| eq_Pair(a, b)
}

field_match : KvStore.KvStore, Maybe.Maybe(CceText) -> Pair
field_match = |s, m| Pair.{ p_a: 7, p_b: (match m {
	Just(_v) => s.kv_count
	None => (s.kv_count + 1)
}) }

eq_Pair : Pair, Pair -> Bool
eq_Pair = |ex, ey| ((ex.p_a == ey.p_a) and (ex.p_b == ey.p_b))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("field-match ", CceText.show_int(field_match(KvStore.kv_empty, None).p_b))))
	Ok({})
}
