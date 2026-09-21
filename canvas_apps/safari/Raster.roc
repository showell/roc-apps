# Raster -- a Safari frame painted into pixels in Roc, for a platform that can
# only show pixels (roc-ray as a framebuffer).
#
# Hand-written. It does what shapewire.js does with a canvas, without one:
# the sky and grass, the sun, then every command in paint order, all turned by
# the camera roll about the screen's centre. A pixel is painted when its centre
# is inside; a polygon fills by the nonzero rule, as the canvas's does. There
# is no anti-aliasing. What a command's paint means, and the colour it gives a
# point, is Brush's. The pixels are 0xRRGGBB, row-major.
#
# The loops are `while` over a `var` list, and every store falls back with
# `crash`: a list threaded down a recursion, or named in a store's fallback, is
# copied on the next store (the list-copying memory in roc-apps' notes).
import Paint
import Sky
import lib.Brush
import SafariBrush
import Num_

Raster :: [].{
	# What a frame shows, in SafariRide's terms.
	Scene : { commands : List(Paint.DrawCmd), roll : F64, sky_top : I64, sky_horizon : I64, sun : Sky.SunPos }

	width : U64
	width = 960

	height : U64
	height = 600

	# The screen's centre, which the roll turns about.
	cx : F64
	cx = 480.0

	cy : F64
	cy = 300.0

	# The roll's cosine and sine. The canvas translates to the centre, rotates
	# by minus the roll and translates back.
	View : { c : F64, s : F64 }

	Pt : { x : F64, y : F64 }

	Cross : { x : F64, w : I64 }

	paint : Raster.Scene -> List(U32)
	paint = |scene| {
		view = view_of(scene.roll)
		var $px = backdrop(view, Brush.opaque(scene.sky_top), Brush.opaque(scene.sky_horizon))
		$px = if scene.sun.visible { paint_sun($px, view, scene.sun) } else { $px }
		n = List.len(scene.commands)
		var $k = 0
		while $k < n {
			c = List.get(scene.commands, $k) ?? crash("command out of range")
			$px = command($px, view, c)
			$k = $k + 1
		}
		$px
	}

	view_of : F64 -> Raster.View
	view_of = |roll| { c: F64.cos(roll), s: F64.sin(roll) }

	# --- Geometry -------------------------------------------------------------

	to_device : Raster.View, F64, F64 -> Raster.Pt
	to_device = |v, x, y| {
		dx = x - cx
		dy = y - cy
		{ x: cx + dx * v.c + dy * v.s, y: cy - dx * v.s + dy * v.c }
	}

	to_scene : Raster.View, F64, F64 -> Raster.Pt
	to_scene = |v, x, y| {
		dx = x - cx
		dy = y - cy
		{ x: cx + dx * v.c - dy * v.s, y: cy + dx * v.s + dy * v.c }
	}

	# The first pixel whose centre is at or past `x`.
	first_center : F64 -> I64
	first_center = |x| {
		bounded = if x < -100000.0 { -100000.0 } else if x > 100000.0 { 100000.0 } else { x }
		F64.to_i64_wrap(Num_.ceil_real(bounded - 0.5))
	}

	at : List(F64), U64 -> F64
	at = |xs, i| List.get(xs, i) ?? 0.0

	# --- Pixels ---------------------------------------------------------------

	byte : F64 -> U32
	byte = |v| {
		n = F64.to_i64_wrap(v + 0.5)
		I64.to_u32_wrap(if n < 0 { 0 } else if n > 255 { 255 } else { n })
	}

	pack : F64, F64, F64 -> U32
	pack = |r, g, b| U32.bitwise_or(U32.bitwise_or(U32.shl_wrap(byte(r), 16), U32.shl_wrap(byte(g), 8)), byte(b))

	unpack : U32, U8 -> F64
	unpack = |p, shift| U32.to_f64(U32.bitwise_and(U32.shr_wrap(p, shift), 255))

	# `src` over the opaque pixel `dst`.
	over : U32, Brush.Rgba -> U32
	over = |dst, src|
		if src.a >= 1.0 {
			pack(src.r, src.g, src.b)
		} else if src.a <= 0.0 {
			dst
		} else {
			k = 1.0 - src.a
			pack(src.r * src.a + unpack(dst, 16) * k, src.g * src.a + unpack(dst, 8) * k, src.b * src.a + unpack(dst, 0) * k)
		}

	blend : List(U32), U64, Brush.Rgba -> List(U32)
	blend = |pixels, idx, src| {
		dst = List.get(pixels, idx) ?? 0
		List.set(pixels, idx, over(dst, src)) ?? crash("pixel out of range")
	}

	# --- The backdrop and the sun ---------------------------------------------

	# The sky band holds the top colour to a fifth of the way down to the
	# horizon, then fades to the horizon colour; the grass starts a pixel above
	# the horizon, which the blitter overlaps to beat a seam under the roll.
	backdrop : Raster.View, Brush.Rgba, Brush.Rgba -> List(U32)
	backdrop = |view, top, horizon| {
		grass = pack(74.0, 143.0, 67.0)
		var $px = List.with_capacity(width * height)
		var $j = 0
		var $i = 0
		while $j < height {
			$i = 0
			while $i < width {
				dx = U64.to_f64($i) + 0.5 - cx
				dy = U64.to_f64($j) + 0.5 - cy
				y = cy + dx * view.s + dy * view.c
				pixel = if y >= 299.0 {
					grass
				} else {
					t = Brush.clamp01(y / 300.0)
					col = if t <= 0.2 { top } else { Brush.mix(top, horizon, (t - 0.2) / 0.8) }
					pack(col.r, col.g, col.b)
				}
				$px = List.append($px, pixel)
				$i = $i + 1
			}
			$j = $j + 1
		}
		$px
	}

	glow_stop0 : Brush.Rgba
	glow_stop0 = { r: 255.0, g: 201.0, b: 128.0, a: 0.85 }

	glow_stop1 : Brush.Rgba
	glow_stop1 = { r: 255.0, g: 150.0, b: 92.0, a: 0.32 }

	glow_stop2 : Brush.Rgba
	glow_stop2 = { r: 255.0, g: 150.0, b: 92.0, a: 0.0 }

	# A warm glow and then the disc, both clipped to the sky, before the
	# commands, so the mountains set the sun behind them.
	paint_sun : List(U32), Raster.View, Sky.SunPos -> List(U32)
	paint_sun = |pixels, view, sun|
		if sun.scale <= 0.0 {
			pixels
		} else {
			glow_in = 8.0 * sun.scale
			glow_out = 340.0 * sun.scale
			disc_in = 4.0 * sun.scale
			disc_r = 46.0 * sun.scale
			disc_c0 = Brush.opaque(0xffe6a3)
			disc_c1 = Brush.opaque(0xff9d5c)
			c = to_device(view, sun.x, sun.y)
			first_row = I64.max(0, first_center(c.y - glow_out))
			last_row = I64.min(599, first_center(c.y + glow_out) - 1)
			first_col = I64.max(0, first_center(c.x - glow_out))
			last_col = I64.min(959, first_center(c.x + glow_out) - 1)
			var $px = pixels
			var $j = first_row
			var $i = first_col
			while $j <= last_row {
				$i = first_col
				while $i <= last_col {
					p = to_scene(view, I64.to_f64($i) + 0.5, I64.to_f64($j) + 0.5)
					$px = if p.x >= 0.0 and p.x < 960.0 and p.y >= 0.0 and p.y < 300.0 {
						idx = I64.to_u64_wrap($j) * width + I64.to_u64_wrap($i)
						d = F64.sqrt((p.x - sun.x) * (p.x - sun.x) + (p.y - sun.y) * (p.y - sun.y))
						t = Brush.clamp01((d - glow_in) / (glow_out - glow_in))
						glow = if t <= 0.4 { Brush.mix(glow_stop0, glow_stop1, t / 0.4) } else { Brush.mix(glow_stop1, glow_stop2, (t - 0.4) / 0.6) }
						lit = blend($px, idx, glow)
						if d < disc_r {
							blend(lit, idx, Brush.mix(disc_c0, disc_c1, Brush.clamp01((d - disc_in) / (disc_r - disc_in))))
						} else {
							lit
						}
					} else {
						$px
					}
					$i = $i + 1
				}
				$j = $j + 1
			}
			$px
		}

	# --- The commands ---------------------------------------------------------

	command : List(U32), Raster.View, Paint.DrawCmd -> List(U32)
	command = |pixels, view, c|
		if c.tag == 3 {
			col = Brush.opaque(c.color)
			disc(pixels, view, at(c.geom, 0), at(c.geom, 1), at(c.geom, 2), { r: col.r, g: col.g, b: col.b, a: c.strength })
		} else {
			fill = SafariBrush.of_command(c)
			match fill {
				Skip => pixels
				_ => fill_polygon(pixels, view, c.pts, fill)
			}
		}

	# A disc at an alpha: the pixels whose centres are strictly inside.
	disc : List(U32), Raster.View, F64, F64, F64, Brush.Rgba -> List(U32)
	disc = |pixels, view, x, y, r, col| {
		c = to_device(view, x, y)
		first_row = I64.max(0, first_center(c.y - r))
		last_row = I64.min(599, first_center(c.y + r) - 1)
		var $px = pixels
		var $j = first_row
		while $j <= last_row {
			dy = I64.to_f64($j) + 0.5 - c.y
			half2 = r * r - dy * dy
			$px = if half2 > 0.0 {
				half = F64.sqrt(half2)
				span($px, view, Flat(col), $j, c.x - half, c.x + half)
			} else {
				$px
			}
			$j = $j + 1
		}
		$px
	}

	# A polygon, as scene points x0, y0, x1, y1, ..., filled by the nonzero rule.
	fill_polygon : List(U32), Raster.View, List(F64), Brush.Fill -> List(U32)
	fill_polygon = |pixels, view, pts, fill| {
		n = List.len(pts) // 2
		if n < 3 {
			pixels
		} else {
			var $dev = List.with_capacity(2 * n)
			var $ymin = 1.0e18
			var $ymax = -1.0e18
			var $k = 0
			while $k < n {
				p = to_device(view, at(pts, 2 * $k), at(pts, 2 * $k + 1))
				$dev = List.append(List.append($dev, p.x), p.y)
				$ymin = F64.min($ymin, p.y)
				$ymax = F64.max($ymax, p.y)
				$k = $k + 1
			}
			dev = $dev
			first_row = I64.max(0, first_center($ymin))
			last_row = I64.min(599, first_center($ymax) - 1)
			var $px = pixels
			var $j = first_row
			var $w = 0
			var $i = 0
			while $j <= last_row {
				xs = crossings(dev, n, I64.to_f64($j) + 0.5)
				m = List.len(xs)
				$w = 0
				$i = 0
				while $i + 1 < m {
					a = List.get(xs, $i) ?? crash("crossing out of range")
					b = List.get(xs, $i + 1) ?? crash("crossing out of range")
					$w = $w + a.w
					$px = if $w != 0 { span($px, view, fill, $j, a.x, b.x) } else { $px }
					$i = $i + 1
				}
				$j = $j + 1
			}
			$px
		}
	}

	# Where the row at `yc` crosses the polygon's edges, left to right, each with
	# the direction its edge runs: an edge holds its upper end and not its lower.
	crossings : List(F64), U64, F64 -> List(Raster.Cross)
	crossings = |dev, n, yc| {
		var $xs = []
		var $k = 0
		while $k < n {
			k1 = if $k + 1 == n { 0 } else { $k + 1 }
			x0 = at(dev, 2 * $k)
			y0 = at(dev, 2 * $k + 1)
			x1 = at(dev, 2 * k1)
			y1 = at(dev, 2 * k1 + 1)
			$xs = if y0 <= yc and yc < y1 {
				List.append($xs, { x: x0 + (yc - y0) * (x1 - x0) / (y1 - y0), w: 1 })
			} else if y1 <= yc and yc < y0 {
				List.append($xs, { x: x0 + (yc - y0) * (x1 - x0) / (y1 - y0), w: -1 })
			} else {
				$xs
			}
			$k = $k + 1
		}
		List.sort_with($xs, |a, b| if a.x < b.x { Before } else if a.x > b.x { After } else { Same })
	}

	# The pixels of row `j` whose centres fall in [xa, xb).
	span : List(U32), Raster.View, Brush.Fill, I64, F64, F64 -> List(U32)
	span = |pixels, view, fill, j, xa, xb| {
		first = I64.max(0, first_center(xa))
		last = I64.min(959, first_center(xb) - 1)
		row = I64.to_u64_wrap(j) * width
		yc = I64.to_f64(j) + 0.5
		var $px = pixels
		var $i = first
		while $i <= last {
			idx = row + I64.to_u64_wrap($i)
			$px = match fill {
				Flat(col) => blend($px, idx, col)
				_ => {
					p = to_scene(view, I64.to_f64($i) + 0.5, yc)
					blend($px, idx, Brush.shade(fill, p.x, p.y))
				}
			}
			$i = $i + 1
		}
		$px
	}
}
