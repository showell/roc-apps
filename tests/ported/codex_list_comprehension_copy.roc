# list-comprehension-copy
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/list-comprehension-copy.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     base-len=1 grown-len=2 grown-head=7
#     0

app [main!] { cdx: "./codex/main.roc" }

import cdx.ListUtils
import cdx.Text

# ListComprehensionCopy -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

report : I64 -> Text
report = |_x| ({
	base = [7]
	copied = ListUtils.map_list(lam_0, base)
	grown = List.append(copied, 9)
	Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("base-len=", Text.show_int(U64.to_i64_wrap(List.len(base)))), " grown-len="), Text.show_int(U64.to_i64_wrap(List.len(grown)))), " grown-head="), Text.show_int((List.get(grown, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))))
})

lam_0 : I64 -> I64
lam_0 = |r| r

# --- Entry ---

main! = |_args| {
	line!(Text.printed(report(0)))
	line!(I64.to_str(0))
	Ok({})
}
