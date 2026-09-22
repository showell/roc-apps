# lib@pixel-buf
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lib@pixel-buf.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     new: ......../......../......../........
#     set: ......../...#..../......../.......#
#     clip: #......./......../......../........
#     clip read: left=0 right=0 inside=3
#     rect: ......../..###.../..###.../........
#     hline: ......../......../########/........
#     vline: .....#../.....#../.....#../........
#     outline: .######./.#....#./.#....#./.######.
#     blend: a0=0 a128=8421504 a239=15724527 a240=16777215 a255=16777215
#     cost: control=0 thousand-writes=0

app [main!] { cdx: "./codex/main.roc" }

import cdx.Mem
import cdx.PixelBuf
import cdx.Text

# PixelBufTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

row! : Mem.Mem, PixelBuf.GopBuf, I64 => (Mem.Mem, List(U8))
row! = |mem, gb, y| row_loop!(mem, gb, y, 0, [])

row_loop! : Mem.Mem, PixelBuf.GopBuf, I64, I64, List(U8) => (Mem.Mem, List(U8))
row_loop! = |mem, gb, y, x, acc| (if (x >= 8) { (mem, acc) } else { ({
	(mem1, v) = PixelBuf.gop_buf_get!(mem, gb, x, y)
	c = (if (v == 0) { [65] } else { (if (v == 1) { [4] } else { (if (v == 2) { [5] } else { [83] }) }) })
	row_loop!(mem1, gb, y, (x + 1), List.concat(acc, c))
}) })

grid! : Mem.Mem, PixelBuf.GopBuf => (Mem.Mem, List(U8))
grid! = |mem, gb| ({
	(mem5, mem__1) = ({
	(mem1, a) = row!(mem, gb, 0)
	(mem2, b) = row!(mem1, gb, 1)
	(mem3, c) = row!(mem2, gb, 2)
	(mem4, d) = row!(mem3, gb, 3)
	(mem4, List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(a, [81]), b), [81]), c), [81]), d))
})
	(mem5, mem__1)
})

line_new! : Mem.Mem => (Mem.Mem, List(U8))
line_new! = |mem| ({
	(mem3, mem__2) = ({
	(mem1, gb) = PixelBuf.gop_buf_new!(mem, 8, 4, 0)
	({
		(mem2, mem__1) = grid!(mem1, gb)
		(mem2, List.concat([18, 13, 27, 69, 2], mem__1))
	})
})
	(mem3, mem__2)
})

line_set! : Mem.Mem => (Mem.Mem, List(U8))
line_set! = |mem| ({
	(mem5, mem__2) = ({
	(mem1, gb) = PixelBuf.gop_buf_new!(mem, 8, 4, 0)
	(mem2, _d) = PixelBuf.gop_buf_set!(mem1, gb, 3, 1, 3)
	(mem3, _e) = PixelBuf.gop_buf_set!(mem2, gb, 7, 3, 3)
	({
		(mem4, mem__1) = grid!(mem3, gb)
		(mem4, List.concat([19, 13, 14, 69, 2], mem__1))
	})
})
	(mem5, mem__2)
})

line_clip! : Mem.Mem => (Mem.Mem, List(U8))
line_clip! = |mem| ({
	(mem8, mem__2) = ({
	(mem1, gb) = PixelBuf.gop_buf_new!(mem, 8, 4, 0)
	(mem2, _a) = PixelBuf.gop_buf_set!(mem1, gb, (-1), 0, 3)
	(mem3, _b) = PixelBuf.gop_buf_set!(mem2, gb, 0, (-1), 3)
	(mem4, _c) = PixelBuf.gop_buf_set!(mem3, gb, 8, 0, 3)
	(mem5, _d) = PixelBuf.gop_buf_set!(mem4, gb, 0, 4, 3)
	(mem6, _e) = PixelBuf.gop_buf_set!(mem5, gb, 0, 0, 3)
	({
		(mem7, mem__1) = grid!(mem6, gb)
		(mem7, List.concat([24, 23, 17, 31, 69, 2], mem__1))
	})
})
	(mem8, mem__2)
})

