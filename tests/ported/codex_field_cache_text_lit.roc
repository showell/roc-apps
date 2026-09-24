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

import cdx.CceText

# FieldCacheTextLit -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Box_ := { items : List(I64) }.{
	is_eq : Box_, Box_ -> Bool
	is_eq = |a, b| a.items == b.items
}

probe : List(I64), CceText, I64, I64 -> I64
probe = |_xs, _name, _i, len| len

# --- Entry ---

main! = |_args| {
	({
		b = Box_.{ items: [7, 8, 9] }
		({
			line!(CceText.printed(CceText.concat("literal between two reads: ", CceText.show_int(probe(b.items, "read-text", 0, U64.to_i64_wrap(List.len(b.items)))))))
			line!(CceText.printed(CceText.concat("empty literal between them: ", CceText.show_int(probe(b.items, "", 0, U64.to_i64_wrap(List.len(b.items)))))))
			line!(CceText.printed(CceText.concat("no literal to cross: ", CceText.show_int(U64.to_i64_wrap(List.len(b.items))))))
		})
	})
	Ok({})
}
