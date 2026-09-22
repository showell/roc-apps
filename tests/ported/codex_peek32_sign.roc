# peek32-sign
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/peek32-sign.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     bit31-set 2882351940
#     bit31-clear 2147483647
#     bit31-only 2147483648
#     hi-word 43981

app [main!] { cdx: "./codex/main.roc" }

import cdx.Mem
import cdx.Text

# Peek32Sign -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |args| {
	mem = Mem.new(U64.to_i64_wrap(List.len(args)))
	(_mem9, mem__5) = ({
		(mem1, b) = Mem.alloc(mem, 16)
		(mem2, _w0) = Mem.store!(mem1, b, 0, 2882351940, 4)
		(mem3, _w1) = Mem.store!(mem2, b, 4, 2147483647, 4)
		(mem4, _w2) = Mem.store!(mem3, b, 8, 2147483648, 4)
		({
			(mem5, mem__1) = Mem.load!(mem4, b, 0, 4)
			_ = line!(Text.printed(List.concat([32, 17, 14, 6, 4, 73, 19, 13, 14, 2], Text.show_int(mem__1))))
			(mem6, mem__2) = Mem.load!(mem5, b, 4, 4)
			_ = line!(Text.printed(List.concat([32, 17, 14, 6, 4, 73, 24, 23, 13, 15, 21, 2], Text.show_int(mem__2))))
			(mem7, mem__3) = Mem.load!(mem6, b, 8, 4)
			_ = line!(Text.printed(List.concat([32, 17, 14, 6, 4, 73, 16, 18, 23, 30, 2], Text.show_int(mem__3))))
			({
				(mem8, mem__4) = Mem.load!(mem7, b, 0, 4)
				(mem8, line!(Text.printed(List.concat([20, 17, 73, 27, 16, 21, 22, 2], Text.show_int(I64.div_trunc_by(mem__4, 65536))))))
			})
		})
	})
	mem__5
	Ok({})
}
