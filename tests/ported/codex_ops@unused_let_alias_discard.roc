# ops@unused-let-alias-discard
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@unused-let-alias-discard.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     reads-in-body: 60
#     reads-in-sibling: 50
#     reads-in-tail: 23

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# UnusedLetAliasDiscard -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

reads_in_body : I64 -> I64
reads_in_body = |_n| ({
	xs = [10, 20, 30]
	_unused = xs
	(((List.get(xs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) + (List.get(xs, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))) + (List.get(xs, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))
})

reads_in_sibling : I64 -> I64
reads_in_sibling = |_n| ({
	xs = [40, 50]
	a = xs
	_unused = xs
	(List.get(a, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))
})

reads_in_tail : List(I64), I64 -> I64
reads_in_tail = |xs, n| (if (n <= 0) { (List.get(xs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) } else { ({
	_unused = xs
	reads_in_tail(xs, (n - 1))
}) })

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("reads-in-body: ", CceText.show_int(reads_in_body(0)))))
	line!(CceText.printed(CceText.concat("reads-in-sibling: ", CceText.show_int(reads_in_sibling(0)))))
	line!(CceText.printed(CceText.concat("reads-in-tail: ", CceText.show_int(reads_in_tail([23], 10000)))))
	Ok({})
}
