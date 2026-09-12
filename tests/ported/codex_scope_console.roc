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

app [main!] {}

# ScopeConsole -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

say : Str => {}
say = |m| line!(m)

wide : Str => {}
wide = |m| line!(m)

# --- Entry ---

main! = |_args| {
	say("console scope holds")
	wide("a bare Console grant still covers Console.Write")
	Ok({})
}