line_clip_read! : Mem.Mem => (Mem.Mem, List(U8))
line_clip_read! = |mem| ({
	(mem6, mem__4) = ({
	(mem1, gb) = PixelBuf.gop_buf_new!(mem, 8, 4, 0)
	(mem2, _d) = PixelBuf.gop_buf_set!(mem1, gb, 7, 0, 3)
	(mem3, mem__1) = PixelBuf.gop_buf_get!(mem2, gb, (-1), 1)
	a = Text.show_int(mem__1)
	(mem4, mem__2) = PixelBuf.gop_buf_get!(mem3, gb, 8, 0)
	b = Text.show_int(mem__2)
	(mem5, mem__3) = PixelBuf.gop_buf_get!(mem4, gb, 7, 0)
	c = Text.show_int(mem__3)
	(mem5, List.concat(List.concat(List.concat(List.concat(List.concat([24, 23, 17, 31, 2, 21, 13, 15, 22, 69, 2, 23, 13, 28, 14, 77], a), [2, 21, 17, 29, 20, 14, 77]), b), [2, 17, 18, 19, 17, 22, 13, 77]), c))
})
	(mem6, mem__4)
})

line_rect! : Mem.Mem => (Mem.Mem, List(U8))
line_rect! = |mem| ({
	(mem4, mem__2) = ({
	(mem1, gb) = PixelBuf.gop_buf_new!(mem, 8, 4, 0)
	(mem2, _d) = PixelBuf.gop_buf_rect!(mem1, gb, 2, 1, 3, 2, 3)
	({
		(mem3, mem__1) = grid!(mem2, gb)
		(mem3, List.concat([21, 13, 24, 14, 69, 2], mem__1))
	})
})
	(mem4, mem__2)
})

line_hline! : Mem.Mem => (Mem.Mem, List(U8))
line_hline! = |mem| ({
	(mem4, mem__2) = ({
	(mem1, gb) = PixelBuf.gop_buf_new!(mem, 8, 4, 0)
	(mem2, _d) = PixelBuf.gop_buf_hline!(mem1, gb, (-2), 99, 2, 3)
	({
		(mem3, mem__1) = grid!(mem2, gb)
		(mem3, List.concat([20, 23, 17, 18, 13, 69, 2], mem__1))
	})
})
	(mem4, mem__2)
})

line_vline! : Mem.Mem => (Mem.Mem, List(U8))
line_vline! = |mem| ({
	(mem4, mem__2) = ({
	(mem1, gb) = PixelBuf.gop_buf_new!(mem, 8, 4, 0)
	(mem2, _d) = PixelBuf.gop_buf_vline!(mem1, gb, 5, (-2), 2, 3)
	({
		(mem3, mem__1) = grid!(mem2, gb)
		(mem3, List.concat([33, 23, 17, 18, 13, 69, 2], mem__1))
	})
})
	(mem4, mem__2)
})

line_outline! : Mem.Mem => (Mem.Mem, List(U8))
line_outline! = |mem| ({
	(mem4, mem__2) = ({
	(mem1, gb) = PixelBuf.gop_buf_new!(mem, 8, 4, 0)
	(mem2, _d) = PixelBuf.gop_buf_outline!(mem1, gb, 1, 0, 6, 4, 3)
	({
		(mem3, mem__1) = grid!(mem2, gb)
		(mem3, List.concat([16, 25, 14, 23, 17, 18, 13, 69, 2], mem__1))
	})
})
	(mem4, mem__2)
})

blended! : Mem.Mem, I64 => (Mem.Mem, List(U8))
blended! = |mem, alpha| ({
	(mem5, mem__2) = ({
	(mem1, gb) = PixelBuf.gop_buf_new!(mem, 8, 4, 0)
	(mem2, _d) = PixelBuf.gop_buf_set!(mem1, gb, 0, 0, 0)
	(mem3, _e) = PixelBuf.gbf_blend_pixel!(mem2, gb, 0, 0, 16777215, alpha)
	({
		(mem4, mem__1) = PixelBuf.gop_buf_get!(mem3, gb, 0, 0)
		(mem4, Text.show_int(mem__1))
	})
})
	(mem5, mem__2)
})

