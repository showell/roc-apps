# text-append-alias
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/text-append-alias.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     PASS

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceChar
import cdx.CceText
import cdx.Sha256

# TextAppendAlias -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

str_bytes_loop : CceText, I64, I64, List(I64) -> List(I64)
str_bytes_loop = |s, i, n, acc| (if (i >= n) { acc } else { str_bytes_loop(s, (i + 1), n, List.append(acc, CceChar.code(CceText.char_at(s, i)))) })

digest : CceText -> CceText
digest = |t| Sha256.sha256_to_hex(Sha256.sha256(str_bytes_loop(t, 0, CceText.len(t), [])))

# --- Entry ---

main! = |_args| {
	({
		a = digest("x")
		_b = CceText.concat(a, "Z")
		line!(CceText.printed((if (CceText.len(a) == 64) { "PASS" } else { CceText.concat("FAIL len=", CceText.show_int(CceText.len(a))) })))
	})
	Ok({})
}
