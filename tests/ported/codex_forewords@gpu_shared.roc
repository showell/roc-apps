# forewords@gpu-shared
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@gpu-shared.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     64

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Shared

# FwdGpuSharedTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	({
		arr = Shared.make_shared_array(0, 64)
		line!(CceText.printed(CceText.show_int(arr.sa_count)))
	})
	Ok({})
}
