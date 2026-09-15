# Surface -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Maybe
import Rasterizer
import Theme

Surface :: [].{
	Surface : { sf_id : Str, sf_x : I64, sf_y : I64, sf_z : I64, sf_fb : Rasterizer.Framebuf, sf_visible : Bool, sf_dirty : Bool, sf_opacity : I64 }
	Compositor : { comp_surfaces : List(Surface.Surface), comp_count : I64, comp_width : I64, comp_height : I64, comp_bg : I64 }

	surface_new : Str, I64, I64, I64, I64, I64 -> Surface.Surface
	surface_new = |id, x, y, w, h, bg| { sf_id: id, sf_x: x, sf_y: y, sf_z: 0, sf_fb: Rasterizer.fb_new(w, h, bg), sf_visible: True, sf_dirty: True, sf_opacity: 1000 }

	surface_new_z : Str, I64, I64, I64, I64, I64, I64 -> Surface.Surface
	surface_new_z = |id, x, y, z, w, h, bg| { sf_id: id, sf_x: x, sf_y: y, sf_z: z, sf_fb: Rasterizer.fb_new(w, h, bg), sf_visible: True, sf_dirty: True, sf_opacity: 1000 }

	compositor_new : I64, I64, I64 -> Surface.Compositor
	compositor_new = |w, h, bg| { comp_surfaces: [], comp_count: 0, comp_width: w, comp_height: h, comp_bg: bg }

	compositor_add : Surface.Compositor, Surface.Surface -> Surface.Compositor
	compositor_add = |comp, sf| { comp_surfaces: List.append(comp.comp_surfaces, sf), comp_count: (comp.comp_count + 1), comp_width: comp.comp_width, comp_height: comp.comp_height, comp_bg: comp.comp_bg }

	compositor_remove : Surface.Compositor, Str -> Surface.Compositor
	compositor_remove = |comp, id| ({
		filtered = comp_filter(comp.comp_surfaces, id, 0, comp.comp_count, [])
		{ comp_surfaces: filtered, comp_count: U64.to_i64_wrap(List.len(filtered)), comp_width: comp.comp_width, comp_height: comp.comp_height, comp_bg: comp.comp_bg }
	})

	comp_filter : List(Surface.Surface), Str, I64, I64, List(Surface.Surface) -> List(Surface.Surface)
	comp_filter = |surfaces, id, i, n, acc| (if (i >= n) { acc } else { ({
		sf = (List.get(surfaces, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (sf.sf_id == id) { comp_filter(surfaces, id, (i + 1), n, acc) } else { comp_filter(surfaces, id, (i + 1), n, List.append(acc, sf)) })
	}) })

	compositor_update_surface : Surface.Compositor, Str, Rasterizer.Framebuf -> Surface.Compositor
	compositor_update_surface = |comp, id, new_fb| ({
		updated = comp_update_fb(comp.comp_surfaces, id, new_fb, 0, comp.comp_count, [])
		{ comp_surfaces: updated, comp_count: comp.comp_count, comp_width: comp.comp_width, comp_height: comp.comp_height, comp_bg: comp.comp_bg }
	})

	comp_update_fb : List(Surface.Surface), Str, Rasterizer.Framebuf, I64, I64, List(Surface.Surface) -> List(Surface.Surface)
	comp_update_fb = |surfaces, id, new_fb, i, n, acc| (if (i >= n) { acc } else { ({
		sf = (List.get(surfaces, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (sf.sf_id == id) { ({
			updated = { sf_id: sf.sf_id, sf_x: sf.sf_x, sf_y: sf.sf_y, sf_z: sf.sf_z, sf_fb: new_fb, sf_visible: sf.sf_visible, sf_dirty: True, sf_opacity: sf.sf_opacity }
			comp_update_fb(surfaces, id, new_fb, (i + 1), n, List.append(acc, updated))
		}) } else { comp_update_fb(surfaces, id, new_fb, (i + 1), n, List.append(acc, sf)) })
	}) })

	compositor_move : Surface.Compositor, Str, I64, I64 -> Surface.Compositor
	compositor_move = |comp, id, dx, dy| ({
		moved = comp_move_sf(comp.comp_surfaces, id, dx, dy, 0, comp.comp_count, [])
		{ comp_surfaces: moved, comp_count: comp.comp_count, comp_width: comp.comp_width, comp_height: comp.comp_height, comp_bg: comp.comp_bg }
	})

	comp_move_sf : List(Surface.Surface), Str, I64, I64, I64, I64, List(Surface.Surface) -> List(Surface.Surface)
	comp_move_sf = |surfaces, id, dx, dy, i, n, acc| (if (i >= n) { acc } else { ({
		sf = (List.get(surfaces, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (sf.sf_id == id) { ({
			moved = { sf_id: sf.sf_id, sf_x: (sf.sf_x + dx), sf_y: (sf.sf_y + dy), sf_z: sf.sf_z, sf_fb: sf.sf_fb, sf_visible: sf.sf_visible, sf_dirty: True, sf_opacity: sf.sf_opacity }
			comp_move_sf(surfaces, id, dx, dy, (i + 1), n, List.append(acc, moved))
		}) } else { comp_move_sf(surfaces, id, dx, dy, (i + 1), n, List.append(acc, sf)) })
	}) })

	compositor_set_z : Surface.Compositor, Str, I64 -> Surface.Compositor
	compositor_set_z = |comp, id, z| ({
		updated = comp_set_z_sf(comp.comp_surfaces, id, z, 0, comp.comp_count, [])
		{ comp_surfaces: updated, comp_count: comp.comp_count, comp_width: comp.comp_width, comp_height: comp.comp_height, comp_bg: comp.comp_bg }
	})

	comp_set_z_sf : List(Surface.Surface), Str, I64, I64, I64, List(Surface.Surface) -> List(Surface.Surface)
	comp_set_z_sf = |surfaces, id, z, i, n, acc| (if (i >= n) { acc } else { ({
		sf = (List.get(surfaces, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (sf.sf_id == id) { ({
			updated = { sf_id: sf.sf_id, sf_x: sf.sf_x, sf_y: sf.sf_y, sf_z: z, sf_fb: sf.sf_fb, sf_visible: sf.sf_visible, sf_dirty: True, sf_opacity: sf.sf_opacity }
			comp_set_z_sf(surfaces, id, z, (i + 1), n, List.append(acc, updated))
		}) } else { comp_set_z_sf(surfaces, id, z, (i + 1), n, List.append(acc, sf)) })
	}) })

	compositor_toggle : Surface.Compositor, Str -> Surface.Compositor
	compositor_toggle = |comp, id| ({
		toggled = comp_toggle_sf(comp.comp_surfaces, id, 0, comp.comp_count, [])
		{ comp_surfaces: toggled, comp_count: comp.comp_count, comp_width: comp.comp_width, comp_height: comp.comp_height, comp_bg: comp.comp_bg }
	})

	comp_toggle_sf : List(Surface.Surface), Str, I64, I64, List(Surface.Surface) -> List(Surface.Surface)
	comp_toggle_sf = |surfaces, id, i, n, acc| (if (i >= n) { acc } else { ({
		sf = (List.get(surfaces, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (sf.sf_id == id) { ({
			toggled = { sf_id: sf.sf_id, sf_x: sf.sf_x, sf_y: sf.sf_y, sf_z: sf.sf_z, sf_fb: sf.sf_fb, sf_visible: (if sf.sf_visible { False } else { True }), sf_dirty: True, sf_opacity: sf.sf_opacity }
			comp_toggle_sf(surfaces, id, (i + 1), n, List.append(acc, toggled))
		}) } else { comp_toggle_sf(surfaces, id, (i + 1), n, List.append(acc, sf)) })
	}) })

	compositor_render : Surface.Compositor -> Rasterizer.Framebuf
	compositor_render = |comp| ({
		output = Rasterizer.fb_new(comp.comp_width, comp.comp_height, comp.comp_bg)
		sorted = comp_sort_by_z(comp.comp_surfaces, comp.comp_count)
		comp_blit_all(sorted, output, 0, comp.comp_count)
	})

	comp_blit_all : List(Surface.Surface), Rasterizer.Framebuf, I64, I64 -> Rasterizer.Framebuf
	comp_blit_all = |surfaces, fb, i, n| (if (i >= n) { fb } else { ({
		sf = (List.get(surfaces, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		fb2 = (if sf.sf_visible { comp_blit_surface(sf, fb) } else { fb })
		comp_blit_all(surfaces, fb2, (i + 1), n)
	}) })

	comp_blit_surface : Surface.Surface, Rasterizer.Framebuf -> Rasterizer.Framebuf
	comp_blit_surface = |sf, fb| comp_blit_rows(sf, fb, 0)

	comp_blit_rows : Surface.Surface, Rasterizer.Framebuf, I64 -> Rasterizer.Framebuf
	comp_blit_rows = |sf, fb, sy| (if (sy >= sf.sf_fb.fb_height) { fb } else { ({
		dy = (sf.sf_y + sy)
		(if (dy < 0) { comp_blit_rows(sf, fb, (sy + 1)) } else { (if (dy >= fb.fb_height) { fb } else { ({
			fb2 = comp_blit_row(sf, fb, sy, dy, 0)
			comp_blit_rows(sf, fb2, (sy + 1))
		}) }) })
	}) })

	comp_blit_row : Surface.Surface, Rasterizer.Framebuf, I64, I64, I64 -> Rasterizer.Framebuf
	comp_blit_row = |sf, fb, sy, dy, sx| (if (sx >= sf.sf_fb.fb_width) { fb } else { ({
		dx = (sf.sf_x + sx)
		(if (dx < 0) { comp_blit_row(sf, fb, sy, dy, (sx + 1)) } else { (if (dx >= fb.fb_width) { fb } else { ({
			pixel = Rasterizer.fb_get(sf.sf_fb, sx, sy)
			fb2 = (if (sf.sf_opacity >= 1000) { Rasterizer.fb_set(fb, dx, dy, pixel) } else { comp_blend_pixel(fb, dx, dy, pixel, sf.sf_opacity) })
			comp_blit_row(sf, fb2, sy, dy, (sx + 1))
		}) }) })
	}) })

	comp_blend_pixel : Rasterizer.Framebuf, I64, I64, I64, I64 -> Rasterizer.Framebuf
	comp_blend_pixel = |fb, x, y, src, alpha| ({
		dst = Rasterizer.fb_get(fb, x, y)
		sr = I64.bitwise_and(I64.shr_zf_wrap(src, I64.to_u8_wrap(16)), 255)
		sg = I64.bitwise_and(I64.shr_zf_wrap(src, I64.to_u8_wrap(8)), 255)
		sb = I64.bitwise_and(src, 255)
		dr = I64.bitwise_and(I64.shr_zf_wrap(dst, I64.to_u8_wrap(16)), 255)
		dg = I64.bitwise_and(I64.shr_zf_wrap(dst, I64.to_u8_wrap(8)), 255)
		db = I64.bitwise_and(dst, 255)
		inv = (1000 - alpha)
		r = I64.div_trunc_by(((sr * alpha) + (dr * inv)), 1000)
		g = I64.div_trunc_by(((sg * alpha) + (dg * inv)), 1000)
		b = I64.div_trunc_by(((sb * alpha) + (db * inv)), 1000)
		Rasterizer.fb_set(fb, x, y, I64.bitwise_or(I64.shl_wrap(r, I64.to_u8_wrap(16)), I64.bitwise_or(I64.shl_wrap(g, I64.to_u8_wrap(8)), b)))
	})

	comp_sort_by_z : List(Surface.Surface), I64 -> List(Surface.Surface)
	comp_sort_by_z = |surfaces, n| comp_isort(surfaces, 1, n)

	comp_isort : List(Surface.Surface), I64, I64 -> List(Surface.Surface)
	comp_isort = |surfaces, i, n| (if (i >= n) { surfaces } else { comp_isort(comp_insert(surfaces, i), (i + 1), n) })

	comp_insert : List(Surface.Surface), I64 -> List(Surface.Surface)
	comp_insert = |surfaces, i| (if (i <= 0) { surfaces } else { ({
		cur = (List.get(surfaces, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		prev = (List.get(surfaces, I64.to_u64_wrap((i - 1))) ?? crash("list-at out of range"))
		(if (cur.sf_z < prev.sf_z) { comp_insert(comp_swap(surfaces, i, (i - 1)), (i - 1)) } else { surfaces })
	}) })

	comp_swap : List(Surface.Surface), I64, I64 -> List(Surface.Surface)
	comp_swap = |surfaces, a, b| ({
		va = (List.get(surfaces, I64.to_u64_wrap(a)) ?? crash("list-at out of range"))
		vb = (List.get(surfaces, I64.to_u64_wrap(b)) ?? crash("list-at out of range"))
		(List.set((List.set(surfaces, I64.to_u64_wrap(a), vb) ?? crash("list-set-at past the end")), I64.to_u64_wrap(b), va) ?? crash("list-set-at past the end"))
	})

	compositor_find : Surface.Compositor, Str -> Maybe.Maybe(Surface.Surface)
	compositor_find = |comp, id| comp_find_loop(comp.comp_surfaces, id, 0, comp.comp_count)

	comp_find_loop : List(Surface.Surface), Str, I64, I64 -> Maybe.Maybe(Surface.Surface)
	comp_find_loop = |surfaces, id, i, n| (if (i >= n) { None } else { ({
		sf = (List.get(surfaces, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (sf.sf_id == id) { Just(sf) } else { comp_find_loop(surfaces, id, (i + 1), n) })
	}) })

	compositor_hit : Surface.Compositor, I64, I64 -> Maybe.Maybe(Surface.Surface)
	compositor_hit = |comp, px, py| comp_hit_loop(comp.comp_surfaces, px, py, (comp.comp_count - 1))

	comp_hit_loop : List(Surface.Surface), I64, I64, I64 -> Maybe.Maybe(Surface.Surface)
	comp_hit_loop = |surfaces, px, py, i| (if (i < 0) { None } else { ({
		sf = (List.get(surfaces, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if sf.sf_visible { (if (px >= sf.sf_x) { (if (px < (sf.sf_x + sf.sf_fb.fb_width)) { (if (py >= sf.sf_y) { (if (py < (sf.sf_y + sf.sf_fb.fb_height)) { Just(sf) } else { comp_hit_loop(surfaces, px, py, (i - 1)) }) } else { comp_hit_loop(surfaces, px, py, (i - 1)) }) } else { comp_hit_loop(surfaces, px, py, (i - 1)) }) } else { comp_hit_loop(surfaces, px, py, (i - 1)) }) } else { comp_hit_loop(surfaces, px, py, (i - 1)) })
	}) })

	format_surface : Surface.Surface -> Str
	format_surface = |sf| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(sf.sf_id, " ("), I64.to_str(sf.sf_x)), ","), I64.to_str(sf.sf_y)), " z="), I64.to_str(sf.sf_z)), " "), I64.to_str(sf.sf_fb.fb_width)), "x"), I64.to_str(sf.sf_fb.fb_height)), " vis="), Theme.theme_fmt_bool(sf.sf_visible)), ")")

	format_compositor : Surface.Compositor -> Str
	format_compositor = |comp| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("compositor ", I64.to_str(comp.comp_width)), "x"), I64.to_str(comp.comp_height)), " surfaces="), I64.to_str(comp.comp_count))
}
