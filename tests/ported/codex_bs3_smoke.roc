# bs3-smoke
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/bs3-smoke.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     hello
#     hi
#     bye

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# BS3Smoke -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Maybe2(a) : [Just2(a), None2]
Def : { name : List(U8), body : List(U8) }
Thing : { th_name : List(U8), th_body : List(U8) }
Holder : [Plain(Thing)]
Box2(a) : [Box2(a)]

extract_name : Maybe2(Def) -> List(U8)
extract_name = |m| (match m {
	Just2(d) => d.name
	None2 => [18, 16, 18, 13]
})

extract_holder : Holder -> List(U8)
extract_holder = |m| (match m {
	Plain(t) => t.th_name
})

extract_box : Box2(Thing) -> List(U8)
extract_box = |m| (match m {
	Box2(t) => t.th_name
})

eq_Maybe2 : Maybe2(a), Maybe2(a) -> Bool where [a.is_eq : a, a -> Bool]
eq_Maybe2 = |ex, ey| (match ex {
	Just2(exf0) => (match ey {
		Just2(eyf0) => (exf0 == eyf0)
		_ => False
	})
	None2 => (match ey {
		None2 => True
		_ => False
	})
})

eq_Holder : Holder, Holder -> Bool
eq_Holder = |ex, ey| (match ex {
	Plain(exf0) => (match ey {
		Plain(eyf0) => (exf0 == eyf0)
		_ => False
	})
})

eq_Box2 : Box2(a), Box2(a) -> Bool where [a.is_eq : a, a -> Bool]
eq_Box2 = |ex, ey| (match ex {
	Box2(exf0) => (match ey {
		Box2(eyf0) => (exf0 == eyf0)
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(extract_name(Just2({ name: [20, 13, 23, 23, 16], body: [27, 16, 21, 23, 22] }))))
	line!(Text.printed(extract_holder(Plain({ th_name: [20, 17], th_body: [32] }))))
	line!(Text.printed(extract_box(Box2({ th_name: [32, 30, 13], th_body: [24] }))))
	Ok({})
}
