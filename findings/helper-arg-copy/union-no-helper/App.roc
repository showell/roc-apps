T : [Leaf(List(U8)), Node(List(List(U8)))]

M : { fuel : I64, mem : T }

set_t : T, U64, U8 -> T
set_t = |t, i, x| match t {
	Leaf(xs) => Leaf(List.set(xs, i, x) ?? crash("leaf"))
	Node(ks) => {
		c = U64.div_trunc_by(i, 32)
		taken = List.replace(ks, c, []) ?? crash("node")
		Node(List.set(taken.list, c, List.set(taken.prev, U64.rem_by(i, 32), x) ?? crash("inner")) ?? crash("node"))
	}
}

get_t : T, U64 -> U8
get_t = |t, i| match t {
	Leaf(xs) => List.get(xs, i) ?? 0
	Node(ks) => List.get(List.get(ks, U64.div_trunc_by(i, 32)) ?? [], U64.rem_by(i, 32)) ?? 0
}

settle : M, I64 -> M
settle = |m, _x| m

do_poke : M, U64 -> M
do_poke = |m, a| {
	{ ..m, mem: set_t(m.mem, a, 7) }
}

main! = |args| {
	a = 100 + List.len(args)
	var $m = { fuel: U64.to_i64_wrap(10000 + List.len(args)), mem: Node(List.repeat(List.repeat(0, 32), 32)) }
	while $m.fuel > 0 {
		$m = do_poke({ ..$m, fuel: $m.fuel - 1 }, a)
	}
	echo!(U8.to_str(get_t($m.mem, a)))
	Ok({})
}
