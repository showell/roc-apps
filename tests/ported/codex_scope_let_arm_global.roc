# scope-let-arm-global
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/scope-let-arm-global.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     arm-scoped: GLOBAL

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# ScopeLetArmGlobal -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

inner : List(U8)
inner = [55, 49, 42, 58, 41, 49]

arm_scoped : I64 -> List(U8)
arm_scoped = |n| ({
	_w = (if (n > 0) { ({
		inner_1 = (n * 10)
		(inner_1 + 1)
	}) } else { 0 })
	inner
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([15, 21, 26, 73, 19, 24, 16, 31, 13, 22, 69, 2], arm_scoped(2))))
	Ok({})
}
