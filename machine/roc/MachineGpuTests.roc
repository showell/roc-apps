# Tests for MachineGpu: `roc test machine/roc/MachineGpuTests.roc`. Small
# screens, with the expected pixels worked out from codex-vm's own arithmetic
# (tools/codex-vm.c: gpu_edge, gpu_rasterize_band, gpu_lerp_color,
# gpu_atmosphere_glow).

import MachineGpu

MachineGpuTests :: [].{
	# The pixel at (x, y), rows stepped by the width.
	pixel : MachineGpu.Gpu, U64, U64 -> U32
	pixel = |g, x, y| List.get(g.planes, g.width * g.height + y * g.width + x) ?? 0

	depth : MachineGpu.Gpu, U64, U64 -> U32
	depth = |g, x, y| List.get(g.planes, y * g.width + x) ?? 0

	# A triangle's 18 words into the command buffer at triangle `t`, through the
	# region's stores as a program's gpu-mem-write reaches them.
	put_tri : MachineGpu.Gpu, U64, List(I64) -> MachineGpu.Gpu
	put_tri = |g0, t, words| {
		var $g = g0
		var $i = 0
		while $i < 18 {
			w = List.get(words, $i) ?? 0
			$g = MachineGpu.store($g, MachineGpu.cmd_base + U64.to_i64_wrap((t * 18 + $i) * 4), I64.to_u64_wrap(w), 4)
			$i = $i + 1
		}
		$g
	}

	# A flat triangle: three corners, one colour, one depth.
	flat : I64, I64, I64, I64, I64, I64, I64, I64 -> List(I64)
	flat = |x0, y0, x1, y1, x2, y2, color, d| [x0, y0, x1, y1, x2, y2, color, color, color, d, d, d, 0, 0, 0, 0, 0, 0]

	count_color : MachineGpu.Gpu, U32 -> U64
	count_color = |g, c| {
		var $n = 0
		var $i = 0
		while $i < g.width * g.height {
			if (List.get(g.planes, g.width * g.height + $i) ?? 0) == c {
				$n = $n + 1
			}
			$i = $i + 1
		}
		$n
	}
}

# A clear paints every visible pixel; a depth clear sets every depth to far.
expect {
	g = MachineGpu.port_out(MachineGpu.port_out(MachineGpu.new(8, 6, 8), 0x401, 0x102030), 0x402, 0)
	MachineGpuTests.count_color(g, 0x102030) == 48 and MachineGpuTests.depth(g, 7, 5) == 999999 and MachineGpuTests.depth(g, 0, 0) == 999999
}

# A padded stride: codex-vm's host GPU draws nothing at all.
expect {
	g = MachineGpu.port_out(MachineGpu.new(8, 6, 12), 0x401, 0x102030)
	MachineGpuTests.pixel(g, 0, 0) == 0
}

# The region: a word at the framebuffer's start is pixel (0, 0); bytes are
# little-endian; the command buffer and depth buffer answer where codex-vm puts
# them.
expect {
	g = MachineGpu.store(MachineGpu.store(MachineGpu.new(8, 6, 8), 0xBF000000, 0xAABBCC, 4), 0xBF000005, 0x77, 1)
	MachineGpuTests.pixel(g, 0, 0) == 0xAABBCC and MachineGpuTests.pixel(g, 1, 0) == 0x7700 and MachineGpu.load(g, 0xBF000000, 4) == 0xAABBCC and MachineGpu.load(g, 0xBF000001, 1) == 0xBB
}
expect {
	g = MachineGpu.store(MachineGpu.new(8, 6, 8), 0xBE800000 + 4 * 9, 1234, 4)
	MachineGpuTests.depth(g, 1, 1) == 1234 and MachineGpu.claims(g, 0xBE000000 + 72 * 65535) and !MachineGpu.claims(g, 0xBF000000 + 8 * 6 * 4)
}

# **EVERY FLUSH ENDS WITH THE GLOW, AND THE GLOW TAKES THE TOP-LEFT PIXEL AS
# THE BACKGROUND.** A triangle drawn over (0, 0) makes its own colour the
# background and gets its edges tinted, as codex-vm's does; the triangles
# below keep (0, 0) clear so the drawn pixels come back unchanged.

# A right triangle with legs along the top and left, (1,1) (5,1) (1,5): the
# edge functions admit (x-1) + (y-1) <= 4, fifteen pixels, drawn nearer than far.
expect {
	cleared = MachineGpu.port_out(MachineGpu.port_out(MachineGpu.new(8, 6, 8), 0x401, 0), 0x402, 0)
	tri = MachineGpuTests.put_tri(cleared, 0, MachineGpuTests.flat(1, 1, 5, 1, 1, 5, 0xFF0000, 100))
	g = MachineGpu.port_out(tri, 0x400, 1)
	MachineGpuTests.count_color(g, 0xFF0000) == 15 and MachineGpuTests.pixel(g, 5, 1) == 0xFF0000 and MachineGpuTests.pixel(g, 4, 3) != 0xFF0000 and MachineGpuTests.depth(g, 2, 2) == 100 and MachineGpuTests.depth(g, 4, 3) == 999999
}

