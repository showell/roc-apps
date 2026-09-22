# Toml -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Maybe
import Text

Toml :: [].{
	TomlValue := [TomlString(List(U8)), TomlInteger(I64), TomlBool(Bool), TomlArray(List(Toml.TomlValue)), TomlTable(List(Toml.TomlPair)), TomlDatetime(List(U8))].{
		is_eq : Toml.TomlValue, Toml.TomlValue -> Bool
		is_eq = |a, b| eq_TomlValue(a, b)
	}
	TomlPair := { tp_key : List(U8), tp_value : Toml.TomlValue }.{
		is_eq : Toml.TomlPair, Toml.TomlPair -> Bool
		is_eq = |a, b| a.tp_key == b.tp_key and a.tp_value == b.tp_value
	}

	toml_string : List(U8) -> Toml.TomlValue
	toml_string = |s| TomlString(s)

	toml_integer : I64 -> Toml.TomlValue
	toml_integer = |n| TomlInteger(n)

	toml_bool : Bool -> Toml.TomlValue
	toml_bool = |b| TomlBool(b)

	toml_table : List(Toml.TomlPair) -> Toml.TomlValue
	toml_table = |pairs| TomlTable(pairs)

	toml_pair : List(U8), Toml.TomlValue -> Toml.TomlPair
	toml_pair = |k, v| { tp_key: k, tp_value: v }

	toml_empty : Toml.TomlValue
	toml_empty = TomlTable([])

	toml_get : Toml.TomlValue, List(U8) -> Maybe.Maybe(Toml.TomlValue)
	toml_get = |v, key| (match v {
		TomlTable(pairs) => toml_find_pair(pairs, key, 0, U64.to_i64_wrap(List.len(pairs)))
		_ => None
	})

	toml_find_pair : List(Toml.TomlPair), List(U8), I64, I64 -> Maybe.Maybe(Toml.TomlValue)
	toml_find_pair = |pairs, key, i, len| (if (i >= len) { None } else { ({
		p = (List.get(pairs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (p.tp_key == key) { Just(p.tp_value) } else { toml_find_pair(pairs, key, (i + 1), len) })
	}) })

	toml_get_str : Toml.TomlValue, List(U8), List(U8) -> List(U8)
	toml_get_str = |v, key, default| (match toml_get(v, key) {
		Just(val) => (match val {
			TomlString(s) => s
			_ => default
		})
		None => default
	})

	toml_get_int : Toml.TomlValue, List(U8), I64 -> I64
	toml_get_int = |v, key, default| (match toml_get(v, key) {
		Just(val) => (match val {
			TomlInteger(n) => n
			_ => default
		})
		None => default
	})

	toml_get_bool : Toml.TomlValue, List(U8), Bool -> Bool
	toml_get_bool = |v, key, default| (match toml_get(v, key) {
		Just(val) => (match val {
			TomlBool(b) => b
			_ => default
		})
		None => default
	})

	toml_get_path : Toml.TomlValue, List(List(U8)) -> Maybe.Maybe(Toml.TomlValue)
	toml_get_path = |v, keys| toml_walk(v, keys, 0, U64.to_i64_wrap(List.len(keys)))

	toml_walk : Toml.TomlValue, List(List(U8)), I64, I64 -> Maybe.Maybe(Toml.TomlValue)
	toml_walk = |v, keys, i, len| (if (i >= len) { Just(v) } else { (match toml_get(v, (List.get(keys, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) {
		Just(child) => toml_walk(child, keys, (i + 1), len)
		None => None
	}) })

	toml_parse : List(U8) -> Maybe.Maybe(Toml.TomlValue)
	toml_parse = |input| ({
		lines = Text.split(input, [1])
		Just(toml_parse_lines(lines, 0, U64.to_i64_wrap(List.len(lines)), [], []))
	})

	toml_parse_lines : List(List(U8)), I64, I64, List(Toml.TomlPair), List(U8) -> Toml.TomlValue
	toml_parse_lines = |lines, i, len, pairs, current_table| (if (i >= len) { TomlTable(pairs) } else { ({
		line = toml_trim((List.get(lines, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))
		(if (Text.len(line) == 0) { toml_parse_lines(lines, (i + 1), len, pairs, current_table) } else { (if toml_starts_with(line, [83]) { toml_parse_lines(lines, (i + 1), len, pairs, current_table) } else { (if toml_starts_with(line, [88]) { ({
			table_name = toml_extract_table_name(line)
			toml_parse_lines(lines, (i + 1), len, pairs, table_name)
		}) } else { ({
			kv = toml_parse_kv(line)
			toml_parse_lines(lines, (i + 1), len, List.append(pairs, kv), current_table)
		}) }) }) })
	}) })

	toml_parse_kv : List(U8) -> Toml.TomlPair
	toml_parse_kv = |line| ({
		eq_pos = toml_find_char(line, 77, 0, Text.len(line))
		(if (eq_pos < 0) { { tp_key: line, tp_value: TomlString([]) } } else { ({
			key = toml_trim(Text.substring(line, 0, eq_pos))
			val_str = toml_trim(Text.substring(line, (eq_pos + 1), ((Text.len(line) - eq_pos) - 1)))
			{ tp_key: key, tp_value: toml_parse_value(val_str) }
		}) })
	})

	toml_parse_value : List(U8) -> Toml.TomlValue
	toml_parse_value = |s| (if (Text.len(s) == 0) { TomlString([]) } else { (if toml_starts_with(s, [72]) { TomlString(toml_unquote(s)) } else { (if toml_starts_with(s, [71]) { TomlString(toml_unquote_literal(s)) } else { (if (s == [14, 21, 25, 13]) { TomlBool(True) } else { (if (s == [28, 15, 23, 19, 13]) { TomlBool(False) } else { (if toml_looks_like_int(s) { TomlInteger(Text.to_integer(s)) } else { TomlString(s) }) }) }) }) }) })

	toml_extract_table_name : List(U8) -> List(U8)
	toml_extract_table_name = |line| ({
		start = 1
		end_pos = toml_find_char(line, 89, start, Text.len(line))
		(if (end_pos < 0) { [] } else { toml_trim(Text.substring(line, start, (end_pos - start))) })
	})

	toml_emit : Toml.TomlValue -> List(U8)
	toml_emit = |v| (match v {
		TomlTable(pairs) => toml_emit_pairs(pairs, 0, U64.to_i64_wrap(List.len(pairs)), [])
		_ => toml_emit_value(v)
	})

	toml_emit_pairs : List(Toml.TomlPair), I64, I64, List(U8) -> List(U8)
	toml_emit_pairs = |pairs, i, len, acc| (if (i >= len) { acc } else { ({
		p = (List.get(pairs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		line = List.concat(List.concat(List.concat(p.tp_key, [2, 77, 2]), toml_emit_value(p.tp_value)), [1])
		toml_emit_pairs(pairs, (i + 1), len, List.concat(acc, line))
	}) })

	toml_emit_value : Toml.TomlValue -> List(U8)
	toml_emit_value = |v| (match v {
		TomlString(s) => List.concat(List.concat([72], s), [72])
		TomlInteger(n) => Text.show_int(n)
		TomlBool(b) => (if b { [14, 21, 25, 13] } else { [28, 15, 23, 19, 13] })
		TomlDatetime(d) => d
		TomlArray(items) => List.concat(List.concat([88], toml_emit_array(items, 0, U64.to_i64_wrap(List.len(items)), [])), [89])
		TomlTable(pairs) => List.concat(List.concat([90, 2], toml_emit_inline(pairs, 0, U64.to_i64_wrap(List.len(pairs)), [])), [2, 91])
	})

	toml_emit_array : List(Toml.TomlValue), I64, I64, List(U8) -> List(U8)
	toml_emit_array = |items, i, len, acc| (if (i >= len) { acc } else { ({
		sep = (if (i == 0) { [] } else { [66, 2] })
		toml_emit_array(items, (i + 1), len, List.concat(List.concat(acc, sep), toml_emit_value((List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))
	}) })

	toml_emit_inline : List(Toml.TomlPair), I64, I64, List(U8) -> List(U8)
	toml_emit_inline = |pairs, i, len, acc| (if (i >= len) { acc } else { ({
		p = (List.get(pairs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		sep = (if (i == 0) { [] } else { [66, 2] })
		toml_emit_inline(pairs, (i + 1), len, List.concat(List.concat(List.concat(List.concat(acc, sep), p.tp_key), [2, 77, 2]), toml_emit_value(p.tp_value)))
	}) })

	toml_looks_like_int : List(U8) -> Bool
	toml_looks_like_int = |s| (if (Text.len(s) == 0) { False } else { ({
		first = Text.char_at(s, 0)
		(if (first >= 3) { (if (first <= 12) { True } else { False }) } else { (if (first == 73) { (if (Text.len(s) > 1) { True } else { False }) } else { (if (first == 76) { (if (Text.len(s) > 1) { True } else { False }) } else { False }) }) })
	}) })

	toml_trim : List(U8) -> List(U8)
	toml_trim = |s| toml_trim_left(toml_trim_right(s))

	toml_trim_left : List(U8) -> List(U8)
	toml_trim_left = |s| (if (Text.len(s) == 0) { s } else { (if (Text.char_at(s, 0) == 2) { toml_trim_left(Text.substring(s, 1, (Text.len(s) - 1))) } else { s }) })

	toml_trim_right : List(U8) -> List(U8)
	toml_trim_right = |s| ({
		len = Text.len(s)
		(if (len == 0) { s } else { (if (Text.char_at(s, (len - 1)) == 2) { toml_trim_right(Text.substring(s, 0, (len - 1))) } else { s }) })
	})

	toml_starts_with : List(U8), List(U8) -> Bool
	toml_starts_with = |s, prefix| Text.starts_with(s, prefix)

	toml_find_char : List(U8), I64, I64, I64 -> I64
	toml_find_char = |s, target, i, len| (if (i >= len) { (0 - 1) } else { (if (Text.char_at(s, i) == target) { i } else { toml_find_char(s, target, (i + 1), len) }) })

	toml_unquote : List(U8) -> List(U8)
	toml_unquote = |s| ({
		len = Text.len(s)
		(if (len < 2) { s } else { Text.substring(s, 1, (len - 2)) })
	})

	toml_unquote_literal : List(U8) -> List(U8)
	toml_unquote_literal = |s| ({
		len = Text.len(s)
		(if (len < 2) { s } else { Text.substring(s, 1, (len - 2)) })
	})

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
}
