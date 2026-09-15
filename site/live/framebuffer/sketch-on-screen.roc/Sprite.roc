# Sprite -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Rasterizer

Sprite :: [].{
	Sprite : { spr_width : I64, spr_height : I64, spr_pixels : List(I64) }
	AnimFrame : { af_sprite : Sprite.Sprite, af_duration : I64 }
	SpriteAnim : { sa_frames : List(Sprite.AnimFrame), sa_count : I64, sa_current : I64, sa_elapsed : I64, sa_looping : Bool }

	sprite_new : I64, I64, I64 -> Sprite.Sprite
	sprite_new = |w, h, fill| { spr_width: w, spr_height: h, spr_pixels: spr_fill((w * h), fill) }

	spr_fill : I64, I64 -> List(I64)
	spr_fill = |n, val| spr_fill_loop(n, val, [])

	spr_fill_loop : I64, I64, List(I64) -> List(I64)
	spr_fill_loop = |n, val, acc| (if (n <= 0) { acc } else { spr_fill_loop((n - 1), val, List.append(acc, val)) })

	sprite_from_pixels : I64, I64, List(I64) -> Sprite.Sprite
	sprite_from_pixels = |w, h, pixels| { spr_width: w, spr_height: h, spr_pixels: pixels }

	sprite_get : Sprite.Sprite, I64, I64 -> I64
	sprite_get = |spr, x, y| (if (x < 0) { 0 } else { (if (y < 0) { 0 } else { (if (x >= spr.spr_width) { 0 } else { (if (y >= spr.spr_height) { 0 } else { (List.get(spr.spr_pixels, I64.to_u64_wrap(((y * spr.spr_width) + x))) ?? crash("list-at out of range")) }) }) }) })

	sprite_set : Sprite.Sprite, I64, I64, I64 -> Sprite.Sprite
	sprite_set = |spr, x, y, color| (if (x < 0) { spr } else { (if (y < 0) { spr } else { (if (x >= spr.spr_width) { spr } else { (if (y >= spr.spr_height) { spr } else { { spr_width: spr.spr_width, spr_height: spr.spr_height, spr_pixels: (List.set(spr.spr_pixels, I64.to_u64_wrap(((y * spr.spr_width) + x)), color) ?? crash("list-set-at past the end")) } }) }) }) })

	sprite_blit : Rasterizer.Framebuf, Sprite.Sprite, I64, I64 -> Rasterizer.Framebuf
	sprite_blit = |fb, spr, dx, dy| spr_blit_loop(fb, spr, dx, dy, 0, 0)

	spr_blit_loop : Rasterizer.Framebuf, Sprite.Sprite, I64, I64, I64, I64 -> Rasterizer.Framebuf
	spr_blit_loop = |fb, spr, dx, dy, sx, sy| (if (sy >= spr.spr_height) { fb } else { (if (sx >= spr.spr_width) { spr_blit_loop(fb, spr, dx, dy, 0, (sy + 1)) } else { ({
		color = sprite_get(spr, sx, sy)
		fb2 = Rasterizer.fb_set(fb, (dx + sx), (dy + sy), color)
		spr_blit_loop(fb2, spr, dx, dy, (sx + 1), sy)
	}) }) })

	sprite_blit_keyed : Rasterizer.Framebuf, Sprite.Sprite, I64, I64, I64 -> Rasterizer.Framebuf
	sprite_blit_keyed = |fb, spr, dx, dy, key| spr_blit_key_loop(fb, spr, dx, dy, key, 0, 0)

	spr_blit_key_loop : Rasterizer.Framebuf, Sprite.Sprite, I64, I64, I64, I64, I64 -> Rasterizer.Framebuf
	spr_blit_key_loop = |fb, spr, dx, dy, key, sx, sy| (if (sy >= spr.spr_height) { fb } else { (if (sx >= spr.spr_width) { spr_blit_key_loop(fb, spr, dx, dy, key, 0, (sy + 1)) } else { ({
		color = sprite_get(spr, sx, sy)
		fb2 = (if (color == key) { fb } else { Rasterizer.fb_set(fb, (dx + sx), (dy + sy), color) })
		spr_blit_key_loop(fb2, spr, dx, dy, key, (sx + 1), sy)
	}) }) })

	sprite_flip_h : Sprite.Sprite -> Sprite.Sprite
	sprite_flip_h = |spr| spr_flip_h_loop(spr, 0, 0, sprite_new(spr.spr_width, spr.spr_height, 0))

	spr_flip_h_loop : Sprite.Sprite, I64, I64, Sprite.Sprite -> Sprite.Sprite
	spr_flip_h_loop = |src, x, y, dst| (if (y >= src.spr_height) { dst } else { (if (x >= src.spr_width) { spr_flip_h_loop(src, 0, (y + 1), dst) } else { ({
		color = sprite_get(src, x, y)
		spr_flip_h_loop(src, (x + 1), y, sprite_set(dst, ((src.spr_width - 1) - x), y, color))
	}) }) })

	sprite_flip_v : Sprite.Sprite -> Sprite.Sprite
	sprite_flip_v = |spr| spr_flip_v_loop(spr, 0, 0, sprite_new(spr.spr_width, spr.spr_height, 0))

	spr_flip_v_loop : Sprite.Sprite, I64, I64, Sprite.Sprite -> Sprite.Sprite
	spr_flip_v_loop = |src, x, y, dst| (if (y >= src.spr_height) { dst } else { (if (x >= src.spr_width) { spr_flip_v_loop(src, 0, (y + 1), dst) } else { ({
		color = sprite_get(src, x, y)
		spr_flip_v_loop(src, (x + 1), y, sprite_set(dst, x, ((src.spr_height - 1) - y), color))
	}) }) })

	sprite_sheet_frame : Sprite.Sprite, I64, I64, I64, I64 -> Sprite.Sprite
	sprite_sheet_frame = |sheet, fx, fy, fw, fh| spr_extract(sheet, fx, fy, fw, fh, 0, 0, sprite_new(fw, fh, 0))

	spr_extract : Sprite.Sprite, I64, I64, I64, I64, I64, I64, Sprite.Sprite -> Sprite.Sprite
	spr_extract = |sheet, fx, fy, fw, fh, x, y, dst| (if (y >= fh) { dst } else { (if (x >= fw) { spr_extract(sheet, fx, fy, fw, fh, 0, (y + 1), dst) } else { ({
		color = sprite_get(sheet, (fx + x), (fy + y))
		spr_extract(sheet, fx, fy, fw, fh, (x + 1), y, sprite_set(dst, x, y, color))
	}) }) })

	anim_new : List(Sprite.AnimFrame), Bool -> Sprite.SpriteAnim
	anim_new = |frames, loop| { sa_frames: frames, sa_count: U64.to_i64_wrap(List.len(frames)), sa_current: 0, sa_elapsed: 0, sa_looping: loop }

	anim_frame : I64, Sprite.Sprite -> Sprite.AnimFrame
	anim_frame = |dur, spr| { af_sprite: spr, af_duration: dur }

	spr_anim_tick : Sprite.SpriteAnim, I64 -> Sprite.SpriteAnim
	spr_anim_tick = |anim, dt| ({
		new_elapsed = (anim.sa_elapsed + dt)
		cur_frame = (List.get(anim.sa_frames, I64.to_u64_wrap(anim.sa_current)) ?? crash("list-at out of range"))
		(if (new_elapsed >= cur_frame.af_duration) { ({
			next = (anim.sa_current + 1)
			(if (next >= anim.sa_count) { (if anim.sa_looping { { sa_frames: anim.sa_frames, sa_count: anim.sa_count, sa_current: 0, sa_elapsed: 0, sa_looping: True } } else { { sa_frames: anim.sa_frames, sa_count: anim.sa_count, sa_current: (anim.sa_count - 1), sa_elapsed: cur_frame.af_duration, sa_looping: False } }) } else { { sa_frames: anim.sa_frames, sa_count: anim.sa_count, sa_current: next, sa_elapsed: 0, sa_looping: anim.sa_looping } })
		}) } else { { sa_frames: anim.sa_frames, sa_count: anim.sa_count, sa_current: anim.sa_current, sa_elapsed: new_elapsed, sa_looping: anim.sa_looping } })
	})

	anim_current_sprite : Sprite.SpriteAnim -> Sprite.Sprite
	anim_current_sprite = |anim| (List.get(anim.sa_frames, I64.to_u64_wrap(anim.sa_current)) ?? crash("list-at out of range")).af_sprite

	sprite_pixel_count : Sprite.Sprite -> I64
	sprite_pixel_count = |spr| (spr.spr_width * spr.spr_height)

	sprite_count_color : Sprite.Sprite, I64 -> I64
	sprite_count_color = |spr, color| spr_count_loop(spr.spr_pixels, color, 0, U64.to_i64_wrap(List.len(spr.spr_pixels)), 0)

	spr_count_loop : List(I64), I64, I64, I64, I64 -> I64
	spr_count_loop = |px, color, i, n, acc| (if (i >= n) { acc } else { ({
		inc = (if ((List.get(px, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) == color) { 1 } else { 0 })
		spr_count_loop(px, color, (i + 1), n, (acc + inc))
	}) })
}
