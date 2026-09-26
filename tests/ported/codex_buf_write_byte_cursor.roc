# buf-write-byte-cursor
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/buf-write-byte-cursor.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     unused 8
#     used 8

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Mem

# BufWriteByteCursor -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

wr! : Mem.Mem, I64, I64, List(I64), I64, I64 => (Mem.Mem, I64)
wr! = |mem, base, dst, xs, i, stop| (if (i >= stop) { (mem, dst) } else { ({
	(mem1, mem__1) = Mem.write_byte!(mem, base, dst, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))
	wr!(mem1, base, mem__1, xs, (i + 1), stop)
}) })

unused! : Mem.Mem, I64 => (Mem.Mem, I64)
unused! = |mem, buf| ({
	(mem1, _e) = wr!(mem, buf, 0, [7, 8, 9], 0, 3)
	Mem.load!(mem1, buf, 1, 1)
})

used! : Mem.Mem, I64 => (Mem.Mem, I64)
used! = |mem, buf| ({
	(mem3, mem__2) = ({
	(mem1, e) = wr!(mem, buf, 0, [7, 8, 9], 0, 3)
	({
		(mem2, mem__1) = Mem.load!(mem1, buf, 1, 1)
		(mem2, (mem__1 + (e * 0)))
	})
})
	(mem3, mem__2)
})

# --- Entry ---

main! = |args| {
	mem = Mem.new(U64.to_i64_wrap(List.len(args)))
	(mem1, mem__1) = Mem.alloc(mem, 16)
	(mem2, mem__2) = unused!(mem1, mem__1)
	line!(CceText.printed(CceText.concat("unused ", CceText.show_int(mem__2))))
	(mem3, mem__3) = Mem.alloc(mem2, 16)
	(_mem4, mem__4) = used!(mem3, mem__3)
	line!(CceText.printed(CceText.concat("used ", CceText.show_int(mem__4))))
	Ok({})
}
