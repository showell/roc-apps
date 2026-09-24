# Canvas -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Canvas :: [].{
	ViewPort := { vp_pan_x : I64, vp_pan_y : I64, vp_zoom : I64, vp_grid : I64, vp_canvas_x : I64, vp_canvas_y : I64, vp_canvas_w : I64, vp_canvas_h : I64 }.{
		is_eq : Canvas.ViewPort, Canvas.ViewPort -> Bool
		is_eq = |a, b| a.vp_pan_x == b.vp_pan_x and a.vp_pan_y == b.vp_pan_y and a.vp_zoom == b.vp_zoom and a.vp_grid == b.vp_grid and a.vp_canvas_x == b.vp_canvas_x and a.vp_canvas_y == b.vp_canvas_y and a.vp_canvas_w == b.vp_canvas_w and a.vp_canvas_h == b.vp_canvas_h
	}

	viewport_new : I64, I64, I64, I64 -> Canvas.ViewPort
	viewport_new = |cx, cy, cw, ch| Canvas.ViewPort.{ vp_pan_x: 0, vp_pan_y: 0, vp_zoom: 100, vp_grid: 20, vp_canvas_x: cx, vp_canvas_y: cy, vp_canvas_w: cw, vp_canvas_h: ch }

	viewport_pan : Canvas.ViewPort, I64, I64 -> Canvas.ViewPort
	viewport_pan = |vp, dx, dy| Canvas.ViewPort.{ vp_pan_x: (vp.vp_pan_x + dx), vp_pan_y: (vp.vp_pan_y + dy), vp_zoom: vp.vp_zoom, vp_grid: vp.vp_grid, vp_canvas_x: vp.vp_canvas_x, vp_canvas_y: vp.vp_canvas_y, vp_canvas_w: vp.vp_canvas_w, vp_canvas_h: vp.vp_canvas_h }

	viewport_zoom_in : Canvas.ViewPort -> Canvas.ViewPort
	viewport_zoom_in = |vp| ({
		nz : I64
		nz = (if (vp.vp_zoom < 50) { (vp.vp_zoom + 10) } else { (if (vp.vp_zoom < 200) { (vp.vp_zoom + 25) } else { (if (vp.vp_zoom < 800) { (vp.vp_zoom + 50) } else { vp.vp_zoom }) }) })
		clamped : I64
		clamped = (if (nz > 800) { 800 } else { nz })
		Canvas.ViewPort.{ vp_pan_x: vp.vp_pan_x, vp_pan_y: vp.vp_pan_y, vp_zoom: clamped, vp_grid: vp.vp_grid, vp_canvas_x: vp.vp_canvas_x, vp_canvas_y: vp.vp_canvas_y, vp_canvas_w: vp.vp_canvas_w, vp_canvas_h: vp.vp_canvas_h }
	})

	viewport_zoom_out : Canvas.ViewPort -> Canvas.ViewPort
	viewport_zoom_out = |vp| ({
		nz : I64
		nz = (if (vp.vp_zoom <= 25) { 10 } else { (if (vp.vp_zoom <= 50) { (vp.vp_zoom - 10) } else { (if (vp.vp_zoom <= 200) { (vp.vp_zoom - 25) } else { (vp.vp_zoom - 50) }) }) })
		clamped : I64
		clamped = (if (nz < 10) { 10 } else { nz })
		Canvas.ViewPort.{ vp_pan_x: vp.vp_pan_x, vp_pan_y: vp.vp_pan_y, vp_zoom: clamped, vp_grid: vp.vp_grid, vp_canvas_x: vp.vp_canvas_x, vp_canvas_y: vp.vp_canvas_y, vp_canvas_w: vp.vp_canvas_w, vp_canvas_h: vp.vp_canvas_h }
	})

	viewport_zoom_fit : Canvas.ViewPort -> Canvas.ViewPort
	viewport_zoom_fit = |vp| Canvas.ViewPort.{ vp_pan_x: 0, vp_pan_y: 0, vp_zoom: 100, vp_grid: vp.vp_grid, vp_canvas_x: vp.vp_canvas_x, vp_canvas_y: vp.vp_canvas_y, vp_canvas_w: vp.vp_canvas_w, vp_canvas_h: vp.vp_canvas_h }

	vp_screen_to_world_x : Canvas.ViewPort, I64 -> I64
	vp_screen_to_world_x = |vp, sx| (I64.div_trunc_by((((sx - vp.vp_canvas_x) - I64.div_trunc_by(vp.vp_canvas_w, 2)) * 100), vp.vp_zoom) - vp.vp_pan_x)

	vp_screen_to_world_y : Canvas.ViewPort, I64 -> I64
	vp_screen_to_world_y = |vp, sy| (I64.div_trunc_by((((sy - vp.vp_canvas_y) - I64.div_trunc_by(vp.vp_canvas_h, 2)) * 100), vp.vp_zoom) - vp.vp_pan_y)

	vp_world_to_screen_x : Canvas.ViewPort, I64 -> I64
	vp_world_to_screen_x = |vp, wx| ((vp.vp_canvas_x + I64.div_trunc_by(vp.vp_canvas_w, 2)) + I64.div_trunc_by(((wx + vp.vp_pan_x) * vp.vp_zoom), 100))

	vp_world_to_screen_y : Canvas.ViewPort, I64 -> I64
	vp_world_to_screen_y = |vp, wy| ((vp.vp_canvas_y + I64.div_trunc_by(vp.vp_canvas_h, 2)) + I64.div_trunc_by(((wy + vp.vp_pan_y) * vp.vp_zoom), 100))

	vp_snap_to_grid : I64, I64 -> I64
	vp_snap_to_grid = |val, grid| (if (grid <= 0) { val } else { ({
		half : I64
		half = I64.div_trunc_by(grid, 2)
		(if (val >= 0) { (I64.div_trunc_by((val + half), grid) * grid) } else { (0 - (I64.div_trunc_by(((0 - val) + half), grid) * grid)) })
	}) })

	vp_contains : Canvas.ViewPort, I64, I64 -> Bool
	vp_contains = |vp, sx, sy| (if (sx < vp.vp_canvas_x) { False } else { (if (sx >= (vp.vp_canvas_x + vp.vp_canvas_w)) { False } else { (if (sy < vp.vp_canvas_y) { False } else { (if (sy >= (vp.vp_canvas_y + vp.vp_canvas_h)) { False } else { True }) }) }) })

	vp_set_canvas : Canvas.ViewPort, I64, I64, I64, I64 -> Canvas.ViewPort
	vp_set_canvas = |vp, cx, cy, cw, ch| Canvas.ViewPort.{ vp_pan_x: vp.vp_pan_x, vp_pan_y: vp.vp_pan_y, vp_zoom: vp.vp_zoom, vp_grid: vp.vp_grid, vp_canvas_x: cx, vp_canvas_y: cy, vp_canvas_w: cw, vp_canvas_h: ch }
}
