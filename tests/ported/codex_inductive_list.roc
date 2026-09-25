# inductive-list
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/inductive-list.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     inductive-list: QED len=3 roundtrip=123

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.InductiveList

# InductiveListTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	({
		xs = InductiveList.ilist_from_list([1, 2, 3])
		back : List(I64)
		back = InductiveList.ilist_to_list(InductiveList.ilist_reverse(InductiveList.ilist_reverse(xs)))
		line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("inductive-list: QED len=", CceText.show_int(InductiveList.ilist_length(xs))), " roundtrip="), CceText.show_int((List.get(back, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))), CceText.show_int((List.get(back, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))), CceText.show_int((List.get(back, I64.to_u64_wrap(2)) ?? crash("list-at out of range"))))))
	})
	Ok({})
}
