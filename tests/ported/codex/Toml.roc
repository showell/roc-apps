# Toml -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceChar
import CceText
import Maybe

Toml :: [].{
	TomlValue := [TomlString(CceText), TomlInteger(I64), TomlBool(Bool), TomlArray(List(Toml.TomlValue)), TomlTable(List(Toml.TomlPair)), TomlDatetime(CceText)].{
		is_eq : Toml.TomlValue, Toml.TomlValue -> Bool
		is_eq = |a, b| eq_TomlValue(a, b)
	}
	TomlPair := { tp_key : CceText, tp_value : Toml.TomlValue }.{
		is_eq : Toml.TomlPair, Toml.TomlPair -> Bool
		is_eq = |a, b| eq_TomlPair(a, b)
	}

	toml_string : CceText -> Toml.TomlValue
	toml_string = |s| TomlString(s)

	toml_integer : I64 -> Toml.TomlValue
	toml_integer = |n| TomlInteger(n)

	toml_bool : Bool -> Toml.TomlValue
	toml_bool = |b| TomlBool(b)

	toml_table : List(Toml.TomlPair) -> Toml.TomlValue
	toml_table = |pairs| TomlTable(pairs)

	toml_pair : CceText, Toml.TomlValue -> Toml.TomlPair
	toml_pair = |k, v| Toml.TomlPair.{ tp_key: k, tp_value: v }

	toml_empty : Toml.TomlValue
	toml_empty = TomlTable([])

	toml_get : Toml.TomlValue, CceText -> Maybe.Maybe(Toml.TomlValue)
	toml_get = |v, key| (match v {
		TomlTable(pairs) => toml_find_pair(pairs, key, 0, U64.to_i64_wrap(List.len(pairs)))
		_ => None
	})

	toml_find_pair : List(Toml.TomlPair), CceText, I64, I64 -> Maybe.Maybe(Toml.TomlValue)
	toml_find_pair = |pairs, key, i, len| (if (i >= len) { None } else { ({
		p = (List.get(pairs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (p.tp_key == key) { Just(p.tp_value) } else { toml_find_pair(pairs, key, (i + 1), len) })
	}) })

	toml_get_str : Toml.TomlValue, CceText, CceText -> CceText
	toml_get_str = |v, key, default| (match toml_get(v, key) {
		Just(val) => (match val {
			TomlString(s) => s
			_ => default
		})
		None => default
	})

	toml_get_int : Toml.TomlValue, CceText, I64 -> I64
	toml_get_int = |v, key, default| (match toml_get(v, key) {
		Just(val) => (match val {
			TomlInteger(n) => n
			_ => default
		})
		None => default
	})

	toml_get_bool : Toml.TomlValue, CceText, Bool -> Bool
	toml_get_bool = |v, key, default| (match toml_get(v, key) {
		Just(val) => (match val {
			TomlBool(b) => b
			_ => default
		})
		None => default
	})

	toml_get_path : Toml.TomlValue, List(CceText) -> Maybe.Maybe(Toml.TomlValue)
	toml_get_path = |v, keys| toml_walk(v, keys, 0, U64.to_i64_wrap(List.len(keys)))

	toml_walk : Toml.TomlValue, List(CceText), I64, I64 -> Maybe.Maybe(Toml.TomlValue)
	toml_walk = |v, keys, i, len| (if (i >= len) { Just(v) } else { (match toml_get(v, (List.get(keys, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) {
		Just(child) => toml_walk(child, keys, (i + 1), len)
		None => None
	}) })

	toml_parse : CceText -> Maybe.Maybe(Toml.TomlValue)
	toml_parse = |input| ({
		lines : List(CceText)
		lines = CceText.split(input, "\n")
		toml_parse_lines_v1 = toml_parse_lines(lines, 0, U64.to_i64_wrap(List.len(lines)), [], "", [], toml_slots(U64.to_i64_wrap(List.len(lines))))
		toml_parse_lines_v1.0
	})

	toml_parse_lines : List(CceText), I64, I64, List(Toml.TomlPair), CceText, List(Toml.TomlPair), List(CceText) -> (Maybe.Maybe(Toml.TomlValue), List(CceText))
	toml_parse_lines = |lines, i, len, top, tname, tpairs, seen| (if (i >= len) { (Just(TomlTable(toml_close_table(top, tname, tpairs))), seen) } else { ({
		line : CceText
		line = toml_trim((List.get(lines, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))
		(if (CceText.len(line) == 0) { toml_parse_lines(lines, (i + 1), len, top, tname, tpairs, seen) } else { (if toml_starts_with(line, "#") { toml_parse_lines(lines, (i + 1), len, top, tname, tpairs, seen) } else { (if toml_starts_with(line, "[") { ({
			name : CceText
			name = toml_header_name(line)
			(if (CceText.len(name) == 0) { (None, seen) } else { ({
				slot : I64
				slot = toml_slot(seen, CceText.concat(".", name))
				(if (CceText.len((List.get(seen, I64.to_u64_wrap(slot)) ?? crash("list-at out of range"))) > 0) { (None, seen) } else { ({
					seen_v1 : List(CceText)
					seen_v1 = (List.set(seen, I64.to_u64_wrap(slot), CceText.concat(".", name)) ?? crash("list-set-at past the end"))
					toml_parse_lines(lines, (i + 1), len, toml_close_table(top, tname, tpairs), name, [], seen_v1)
				}) })
			}) })
		}) } else { (match toml_parse_kv(line) {
			None => (None, seen)
			Just(kv) => ({
				full : CceText
				full = CceText.concat(CceText.concat(tname, "."), kv.tp_key)
				slot : I64
				slot = toml_slot(seen, full)
				(if (CceText.len((List.get(seen, I64.to_u64_wrap(slot)) ?? crash("list-at out of range"))) > 0) { (None, seen) } else { (if (CceText.len(tname) == 0) { ({
					seen_v2 : List(CceText)
					seen_v2 = (List.set(seen, I64.to_u64_wrap(slot), full) ?? crash("list-set-at past the end"))
					toml_parse_lines(lines, (i + 1), len, List.append(top, kv), tname, tpairs, seen_v2)
				}) } else { ({
					seen_v3 : List(CceText)
					seen_v3 = (List.set(seen, I64.to_u64_wrap(slot), full) ?? crash("list-set-at past the end"))
					toml_parse_lines(lines, (i + 1), len, top, tname, List.append(tpairs, kv), seen_v3)
				}) }) })
			})
		}) }) }) })
	}) })

	toml_slots : I64 -> List(CceText)
	toml_slots = |n| toml_fill_slots(0, toml_capacity(n, 16), [])

	toml_capacity : I64, I64 -> I64
	toml_capacity = |n, c| (if (c >= ((2 * n) + 2)) { c } else { toml_capacity(n, (c * 2)) })

	toml_fill_slots : I64, I64, List(CceText) -> List(CceText)
	toml_fill_slots = |i, cap, acc| (if (i >= cap) { acc } else { toml_fill_slots((i + 1), cap, List.append(acc, "")) })

	toml_slot : List(CceText), CceText -> I64
	toml_slot = |slots, name| ({
		mask : I64
		mask = (U64.to_i64_wrap(List.len(slots)) - 1)
		toml_probe(slots, name, I64.bitwise_and(toml_hash(name, 0, CceText.len(name), 5381), mask), mask)
	})

	toml_probe : List(CceText), CceText, I64, I64 -> I64
	toml_probe = |slots, name, i, mask| ({
		s : CceText
		s = (List.get(slots, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (CceText.len(s) == 0) { i } else { (if (s == name) { i } else { toml_probe(slots, name, I64.bitwise_and((i + 1), mask), mask) }) })
	})

	toml_hash : CceText, I64, I64, I64 -> I64
	toml_hash = |s, i, n, h| (if (i >= n) { h } else { toml_hash(s, (i + 1), n, I64.bitwise_and(((h * 31) + CceText.char_code_at(s, i)), 16777215)) })

	toml_close_table : List(Toml.TomlPair), CceText, List(Toml.TomlPair) -> List(Toml.TomlPair)
	toml_close_table = |top, tname, tpairs| (if (CceText.len(tname) == 0) { top } else { List.append(top, Toml.TomlPair.{ tp_key: tname, tp_value: TomlTable(tpairs) }) })

	toml_header_name : CceText -> CceText
	toml_header_name = |line| ({
		close : I64
		close = toml_find_char(line, CceText.char_code_at("]", 0), 1, CceText.len(line))
		(if (close < 0) { "" } else { (if toml_rest_ok(line, (close + 1)) { ({
			name : CceText
			name = toml_trim(CceText.substring(line, 1, (close - 1)))
			(if toml_bare_key(name) { name } else { "" })
		}) } else { "" }) })
	})

	toml_parse_kv : CceText -> Maybe.Maybe(Toml.TomlPair)
	toml_parse_kv = |line| ({
		eq_pos : I64
		eq_pos = toml_find_char(line, CceText.char_code_at("=", 0), 0, CceText.len(line))
		(if (eq_pos < 0) { None } else { ({
			key : CceText
			key = toml_trim(CceText.substring(line, 0, eq_pos))
			(if toml_bare_key(key) { (match toml_parse_value(toml_trim(CceText.substring(line, (eq_pos + 1), ((CceText.len(line) - eq_pos) - 1)))) {
				Just(v) => Just(Toml.TomlPair.{ tp_key: key, tp_value: v })
				None => None
			}) } else { None })
		}) })
	})

	toml_parse_value : CceText -> Maybe.Maybe(Toml.TomlValue)
	toml_parse_value = |s| (if toml_starts_with(s, "\"") { toml_quoted(s, "\"", True) } else { (if toml_starts_with(s, "'") { toml_quoted(s, "'", False) } else { ({
		bare : CceText
		bare = toml_strip_comment(s)
		(if (bare == "true") { Just(TomlBool(True)) } else { (if (bare == "false") { Just(TomlBool(False)) } else { (if toml_decimal(bare) { Just(TomlInteger(toml_integer_value(bare))) } else { None }) }) })
	}) }) })

	toml_quoted : CceText, CceText, Bool -> Maybe.Maybe(Toml.TomlValue)
	toml_quoted = |s, quote, basic| ({
		close : I64
		close = toml_find_char(s, CceText.char_code_at(quote, 0), 1, CceText.len(s))
		(if (close < 0) { None } else { ({
			inner : CceText
			inner = CceText.substring(s, 1, (close - 1))
			(if basic { (if CceText.contains(inner, "\\") { None } else { (if toml_rest_ok(s, (close + 1)) { Just(TomlString(inner)) } else { None }) }) } else { (if toml_rest_ok(s, (close + 1)) { Just(TomlString(inner)) } else { None }) })
		}) })
	})

	toml_integer_value : CceText -> I64
	toml_integer_value = |s| (if toml_starts_with(s, "+") { CceText.to_integer(CceText.substring(s, 1, (CceText.len(s) - 1))) } else { CceText.to_integer(s) })

	toml_emit : Toml.TomlValue -> CceText
	toml_emit = |v| (match v {
		TomlTable(pairs) => CceText.concat_list(toml_emit_pairs(pairs, 0, U64.to_i64_wrap(List.len(pairs)), []))
		_ => toml_emit_value(v)
	})

	toml_emit_pairs : List(Toml.TomlPair), I64, I64, List(CceText) -> List(CceText)
	toml_emit_pairs = |pairs, i, len, acc| (if (i >= len) { acc } else { ({
		p = (List.get(pairs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		toml_emit_pairs(pairs, (i + 1), len, List.append(acc, CceText.concat(CceText.concat(CceText.concat(p.tp_key, " = "), toml_emit_value(p.tp_value)), "\n")))
	}) })

	toml_emit_value : Toml.TomlValue -> CceText
	toml_emit_value = |v| (match v {
		TomlString(s) => CceText.concat(CceText.concat("\"", s), "\"")
		TomlInteger(n) => CceText.show_int(n)
		TomlBool(b) => (if b { "true" } else { "false" })
		TomlDatetime(d) => d
		TomlArray(items) => CceText.concat(CceText.concat("[", CceText.concat_list(toml_emit_array(items, 0, U64.to_i64_wrap(List.len(items)), []))), "]")
		TomlTable(pairs) => CceText.concat(CceText.concat("{ ", CceText.concat_list(toml_emit_inline(pairs, 0, U64.to_i64_wrap(List.len(pairs)), []))), " }")
	})

	toml_emit_array : List(Toml.TomlValue), I64, I64, List(CceText) -> List(CceText)
	toml_emit_array = |items, i, len, acc| (if (i >= len) { acc } else { ({
		sep : CceText
		sep = (if (i == 0) { "" } else { ", " })
		toml_emit_array(items, (i + 1), len, List.append(List.append(acc, sep), toml_emit_value((List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))
	}) })

	toml_emit_inline : List(Toml.TomlPair), I64, I64, List(CceText) -> List(CceText)
	toml_emit_inline = |pairs, i, len, acc| (if (i >= len) { acc } else { ({
		p = (List.get(pairs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		sep : CceText
		sep = (if (i == 0) { "" } else { ", " })
		toml_emit_inline(pairs, (i + 1), len, List.append(List.append(acc, sep), CceText.concat(CceText.concat(p.tp_key, " = "), toml_emit_value(p.tp_value))))
	}) })

	toml_decimal : CceText -> Bool
	toml_decimal = |s| ({
		n : I64
		n = CceText.len(s)
		start : I64
		start = (if toml_starts_with(s, "+") { 1 } else { (if toml_starts_with(s, "-") { 1 } else { 0 }) })
		(if ((n - start) < 1) { False } else { (if ((n - start) > 18) { False } else { (if ((n - start) > 1) { (if (CceText.char_code_at(s, start) == CceText.char_code_at("0", 0)) { False } else { toml_digits(s, start, n) }) } else { toml_digits(s, start, n) }) }) })
	})

	toml_digits : CceText, I64, I64 -> Bool
	toml_digits = |s, i, n| (if (i >= n) { True } else { (if CceChar.is_digit(CceText.char_at(s, i)) { toml_digits(s, (i + 1), n) } else { False }) })

	toml_bare_key : CceText -> Bool
	toml_bare_key = |k| (if (CceText.len(k) == 0) { False } else { toml_bare_loop(k, 0, CceText.len(k)) })

	toml_bare_loop : CceText, I64, I64 -> Bool
	toml_bare_loop = |k, i, n| (if (i >= n) { True } else { ({
		c : I64
		c = CceText.char_code_at(k, i)
		(if CceChar.is_letter(CceText.char_at(k, i)) { toml_bare_loop(k, (i + 1), n) } else { (if CceChar.is_digit(CceText.char_at(k, i)) { toml_bare_loop(k, (i + 1), n) } else { (if (c == CceText.char_code_at("_", 0)) { toml_bare_loop(k, (i + 1), n) } else { (if (c == CceText.char_code_at("-", 0)) { toml_bare_loop(k, (i + 1), n) } else { False }) }) }) })
	}) })

	toml_rest_ok : CceText, I64 -> Bool
	toml_rest_ok = |s, from| ({
		rest : CceText
		rest = toml_trim(CceText.substring(s, from, (CceText.len(s) - from)))
		(if (CceText.len(rest) == 0) { True } else { toml_starts_with(rest, "#") })
	})

	toml_strip_comment : CceText -> CceText
	toml_strip_comment = |s| ({
		hash : I64
		hash = toml_find_char(s, CceText.char_code_at("#", 0), 0, CceText.len(s))
		(if (hash < 0) { s } else { toml_trim(CceText.substring(s, 0, hash)) })
	})

	toml_trim : CceText -> CceText
	toml_trim = |s| ({
		n : I64
		n = CceText.len(s)
		a : I64
		a = toml_first_solid(s, 0, n)
		b : I64
		b = toml_last_solid(s, n)
		(if (a >= b) { "" } else { CceText.substring(s, a, (b - a)) })
	})

	toml_first_solid : CceText, I64, I64 -> I64
	toml_first_solid = |s, i, n| (if (i >= n) { n } else { (if (CceText.char_code_at(s, i) == CceText.char_code_at(" ", 0)) { toml_first_solid(s, (i + 1), n) } else { i }) })

	toml_last_solid : CceText, I64 -> I64
	toml_last_solid = |s, j| (if (j <= 0) { 0 } else { (if (CceText.char_code_at(s, (j - 1)) == CceText.char_code_at(" ", 0)) { toml_last_solid(s, (j - 1)) } else { j }) })

	toml_starts_with : CceText, CceText -> Bool
	toml_starts_with = |s, prefix| CceText.starts_with(s, prefix)

	toml_find_char : CceText, I64, I64, I64 -> I64
	toml_find_char = |s, target, i, len| (if (i >= len) { (0 - 1) } else { (if (CceChar.code(CceText.char_at(s, i)) == target) { i } else { toml_find_char(s, target, (i + 1), len) }) })

	eq_TomlValue : Toml.TomlValue, Toml.TomlValue -> Bool
	eq_TomlValue = |ex, ey| (match ex {
		TomlString(exf0) => (match ey {
			TomlString(eyf0) => (exf0 == eyf0)
			_ => False
		})
		TomlInteger(exf0) => (match ey {
			TomlInteger(eyf0) => (exf0 == eyf0)
			_ => False
		})
		TomlBool(exf0) => (match ey {
			TomlBool(eyf0) => (exf0 == eyf0)
			_ => False
		})
		TomlArray(exf0) => (match ey {
			TomlArray(eyf0) => (exf0 == eyf0)
			_ => False
		})
		TomlTable(exf0) => (match ey {
			TomlTable(eyf0) => (exf0 == eyf0)
			_ => False
		})
		TomlDatetime(exf0) => (match ey {
			TomlDatetime(eyf0) => (exf0 == eyf0)
			_ => False
		})
	})

	eq_TomlPair : Toml.TomlPair, Toml.TomlPair -> Bool
	eq_TomlPair = |ex, ey| ((ex.tp_key == ey.tp_key) and eq_TomlValue(ex.tp_value, ey.tp_value))
}
