# list-tail-empty
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/list-tail-empty.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     empty-len 0
#     three-len 2
#     three-first 2
#     three-last 3
#     one-len 0

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.ListUtils

# ListTailEmpty -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

no_ints : List(I64)
no_ints = []

# --- Entry ---

main! = |_args| {
	({
		empty = ListUtils.list_tail(no_ints)
		three = ListUtils.list_tail([1, 2, 3])
		one = ListUtils.list_tail([7])
		({
			line!(CceText.printed(CceText.concat("empty-len ", CceText.show_int(U64.to_i64_wrap(List.len(empty))))))
			line!(CceText.printed(CceText.concat("three-len ", CceText.show_int(U64.to_i64_wrap(List.len(three))))))
			line!(CceText.printed(CceText.concat("three-first ", CceText.show_int((List.get(three, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))))))
			line!(CceText.printed(CceText.concat("three-last ", CceText.show_int((List.get(three, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))))))
			line!(CceText.printed(CceText.concat("one-len ", CceText.show_int(U64.to_i64_wrap(List.len(one))))))
		})
	})
	Ok({})
}
