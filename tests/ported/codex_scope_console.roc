# scope-console
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/scope-console.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     console scope holds
#     a bare Console grant still covers Console.Write

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# ScopeConsole -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

say! : List(U8) => {}
say! = |m| line!(Text.printed(m))

wide! : List(U8) => {}
wide! = |m| line!(Text.printed(m))

# --- Entry ---

main! = |_args| {
	say!([24, 16, 18, 19, 16, 23, 13, 2, 19, 24, 16, 31, 13, 2, 20, 16, 23, 22, 19])
	wide!([15, 2, 32, 15, 21, 13, 2, 50, 16, 18, 19, 16, 23, 13, 2, 29, 21, 15, 18, 14, 2, 19, 14, 17, 23, 23, 2, 24, 16, 33, 13, 21, 19, 2, 50, 16, 18, 19, 16, 23, 13, 65, 53, 21, 17, 14, 13])
	Ok({})
}
