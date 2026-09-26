# ops@runtime-bytes-unsigned
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@runtime-bytes-unsigned.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     buf-read 128 200
#     compare-a-high -1
#     compare-high-a 1

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceChar
import cdx.CceText
import cdx.Mem

# RuntimeBytesUnsigned -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

list_text : List(I64), I64, CceText -> CceText
list_text = |xs, i, acc| (if (i >= U64.to_i64_wrap(List.len(xs))) { acc } else { list_text(xs, (i + 1), CceText.concat(CceText.concat(acc, " "), CceText.show_int((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

high : CceText
high = CceText.char_encode(CceChar.of_code(128))

# --- Entry ---

main! = |args| {
	mem = Mem.new(U64.to_i64_wrap(List.len(args)))
	(_mem4, mem__2) = ({
		(mem1, b) = Mem.alloc(mem, 8)
		(mem2, _w0) = Mem.store!(mem1, b, 0, 51328, 4)
		({
			(mem3, mem__1) = Mem.read_bytes!(mem2, b, 0, 2)
			_ = line!(CceText.printed(CceText.concat("buf-read", list_text(mem__1, 0, ""))))
			_ = line!(CceText.printed(CceText.concat("compare-a-high ", CceText.show_int(CceText.compare("a", high)))))
			(mem3, line!(CceText.printed(CceText.concat("compare-high-a ", CceText.show_int(CceText.compare(high, "a"))))))
		})
	})
	mem__2
	Ok({})
}
