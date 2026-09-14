# The GPU codex-vm models behind ports 0x400-0x417, drawing into the GOP
# framebuffer (tools/codex-vm.c: gpu_clear_fb, gpu_clear_depth,
# gpu_rasterize_band, gpu_lerp_color, gpu_atmosphere_glow). A program writes
# triangles into the command buffer at 0xBE000000, 72 bytes each, clears the
# framebuffer (port 0x401) and the depth buffer at 0xBE800000 (port 0x402),
# and flushes a count (port 0x400): each triangle is filled where all three
# edge functions agree, its depth and colour interpolated across it, a pixel
# drawn only where it is strictly nearer than what the depth buffer holds;
# then the glow tints the background within 16 pixels of what was drawn.
#
# codex-vm addresses the framebuffer's rows by the visible width, so with a
# padded stride it draws nothing (gop_host_gpu_refuses), and so does this.
# Textured, additive and shadowed triangles, the viewport, the lights and the
# cinematic pass are ports and fields none of this machine's programs use; a
# program that reaches one stops by name.
#
# **ONE LIST HOLDS THE DEPTH BUFFER AND THE FRAMEBUFFER**, depth first. A
# pixel's test and its write touch both, and a loop that updates two lists
# taken from one record makes Roc copy one of them on every write (see
# `reference_roc_list_copying`); one list, read only inside the record update
# that writes it back, is written in place.

