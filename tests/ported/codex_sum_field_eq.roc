# sum-field-eq
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/sum-field-eq.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     eq
#     ne
#     eq
#     ne
#     eq
#     ne
#     ne
#     ne
#     ne

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# SumFieldEq -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Held : [Empty, Hold(List(U8))]
Quad : [Quad(I64, I64, I64, I64)]

eq_Held : Held, Held -> Bool
eq_Held = |ex, ey| (match ex {
	Empty => (match ey {
		Empty => True
		_ => False
	})
	Hold(exf0) => (match ey {
		Hold(eyf0) => (exf0 == eyf0)
		_ => False
	})
})

eq_Quad : Quad, Quad -> Bool
eq_Quad = |ex, ey| (match ex {
	Quad(exf0, exf1, exf2, exf3) => (match ey {
		Quad(eyf0, eyf1, eyf2, eyf3) => ((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3))
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed((if eq_Held(Hold(List.concat([20], [17])), Hold([20, 17])) { [13, 37] } else { [18, 13] })))
	line!(Text.printed((if eq_Held(Hold([20, 17]), Hold([18, 16])) { [13, 37] } else { [18, 13] })))
	line!(Text.printed((if eq_Held(Empty, Empty) { [13, 37] } else { [18, 13] })))
	line!(Text.printed((if eq_Held(Empty, Hold([20, 17])) { [13, 37] } else { [18, 13] })))
	line!(Text.printed((if eq_Quad(Quad(1, 2, 3, 4), Quad(1, 2, 3, 4)) { [13, 37] } else { [18, 13] })))
	line!(Text.printed((if eq_Quad(Quad(9, 2, 3, 4), Quad(1, 2, 3, 4)) { [13, 37] } else { [18, 13] })))
	line!(Text.printed((if eq_Quad(Quad(1, 9, 3, 4), Quad(1, 2, 3, 4)) { [13, 37] } else { [18, 13] })))
	line!(Text.printed((if eq_Quad(Quad(1, 2, 9, 4), Quad(1, 2, 3, 4)) { [13, 37] } else { [18, 13] })))
	line!(Text.printed((if eq_Quad(Quad(1, 2, 3, 9), Quad(1, 2, 3, 4)) { [13, 37] } else { [18, 13] })))
	Ok({})
}
