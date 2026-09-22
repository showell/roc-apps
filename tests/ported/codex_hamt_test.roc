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

import cdx.Hamt
import cdx.Maybe
import cdx.Text

# HamtTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

show_maybe : Maybe.Maybe(I64) -> List(U8)
show_maybe = |m| (match m {
	Just(v) => Text.show_int(v)
	None => [44, 16, 18, 13]
})

test_basic : List(U8)
test_basic = ({
	m0 = Hamt.hamt_empty
	m1 = Hamt.hamt_set(m0, [20, 13, 23, 23, 16], 42)
	m2 = Hamt.hamt_set(m1, [27, 16, 21, 23, 22], 99)
	m3 = Hamt.hamt_set(m2, [24, 16, 22, 13, 36], 7)
	r1 = show_maybe(Hamt.hamt_get(m3, [20, 13, 23, 23, 16]))
	r2 = show_maybe(Hamt.hamt_get(m3, [27, 16, 21, 23, 22]))
	r3 = show_maybe(Hamt.hamt_get(m3, [24, 16, 22, 13, 36]))
	r4 = show_maybe(Hamt.hamt_get(m3, [26, 17, 19, 19, 17, 18, 29]))
	List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([29, 13, 14, 2, 20, 13, 23, 23, 16, 77], r1), [2, 27, 16, 21, 23, 22, 77]), r2), [2, 24, 16, 22, 13, 36, 77]), r3), [2, 26, 17, 19, 19, 17, 18, 29, 77]), r4)
})

test_overwrite : List(U8)
test_overwrite = ({
	m = Hamt.hamt_set(Hamt.hamt_set(Hamt.hamt_empty, [34], 1), [34], 2)
	List.concat(List.concat(List.concat([16, 33, 13, 21, 27, 21, 17, 14, 13, 2, 34, 77], show_maybe(Hamt.hamt_get(m, [34]))), [2, 19, 17, 38, 13, 77]), Text.show_int(Hamt.hamt_size(m)))
})

test_remove : List(U8)
test_remove = ({
	m = Hamt.hamt_set(Hamt.hamt_set(Hamt.hamt_set(Hamt.hamt_empty, [15], 1), [32], 2), [24], 3)
	m2 = Hamt.hamt_remove(m, [32])
	List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([15, 28, 14, 13, 21, 2, 21, 13, 26, 16, 33, 13, 2, 32, 69, 2, 15, 77], show_maybe(Hamt.hamt_get(m2, [15]))), [2, 32, 77]), show_maybe(Hamt.hamt_get(m2, [32]))), [2, 24, 77]), show_maybe(Hamt.hamt_get(m2, [24]))), [2, 19, 17, 38, 13, 77]), Text.show_int(Hamt.hamt_size(m2)))
})

test_contains : List(U8)
test_contains = ({
	m = Hamt.hamt_set(Hamt.hamt_set(Hamt.hamt_empty, [36], 10), [30], 20)
	List.concat(List.concat(List.concat([24, 16, 18, 14, 15, 17, 18, 19, 2, 36, 77], (if Hamt.hamt_contains(m, [36]) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] })), [2, 38, 77]), (if Hamt.hamt_contains(m, [38]) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))
})

test_many : I64, Hamt.HamtMap(I64) -> Hamt.HamtMap(I64)
test_many = |n, m| (if (n == 0) { m } else { test_many((n - 1), Hamt.hamt_set(m, List.concat([34, 13, 30, 73], Text.show_int(n)), n)) })

test_scale : List(U8)
test_scale = ({
	m = test_many(100, Hamt.hamt_empty)
	r50 = show_maybe(Hamt.hamt_get(m, [34, 13, 30, 73, 8, 3]))
	r1 = show_maybe(Hamt.hamt_get(m, [34, 13, 30, 73, 4]))
	r100 = show_maybe(Hamt.hamt_get(m, [34, 13, 30, 73, 4, 3, 3]))
	List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([4, 3, 3, 2, 13, 18, 14, 21, 17, 13, 19, 69, 2, 34, 13, 30, 73, 8, 3, 77], r50), [2, 34, 13, 30, 73, 4, 77]), r1), [2, 34, 13, 30, 73, 4, 3, 3, 77]), r100), [2, 19, 17, 38, 13, 77]), Text.show_int(Hamt.hamt_size(m)))
})

