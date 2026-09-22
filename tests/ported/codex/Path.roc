# Path -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Text

Path :: [].{

	path_separator : I64
	path_separator = 81

	path_join : List(U8), List(U8) -> List(U8)
	path_join = |a, b| (if (Text.len(a) == 0) { b } else { (if (Text.len(b) == 0) { a } else { (if path_ends_with_sep(a) { (if path_is_absolute(b) { List.concat(a, Text.substring(b, 1, (Text.len(b) - 1))) } else { List.concat(a, b) }) } else { (if path_is_absolute(b) { List.concat(a, b) } else { List.concat(List.concat(a, [81]), b) }) }) }) })

	path_ends_with_sep : List(U8) -> Bool
	path_ends_with_sep = |s| ({
		len = Text.len(s)
		(if (len == 0) { False } else { (Text.char_at(s, (len - 1)) == path_separator) })
	})

	path_parent : List(U8) -> List(U8)
	path_parent = |p| ({
		idx = path_last_sep(p)
		(if (idx < 0) { [] } else { Text.substring(p, 0, idx) })
	})

	path_filename : List(U8) -> List(U8)
	path_filename = |p| ({
		idx = path_last_sep(p)
		(if (idx < 0) { p } else { Text.substring(p, (idx + 1), ((Text.len(p) - idx) - 1)) })
	})

	path_stem : List(U8) -> List(U8)
	path_stem = |p| ({
		name = path_filename(p)
		dot = path_last_dot(name)
		(if (dot <= 0) { name } else { Text.substring(name, 0, dot) })
	})

	path_extension : List(U8) -> List(U8)
	path_extension = |p| ({
		name = path_filename(p)
		dot = path_last_dot(name)
		(if (dot <= 0) { [] } else { Text.substring(name, (dot + 1), ((Text.len(name) - dot) - 1)) })
	})

	path_segments : List(U8) -> List(List(U8))
	path_segments = |p| path_split_loop(p, 0, Text.len(p), 0, [])

	path_split_loop : List(U8), I64, I64, I64, List(List(U8)) -> List(List(U8))
	path_split_loop = |s, i, len, start, acc| (if (i >= len) { (if (i > start) { List.append(acc, Text.substring(s, start, (i - start))) } else { acc }) } else { (if (Text.char_at(s, i) == path_separator) { (if (i > start) { path_split_loop(s, (i + 1), len, (i + 1), List.append(acc, Text.substring(s, start, (i - start)))) } else { path_split_loop(s, (i + 1), len, (i + 1), acc) }) } else { path_split_loop(s, (i + 1), len, start, acc) }) })

	path_is_absolute : List(U8) -> Bool
	path_is_absolute = |p| (if (Text.len(p) == 0) { False } else { (Text.char_at(p, 0) == path_separator) })

	path_has_extension : List(U8), List(U8) -> Bool
	path_has_extension = |p, ext| (path_extension(p) == ext)

	path_normalize : List(U8) -> List(U8)
	path_normalize = |p| ({
		segs = path_segments(p)
		clean = path_remove_dots(segs, 0, U64.to_i64_wrap(List.len(segs)), [])
		path_rejoin(clean, 0, U64.to_i64_wrap(List.len(clean)), [], path_is_absolute(p))
	})

	path_remove_dots : List(List(U8)), I64, I64, List(List(U8)) -> List(List(U8))
	path_remove_dots = |segs, i, len, acc| (if (i >= len) { acc } else { ({
		s = (List.get(segs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (s == [65]) { path_remove_dots(segs, (i + 1), len, acc) } else { (if (s == [65, 65]) { (if (U64.to_i64_wrap(List.len(acc)) > 0) { path_remove_dots(segs, (i + 1), len, path_drop_last(acc)) } else { path_remove_dots(segs, (i + 1), len, acc) }) } else { path_remove_dots(segs, (i + 1), len, List.append(acc, s)) }) })
	}) })

	path_drop_last : List(List(U8)) -> List(List(U8))
	path_drop_last = |xs| path_take(xs, 0, (U64.to_i64_wrap(List.len(xs)) - 1), [])

	path_take : List(List(U8)), I64, I64, List(List(U8)) -> List(List(U8))
	path_take = |xs, i, n, acc| (if (i >= n) { acc } else { path_take(xs, (i + 1), n, List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	path_rejoin : List(List(U8)), I64, I64, List(U8), Bool -> List(U8)
	path_rejoin = |segs, i, len, acc, abs| (if (i >= len) { (if abs { List.concat([81], acc) } else { acc }) } else { ({
		sep = (if (i == 0) { [] } else { [81] })
		path_rejoin(segs, (i + 1), len, List.concat(List.concat(acc, sep), (List.get(segs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), abs)
	}) })

	path_last_sep : List(U8) -> I64
	path_last_sep = |p| path_scan_back(p, (Text.len(p) - 1), path_separator)

	path_last_dot : List(U8) -> I64
	path_last_dot = |p| path_scan_back(p, (Text.len(p) - 1), 65)

	path_scan_back : List(U8), I64, I64 -> I64
	path_scan_back = |s, i, target| (if (i < 0) { (0 - 1) } else { (if (Text.char_at(s, i) == target) { i } else { path_scan_back(s, (i - 1), target) }) })
}
