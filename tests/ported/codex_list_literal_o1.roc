# list-literal-o1
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/list-literal-o1.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     flat-len=5 ends=6 alloc=e1e2e3 nested=5 nested-len=3 mixed=15
#     0

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# ListO1Probe -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

tag : I64 -> List(U8)
tag = |n| List.concat([13], Text.show_int(n))

flat : List(I64)
flat = [1, 2, 3, 4, 5]

nested : List(List(I64))
nested = [[1, 2], [3, 4, 5], [6]]

report : I64 -> List(U8)
report = |_x| ({
	alloc = [tag(1), tag(2), tag(3)]
	mixed = [U64.to_i64_wrap(List.len(flat)), U64.to_i64_wrap(List.len((List.get(nested, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))), 7]
	List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([28, 23, 15, 14, 73, 23, 13, 18, 77], Text.show_int(U64.to_i64_wrap(List.len(flat)))), [2, 13, 18, 22, 19, 77]), Text.show_int(((List.get(flat, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) + (List.get(flat, I64.to_u64_wrap(4)) ?? crash("list-at out of range"))))), [2, 15, 23, 23, 16, 24, 77]), (List.get(alloc, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))), (List.get(alloc, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))), (List.get(alloc, I64.to_u64_wrap(2)) ?? crash("list-at out of range"))), [2, 18, 13, 19, 14, 13, 22, 77]), Text.show_int((List.get((List.get(nested, I64.to_u64_wrap(1)) ?? crash("list-at out of range")), I64.to_u64_wrap(2)) ?? crash("list-at out of range")))), [2, 18, 13, 19, 14, 13, 22, 73, 23, 13, 18, 77]), Text.show_int(U64.to_i64_wrap(List.len(nested)))), [2, 26, 17, 36, 13, 22, 77]), Text.show_int((((List.get(mixed, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) + (List.get(mixed, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))) + (List.get(mixed, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))))
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(report(0)))
	line!(I64.to_str(0))
	Ok({})
}
