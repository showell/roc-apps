# Yaml -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceChar
import CceText
import Maybe

Yaml :: [].{
	YamlValue := [YamlString(CceText), YamlInt(I64), YamlBool(Bool), YamlNull, YamlList(List(Yaml.YamlValue)), YamlMap(List(Yaml.YamlPair))].{
		is_eq : Yaml.YamlValue, Yaml.YamlValue -> Bool
		is_eq = |a, b| eq_YamlValue(a, b)
	}
	YamlPair := { yp_key : CceText, yp_value : Yaml.YamlValue }.{
		is_eq : Yaml.YamlPair, Yaml.YamlPair -> Bool
		is_eq = |a, b| eq_YamlPair(a, b)
	}

	yaml_string : CceText -> Yaml.YamlValue
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

	yaml_pair : CceText, Yaml.YamlValue -> Yaml.YamlPair
	yaml_pair = |k, v| Yaml.YamlPair.{ yp_key: k, yp_value: v }

	yaml_get : Yaml.YamlValue, CceText -> Maybe.Maybe(Yaml.YamlValue)
	yaml_get = |v, key| (match v {
		YamlMap(pairs) => yaml_find_pair(pairs, key, 0, U64.to_i64_wrap(List.len(pairs)))
		_ => None
	})

	yaml_find_pair : List(Yaml.YamlPair), CceText, I64, I64 -> Maybe.Maybe(Yaml.YamlValue)
	yaml_find_pair = |pairs, key, i, len| (if (i >= len) { None } else { ({
		p = (List.get(pairs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (p.yp_key == key) { Just(p.yp_value) } else { yaml_find_pair(pairs, key, (i + 1), len) })
	}) })

	yaml_get_str : Yaml.YamlValue, CceText, CceText -> CceText
	yaml_get_str = |v, key, default| (match yaml_get(v, key) {
		Just(val) => (match val {
			YamlString(s) => s
			_ => default
		})
		None => default
	})

	yaml_get_int : Yaml.YamlValue, CceText, I64 -> I64
	yaml_get_int = |v, key, default| (match yaml_get(v, key) {
		Just(val) => (match val {
			YamlInt(n) => n
			_ => default
		})
		None => default
	})

	yaml_get_list : Yaml.YamlValue, CceText -> List(Yaml.YamlValue)
	yaml_get_list = |v, key| (match yaml_get(v, key) {
		Just(val) => (match val {
			YamlList(items) => items
			_ => []
		})
		None => []
	})

	yaml_parse : CceText -> Maybe.Maybe(Yaml.YamlValue)
	yaml_parse = |input| ({
		lines : List(CceText)
		lines = CceText.split(input, "\n")
		n : I64
		n = U64.to_i64_wrap(List.len(lines))
		first : I64
		first = yaml_first_content(lines, 0, n)
		(if (first >= n) { Just(YamlNull) } else { (if yaml_is_item((List.get(lines, I64.to_u64_wrap(first)) ?? crash("list-at out of range"))) { yaml_seq_loop(lines, first, n, []) } else { ({
			yaml_map_loop_v1 = yaml_map_loop(lines, first, n, [], yaml_slots(n))
			yaml_map_loop_v1.0
		}) }) })
	})

	yaml_first_content : List(CceText), I64, I64 -> I64
	yaml_first_content = |lines, i, n| (if (i >= n) { n } else { (if yaml_skippable((List.get(lines, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { yaml_first_content(lines, (i + 1), n) } else { i }) })

	yaml_skippable : CceText -> Bool
	yaml_skippable = |line| ({
		t : CceText
		t = yaml_trim(line)
		(if (CceText.len(t) == 0) { True } else { yaml_starts_with(t, "#") })
	})

	yaml_is_item : CceText -> Bool
	yaml_is_item = |line| (if (yaml_trim_right(line) == "-") { True } else { yaml_starts_with(line, "- ") })

	yaml_seq_loop : List(CceText), I64, I64, List(Yaml.YamlValue) -> Maybe.Maybe(Yaml.YamlValue)
	yaml_seq_loop = |lines, i, n, acc| (if (i >= n) { Just(YamlList(acc)) } else { ({
		line : CceText
		line = yaml_trim_right((List.get(lines, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))
		(if yaml_skippable(line) { yaml_seq_loop(lines, (i + 1), n, acc) } else { (if yaml_is_item(line) { (match yaml_scalar(yaml_trim(CceText.substring(line, 1, (CceText.len(line) - 1)))) {
			Just(v) => yaml_seq_loop(lines, (i + 1), n, List.append(acc, v))
			None => None
		}) } else { None }) })
	}) })

	yaml_map_loop : List(CceText), I64, I64, List(Yaml.YamlPair), List(CceText) -> (Maybe.Maybe(Yaml.YamlValue), List(CceText))
	yaml_map_loop = |lines, i, n, acc, seen| (if (i >= n) { (Just(YamlMap(acc)), seen) } else { ({
		line : CceText
		line = yaml_trim_right((List.get(lines, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))
		(if yaml_skippable(line) { yaml_map_loop(lines, (i + 1), n, acc, seen) } else { ({
			colon : I64
			colon = yaml_key_end(line, 0, CceText.len(line))
			(if (colon <= 0) { (None, seen) } else { ({
				key : CceText
				key = CceText.substring(line, 0, colon)
				(if yaml_plain_key(key, 0, colon) { ({
					slot : I64
					slot = yaml_slot(seen, key)
					(if (CceText.len((List.get(seen, I64.to_u64_wrap(slot)) ?? crash("list-at out of range"))) > 0) { (None, seen) } else { (match yaml_scalar(yaml_trim(CceText.substring(line, (colon + 1), ((CceText.len(line) - colon) - 1)))) {
						Just(v) => ({
							seen_v1 : List(CceText)
							seen_v1 = (List.set(seen, I64.to_u64_wrap(slot), key) ?? crash("list-set-at past the end"))
							yaml_map_loop(lines, (i + 1), n, List.append(acc, Yaml.YamlPair.{ yp_key: key, yp_value: v }), seen_v1)
						})
						None => (None, seen)
					}) })
				}) } else { (None, seen) })
			}) })
		}) })
	}) })

	yaml_key_end : CceText, I64, I64 -> I64
	yaml_key_end = |s, i, n| (if (i >= n) { (0 - 1) } else { (if (CceText.char_code_at(s, i) == CceText.char_code_at(":", 0)) { (if ((i + 1) >= n) { i } else { (if (CceText.char_code_at(s, (i + 1)) == CceText.char_code_at(" ", 0)) { i } else { yaml_key_end(s, (i + 1), n) }) }) } else { yaml_key_end(s, (i + 1), n) }) })

	yaml_plain_key : CceText, I64, I64 -> Bool
	yaml_plain_key = |k, i, n| (if (i >= n) { True } else { ({
		c : I64
		c = CceText.char_code_at(k, i)
		(if CceChar.is_letter(CceText.char_at(k, i)) { yaml_plain_key(k, (i + 1), n) } else { (if CceChar.is_digit(CceText.char_at(k, i)) { yaml_plain_key(k, (i + 1), n) } else { (if (c == CceText.char_code_at("_", 0)) { yaml_plain_key(k, (i + 1), n) } else { (if (c == CceText.char_code_at("-", 0)) { yaml_plain_key(k, (i + 1), n) } else { (if (c == CceText.char_code_at(".", 0)) { yaml_plain_key(k, (i + 1), n) } else { False }) }) }) }) })
	}) })

	yaml_scalar : CceText -> Maybe.Maybe(Yaml.YamlValue)
	yaml_scalar = |s| (if (CceText.len(s) == 0) { Just(YamlNull) } else { (if yaml_starts_with(s, "\"") { yaml_quoted(s, "\"", True) } else { (if yaml_starts_with(s, "'") { yaml_quoted(s, "'", False) } else { yaml_plain(yaml_strip_comment(s)) }) }) })

	yaml_quoted : CceText, CceText, Bool -> Maybe.Maybe(Yaml.YamlValue)
	yaml_quoted = |s, quote, double| ({
		close : I64
		close = yaml_find_char(s, CceText.char_code_at(quote, 0), 1, CceText.len(s))
		(if (close < 0) { None } else { ({
			inner : CceText
			inner = CceText.substring(s, 1, (close - 1))
			rest : CceText
			rest = CceText.substring(s, (close + 1), ((CceText.len(s) - close) - 1))
			(if double { (if CceText.contains(inner, "\\") { None } else { (if yaml_rest_ok(rest) { Just(YamlString(inner)) } else { None }) }) } else { (if yaml_rest_ok(rest) { Just(YamlString(inner)) } else { None }) })
		}) })
	})

	yaml_rest_ok : CceText -> Bool
	yaml_rest_ok = |rest| (if (CceText.len(rest) == 0) { True } else { (if yaml_starts_with(rest, " ") { yaml_starts_with(yaml_trim(rest), "#") } else { False }) })

	yaml_plain : CceText -> Maybe.Maybe(Yaml.YamlValue)
	yaml_plain = |v| (if (CceText.len(v) == 0) { Just(YamlNull) } else { (if yaml_indicator(CceText.char_at(v, 0)) { None } else { (if CceText.contains(v, ": ") { None } else { (if (CceText.char_code_at(v, (CceText.len(v) - 1)) == CceText.char_code_at(":", 0)) { None } else { (if (v == "true") { Just(YamlBool(True)) } else { (if (v == "True") { Just(YamlBool(True)) } else { (if (v == "TRUE") { Just(YamlBool(True)) } else { (if (v == "false") { Just(YamlBool(False)) } else { (if (v == "False") { Just(YamlBool(False)) } else { (if (v == "FALSE") { Just(YamlBool(False)) } else { (if (v == "null") { Just(YamlNull) } else { (if (v == "Null") { Just(YamlNull) } else { (if (v == "NULL") { Just(YamlNull) } else { (if (v == "~") { Just(YamlNull) } else { (if yaml_numeric_start(v) { (if yaml_decimal(v) { Just(YamlInt(yaml_integer_value(v))) } else { None }) } else { (if (v == "-") { None } else { (if yaml_starts_with(v, "- ") { None } else { Just(YamlString(v)) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) })

	yaml_indicator : CceChar -> Bool
	yaml_indicator = |c| CceText.contains("[]{}&*!|>%@`,?:#'\"", CceText.char_to_text(c))

	yaml_numeric_start : CceText -> Bool
	yaml_numeric_start = |v| (if CceChar.is_digit(CceText.char_at(v, 0)) { True } else { (if (CceText.len(v) < 2) { False } else { (if CceChar.is_digit(CceText.char_at(v, 1)) { (if yaml_starts_with(v, "-") { True } else { (if yaml_starts_with(v, "+") { True } else { yaml_starts_with(v, ".") }) }) } else { False }) }) })

	yaml_decimal : CceText -> Bool
	yaml_decimal = |v| ({
		n : I64
		n = CceText.len(v)
		start : I64
		start = (if yaml_starts_with(v, "+") { 1 } else { (if yaml_starts_with(v, "-") { 1 } else { 0 }) })
		(if ((n - start) < 1) { False } else { (if ((n - start) > 18) { False } else { yaml_digits(v, start, n) }) })
	})

	yaml_digits : CceText, I64, I64 -> Bool
	yaml_digits = |s, i, n| (if (i >= n) { True } else { (if CceChar.is_digit(CceText.char_at(s, i)) { yaml_digits(s, (i + 1), n) } else { False }) })

	yaml_integer_value : CceText -> I64
	yaml_integer_value = |v| (if yaml_starts_with(v, "+") { CceText.to_integer(CceText.substring(v, 1, (CceText.len(v) - 1))) } else { CceText.to_integer(v) })

	yaml_strip_comment : CceText -> CceText
	yaml_strip_comment = |s| ({
		hash : I64
		hash = yaml_find_comment(s, 1, CceText.len(s))
		(if (hash < 0) { s } else { yaml_trim(CceText.substring(s, 0, hash)) })
	})

	yaml_find_comment : CceText, I64, I64 -> I64
	yaml_find_comment = |s, i, n| (if (i >= n) { (0 - 1) } else { (if (CceText.char_code_at(s, i) == CceText.char_code_at("#", 0)) { (if (CceText.char_code_at(s, (i - 1)) == CceText.char_code_at(" ", 0)) { i } else { yaml_find_comment(s, (i + 1), n) }) } else { yaml_find_comment(s, (i + 1), n) }) })

	yaml_find_char : CceText, I64, I64, I64 -> I64
	yaml_find_char = |s, target, i, n| (if (i >= n) { (0 - 1) } else { (if (CceText.char_code_at(s, i) == target) { i } else { yaml_find_char(s, target, (i + 1), n) }) })

	yaml_slots : I64 -> List(CceText)
	yaml_slots = |n| yaml_fill_slots(0, yaml_capacity(n, 16), [])

	yaml_capacity : I64, I64 -> I64
	yaml_capacity = |n, c| (if (c >= ((2 * n) + 2)) { c } else { yaml_capacity(n, (c * 2)) })

	yaml_fill_slots : I64, I64, List(CceText) -> List(CceText)
	yaml_fill_slots = |i, cap, acc| (if (i >= cap) { acc } else { yaml_fill_slots((i + 1), cap, List.append(acc, "")) })

	yaml_slot : List(CceText), CceText -> I64
	yaml_slot = |slots, key| ({
		mask : I64
		mask = (U64.to_i64_wrap(List.len(slots)) - 1)
		yaml_probe(slots, key, I64.bitwise_and(yaml_hash(key, 0, CceText.len(key), 5381), mask), mask)
	})

	yaml_probe : List(CceText), CceText, I64, I64 -> I64
	yaml_probe = |slots, key, i, mask| ({
		s : CceText
		s = (List.get(slots, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (CceText.len(s) == 0) { i } else { (if (s == key) { i } else { yaml_probe(slots, key, I64.bitwise_and((i + 1), mask), mask) }) })
	})

	yaml_hash : CceText, I64, I64, I64 -> I64
	yaml_hash = |s, i, n, h| (if (i >= n) { h } else { yaml_hash(s, (i + 1), n, I64.bitwise_and(((h * 31) + CceText.char_code_at(s, i)), 16777215)) })

	yaml_emit : Yaml.YamlValue -> CceText
	yaml_emit = |v| yaml_emit_at(v, 0)

	yaml_emit_at : Yaml.YamlValue, I64 -> CceText
	yaml_emit_at = |v, indent| (match v {
		YamlString(s) => yaml_quote_if_needed(s)
		YamlInt(n) => CceText.show_int(n)
		YamlBool(b) => (if b { "true" } else { "false" })
		YamlNull => "null"
		YamlList(items) => CceText.concat_list(yaml_emit_list(items, indent, 0, U64.to_i64_wrap(List.len(items)), []))
		YamlMap(pairs) => CceText.concat_list(yaml_emit_map(pairs, indent, 0, U64.to_i64_wrap(List.len(pairs)), []))
	})

	yaml_emit_list : List(Yaml.YamlValue), I64, I64, I64, List(CceText) -> List(CceText)
	yaml_emit_list = |items, indent, i, len, acc| (if (i >= len) { acc } else { ({
		prefix : CceText
		prefix = (if (i == 0) { "" } else { CceText.concat("\n", yaml_indent(indent)) })
		val : CceText
		val = yaml_emit_at((List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), (indent + 2))
		yaml_emit_list(items, indent, (i + 1), len, List.append(acc, CceText.concat(CceText.concat(prefix, "- "), val)))
	}) })

	yaml_emit_map : List(Yaml.YamlPair), I64, I64, I64, List(CceText) -> List(CceText)
	yaml_emit_map = |pairs, indent, i, len, acc| (if (i >= len) { acc } else { ({
		p = (List.get(pairs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		prefix : CceText
		prefix = (if (i == 0) { "" } else { CceText.concat("\n", yaml_indent(indent)) })
		val : CceText
		val = yaml_emit_at(p.yp_value, (indent + 2))
		yaml_emit_map(pairs, indent, (i + 1), len, List.append(acc, CceText.concat(CceText.concat(CceText.concat(prefix, p.yp_key), ": "), val)))
	}) })

	yaml_indent : I64 -> CceText
	yaml_indent = |n| yaml_spaces(n, "")

	yaml_spaces : I64, CceText -> CceText
	yaml_spaces = |n, acc| (if (n <= 0) { acc } else { yaml_spaces((n - 1), CceText.concat(acc, " ")) })

	yaml_quote_if_needed : CceText -> CceText
	yaml_quote_if_needed = |s| (if yaml_needs_quoting(s) { CceText.concat(CceText.concat("\"", s), "\"") } else { s })

	yaml_needs_quoting : CceText -> Bool
	yaml_needs_quoting = |s| (if (CceText.len(s) == 0) { True } else { (if yaml_starts_with(s, "- ") { True } else { yaml_contains(s, ": ") }) })

	yaml_trim : CceText -> CceText
	yaml_trim = |s| ({
		n : I64
		n = CceText.len(s)
		a : I64
		a = yaml_first_solid(s, 0, n)
		b : I64
		b = yaml_last_solid(s, n)
		(if (a >= b) { "" } else { CceText.substring(s, a, (b - a)) })
	})

	yaml_trim_right : CceText -> CceText
	yaml_trim_right = |s| ({
		b : I64
		b = yaml_last_solid(s, CceText.len(s))
		(if (b == CceText.len(s)) { s } else { CceText.substring(s, 0, b) })
	})

	yaml_first_solid : CceText, I64, I64 -> I64
	yaml_first_solid = |s, i, n| (if (i >= n) { n } else { (if (CceText.char_code_at(s, i) == CceText.char_code_at(" ", 0)) { yaml_first_solid(s, (i + 1), n) } else { i }) })

	yaml_last_solid : CceText, I64 -> I64
	yaml_last_solid = |s, j| (if (j <= 0) { 0 } else { (if (CceText.char_code_at(s, (j - 1)) == CceText.char_code_at(" ", 0)) { yaml_last_solid(s, (j - 1)) } else { j }) })

	yaml_starts_with : CceText, CceText -> Bool
	yaml_starts_with = |s, prefix| CceText.starts_with(s, prefix)

	yaml_contains : CceText, CceText -> Bool
	yaml_contains = |s, sub| CceText.contains(s, sub)

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

	eq_YamlPair : Yaml.YamlPair, Yaml.YamlPair -> Bool
	eq_YamlPair = |ex, ey| ((ex.yp_key == ey.yp_key) and eq_YamlValue(ex.yp_value, ey.yp_value))
}
