# mut-borrow-transitive
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/mut-borrow-transitive.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     24

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# MutBorrowTransitive -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
ScanState : { pos : I64 }
Trivia : { origin : ScanState }
TokenLike : { kind : I64, trivia : List(Trivia) }

snapshot : ScanState, I64 -> TokenLike
snapshot = |s, n| { kind: (s.pos + n), trivia: [] }

scan_twice : ScanState -> I64
scan_twice = |m| ({
	t1 = snapshot(m, 1)
	t2 = snapshot(m, 2)
	((t1.kind + t2.kind) + m.pos)
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.show_int(scan_twice({ pos: 7 }))))
	Ok({})
}