MachineGpu :: [].{
	Gpu : {
		width : U64,
		height : U64,
		stride : U64,
		# width * height words of depth, then stride * height words of pixels.
		planes : List(U32),
		# 65,536 triangles of 18 words.
		cmd : List(U32),
		# The glow's distance field and whether it has been computed; codex-vm
		# keeps both between flushes and recomputes the field on frames 1, 5, 9 ...
		glow : List(U8),
		glow_valid : Bool,
		frames : U64,
	}

	cmd_base : I64
	cmd_base = 0xBE000000

	depth_base : I64
	depth_base = 0xBE800000

	fb_base : I64
	fb_base = 0xBF000000

	max_tris : U64
	max_tris = 65536

	depth_far : U32
	depth_far = 999999

	glow_radius : U64
	glow_radius = 16

	# A machine with no screen: codex-vm draws nothing, and the GPU region is
	# ordinary memory.
	none : MachineGpu.Gpu
	none = { width: 0, height: 0, stride: 0, planes: [], cmd: [], glow: [], glow_valid: False, frames: 0 }

	active : MachineGpu.Gpu -> Bool
	active = |g| g.width > 0

	# The framebuffer's stride * height words, as a slice of the planes.
	framebuffer : MachineGpu.Gpu -> List(U32)
	framebuffer = |g| List.sublist(g.planes, { start: g.width * g.height, len: g.stride * g.height })

	new : U64, U64, U64 -> MachineGpu.Gpu
	new = |width, height, stride| {
		width: width,
		height: height,
		stride: stride,
		planes: List.repeat(0, width * height + stride * height),
		cmd: List.repeat(0, MachineGpu.max_tris * 18),
		glow: List.repeat(0, width * height),
		glow_valid: False,
		frames: 0,
	}

	# ---- the region ---------------------------------------------------------

	# The word an address falls in: the command buffer, the depth buffer or the
	# framebuffer, as an index into `cmd` or `planes`, and the byte within it.
	Word : [Cmd(U64, U64), Plane(U64, U64), Outside]

	word_of : MachineGpu.Gpu, I64 -> MachineGpu.Word
	word_of = |g, a|
		if a >= MachineGpu.fb_base and a < MachineGpu.fb_base + U64.to_i64_wrap(g.stride * g.height * 4) {
			off = I64.to_u64_wrap(a - MachineGpu.fb_base)
			Plane(g.width * g.height + U64.div_trunc_by(off, 4), U64.bitwise_and(off, 3))
		} else if a >= MachineGpu.depth_base and a < MachineGpu.depth_base + U64.to_i64_wrap(g.width * g.height * 4) {
			off = I64.to_u64_wrap(a - MachineGpu.depth_base)
			Plane(U64.div_trunc_by(off, 4), U64.bitwise_and(off, 3))
		} else if a >= MachineGpu.cmd_base and a < MachineGpu.cmd_base + U64.to_i64_wrap(MachineGpu.max_tris * 72) {
			off = I64.to_u64_wrap(a - MachineGpu.cmd_base)
			Cmd(U64.div_trunc_by(off, 4), U64.bitwise_and(off, 3))
		} else {
			Outside
		}

	claims : MachineGpu.Gpu, I64 -> Bool
	claims = |g, a|
		match MachineGpu.word_of(g, a) {
			Outside => False
			_ => True
		}

	# `width` bytes from `a`, little-endian; every byte must lie in the region.
	load : MachineGpu.Gpu, I64, I64 -> U64
	load = |g, a, width| {
		var $v = 0
		var $j = width - 1
		while $j >= 0 {
			$v = U64.plus_wrap(U64.times_wrap($v, 256), MachineGpu.byte_at(g, a + $j))
			$j = $j - 1
		}
		$v
	}

	byte_at : MachineGpu.Gpu, I64 -> U64
	byte_at = |g, a|
		match MachineGpu.word_of(g, a) {
			Plane(i, b) => U32.to_u64(U32.bitwise_and(U32.shr_zf_wrap(List.get(g.planes, i) ?? 0, U64.to_u8_wrap(b * 8)), 255))
			Cmd(i, b) => U32.to_u64(U32.bitwise_and(U32.shr_zf_wrap(List.get(g.cmd, i) ?? 0, U64.to_u8_wrap(b * 8)), 255))
			Outside => crash("machine: a read that runs past the GPU region's edge")
		}

	# The low `width` bytes of `u` from `a`, little-endian. A whole aligned word
	# is one set; anything else goes a byte at a time.
	store : MachineGpu.Gpu, I64, U64, I64 -> MachineGpu.Gpu
	store = |g, a, u, width|
		match MachineGpu.word_of(g, a) {
			Plane(i, 0) if width == 4 => { ..g, planes: List.set(g.planes, i, U64.to_u32_wrap(u)) ?? crash("machine: GPU plane index") }
			Cmd(i, 0) if width == 4 => { ..g, cmd: List.set(g.cmd, i, U64.to_u32_wrap(u)) ?? crash("machine: GPU command index") }
			_ => MachineGpu.store_bytes(g, a, u, width)
		}

	store_bytes : MachineGpu.Gpu, I64, U64, I64 -> MachineGpu.Gpu
	store_bytes = |g0, a, u0, width| {
		var $g = g0
		var $u = u0
		var $j = 0
		while $j < width {
			$g = MachineGpu.store_byte($g, a + $j, U64.bitwise_and($u, 255))
			$u = U64.div_trunc_by($u, 256)
			$j = $j + 1
		}
		$g
	}

	store_byte : MachineGpu.Gpu, I64, U64 -> MachineGpu.Gpu
	store_byte = |g, a, b|
		match MachineGpu.word_of(g, a) {
			Plane(i, k) => { ..g, planes: MachineGpu.with_byte(g.planes, i, k, b) }
			Cmd(i, k) => { ..g, cmd: MachineGpu.with_byte(g.cmd, i, k, b) }
			Outside => crash("machine: a write that runs past the GPU region's edge")
		}

	with_byte : List(U32), U64, U64, U64 -> List(U32)
	with_byte = |xs, i, k, b| {
		shift = U64.to_u8_wrap(k * 8)
		old = List.get(xs, i) ?? 0
		cleared = U32.bitwise_and(old, U32.bitwise_xor(U32.shl_wrap(255, shift), 0xFFFFFFFF))
		List.set(xs, i, U32.bitwise_or(cleared, U32.shl_wrap(U64.to_u32_wrap(b), shift))) ?? crash("machine: GPU byte index")
	}

	# ---- the ports ----------------------------------------------------------

	# A write to a port in 0x400-0x417, the value as the program wrote it.
	port_out : MachineGpu.Gpu, U64, U64 -> MachineGpu.Gpu
	port_out = |g, port, v|
		if port == 0x401 {
			MachineGpu.clear(g, U64.to_u32_wrap(v))
		} else if port == 0x402 and U64.bitwise_and(v, 0xFFFFFFFF) == 0 {
			MachineGpu.clear_depth(g)
		} else if port == 0x402 {
			crash("machine: port-out-32 to port 0x402 arms the GPU's shadow map, which this machine does not model")
		} else if port == 0x400 and U64.bitwise_and(v, 0x40000000) != 0 {
			crash("machine: port-out-32 to port 0x400 with the shadow flag, a shadow pass this machine does not model")
		} else if port == 0x403 {
			# The viewport's origin, which does nothing until 0x40F arms it.
			g
		} else if port == 0x40F and U64.bitwise_and(v, 0xFFFFFFFF) == 0 {
			# Zero disarms the viewport, which this machine never arms.
			g
		} else if port == 0x40F {
			crash("machine: port-out-32 to port 0x40F arms the GPU's viewport, which this machine does not model")
		} else if port == 0x410 and U64.bitwise_and(v, 0xFFFFFFFF) == 0 {
			# Zero turns the cinematic pass off, which this machine never turns on.
			g
		} else if port == 0x410 {
			crash("machine: port-out-32 to port 0x410 turns on the GPU's cinematic pass, which this machine does not model")
		} else if port == 0x400 {
			# codex-vm reads the count as an int: one with bit 31 set draws nothing.
			n = I32.to_i64(U32.to_i32_wrap(U64.to_u32_wrap(v)))
			MachineGpu.flush(g, if n < 0 { 0 } else { I64.to_u64_wrap(n) })
		} else {
			crash("machine: port-out-32 to GPU port ${MachineGpu.hex(port)}, which this machine's GPU does not model")
		}

	# A read of a port in 0x400-0x417: 0x403 answers that a rasterizer is there,
	# and 0x40E and 0x40F the size of the last asset loaded, which with no asset
	# loaded is 0.
	port_in : U64 -> U64
	port_in = |port|
		if port == 0x403 {
			1
		} else if port == 0x40E or port == 0x40F {
			0
		} else {
			crash("machine: port-in-32 from GPU port ${MachineGpu.hex(port)}, which this machine's GPU does not model")
		}

	hex : U64 -> Str
	hex = |v| MachineGpu.hex_go(v, 3, "")

	hex_go : U64, U64, Str -> Str
	hex_go = |v, left, acc|
		if left == 0 {
			"0x${acc}"
		} else {
			d = U64.bitwise_and(v, 15)
			c = Str.from_utf8([U64.to_u8_wrap(if d < 10 { 48 + d } else { 55 + d })]) ?? "?"
			MachineGpu.hex_go(U64.shr_zf_wrap(v, 4), left - 1, Str.concat(c, acc))
		}

	# ---- clearing -----------------------------------------------------------

	# Port 0x401: every visible pixel, rows stepped by the width.
	clear : MachineGpu.Gpu, U32 -> MachineGpu.Gpu
	clear = |g, color|
		if g.stride != g.width {
			g
		} else {
			{ ..g, planes: MachineGpu.fill(g.planes, g.width * g.height, g.width * g.height, color) }
		}

	# Port 0x402 with 0: the depth buffer to far.
	clear_depth : MachineGpu.Gpu -> MachineGpu.Gpu
	clear_depth = |g|
		if g.stride != g.width {
			g
		} else {
			{ ..g, planes: MachineGpu.fill(g.planes, 0, g.width * g.height, MachineGpu.depth_far) }
		}

	fill : List(U32), U64, U64, U32 -> List(U32)
	fill = |xs, from, n, v| {
		var $xs = xs
		var $i = from
		while $i < from + n {
			$xs = List.set($xs, $i, v) ?? crash("machine: GPU fill index")
			$i = $i + 1
		}
		$xs
	}

	# ---- drawing ------------------------------------------------------------

	# Port 0x400: the first `count` triangles (at most 65,536), then the glow.
	flush : MachineGpu.Gpu, U64 -> MachineGpu.Gpu
	flush = |g, count|
		if g.stride != g.width {
			g
		} else {
			n = if count > MachineGpu.max_tris { MachineGpu.max_tris } else { count }
			drawn = { ..g, frames: g.frames + 1, planes: MachineGpu.triangles(g.planes, g.cmd, g.width, g.height, n) }
			MachineGpu.glow_pass(drawn)
		}

	triangles : List(U32), List(U32), U64, U64, U64 -> List(U32)
	triangles = |planes, cmd, w, h, n| {
		var $p = planes
		var $t = 0
		while $t < n {
			$p = MachineGpu.triangle($p, cmd, w, h, $t * 18)
			$t = $t + 1
		}
		$p
	}

	# A command word as the int codex-vm reads it.
	int_at : List(U32), U64 -> I64
	int_at = |cmd, i| I32.to_i64(U32.to_i32_wrap(List.get(cmd, i) ?? 0))

	edge : I64, I64, I64, I64, I64, I64 -> I64
	edge = |ax, ay, bx, by, px, py| (bx - ax) * (py - ay) - (by - ay) * (px - ax)

	triangle : List(U32), List(U32), U64, U64, U64 -> List(U32)
	triangle = |planes, cmd, w, h, at| {
		x0 = MachineGpu.int_at(cmd, at)
		y0 = MachineGpu.int_at(cmd, at + 1)
		x1 = MachineGpu.int_at(cmd, at + 2)
		y1 = MachineGpu.int_at(cmd, at + 3)
		x2 = MachineGpu.int_at(cmd, at + 4)
		y2 = MachineGpu.int_at(cmd, at + 5)
		if (List.get(cmd, at + 12) ?? 0) != 0 or (List.get(cmd, at + 13) ?? 0) != 0 or (List.get(cmd, at + 14) ?? 0) != 0 or (List.get(cmd, at + 15) ?? 0) != 0 or (List.get(cmd, at + 16) ?? 0) != 0 or (List.get(cmd, at + 17) ?? 0) != 0 {
			crash("machine: a textured triangle, which this machine's GPU does not draw")
		} else {
			minx = I64.max(I64.min(x0, I64.min(x1, x2)), 0)
			miny = I64.max(I64.min(y0, I64.min(y1, y2)), 0)
			maxx = I64.min(I64.max(x0, I64.max(x1, x2)), U64.to_i64_wrap(w) - 1)
			maxy = I64.min(I64.max(y0, I64.max(y1, y2)), U64.to_i64_wrap(h) - 1)
			area = MachineGpu.edge(x0, y0, x1, y1, x2, y2)
			if minx > maxx or miny > maxy or area == 0 {
				planes
			} else {
				sign = if area > 0 { 1 } else { -1 }
				abs_area = if area > 0 { area } else { 0 - area }
				c0 = List.get(cmd, at + 6) ?? 0
				c1 = List.get(cmd, at + 7) ?? 0
				c2 = List.get(cmd, at + 8) ?? 0
				d0 = MachineGpu.int_at(cmd, at + 9)
				d1 = MachineGpu.int_at(cmd, at + 10)
				d2 = MachineGpu.int_at(cmd, at + 11)
				fb0 = w * h
				var $p = planes
				var $y = miny
				while $y <= maxy {
					var $x = minx
					while $x <= maxx {
						bw0 = MachineGpu.edge(x1, y1, x2, y2, $x, $y) * sign
						bw1 = MachineGpu.edge(x2, y2, x0, y0, $x, $y) * sign
						bw2 = MachineGpu.edge(x0, y0, x1, y1, $x, $y) * sign
						if bw0 >= 0 and bw1 >= 0 and bw2 >= 0 {
							depth = I64.to_u32_wrap(I64.div_trunc_by(d0 * bw0 + d1 * bw1 + d2 * bw2, abs_area))
							idx = I64.to_u64_wrap($y) * w + I64.to_u64_wrap($x)
							if depth < (List.get($p, idx) ?? 0) {
								pixel = MachineGpu.lerp(c0, c1, c2, bw0, bw1, bw2, abs_area)
								$p = List.set(List.set($p, fb0 + idx, pixel) ?? crash("machine: GPU pixel index"), idx, depth) ?? crash("machine: GPU depth index")
							}
						}
						$x = $x + 1
					}
					$y = $y + 1
				}
				$p
			}
		}
	}

	lerp : U32, U32, U32, I64, I64, I64, I64 -> U32
	lerp = |c0, c1, c2, w0, w1, w2, area| {
		r = MachineGpu.channel(c0, c1, c2, 16, w0, w1, w2, area)
		g = MachineGpu.channel(c0, c1, c2, 8, w0, w1, w2, area)
		b = MachineGpu.channel(c0, c1, c2, 0, w0, w1, w2, area)
		U32.bitwise_or(U32.shl_wrap(r, 16), U32.bitwise_or(U32.shl_wrap(g, 8), b))
	}

	channel : U32, U32, U32, U8, I64, I64, I64, I64 -> U32
	channel = |c0, c1, c2, shift, w0, w1, w2, area| {
		k = |c| U32.to_i64(U32.bitwise_and(U32.shr_zf_wrap(c, shift), 255))
		v = I64.div_trunc_by(k(c0) * w0 + k(c1) * w1 + k(c2) * w2, area)
		I64.to_u32_wrap(I64.max(I64.min(v, 255), 0))
	}

	# ---- the glow -----------------------------------------------------------

	# After a flush: every pixel equal to the top-left one is background, the
	# distance from each background pixel to the nearest other pixel is found in
	# two passes of four sweeps, and a background pixel less than 16 away gains
	# 25 red, 55 green and 150 blue scaled by (1 - d/16) cubed. codex-vm computes
	# that in single-precision floats, where every step is exact, so the integer
	# form below is the same number.
	glow_pass : MachineGpu.Gpu -> MachineGpu.Gpu
	glow_pass = |g| {
		fresh =
			if U64.bitwise_and(g.frames, 3) == 1 or !g.glow_valid {
				{ ..g, glow: MachineGpu.distances(g.glow, g.planes, g.width, g.height), glow_valid: True }
			} else {
				g
			}
		{ ..fresh, planes: MachineGpu.tint(fresh.planes, fresh.glow, fresh.width * fresh.height) }
	}

	distances : List(U8), List(U32), U64, U64 -> List(U8)
	distances = |glow, planes, w, h| {
		fb0 = w * h
		bg = List.get(planes, fb0) ?? 0
		var $d = glow
		var $i = 0
		while $i < w * h {
			$d = List.set($d, $i, if (List.get(planes, fb0 + $i) ?? 0) == bg { 255 } else { 0 }) ?? crash("machine: glow index")
			$i = $i + 1
		}
		var $pass = 0
		while $pass < 2 {
			var $y = 0
			while $y < h {
				row = $y * w
				var $x = 1
				while $x < w {
					$d = MachineGpu.relax($d, row + $x, row + $x - 1)
					$x = $x + 1
				}
				var $xb = w - 1
				while $xb > 0 {
					$d = MachineGpu.relax($d, row + $xb - 1, row + $xb)
					$xb = $xb - 1
				}
				$y = $y + 1
			}
			var $cx = 0
			while $cx < w {
				var $cy = 1
				while $cy < h {
					$d = MachineGpu.relax($d, $cy * w + $cx, ($cy - 1) * w + $cx)
					$cy = $cy + 1
				}
				var $cyb = h - 1
				while $cyb > 0 {
					$d = MachineGpu.relax($d, ($cyb - 1) * w + $cx, $cyb * w + $cx)
					$cyb = $cyb - 1
				}
				$cx = $cx + 1
			}
			$pass = $pass + 1
		}
		$d
	}

	# dist[at] becomes dist[from] + 1 where that is smaller.
	relax : List(U8), U64, U64 -> List(U8)
	relax = |d, at, from| {
		here = List.get(d, at) ?? 0
		there = List.get(d, from) ?? 0
		if U8.to_u64(here) > U8.to_u64(there) + 1 {
			List.set(d, at, there + 1) ?? crash("machine: glow index")
		} else {
			d
		}
	}

	tint : List(U32), List(U8), U64 -> List(U32)
	tint = |planes, glow, n| {
		var $p = planes
		var $i = 0
		while $i < n {
			d = U8.to_u64(List.get(glow, $i) ?? 0)
			if d > 0 and d < MachineGpu.glow_radius {
				k = MachineGpu.glow_radius - d
				cube = k * k * k
				px = List.get($p, n + $i) ?? 0
				r = U64.min(U32.to_u64(U32.bitwise_and(U32.shr_zf_wrap(px, 16), 255)) + U64.div_trunc_by(25 * cube, 4096), 255)
				gr = U64.min(U32.to_u64(U32.bitwise_and(U32.shr_zf_wrap(px, 8), 255)) + U64.div_trunc_by(55 * cube, 4096), 255)
				b = U64.min(U32.to_u64(U32.bitwise_and(px, 255)) + U64.div_trunc_by(150 * cube, 4096), 255)
				$p = List.set($p, n + $i, U64.to_u32_wrap(r * 65536 + gr * 256 + b)) ?? crash("machine: glow pixel index")
			}
			$i = $i + 1
		}
		$p
	}
}
