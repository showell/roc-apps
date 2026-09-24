# hamt-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/hamt-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     === HAMT (Hash Array Mapped Trie) ===
#     
#     PASS: basic get
#     PASS: overwrite
#     PASS: remove
#     PASS: contains
#     PASS: 100 entries
#     PASS: persistence
#     
#     All PASS = persistent immutable trie with O(log32 n) operations.
#     Zero external dependencies. Compiles to all 12 backends.

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Hamt
import cdx.Maybe

# HamtTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

show_maybe : Maybe.Maybe(I64) -> CceText
show_maybe = |m| (match m {
	Just(v) => CceText.show_int(v)
	None => "None"
})

test_basic : CceText
test_basic = ({
	m0 = Hamt.hamt_empty
	m1 = Hamt.hamt_set(m0, "hello", 42)
	m2 = Hamt.hamt_set(m1, "world", 99)
	m3 = Hamt.hamt_set(m2, "codex", 7)
	r1 : CceText
	r1 = show_maybe(Hamt.hamt_get(m3, "hello"))
	r2 : CceText
	r2 = show_maybe(Hamt.hamt_get(m3, "world"))
	r3 : CceText
	r3 = show_maybe(Hamt.hamt_get(m3, "codex"))
	r4 : CceText
	r4 = show_maybe(Hamt.hamt_get(m3, "missing"))
	CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("get hello=", r1), " world="), r2), " codex="), r3), " missing="), r4)
})

test_overwrite : CceText
test_overwrite = ({
	m = Hamt.hamt_set(Hamt.hamt_set(Hamt.hamt_empty, "k", 1), "k", 2)
	CceText.concat(CceText.concat(CceText.concat("overwrite k=", show_maybe(Hamt.hamt_get(m, "k"))), " size="), CceText.show_int(Hamt.hamt_size(m)))
})

test_remove : CceText
test_remove = ({
	m = Hamt.hamt_set(Hamt.hamt_set(Hamt.hamt_set(Hamt.hamt_empty, "a", 1), "b", 2), "c", 3)
	m2 = Hamt.hamt_remove(m, "b")
	CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("after remove b: a=", show_maybe(Hamt.hamt_get(m2, "a"))), " b="), show_maybe(Hamt.hamt_get(m2, "b"))), " c="), show_maybe(Hamt.hamt_get(m2, "c"))), " size="), CceText.show_int(Hamt.hamt_size(m2)))
})

test_contains : CceText
test_contains = ({
	m = Hamt.hamt_set(Hamt.hamt_set(Hamt.hamt_empty, "x", 10), "y", 20)
	CceText.concat(CceText.concat(CceText.concat("contains x=", (if Hamt.hamt_contains(m, "x") { "True" } else { "False" })), " z="), (if Hamt.hamt_contains(m, "z") { "True" } else { "False" }))
})

test_many : I64, Hamt.HamtMap(I64) -> Hamt.HamtMap(I64)
test_many = |n, m| (if (n == 0) { m } else { test_many((n - 1), Hamt.hamt_set(m, CceText.concat("key-", CceText.show_int(n)), n)) })

test_scale : CceText
test_scale = ({
	m = test_many(100, Hamt.hamt_empty)
	r50 : CceText
	r50 = show_maybe(Hamt.hamt_get(m, "key-50"))
	r1 : CceText
	r1 = show_maybe(Hamt.hamt_get(m, "key-1"))
	r100 : CceText
	r100 = show_maybe(Hamt.hamt_get(m, "key-100"))
	CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("100 entries: key-50=", r50), " key-1="), r1), " key-100="), r100), " size="), CceText.show_int(Hamt.hamt_size(m)))
})

test_persistence : CceText
test_persistence = ({
	m1 = Hamt.hamt_set(Hamt.hamt_set(Hamt.hamt_empty, "a", 1), "b", 2)
	m2 = Hamt.hamt_set(m1, "c", 3)
	m1_has_c : CceText
	m1_has_c = (if Hamt.hamt_contains(m1, "c") { "True" } else { "False" })
	m2_has_c : CceText
	m2_has_c = (if Hamt.hamt_contains(m2, "c") { "True" } else { "False" })
	CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("persistence: m1 has c=", m1_has_c), " m2 has c="), m2_has_c), " m1 size="), CceText.show_int(Hamt.hamt_size(m1))), " m2 size="), CceText.show_int(Hamt.hamt_size(m2)))
})

check : CceText, CceText, CceText -> CceText
check = |name, actual, expected| (if (actual == expected) { CceText.concat("PASS: ", name) } else { CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("FAIL: ", name), " expected ["), expected), "] got ["), actual), "]") })

# --- Entry ---

main! = |_args| {
	line!(CceText.printed("=== HAMT (Hash Array Mapped Trie) ==="))
	line!(CceText.printed(""))
	line!(CceText.printed(check("basic get", test_basic, "get hello=42 world=99 codex=7 missing=None")))
	line!(CceText.printed(check("overwrite", test_overwrite, "overwrite k=2 size=1")))
	line!(CceText.printed(check("remove", test_remove, "after remove b: a=1 b=None c=3 size=2")))
	line!(CceText.printed(check("contains", test_contains, "contains x=True z=False")))
	line!(CceText.printed(check("100 entries", test_scale, "100 entries: key-50=50 key-1=1 key-100=100 size=100")))
	line!(CceText.printed(check("persistence", test_persistence, "persistence: m1 has c=False m2 has c=True m1 size=2 m2 size=3")))
	line!(CceText.printed(""))
	line!(CceText.printed("All PASS = persistent immutable trie with O(log32 n) operations."))
	line!(CceText.printed("Zero external dependencies. Compiles to all 12 backends."))
	Ok({})
}
