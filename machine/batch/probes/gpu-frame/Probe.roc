import MachineGpu

# The whole of a frame at a width from the command line (the height is three
# quarters of it): clear, clear the depth buffer, two triangles covering the
# screen written a word at a time into the command buffer, then flush.
put : MachineGpu.Gpu, U64, List(I64) -> MachineGpu.Gpu
put = |g0, t, words| {
	var $g = g0
	var $i = 0
	while $i < 18 {
		w = List.get(words, $i) ?? 0
		$g = MachineGpu.store($g, MachineGpu.cmd_base + U64.to_i64_wrap((t * 18 + $i) * 4), I64.to_u64_wrap(w), 4)
		$i = $i + 1
	}
	$g
}

drawn : MachineGpu.Gpu -> U64
drawn = |g| {
	var $n = 0
	var $i = 0
	while $i < g.width * g.height {
		if (List.get(g.planes, g.width * g.height + $i) ?? 0) != 0x102030 {
			$n = $n + 1
		}
		$i = $i + 1
	}
	$n
}

main! = |args| {
	w = U64.from_str(List.get(args, 0) ?? "160") ?? 160
	h = U64.div_trunc_by(w * 3, 4)
	stage = List.get(args, 1) ?? "all"
	wi = U64.to_i64_wrap(w) - 1
	hi = U64.to_i64_wrap(h) - 1
	g0 = MachineGpu.new(w, h, w)
	g1 = MachineGpu.port_out(MachineGpu.port_out(g0, 0x401, 0x102030), 0x402, 0)
	g2 = if stage == "clear" { g1 } else { put(put(g1, 0, [0, 0, wi, 0, 0, hi, 0xFF0000, 0x00FF00, 0x0000FF, 100, 100, 100, 0, 0, 0, 0, 0, 0]), 1, [wi, 0, wi, hi, 0, hi, 0x00FF00, 0x0000FF, 0xFF0000, 200, 200, 200, 0, 0, 0, 0, 0, 0]) }
	g3 = if stage == "clear" { g2 } else { MachineGpu.port_out(g2, 0x400, 2) }
	echo!(Str.concat(U64.to_str(drawn(g3)), "\n"))
	Ok({})
}
