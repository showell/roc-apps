# unconstrained-nullary-sum
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/unconstrained-nullary-sum.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     ok
#     ok
#     42
#     text
#     7
#     kept

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# UnconstrainedNullarySum -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Foo(a) : [Bar(a), Baz]

inspect_foo : Foo(a) -> CceText
inspect_foo = |_ignored| "ok"

payload_or : Foo(a), a -> a
payload_or = |value, fallback| (match value {
	Bar(item) => item
	Baz => fallback
})

eq_Foo : Foo(a), Foo(a) -> Bool where [a.is_eq : a, a -> Bool]
eq_Foo = |ex, ey| (match ex {
	Bar(exf0) => (match ey {
		Bar(eyf0) => (exf0 == eyf0)
		_ => False
	})
	Baz => (match ey {
		Baz => True
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(inspect_foo(Baz)))
	line!(CceText.printed(inspect_foo(Bar(1))))
	line!(CceText.printed(CceText.show_int(payload_or(Baz, 42))))
	line!(CceText.printed(payload_or(Baz, "text")))
	line!(CceText.printed(CceText.show_int(payload_or(Bar(7), 0))))
	line!(CceText.printed(payload_or(Bar("kept"), "fallback")))
	Ok({})
}
