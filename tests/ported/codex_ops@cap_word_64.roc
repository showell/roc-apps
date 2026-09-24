# ops@cap-word-64
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@cap-word-64.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     q-bit31 : 2147483648
#     q-bit40 : 1099511627776
#     q-small : 305419896
#     d-small : 305419896
#     d-bit40 : 0

app [main!] { cdx: "./codex/main.roc" }

import cdx.Mem
import cdx.Text

# CapWord64 -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bit31 : I64
bit31 = 2147483648

bit40 : I64
bit40 = 1099511627776

small : I64
small = 305419896

# --- Entry ---

main! = |args| {
	mem = Mem.new(U64.to_i64_wrap(List.len(args)))
	(_mem12, mem__6) = ({
		(mem1, a) = Mem.alloc(mem, 64)
		(mem2, _w1) = Mem.store!(mem1, a, 0, bit31, 8)
		(mem3, _w2) = Mem.store!(mem2, a, 8, bit40, 8)
		(mem4, _w3) = Mem.store!(mem3, a, 16, small, 8)
		(mem5, _w4) = Mem.store!(mem4, a, 24, small, 4)
		(mem6, _w5) = Mem.store!(mem5, a, 32, bit40, 4)
		({
			(mem7, mem__1) = Mem.load!(mem6, a, 0, 8)
			_ = line!(Text.printed(Text.concat("q-bit31 : ", Text.show_int(mem__1))))
			(mem8, mem__2) = Mem.load!(mem7, a, 8, 8)
			_ = line!(Text.printed(Text.concat("q-bit40 : ", Text.show_int(mem__2))))
			(mem9, mem__3) = Mem.load!(mem8, a, 16, 8)
			_ = line!(Text.printed(Text.concat("q-small : ", Text.show_int(mem__3))))
			(mem10, mem__4) = Mem.load!(mem9, a, 24, 4)
			_ = line!(Text.printed(Text.concat("d-small : ", Text.show_int(mem__4))))
			({
				(mem11, mem__5) = Mem.load!(mem10, a, 32, 4)
				(mem11, line!(Text.printed(Text.concat("d-bit40 : ", Text.show_int(mem__5)))))
			})
		})
	})
	mem__6
	Ok({})
}
