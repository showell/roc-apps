# forewords@gpu-atomic
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@gpu-atomic.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     Gpu/Atomic OK

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# FwdGpuAtomicTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	(match Relaxed {
		Relaxed => line!(Text.printed([55, 31, 25, 81, 41, 14, 16, 26, 17, 24, 2, 42, 60]))
		_ => line!(Text.printed([28, 15, 17, 23]))
	})
	Ok({})
}
