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

import cdx.Sha256
import cdx.Text

# TextAppendAlias -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

str_bytes_loop : Text, I64, I64, List(I64) -> List(I64)
str_bytes_loop = |s, i, n, acc| (if (i >= n) { acc } else { str_bytes_loop(s, (i + 1), n, List.append(acc, Text.char_at(s, i))) })

digest : Text -> Text
digest = |t| Sha256.sha256_to_hex(Sha256.sha256(str_bytes_loop(t, 0, Text.len(t), [])))

# --- Entry ---

main! = |_args| {
	({
		a = digest("x")
		_b = Text.concat(a, "Z")
		line!(Text.printed((if (Text.len(a) == 64) { "PASS" } else { Text.concat("FAIL len=", Text.show_int(Text.len(a))) })))
	})
	Ok({})
}
