answer : U64 -> Str
answer = |n| {
	# Edges highest first, so a pass moves a value one step.
	edges = List.map_with_index(List.repeat(0, n - 1), |_, i| { from: n - 1 - i, to: n - 2 - i, cost: 1 })
	relax = |d|
		List.fold(
			edges,
			d,
			|acc, e| {
				via = (List.get(acc, e.to) ?? 1000) + e.cost
				if via < (List.get(acc, e.from) ?? 1000) {
					List.set(acc, e.from, via) ?? crash("relax: out of range")
				} else {
					acc
				}
			},
		)
	start = List.set(List.repeat(1000, n), 0, 0) ?? crash("start")
	var $d = start
	var $next = relax(start)
	var $passes = 1
	while $next != $d {
		$d = $next
		$next = relax($d)
		$passes = $passes + 1
	}
	"passes ${U64.to_str($passes)}: ${Str.join_with(List.map($d, I64.to_str), " ")}"
}

main! = |args| {
	echo!(answer(10 + List.len(args)))
	Ok({})
}
