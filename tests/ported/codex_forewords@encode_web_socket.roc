# forewords@encode-web-socket
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@encode-web-socket.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     Encode/WebSocket OK

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# FwdWebSocketTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed([39, 18, 24, 16, 22, 13, 81, 53, 13, 32, 45, 16, 24, 34, 13, 14, 2, 42, 60]))
	Ok({})
}
