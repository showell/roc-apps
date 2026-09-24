# linear-smoke
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/linear-smoke.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     42 21 56

app [main!] { cdx: "./codex/main.roc" }

import cdx.Linear
import cdx.Text

# LinearSmoke -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

consume : I64 -> I64
consume = |n| (n * 2)

use_once : I64
use_once = consume(21)

finalize : I64 -> I64
finalize = |n| Linear.freeze(n)

shadow_test : I64 -> I64
shadow_test = |n| ({
	base = (n + 1)
	n_1 = 7
	((base + n_1) + n_1)
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat(Text.concat(Text.concat(Text.concat(Text.show_int(use_once), " "), Text.show_int(finalize(21))), " "), Text.show_int(shadow_test(41)))))
	Ok({})
}
