# Toml -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Maybe
import Text

Toml :: [].{
	TomlValue := [TomlString(Text), TomlInteger(I64), TomlBool(Bool), TomlArray(List(Toml.TomlValue)), TomlTable(List(Toml.TomlPair)), TomlDatetime(Text)].{
		is_eq : Toml.TomlValue, Toml.TomlValue -> Bool
		is_eq = |a, b| eq_TomlValue(a, b)
	}
	TomlPair := { tp_key : Text, tp_value : Toml.TomlValue }.{
		is_eq : Toml.TomlPair, Toml.TomlPair -> Bool
		is_eq = |a, b| a.tp_key == b.tp_key and a.tp_value == b.tp_value
	}

	toml_string : Text -> Toml.TomlValue
	toml_string = |s| TomlString(s)

	toml_integer : I64 -> Toml.TomlValue
	toml_integer = |n| TomlInteger(n)

	toml_bool : Bool -> Toml.TomlValue
	toml_bool = |b| TomlBool(b)

	toml_table : List(Toml.TomlPair) -> Toml.TomlValue
	toml_table = |pairs| TomlTable(pairs)

	toml_pair : Text, Toml.TomlValue -> Toml.TomlPair
	toml_pair = |k, v| { tp_key: k, tp_value: v }

	toml_empty : Toml.TomlValue
	toml_empty = TomlTable([])

	toml_get : Toml.TomlValue, Text -> Maybe.Maybe(Toml.TomlValue)
	toml_get = |v, key| (match v {
		TomlTable(pairs) => toml_find_pair(pairs, key, 0, U64.to_i64_wrap(List.len(pairs)))
		_ => None
	})

	toml_find_pair : List(Toml.TomlPair), Text, I64, I64 -> Maybe.Maybe(Toml.TomlValue)
	toml_find_pair = |pairs, key, i, len| (if (i >= len) { None } else { ({
		p = (List.get(pairs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (p.tp_key == key) { Just(p.tp_value) } else { toml_find_pair(pairs, key, (i + 1), len) })
	}) })

	toml_get_str : Toml.TomlValue, Text, Text -> Text
	toml_get_str = |v, key, default| (match toml_get(v, key) {
		Just(val) => (match val {
			TomlString(s) => s
			_ => default
		})
		None => default
	})

	toml_get_int : Toml.TomlValue, Text, I64 -> I64
	toml_get_int = |v, key, default| (match toml_get(v, key) {
		Just(val) => (match val {
			TomlInteger(n) => n
			_ => default
		})
		None => default
	})

	toml_get_bool : Toml.TomlValue, Text, Bool -> Bool
	toml_get_bool = |v, key, default| (match toml_get(v, key) {
		Just(val) => (match val {
			TomlBool(b) => b
			_ => default
		})
		None => default
	})

	toml_get_path : Toml.TomlValue, List(Text) -> Maybe.Maybe(Toml.TomlValue)
	toml_get_path = |v, keys| toml_walk(v, keys, 0, U64.to_i64_wrap(List.len(keys)))

	toml_walk : Toml.TomlValue, List(Text), I64, I64 -> Maybe.Maybe(Toml.TomlValue)
	toml_walk = |v, keys, i, len| (if (i >= len) { Just(v) } else { (match toml_get(v, (List.get(keys, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) {
		Just(child) => toml_walk(child, keys, (i + 1), len)
		None => None
	}) })

	toml_parse : Text -> Maybe.Maybe(Toml.TomlValue)
	toml_parse = |input| ({
		lines = Text.split(input, "\n")
		Just(toml_parse_lines(lines, 0, U64.to_i64_wrap(List.len(lines)), [], ""))
	})

	toml_parse_lines : List(Text), I64, I64, List(Toml.TomlPair), Text -> Toml.TomlValue
	toml_parse_lines = |lines, i, len, pairs, current_table| (if (i >= len) { TomlTable(pairs) } else { ({
		line = toml_trim((List.get(lines, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))
		(if (Text.len(line) == 0) { toml_parse_lines(lines, (i + 1), len, pairs, current_table) } else { (if toml_starts_with(line, "#") { toml_parse_lines(lines, (i + 1), len, pairs, current_table) } else { (if toml_starts_with(line, "[") { ({
			table_name = toml_extract_table_name(line)
			toml_parse_lines(lines, (i + 1), len, pairs, table_name)
		}) } else { ({
			kv = toml_parse_kv(line)
			toml_parse_lines(lines, (i + 1), len, List.append(pairs, kv), current_table)
		}) }) }) })
	}) })

	toml_parse_kv : Text -> Toml.TomlPair
	toml_parse_kv = |line| ({
		eq_pos = toml_find_char(line, 77, 0, Text.len(line))
		(if (eq_pos < 0) { { tp_key: line, tp_value: TomlString("") } } else { ({
			key = toml_trim(Text.substring(line, 0, eq_pos))
			val_str = toml_trim(Text.substring(line, (eq_pos + 1), ((Text.len(line) - eq_pos) - 1)))
			{ tp_key: key, tp_value: toml_parse_value(val_str) }
		}) })
	})

	toml_parse_value : Text -> Toml.TomlValue
	toml_parse_value = |s| (if (Text.len(s) == 0) { TomlString("") } else { (if toml_starts_with(s, "\"") { TomlString(toml_unquote(s)) } else { (if toml_starts_with(s, "'") { TomlString(toml_unquote_literal(s)) } else { (if (s == "true") { TomlBool(True) } else { (if (s == "false") { TomlBool(False) } else { (if toml_looks_like_int(s) { TomlInteger(Text.to_integer(s)) } else { TomlString(s) }) }) }) }) }) })

	toml_extract_table_name : Text -> Text
	toml_extract_table_name = |line| ({
		start = 1
		end_pos = toml_find_char(line, 89, start, Text.len(line))
		(if (end_pos < 0) { "" } else { toml_trim(Text.substring(line, start, (end_pos - start))) })
	})

	toml_emit : Toml.TomlValue -> Text
	toml_emit = |v| (match v {
		TomlTable(pairs) => toml_emit_pairs(pairs, 0, U64.to_i64_wrap(List.len(pairs)), "")
		_ => toml_emit_value(v)
	})

	toml_emit_pairs : List(Toml.TomlPair), I64, I64, Text -> Text
	toml_emit_pairs = |pairs, i, len, acc| (if (i >= len) { acc } else { ({
		p = (List.get(pairs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		line = Text.concat(Text.concat(Text.concat(p.tp_key, " = "), toml_emit_value(p.tp_value)), "\n")
		toml_emit_pairs(pairs, (i + 1), len, Text.concat(acc, line))
	}) })

	toml_emit_value : Toml.TomlValue -> Text
	toml_emit_value = |v| (match v {
		TomlString(s) => Text.concat(Text.concat("\"", s), "\"")
		TomlInteger(n) => Text.show_int(n)
		TomlBool(b) => (if b { "true" } else { "false" })
		TomlDatetime(d) => d
		TomlArray(items) => Text.concat(Text.concat("[", toml_emit_array(items, 0, U64.to_i64_wrap(List.len(items)), "")), "]")
		TomlTable(pairs) => Text.concat(Text.concat("{ ", toml_emit_inline(pairs, 0, U64.to_i64_wrap(List.len(pairs)), "")), " }")
	})

	toml_emit_array : List(Toml.TomlValue), I64, I64, Text -> Text
	toml_emit_array = |items, i, len, acc| (if (i >= len) { acc } else { ({
		sep = (if (i == 0) { "" } else { ", " })
		toml_emit_array(items, (i + 1), len, Text.concat(Text.concat(acc, sep), toml_emit_value((List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))
	}) })

	toml_emit_inline : List(Toml.TomlPair), I64, I64, Text -> Text
	toml_emit_inline = |pairs, i, len, acc| (if (i >= len) { acc } else { ({
		p = (List.get(pairs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		sep = (if (i == 0) { "" } else { ", " })
		toml_emit_inline(pairs, (i + 1), len, Text.concat(Text.concat(Text.concat(Text.concat(acc, sep), p.tp_key), " = "), toml_emit_value(p.tp_value)))
	}) })

	toml_looks_like_int : Text -> Bool
	toml_looks_like_int = |s| (if (Text.len(s) == 0) { False } else { ({
		first = Text.char_at(s, 0)
		(if (first >= 3) { (if (first <= 12) { True } else { False }) } else { (if (first == 73) { (if (Text.len(s) > 1) { True } else { False }) } else { (if (first == 76) { (if (Text.len(s) > 1) { True } else { False }) } else { False }) }) })
	}) })

	toml_trim : Text -> Text
	toml_trim = |s| toml_trim_left(toml_trim_right(s))

	toml_trim_left : Text -> Text
	toml_trim_left = |s| (if (Text.len(s) == 0) { s } else { (if (Text.char_at(s, 0) == 2) { toml_trim_left(Text.substring(s, 1, (Text.len(s) - 1))) } else { s }) })

	toml_trim_right : Text -> Text
	toml_trim_right = |s| ({
		len = Text.len(s)
		(if (len == 0) { s } else { (if (Text.char_at(s, (len - 1)) == 2) { toml_trim_right(Text.substring(s, 0, (len - 1))) } else { s }) })
	})

	toml_starts_with : Text, Text -> Bool
	toml_starts_with = |s, prefix| Text.starts_with(s, prefix)

	toml_find_char : Text, I64, I64, I64 -> I64
	toml_find_char = |s, target, i, len| (if (i >= len) { (0 - 1) } else { (if (Text.char_at(s, i) == target) { i } else { toml_find_char(s, target, (i + 1), len) }) })

	toml_unquote : Text -> Text
	toml_unquote = |s| ({
		len = Text.len(s)
		(if (len < 2) { s } else { Text.substring(s, 1, (len - 2)) })
	})

	toml_unquote_literal : Text -> Text
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
