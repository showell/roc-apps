# poke16-width
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/poke16-width.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     neighbour 1271739204
#     odd-bytes 0 255 238 0
#     peek16-odd 61183
#     peek16-hi 19405

app [main!] { cdx: "./codex/main.roc" }

import cdx.Mem
import cdx.Text

# Poke16Width -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

hex_bytes! : Mem.Mem, I64, I64, I64, Text => (Mem.Mem, Text)
hex_bytes! = |mem, b, i, n, acc| (if (i >= n) { (mem, acc) } else { ({
	(mem1, mem__1) = Mem.load!(mem, b, i, 1)
	hex_bytes!(mem1, b, (i + 1), n, Text.concat(Text.concat(acc, " "), Text.show_int(mem__1)))
}) })

# --- Entry ---

main! = |args| {
	mem = Mem.new(U64.to_i64_wrap(List.len(args)))
	(_mem11, mem__3) = ({
		(mem1, b) = Mem.alloc(mem, 16)
		(mem2, _w0) = Mem.store!(mem1, b, 0, 287454020, 4)
		(mem3, _w1) = Mem.store!(mem2, b, 2, 19405, 2)
		(mem4, aligned) = Mem.load!(mem3, b, 0, 4)
		(mem5, _w2) = Mem.store!(mem4, b, 4, 0, 4)
		(mem6, _w3) = Mem.store!(mem5, b, 8, 0, 4)
		(mem7, _w4) = Mem.store!(mem6, b, 5, 61183, 2)
		(mem8, odd) = Mem.load!(mem7, b, 5, 2)
		({
			_ = line!(Text.printed(Text.concat("neighbour ", Text.show_int(aligned))))
			(mem9, mem__1) = hex_bytes!(mem8, b, 4, 8, "")
			_ = line!(Text.printed(Text.concat("odd-bytes", mem__1)))
			_ = line!(Text.printed(Text.concat("peek16-odd ", Text.show_int(odd))))
			({
				(mem10, mem__2) = Mem.load!(mem9, b, 2, 2)
				(mem10, line!(Text.printed(Text.concat("peek16-hi ", Text.show_int(mem__2)))))
			})
		})
	})
	mem__3
	Ok({})
}