# The same triangle wound the other way draws the same pixels.
expect {
	cleared = MachineGpu.port_out(MachineGpu.port_out(MachineGpu.new(8, 6, 8), 0x401, 0), 0x402, 0)
	g = MachineGpu.port_out(MachineGpuTests.put_tri(cleared, 0, MachineGpuTests.flat(1, 1, 1, 5, 5, 1, 0xFF0000, 100)), 0x400, 1)
	MachineGpuTests.count_color(g, 0xFF0000) == 15
}

# Depth is strictly nearer: a second triangle at the same depth loses, one
# nearer wins.
expect {
	cleared = MachineGpu.port_out(MachineGpu.port_out(MachineGpu.new(8, 6, 8), 0x401, 0), 0x402, 0)
	two = MachineGpuTests.put_tri(MachineGpuTests.put_tri(cleared, 0, MachineGpuTests.flat(1, 1, 5, 1, 1, 5, 0xFF0000, 100)), 1, MachineGpuTests.flat(1, 1, 5, 1, 1, 5, 0x00FF00, 100))
	same = MachineGpu.port_out(two, 0x400, 2)
	three = MachineGpuTests.put_tri(two, 2, MachineGpuTests.flat(1, 1, 5, 1, 1, 5, 0x0000FF, 99))
	nearer = MachineGpu.port_out(three, 0x400, 3)
	MachineGpuTests.count_color(same, 0xFF0000) == 15 and MachineGpuTests.count_color(same, 0x00FF00) == 0 and MachineGpuTests.count_color(nearer, 0x0000FF) == 15
}

# Colour is interpolated by the barycentric weights and truncated: at a corner
# the weight is all on that corner; halfway along the top edge, (3, 1), half on
# each of the first two, (255 * 8) // 16 = 127.
expect {
	cleared = MachineGpu.port_out(MachineGpu.port_out(MachineGpu.new(8, 6, 8), 0x401, 0), 0x402, 0)
	words = [1, 1, 5, 1, 1, 5, 0xFF0000, 0x0000FF, 0x00FF00, 10, 10, 10, 0, 0, 0, 0, 0, 0]
	g = MachineGpu.port_out(MachineGpuTests.put_tri(cleared, 0, words), 0x400, 1)
	MachineGpuTests.pixel(g, 1, 1) == 0xFF0000 and MachineGpuTests.pixel(g, 5, 1) == 0x0000FF and MachineGpuTests.pixel(g, 1, 5) == 0x00FF00 and MachineGpuTests.pixel(g, 3, 1) == 0x7F007F
}

# The glow: a background pixel one step from a drawn one gains
# 25*15^3//4096 = 20 red, 55*15^3//4096 = 45 green and 150*15^3//4096 = 123
# blue; two steps, 25*14^3//4096 = 16, 36 and 100; a drawn pixel and a
# background pixel 16 or more away do not change. The triangle (2,0) (3,0)
# (2,1) covers exactly those three pixels.
expect {
	cleared = MachineGpu.port_out(MachineGpu.port_out(MachineGpu.new(40, 3, 40), 0x401, 0), 0x402, 0)
	g = MachineGpu.port_out(MachineGpuTests.put_tri(cleared, 0, MachineGpuTests.flat(2, 0, 3, 0, 2, 1, 0xFFFFFF, 5)), 0x400, 1)
	MachineGpuTests.pixel(g, 2, 0) == 0xFFFFFF and MachineGpuTests.pixel(g, 4, 0) == 0x142D7B and MachineGpuTests.pixel(g, 5, 0) == 0x102464 and MachineGpuTests.pixel(g, 39, 2) == 0 and MachineGpuTests.count_color(g, 0xFFFFFF) == 3
}

# Disarming the viewport or the cinematic pass, neither ever armed here, and
# setting the viewport's origin change nothing.
expect {
	cleared = MachineGpu.port_out(MachineGpu.new(8, 6, 8), 0x401, 0x445566)
	g = MachineGpu.port_out(MachineGpu.port_out(MachineGpu.port_out(cleared, 0x40F, 0), 0x410, 0), 0x403, 0x00020003)
	g.planes == cleared.planes
}

# The read port: 0x403 says a rasterizer is there. A negative count draws
# nothing and still counts the frame.
expect MachineGpu.port_in(0x403) == 1
expect {
	cleared = MachineGpu.port_out(MachineGpu.port_out(MachineGpu.new(8, 6, 8), 0x401, 0), 0x402, 0)
	g = MachineGpu.port_out(MachineGpuTests.put_tri(cleared, 0, MachineGpuTests.flat(0, 0, 4, 0, 0, 4, 0xFF0000, 100)), 0x400, 0x80000001)
	MachineGpuTests.count_color(g, 0xFF0000) == 0 and g.frames == 1
}