test_persistence : List(U8)
test_persistence = ({
	m1 = Hamt.hamt_set(Hamt.hamt_set(Hamt.hamt_empty, [15], 1), [32], 2)
	m2 = Hamt.hamt_set(m1, [24], 3)
	m1_has_c = (if Hamt.hamt_contains(m1, [24]) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] })
	m2_has_c = (if Hamt.hamt_contains(m2, [24]) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] })
	List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([31, 13, 21, 19, 17, 19, 14, 13, 18, 24, 13, 69, 2, 26, 4, 2, 20, 15, 19, 2, 24, 77], m1_has_c), [2, 26, 5, 2, 20, 15, 19, 2, 24, 77]), m2_has_c), [2, 26, 4, 2, 19, 17, 38, 13, 77]), Text.show_int(Hamt.hamt_size(m1))), [2, 26, 5, 2, 19, 17, 38, 13, 77]), Text.show_int(Hamt.hamt_size(m2)))
})

check : List(U8), List(U8), List(U8) -> List(U8)
check = |name, actual, expected| (if (actual == expected) { List.concat([57, 41, 45, 45, 69, 2], name) } else { List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([54, 41, 43, 49, 69, 2], name), [2, 13, 36, 31, 13, 24, 14, 13, 22, 2, 88]), expected), [89, 2, 29, 16, 14, 2, 88]), actual), [89]) })

# --- Entry ---

main! = |_args| {
	line!(Text.printed([77, 77, 77, 2, 46, 41, 52, 40, 2, 74, 46, 15, 19, 20, 2, 41, 21, 21, 15, 30, 2, 52, 15, 31, 31, 13, 22, 2, 40, 21, 17, 13, 75, 2, 77, 77, 77]))
	line!(Text.printed([]))
	line!(Text.printed(check([32, 15, 19, 17, 24, 2, 29, 13, 14], test_basic, [29, 13, 14, 2, 20, 13, 23, 23, 16, 77, 7, 5, 2, 27, 16, 21, 23, 22, 77, 12, 12, 2, 24, 16, 22, 13, 36, 77, 10, 2, 26, 17, 19, 19, 17, 18, 29, 77, 44, 16, 18, 13])))
	line!(Text.printed(check([16, 33, 13, 21, 27, 21, 17, 14, 13], test_overwrite, [16, 33, 13, 21, 27, 21, 17, 14, 13, 2, 34, 77, 5, 2, 19, 17, 38, 13, 77, 4])))
	line!(Text.printed(check([21, 13, 26, 16, 33, 13], test_remove, [15, 28, 14, 13, 21, 2, 21, 13, 26, 16, 33, 13, 2, 32, 69, 2, 15, 77, 4, 2, 32, 77, 44, 16, 18, 13, 2, 24, 77, 6, 2, 19, 17, 38, 13, 77, 5])))
	line!(Text.printed(check([24, 16, 18, 14, 15, 17, 18, 19], test_contains, [24, 16, 18, 14, 15, 17, 18, 19, 2, 36, 77, 40, 21, 25, 13, 2, 38, 77, 54, 15, 23, 19, 13])))
	line!(Text.printed(check([4, 3, 3, 2, 13, 18, 14, 21, 17, 13, 19], test_scale, [4, 3, 3, 2, 13, 18, 14, 21, 17, 13, 19, 69, 2, 34, 13, 30, 73, 8, 3, 77, 8, 3, 2, 34, 13, 30, 73, 4, 77, 4, 2, 34, 13, 30, 73, 4, 3, 3, 77, 4, 3, 3, 2, 19, 17, 38, 13, 77, 4, 3, 3])))
	line!(Text.printed(check([31, 13, 21, 19, 17, 19, 14, 13, 18, 24, 13], test_persistence, [31, 13, 21, 19, 17, 19, 14, 13, 18, 24, 13, 69, 2, 26, 4, 2, 20, 15, 19, 2, 24, 77, 54, 15, 23, 19, 13, 2, 26, 5, 2, 20, 15, 19, 2, 24, 77, 40, 21, 25, 13, 2, 26, 4, 2, 19, 17, 38, 13, 77, 5, 2, 26, 5, 2, 19, 17, 38, 13, 77, 6])))
	line!(Text.printed([]))
	line!(Text.printed([41, 23, 23, 2, 57, 41, 45, 45, 2, 77, 2, 31, 13, 21, 19, 17, 19, 14, 13, 18, 14, 2, 17, 26, 26, 25, 14, 15, 32, 23, 13, 2, 14, 21, 17, 13, 2, 27, 17, 14, 20, 2, 42, 74, 23, 16, 29, 6, 5, 2, 18, 75, 2, 16, 31, 13, 21, 15, 14, 17, 16, 18, 19, 65]))
	line!(Text.printed([64, 13, 21, 16, 2, 13, 36, 14, 13, 21, 18, 15, 23, 2, 22, 13, 31, 13, 18, 22, 13, 18, 24, 17, 13, 19, 65, 2, 50, 16, 26, 31, 17, 23, 13, 19, 2, 14, 16, 2, 15, 23, 23, 2, 4, 5, 2, 32, 15, 24, 34, 13, 18, 22, 19, 65]))
	Ok({})
}
