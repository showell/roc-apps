# field-cache-text-lit
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/field-cache-text-lit.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     literal between two reads: 3
#     empty literal between them: 3
#     no literal to cross: 3

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# FieldCacheTextLit -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Box_ : { items : List(I64) }

probe : List(I64), List(U8), I64, I64 -> I64
probe = |_xs, _name, _i, len| len

# --- Entry ---

main! = |_args| {
	({
		b = { items: [7, 8, 9] }
		({
			line!(Text.printed(List.concat([23, 17, 14, 13, 21, 15, 23, 2, 32, 13, 14, 27, 13, 13, 18, 2, 14, 27, 16, 2, 21, 13, 15, 22, 19, 69, 2], Text.show_int(probe(b.items, [21, 13, 15, 22, 73, 14, 13, 36, 14], 0, U64.to_i64_wrap(List.len(b.items)))))))
			line!(Text.printed(List.concat([13, 26, 31, 14, 30, 2, 23, 17, 14, 13, 21, 15, 23, 2, 32, 13, 14, 27, 13, 13, 18, 2, 14, 20, 13, 26, 69, 2], Text.show_int(probe(b.items, [], 0, U64.to_i64_wrap(List.len(b.items)))))))
			line!(Text.printed(List.concat([18, 16, 2, 23, 17, 14, 13, 21, 15, 23, 2, 14, 16, 2, 24, 21, 16, 19, 19, 69, 2], Text.show_int(U64.to_i64_wrap(List.len(b.items))))))
		})
	})
	Ok({})
}
