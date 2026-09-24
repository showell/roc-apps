# Path -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceChar
import CceText

Path :: [].{

	path_separator : I64
	path_separator = 81

	path_join : CceText, CceText -> CceText
	path_join = |a, b| (if (CceText.len(a) == 0) { b } else { (if (CceText.len(b) == 0) { a } else { (if path_ends_with_sep(a) { (if path_is_absolute(b) { CceText.concat(a, CceText.substring(b, 1, (CceText.len(b) - 1))) } else { CceText.concat(a, b) }) } else { (if path_is_absolute(b) { CceText.concat(a, b) } else { CceText.concat(CceText.concat(a, "/"), b) }) }) }) })

	path_ends_with_sep : CceText -> Bool
	path_ends_with_sep = |s| ({
		len = CceText.len(s)
		(if (len == 0) { False } else { (CceChar.code(CceText.char_at(s, (len - 1))) == path_separator) })
	})

	path_parent : CceText -> CceText
	path_parent = |p| ({
		idx = path_last_sep(p)
		(if (idx < 0) { "" } else { CceText.substring(p, 0, idx) })
	})

	path_filename : CceText -> CceText
	path_filename = |p| ({
		idx = path_last_sep(p)
		(if (idx < 0) { p } else { CceText.substring(p, (idx + 1), ((CceText.len(p) - idx) - 1)) })
	})

	path_stem : CceText -> CceText
	path_stem = |p| ({
		name = path_filename(p)
		dot = path_last_dot(name)
		(if (dot <= 0) { name } else { CceText.substring(name, 0, dot) })
	})

	path_extension : CceText -> CceText
	path_extension = |p| ({
		name = path_filename(p)
		dot = path_last_dot(name)
		(if (dot <= 0) { "" } else { CceText.substring(name, (dot + 1), ((CceText.len(name) - dot) - 1)) })
	})

	path_segments : CceText -> List(CceText)
	path_segments = |p| path_split_loop(p, 0, CceText.len(p), 0, [])

	path_split_loop : CceText, I64, I64, I64, List(CceText) -> List(CceText)
	path_split_loop = |s, i, len, start, acc| (if (i >= len) { (if (i > start) { List.append(acc, CceText.substring(s, start, (i - start))) } else { acc }) } else { (if (CceChar.code(CceText.char_at(s, i)) == path_separator) { (if (i > start) { path_split_loop(s, (i + 1), len, (i + 1), List.append(acc, CceText.substring(s, start, (i - start)))) } else { path_split_loop(s, (i + 1), len, (i + 1), acc) }) } else { path_split_loop(s, (i + 1), len, start, acc) }) })

	path_is_absolute : CceText -> Bool
	path_is_absolute = |p| (if (CceText.len(p) == 0) { False } else { (CceChar.code(CceText.char_at(p, 0)) == path_separator) })

	path_has_extension : CceText, CceText -> Bool
	path_has_extension = |p, ext| (path_extension(p) == ext)

	path_normalize : CceText -> CceText
	path_normalize = |p| ({
		segs = path_segments(p)
		clean = path_remove_dots(segs, 0, U64.to_i64_wrap(List.len(segs)), [])
		path_rejoin(clean, 0, U64.to_i64_wrap(List.len(clean)), "", path_is_absolute(p))
	})

	path_remove_dots : List(CceText), I64, I64, List(CceText) -> List(CceText)
	path_remove_dots = |segs, i, len, acc| (if (i >= len) { acc } else { ({
		s = (List.get(segs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (s == ".") { path_remove_dots(segs, (i + 1), len, acc) } else { (if (s == "..") { (if (U64.to_i64_wrap(List.len(acc)) > 0) { path_remove_dots(segs, (i + 1), len, path_drop_last(acc)) } else { path_remove_dots(segs, (i + 1), len, acc) }) } else { path_remove_dots(segs, (i + 1), len, List.append(acc, s)) }) })
	}) })

	path_drop_last : List(CceText) -> List(CceText)
	path_drop_last = |xs| path_take(xs, 0, (U64.to_i64_wrap(List.len(xs)) - 1), [])

	path_take : List(CceText), I64, I64, List(CceText) -> List(CceText)
	path_take = |xs, i, n, acc| (if (i >= n) { acc } else { path_take(xs, (i + 1), n, List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	path_rejoin : List(CceText), I64, I64, CceText, Bool -> CceText
	path_rejoin = |segs, i, len, acc, abs| (if (i >= len) { (if abs { CceText.concat("/", acc) } else { acc }) } else { ({
		sep = (if (i == 0) { "" } else { "/" })
		path_rejoin(segs, (i + 1), len, CceText.concat(CceText.concat(acc, sep), (List.get(segs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), abs)
	}) })

	path_last_sep : CceText -> I64
	path_last_sep = |p| path_scan_back(p, (CceText.len(p) - 1), path_separator)

	path_last_dot : CceText -> I64
	path_last_dot = |p| path_scan_back(p, (CceText.len(p) - 1), 65)

	path_scan_back : CceText, I64, I64 -> I64
	path_scan_back = |s, i, target| (if (i < 0) { (0 - 1) } else { (if (CceChar.code(CceText.char_at(s, i)) == target) { i } else { path_scan_back(s, (i - 1), target) }) })
}
