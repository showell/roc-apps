# Yaml -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Maybe
import Text

Yaml :: [].{
	YamlValue := [YamlString(List(U8)), YamlInt(I64), YamlBool(Bool), YamlNull, YamlList(List(Yaml.YamlValue)), YamlMap(List(Yaml.YamlPair))].{
		is_eq : Yaml.YamlValue, Yaml.YamlValue -> Bool
		is_eq = |a, b| eq_YamlValue(a, b)
	}
	YamlPair := { yp_key : List(U8), yp_value : Yaml.YamlValue }.{
		is_eq : Yaml.YamlPair, Yaml.YamlPair -> Bool
		is_eq = |a, b| a.yp_key == b.yp_key and a.yp_value == b.yp_value
	}
	YamlParseResult : { value : Yaml.YamlValue, next_line : I64 }

	yaml_string : List(U8) -> Yaml.YamlValue
	yaml_string = |s| YamlString(s)

	yaml_int : I64 -> Yaml.YamlValue
	yaml_int = |n| YamlInt(n)

	yaml_bool : Bool -> Yaml.YamlValue
	yaml_bool = |b| YamlBool(b)

	yaml_null : Yaml.YamlValue
	yaml_null = YamlNull

	yaml_list : List(Yaml.YamlValue) -> Yaml.YamlValue
	yaml_list = |items| YamlList(items)

	yaml_map : List(Yaml.YamlPair) -> Yaml.YamlValue
	yaml_map = |pairs| YamlMap(pairs)

	yaml_pair : List(U8), Yaml.YamlValue -> Yaml.YamlPair
	yaml_pair = |k, v| { yp_key: k, yp_value: v }

	yaml_get : Yaml.YamlValue, List(U8) -> Maybe.Maybe(Yaml.YamlValue)
	yaml_get = |v, key| (match v {
		YamlMap(pairs) => yaml_find_pair(pairs, key, 0, U64.to_i64_wrap(List.len(pairs)))
		_ => None
	})

	yaml_find_pair : List(Yaml.YamlPair), List(U8), I64, I64 -> Maybe.Maybe(Yaml.YamlValue)
	yaml_find_pair = |pairs, key, i, len| (if (i >= len) { None } else { ({
		p = (List.get(pairs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (p.yp_key == key) { Just(p.yp_value) } else { yaml_find_pair(pairs, key, (i + 1), len) })
	}) })

	yaml_get_str : Yaml.YamlValue, List(U8), List(U8) -> List(U8)
	yaml_get_str = |v, key, default| (match yaml_get(v, key) {
		Just(val) => (match val {
			YamlString(s) => s
			_ => default
		})
		None => default
	})

	yaml_get_int : Yaml.YamlValue, List(U8), I64 -> I64
	yaml_get_int = |v, key, default| (match yaml_get(v, key) {
		Just(val) => (match val {
			YamlInt(n) => n
			_ => default
		})
		None => default
	})

	yaml_get_list : Yaml.YamlValue, List(U8) -> List(Yaml.YamlValue)
	yaml_get_list = |v, key| (match yaml_get(v, key) {
		Just(val) => (match val {
			YamlList(items) => items
			_ => []
		})
		None => []
	})

	yaml_parse : List(U8) -> Maybe.Maybe(Yaml.YamlValue)
	yaml_parse = |input| ({
		lines = Text.split(input, [1])
		result = yaml_parse_block(lines, 0, U64.to_i64_wrap(List.len(lines)), 0)
		Just(result.value)
	})

	yaml_parse_block : List(List(U8)), I64, I64, I64 -> Yaml.YamlParseResult
	yaml_parse_block = |lines, start, len, indent| (if (start >= len) { { value: YamlNull, next_line: start } } else { ({
		line = (List.get(lines, I64.to_u64_wrap(start)) ?? crash("list-at out of range"))
		trimmed = yaml_trim(line)
		(if (Text.len(trimmed) == 0) { yaml_parse_block(lines, (start + 1), len, indent) } else { (if yaml_starts_with(trimmed, [83]) { yaml_parse_block(lines, (start + 1), len, indent) } else { (if yaml_starts_with(trimmed, [73, 2]) { yaml_parse_list(lines, start, len, indent) } else { (if yaml_contains(trimmed, [69, 2]) { yaml_parse_map(lines, start, len, indent) } else { { value: yaml_parse_scalar(trimmed), next_line: (start + 1) } }) }) }) })
	}) })

	yaml_parse_scalar : List(U8) -> Yaml.YamlValue
	yaml_parse_scalar = |s| (if (s == [14, 21, 25, 13]) { YamlBool(True) } else { (if (s == [28, 15, 23, 19, 13]) { YamlBool(False) } else { (if (s == [18, 25, 23, 23]) { YamlNull } else { (if (s == [92]) { YamlNull } else { (if yaml_is_int(s) { YamlInt(Text.to_integer(s)) } else { YamlString(yaml_unquote(s)) }) }) }) }) })

	yaml_is_int : List(U8) -> Bool
	yaml_is_int = |s| ({
		len = Text.len(s)
		(if (len == 0) { False } else { ({
			start = (if (Text.char_at(s, 0) == 73) { 1 } else { 0 })
			yaml_all_digits(s, start, len)
		}) })
	})

	yaml_all_digits : List(U8), I64, I64 -> Bool
	yaml_all_digits = |s, i, len| (if (i >= len) { (i > 0) } else { ({
		c = Text.char_at(s, i)
		(if (c >= 3) { (if (c <= 12) { yaml_all_digits(s, (i + 1), len) } else { False }) } else { False })
	}) })

	yaml_parse_list : List(List(U8)), I64, I64, I64 -> Yaml.YamlParseResult
	yaml_parse_list = |lines, start, len, indent| yaml_list_loop(lines, start, len, indent, [])

	yaml_list_loop : List(List(U8)), I64, I64, I64, List(Yaml.YamlValue) -> Yaml.YamlParseResult
	yaml_list_loop = |lines, pos, len, indent, acc| (if (pos >= len) { { value: YamlList(acc), next_line: pos } } else { ({
		line = (List.get(lines, I64.to_u64_wrap(pos)) ?? crash("list-at out of range"))
		line_indent = yaml_count_indent(line)
		trimmed = yaml_trim(line)
		(if (line_indent < indent) { { value: YamlList(acc), next_line: pos } } else { (if yaml_starts_with(trimmed, [73, 2]) { ({
			val_str = yaml_trim(Text.substring(trimmed, 2, (Text.len(trimmed) - 2)))
			val = yaml_parse_scalar(val_str)
			yaml_list_loop(lines, (pos + 1), len, indent, List.append(acc, val))
		}) } else { { value: YamlList(acc), next_line: pos } }) })
	}) })

	yaml_parse_map : List(List(U8)), I64, I64, I64 -> Yaml.YamlParseResult
	yaml_parse_map = |lines, start, len, indent| yaml_map_loop(lines, start, len, indent, [])

	yaml_map_loop : List(List(U8)), I64, I64, I64, List(Yaml.YamlPair) -> Yaml.YamlParseResult
	yaml_map_loop = |lines, pos, len, indent, acc| (if (pos >= len) { { value: YamlMap(acc), next_line: pos } } else { ({
		line = (List.get(lines, I64.to_u64_wrap(pos)) ?? crash("list-at out of range"))
		line_indent = yaml_count_indent(line)
		trimmed = yaml_trim(line)
		(if (Text.len(trimmed) == 0) { yaml_map_loop(lines, (pos + 1), len, indent, acc) } else { (if yaml_starts_with(trimmed, [83]) { yaml_map_loop(lines, (pos + 1), len, indent, acc) } else { (if (line_indent < indent) { { value: YamlMap(acc), next_line: pos } } else { (if yaml_contains(trimmed, [69, 2]) { ({
			colon = yaml_find_colon_space(trimmed, 0, Text.len(trimmed))
			key = Text.substring(trimmed, 0, colon)
			val_str = yaml_trim(Text.substring(trimmed, (colon + 2), ((Text.len(trimmed) - colon) - 2)))
			val = yaml_parse_scalar(val_str)
			yaml_map_loop(lines, (pos + 1), len, indent, List.append(acc, { yp_key: key, yp_value: val }))
		}) } else { { value: YamlMap(acc), next_line: pos } }) }) }) })
	}) })

	yaml_emit : Yaml.YamlValue -> List(U8)
	yaml_emit = |v| yaml_emit_at(v, 0)

	yaml_emit_at : Yaml.YamlValue, I64 -> List(U8)
	yaml_emit_at = |v, indent| (match v {
		YamlString(s) => yaml_quote_if_needed(s)
		YamlInt(n) => Text.show_int(n)
		YamlBool(b) => (if b { [14, 21, 25, 13] } else { [28, 15, 23, 19, 13] })
		YamlNull => [18, 25, 23, 23]
		YamlList(items) => yaml_emit_list(items, indent, 0, U64.to_i64_wrap(List.len(items)), [])
		YamlMap(pairs) => yaml_emit_map(pairs, indent, 0, U64.to_i64_wrap(List.len(pairs)), [])
	})

	yaml_emit_list : List(Yaml.YamlValue), I64, I64, I64, List(U8) -> List(U8)
	yaml_emit_list = |items, indent, i, len, acc| (if (i >= len) { acc } else { ({
		prefix = (if (i == 0) { [] } else { List.concat([1], yaml_indent(indent)) })
		val = yaml_emit_at((List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), (indent + 2))
		yaml_emit_list(items, indent, (i + 1), len, List.concat(List.concat(List.concat(acc, prefix), [73, 2]), val))
	}) })

	yaml_emit_map : List(Yaml.YamlPair), I64, I64, I64, List(U8) -> List(U8)
	yaml_emit_map = |pairs, indent, i, len, acc| (if (i >= len) { acc } else { ({
		p = (List.get(pairs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		prefix = (if (i == 0) { [] } else { List.concat([1], yaml_indent(indent)) })
		val = yaml_emit_at(p.yp_value, (indent + 2))
		yaml_emit_map(pairs, indent, (i + 1), len, List.concat(List.concat(List.concat(List.concat(acc, prefix), p.yp_key), [69, 2]), val))
	}) })

	yaml_indent : I64 -> List(U8)
	yaml_indent = |n| yaml_spaces(n, [])

	yaml_spaces : I64, List(U8) -> List(U8)
	yaml_spaces = |n, acc| (if (n <= 0) { acc } else { yaml_spaces((n - 1), List.concat(acc, [2])) })

	yaml_quote_if_needed : List(U8) -> List(U8)
	yaml_quote_if_needed = |s| (if yaml_needs_quoting(s) { List.concat(List.concat([72], s), [72]) } else { s })

	yaml_needs_quoting : List(U8) -> Bool
	yaml_needs_quoting = |s| (if (Text.len(s) == 0) { True } else { (if yaml_starts_with(s, [73, 2]) { True } else { yaml_contains(s, [69, 2]) }) })

	yaml_trim : List(U8) -> List(U8)
	yaml_trim = |s| yaml_trim_left(yaml_trim_right(s))

	yaml_trim_left : List(U8) -> List(U8)
	yaml_trim_left = |s| (if (Text.len(s) == 0) { s } else { (if (Text.char_at(s, 0) == 2) { yaml_trim_left(Text.substring(s, 1, (Text.len(s) - 1))) } else { s }) })

	yaml_trim_right : List(U8) -> List(U8)
	yaml_trim_right = |s| ({
		len = Text.len(s)
		(if (len == 0) { s } else { (if (Text.char_at(s, (len - 1)) == 2) { yaml_trim_right(Text.substring(s, 0, (len - 1))) } else { s }) })
	})

	yaml_count_indent : List(U8) -> I64
	yaml_count_indent = |s| yaml_ci_loop(s, 0, Text.len(s))

	yaml_ci_loop : List(U8), I64, I64 -> I64
	yaml_ci_loop = |s, i, len| (if (i >= len) { i } else { (if (Text.char_at(s, i) == 2) { yaml_ci_loop(s, (i + 1), len) } else { i }) })

	yaml_starts_with : List(U8), List(U8) -> Bool
	yaml_starts_with = |s, prefix| Text.starts_with(s, prefix)

	yaml_contains : List(U8), List(U8) -> Bool
	yaml_contains = |s, sub| Text.contains(s, sub)

	yaml_find_colon_space : List(U8), I64, I64 -> I64
	yaml_find_colon_space = |s, i, len| (if ((i + 1) >= len) { len } else { (if (Text.char_at(s, i) == 69) { (if (Text.char_at(s, (i + 1)) == 2) { i } else { yaml_find_colon_space(s, (i + 1), len) }) } else { yaml_find_colon_space(s, (i + 1), len) }) })

	yaml_unquote : List(U8) -> List(U8)
	yaml_unquote = |s| ({
		len = Text.len(s)
		(if (len < 2) { s } else { (if (Text.char_at(s, 0) == 72) { Text.substring(s, 1, (len - 2)) } else { (if (Text.char_at(s, 0) == 71) { Text.substring(s, 1, (len - 2)) } else { s }) }) })
	})

	eq_YamlValue : Yaml.YamlValue, Yaml.YamlValue -> Bool
	eq_YamlValue = |ex, ey| (match ex {
		YamlString(exf0) => (match ey {
			YamlString(eyf0) => (exf0 == eyf0)
			_ => False
		})
		YamlInt(exf0) => (match ey {
			YamlInt(eyf0) => (exf0 == eyf0)
			_ => False
		})
		YamlBool(exf0) => (match ey {
			YamlBool(eyf0) => (exf0 == eyf0)
			_ => False
		})
		YamlNull => (match ey {
			YamlNull => True
			_ => False
		})
		YamlList(exf0) => (match ey {
			YamlList(eyf0) => (exf0 == eyf0)
			_ => False
		})
		YamlMap(exf0) => (match ey {
			YamlMap(eyf0) => (exf0 == eyf0)
			_ => False
		})
	})
}
