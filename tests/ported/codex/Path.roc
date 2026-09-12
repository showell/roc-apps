# Path -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Cce

Path :: [].{

	path_separator : I64
	path_separator = 81

	path_join : Str, Str -> Str
	path_join = |a, b| (if (Cce.length(a) == 0) { b } else { (if (Cce.length(b) == 0) { a } else { (if path_ends_with_sep(a) { (if path_is_absolute(b) { Str.concat(a, Cce.substring(b, 1, (Cce.length(b) - 1))) } else { Str.concat(a, b) }) } else { (if path_is_absolute(b) { Str.concat(a, b) } else { Str.concat(Str.concat(a, "/"), b) }) }) }) })

	path_ends_with_sep : Str -> Bool
	path_ends_with_sep = |s| ({
		len = Cce.length(s)
		(if (len == 0) { False } else { (Cce.at_or_crash(s, (len - 1)) == path_separator) })
	})

	path_parent : Str -> Str
	path_parent = |p| ({
		idx = path_last_sep(p)
		(if (idx < 0) { "" } else { Cce.substring(p, 0, idx) })
	})

	path_filename : Str -> Str
	path_filename = |p| ({
		idx = path_last_sep(p)
		(if (idx < 0) { p } else { Cce.substring(p, (idx + 1), ((Cce.length(p) - idx) - 1)) })
	})

	path_stem : Str -> Str
	path_stem = |p| ({
		name = path_filename(p)
		dot = path_last_dot(name)
		(if (dot <= 0) { name } else { Cce.substring(name, 0, dot) })
	})

	path_extension : Str -> Str
	path_extension = |p| ({
		name = path_filename(p)
		dot = path_last_dot(name)
		(if (dot <= 0) { "" } else { Cce.substring(name, (dot + 1), ((Cce.length(name) - dot) - 1)) })
	})

	path_segments : Str -> List(Str)
	path_segments = |p| path_split_loop(p, 0, Cce.length(p), 0, [])

	path_split_loop : Str, I64, I64, I64, List(Str) -> List(Str)
	path_split_loop = |s, i, len, start, acc| (if (i >= len) { (if (i > start) { List.append(acc, Cce.substring(s, start, (i - start))) } else { acc }) } else { (if (Cce.at_or_crash(s, i) == path_separator) { (if (i > start) { path_split_loop(s, (i + 1), len, (i + 1), List.append(acc, Cce.substring(s, start, (i - start)))) } else { path_split_loop(s, (i + 1), len, (i + 1), acc) }) } else { path_split_loop(s, (i + 1), len, start, acc) }) })

	path_is_absolute : Str -> Bool
	path_is_absolute = |p| (if (Cce.length(p) == 0) { False } else { (Cce.at_or_crash(p, 0) == path_separator) })

	path_has_extension : Str, Str -> Bool
	path_has_extension = |p, ext| (path_extension(p) == ext)

	path_normalize : Str -> Str
	path_normalize = |p| ({
		segs = path_segments(p)
		clean = path_remove_dots(segs, 0, U64.to_i64_wrap(List.len(segs)), [])
		path_rejoin(clean, 0, U64.to_i64_wrap(List.len(clean)), "", path_is_absolute(p))
	})

	path_remove_dots : List(Str), I64, I64, List(Str) -> List(Str)
	path_remove_dots = |segs, i, len, acc| (if (i >= len) { acc } else { ({
		s = (List.get(segs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (s == ".") { path_remove_dots(segs, (i + 1), len, acc) } else { (if (s == "..") { (if (U64.to_i64_wrap(List.len(acc)) > 0) { path_remove_dots(segs, (i + 1), len, path_drop_last(acc)) } else { path_remove_dots(segs, (i + 1), len, acc) }) } else { path_remove_dots(segs, (i + 1), len, List.append(acc, s)) }) })
	}) })

	path_drop_last : List(Str) -> List(Str)
	path_drop_last = |xs| path_take(xs, 0, (U64.to_i64_wrap(List.len(xs)) - 1), [])

	path_take : List(Str), I64, I64, List(Str) -> List(Str)
	path_take = |xs, i, n, acc| (if (i >= n) { acc } else { path_take(xs, (i + 1), n, List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	path_rejoin : List(Str), I64, I64, Str, Bool -> Str
	path_rejoin = |segs, i, len, acc, abs| (if (i >= len) { (if abs { Str.concat("/", acc) } else { acc }) } else { ({
		sep = (if (i == 0) { "" } else { "/" })
		path_rejoin(segs, (i + 1), len, Str.concat(Str.concat(acc, sep), (List.get(segs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), abs)
	}) })

	path_last_sep : Str -> I64
	path_last_sep = |p| path_scan_back(p, (Cce.length(p) - 1), path_separator)

	path_last_dot : Str -> I64
	path_last_dot = |p| path_scan_back(p, (Cce.length(p) - 1), 65)

	path_scan_back : Str, I64, I64 -> I64
	path_scan_back = |s, i, target| (if (i < 0) { (0 - 1) } else { (if (Cce.at_or_crash(s, i) == target) { i } else { path_scan_back(s, (i - 1), target) }) })
}