line_blend! : Mem.Mem => (Mem.Mem, List(U8))
line_blend! = |mem| ({
	(mem6, mem__1) = ({
	(mem1, a) = blended!(mem, 0)
	(mem2, b) = blended!(mem1, 128)
	(mem3, c) = blended!(mem2, 239)
	(mem4, d) = blended!(mem3, 240)
	(mem5, e) = blended!(mem4, 255)
	(mem5, List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([32, 23, 13, 18, 22, 69, 2, 15, 3, 77], a), [2, 15, 4, 5, 11, 77]), b), [2, 15, 5, 6, 12, 77]), c), [2, 15, 5, 7, 3, 77]), d), [2, 15, 5, 8, 8, 77]), e))
})
	(mem6, mem__1)
})

heap_now! : Mem.Mem => (Mem.Mem, I64)
heap_now! = |mem| Mem.alloc(mem, 0)

spin : I64, I64 -> I64
spin = |i, n| (if (i >= n) { 0 } else { spin((i + 1), n) })

write_loop! : Mem.Mem, PixelBuf.GopBuf, I64, I64 => (Mem.Mem, I64)
write_loop! = |mem, gb, i, n| (if (i >= n) { (mem, 0) } else { ({
	(mem1, _d) = PixelBuf.gop_buf_set!(mem, gb, 0, 0, i)
	write_loop!(mem1, gb, (i + 1), n)
}) })

line_cost! : Mem.Mem => (Mem.Mem, List(U8))
line_cost! = |mem| ({
	(mem7, mem__1) = ({
	(mem1, gb) = PixelBuf.gop_buf_new!(mem, 8, 4, 0)
	(mem2, c0) = heap_now!(mem1)
	_cd = spin(0, 1000)
	(mem3, c1) = heap_now!(mem2)
	(mem4, w0) = heap_now!(mem3)
	(mem5, _wd) = write_loop!(mem4, gb, 0, 1000)
	(mem6, w1) = heap_now!(mem5)
	(mem6, List.concat(List.concat(List.concat([24, 16, 19, 14, 69, 2, 24, 16, 18, 14, 21, 16, 23, 77], Text.show_int((c1 - c0))), [2, 14, 20, 16, 25, 19, 15, 18, 22, 73, 27, 21, 17, 14, 13, 19, 77]), Text.show_int((w1 - w0))))
})
	(mem7, mem__1)
})

report_a! : Mem.Mem => (Mem.Mem, List(U8))
report_a! = |mem| ({
	(mem1, mem__1) = line_new!(mem)
	(mem2, mem__2) = line_set!(mem1)
	(mem3, mem__3) = line_clip!(mem2)
	(mem4, mem__4) = line_clip_read!(mem3)
	(mem4, List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(mem__1, [1]), mem__2), [1]), mem__3), [1]), mem__4))
})

report_b! : Mem.Mem => (Mem.Mem, List(U8))
report_b! = |mem| ({
	(mem1, mem__1) = line_rect!(mem)
	(mem2, mem__2) = line_hline!(mem1)
	(mem3, mem__3) = line_vline!(mem2)
	(mem4, mem__4) = line_outline!(mem3)
	(mem4, List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(mem__1, [1]), mem__2), [1]), mem__3), [1]), mem__4))
})

report_c! : Mem.Mem => (Mem.Mem, List(U8))
report_c! = |mem| ({
	(mem1, mem__1) = line_blend!(mem)
	(mem2, mem__2) = line_cost!(mem1)
	(mem2, List.concat(List.concat(mem__1, [1]), mem__2))
})

# --- Entry ---

main! = |args| {
	mem = Mem.new(U64.to_i64_wrap(List.len(args)))
	(mem1, mem__1) = report_a!(mem)
	line!(Text.printed(mem__1))
	(mem2, mem__2) = report_b!(mem1)
	line!(Text.printed(mem__2))
	(_mem3, mem__3) = report_c!(mem2)
	line!(Text.printed(mem__3))
	Ok({})
}
