app [main!] { pf: platform "../../../../../../showell_repos/roc-apps/framebuffer/platform/main.roc" }

import pf.Echo

echo! = |msg| Echo.line!(msg)

# SketchOnScreen -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Mem
import Rasterizer
import Sprite

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

fb_base : I64
fb_base = 3204448256

cell_width : I64
cell_width = 1988

cell_height : I64
cell_height = 1992

cell_stride : I64
cell_stride = 2016

cell_clock : I64
cell_clock = 2032

sketch_w : I64
sketch_w = 80

sketch_h : I64
sketch_h = 60

paper : I64
paper = 1777450

gold : I64
gold = 15909198

teal : I64
teal = 4175528

coral : I64
coral = 15887707

lilac : I64
lilac = 10325489

chalk : I64
chalk = 16052712

arrow : Sprite.Sprite
arrow = Sprite.sprite_from_pixels(7, 5, [0, 0, 0, 0, chalk, 0, 0, 0, 0, 0, 0, chalk, chalk, 0, chalk, chalk, chalk, chalk, chalk, chalk, chalk, 0, 0, 0, 0, chalk, chalk, 0, 0, 0, 0, 0, chalk, 0, 0])

face_open : Sprite.Sprite
face_open = Sprite.sprite_from_pixels(6, 6, [0, gold, gold, gold, gold, 0, gold, gold, gold, gold, gold, gold, gold, paper, gold, gold, paper, gold, gold, gold, gold, gold, gold, gold, gold, paper, paper, paper, paper, gold, 0, gold, gold, gold, gold, 0])

face_shut : Sprite.Sprite
face_shut = Sprite.sprite_from_pixels(6, 6, [0, gold, gold, gold, gold, 0, gold, gold, gold, gold, gold, gold, gold, gold, gold, gold, gold, gold, gold, paper, gold, gold, paper, gold, gold, paper, paper, paper, paper, gold, 0, gold, gold, gold, gold, 0])

blink : Sprite.SpriteAnim
blink = Sprite.anim_new([Sprite.anim_frame(900, face_open), Sprite.anim_frame(150, face_shut)], True)

sketch_at : I64 -> Rasterizer.Framebuf
sketch_at = |t| ({
	bg = Rasterizer.fb_new(sketch_w, sketch_h, paper)
	l1 = Rasterizer.fb_line(bg, 2, 2, 77, 57, teal)
	l2 = Rasterizer.fb_line(l1, 2, 57, 77, 2, teal)
	r1 = Rasterizer.fb_rect(l2, 4, 4, 20, 14, lilac)
	c1 = Rasterizer.fb_circle_filled(r1, 62, 15, 10, coral)
	t1 = Rasterizer.fb_tri(c1, 40, 20, 24, 50, 56, 50, lilac)
	x = ((2 + I64.div_trunc_by(t, 60)) - (I64.div_trunc_by(I64.div_trunc_by(t, 60), 70) * 70))
	s1 = Sprite.sprite_blit_keyed(t1, arrow, x, 52, 0)
	s2 = Sprite.sprite_blit_keyed(s1, Sprite.sprite_flip_h(arrow), (72 - x), 2, 0)
	face = Sprite.anim_current_sprite(Sprite.spr_anim_tick(blink, (t - (I64.div_trunc_by(t, 1050) * 1050))))
	Sprite.sprite_blit_keyed(s2, face, 37, 34, 0)
})

copy_cols! : Mem.Mem, Rasterizer.Framebuf, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
copy_cols! = |mem, src, stride, w, h, y, x| (if (x >= w) { (mem, 0) } else { ({
	c = Rasterizer.fb_get(src, I64.div_trunc_by((x * src.fb_width), w), I64.div_trunc_by((y * src.fb_height), h))
	(mem1, _p) = Mem.store!(mem, fb_base, (((y * stride) + x) * 4), c, 4)
	copy_cols!(mem1, src, stride, w, h, y, (x + 1))
}) })

copy_rows! : Mem.Mem, Rasterizer.Framebuf, I64, I64, I64, I64 => (Mem.Mem, I64)
copy_rows! = |mem, src, stride, w, h, y| (if (y >= h) { (mem, 0) } else { ({
	(mem1, _d) = copy_cols!(mem, src, stride, w, h, y, 0)
	copy_rows!(mem1, src, stride, w, h, (y + 1))
}) })

# --- Entry ---

main! = |args| {
	mem = Mem.new(U64.to_i64_wrap(List.len(args)))
	(_mem6, mem__1) = ({
		(mem1, w) = Mem.load!(mem, cell_width, 0, 4)
		(mem2, h) = Mem.load!(mem1, cell_height, 0, 4)
		(mem3, stride) = Mem.load!(mem2, cell_stride, 0, 4)
		(mem4, t) = Mem.load!(mem3, cell_clock, 0, 4)
		(mem5, _d) = copy_rows!(mem4, sketch_at(t), stride, w, h, 0)
		({
			(mem5, line!(Str.concat(Str.concat("clock : ", I64.to_str(t)), " ms")))
		})
	})
	mem__1
	Ok({})
}
