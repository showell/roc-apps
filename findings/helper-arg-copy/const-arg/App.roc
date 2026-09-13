import Vec

M : { fuel : I64, mem : Vec.V(U8) }

settle : M, I64 -> M
settle = |m, _x| m

do_poke : M, U64 -> M
do_poke = |m, a| {
	d = settle(m, 0)
	{ ..d, mem: Vec.set(d.mem, a, 7) }
}

main! = |args| {
	a = 262144 + List.len(args)
	var $m = { fuel: U64.to_i64_wrap(10000 + List.len(args)), mem: Vec.repeat(16777216, 0) }
	while $m.fuel > 0 {
		$m = do_poke({ ..$m, fuel: $m.fuel - 1 }, a)
	}
	echo!(U8.to_str(Vec.get($m.mem, a, 0)))
	Ok({})
}
