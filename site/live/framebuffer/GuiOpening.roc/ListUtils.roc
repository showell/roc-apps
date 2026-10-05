# ListUtils -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

ListUtils :: [].{

	map_list : (a -> b), List(a) -> List(b)
	map_list = |f, xs| map_list_loop(f, xs, 0, U64.to_i64_wrap(List.len(xs)), [])

	map_list_loop : (a -> b), List(a), I64, I64, List(b) -> List(b)
	map_list_loop = |f, xs, i, len, acc| (if (i == len) { acc } else { map_list_loop(f, xs, (i + 1), len, List.append(acc, f((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })
}
