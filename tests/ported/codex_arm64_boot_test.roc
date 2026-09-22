# arm64-boot-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/arm64-boot-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     Codex ARM64 boot OK
#     hello world

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# Arm64BootTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed([50, 16, 22, 13, 36, 2, 41, 47, 52, 9, 7, 2, 32, 16, 16, 14, 2, 42, 60]))
	line!(Text.printed(List.concat([20, 13, 23, 23, 16, 2], [27, 16, 21, 23, 22])))
	Ok({})
}
