# Bencode -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceChar
import CceText

Bencode :: [].{
	BenValue := [BenInt(I64), BenStr(CceText), BenList(List(Bencode.BenValue)), BenDict(List(Bencode.BenPair))].{
		is_eq : Bencode.BenValue, Bencode.BenValue -> Bool
		is_eq = |a, b| eq_BenValue(a, b)
	}
	BenPair := { ben_key : CceText, ben_val : Bencode.BenValue }.{
		is_eq : Bencode.BenPair, Bencode.BenPair -> Bool
		is_eq = |a, b| a.ben_key == b.ben_key and a.ben_val == b.ben_val
	}
	BenDecodeResult := { ben_value : Bencode.BenValue, ben_pos : I64, ben_ok : Bool }.{
		is_eq : Bencode.BenDecodeResult, Bencode.BenDecodeResult -> Bool
		is_eq = |a, b| a.ben_value == b.ben_value and a.ben_pos == b.ben_pos and a.ben_ok == b.ben_ok
	}

	ben_encode : Bencode.BenValue -> CceText
	ben_encode = |v| (match v {
		BenInt(n) => CceText.concat(CceText.concat("i", CceText.show_int(n)), "e")
		BenStr(s) => CceText.concat(CceText.concat(CceText.show_int(CceText.len(s)), ":"), s)
		BenList(items) => CceText.concat(CceText.concat("l", ben_encode_list(items, 0, U64.to_i64_wrap(List.len(items)), "")), "e")
		BenDict(pairs) => CceText.concat(CceText.concat("d", ben_encode_dict(pairs, 0, U64.to_i64_wrap(List.len(pairs)), "")), "e")
	})

	ben_encode_list : List(Bencode.BenValue), I64, I64, CceText -> CceText
	ben_encode_list = |items, i, len, acc| (if (i >= len) { acc } else { ben_encode_list(items, (i + 1), len, CceText.concat(acc, ben_encode((List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	ben_encode_dict : List(Bencode.BenPair), I64, I64, CceText -> CceText
	ben_encode_dict = |pairs, i, len, acc| (if (i >= len) { acc } else { ({
		p = (List.get(pairs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		ben_encode_dict(pairs, (i + 1), len, CceText.concat(CceText.concat(acc, ben_encode(BenStr(p.ben_key))), ben_encode(p.ben_val)))
	}) })

	ben_max_depth : I64
	ben_max_depth = 256

	ben_fail : I64 -> Bencode.BenDecodeResult
	ben_fail = |pos| Bencode.BenDecodeResult.{ ben_value: BenInt(0), ben_pos: pos, ben_ok: False }

	ben_decode : CceText -> Bencode.BenDecodeResult
	ben_decode = |s| ({
		r = ben_decode_at(s, 0, CceText.len(s))
		(if (r.ben_ok and (r.ben_pos != CceText.len(s))) { ben_fail(r.ben_pos) } else { r })
	})

	ben_decode_at : CceText, I64, I64 -> Bencode.BenDecodeResult
	ben_decode_at = |s, pos, len| ben_decode_item(s, pos, len, 0)

	ben_decode_item : CceText, I64, I64, I64 -> Bencode.BenDecodeResult
	ben_decode_item = |s, pos, len, depth| (if (depth > ben_max_depth) { ben_fail(pos) } else { (if (pos >= len) { ben_fail(pos) } else { ({
		ch : I64
		ch = CceChar.code(CceText.char_at(s, pos))
		(if (ch == CceChar.code(CceText.char_at("i", 0))) { ben_decode_int(s, (pos + 1), len) } else { (if (ch == CceChar.code(CceText.char_at("l", 0))) { ben_decode_list(s, (pos + 1), len, [], (depth + 1)) } else { (if (ch == CceChar.code(CceText.char_at("d", 0))) { ben_decode_dict(s, (pos + 1), len, [], (depth + 1)) } else { ben_decode_str(s, pos, len) }) }) })
	}) }) })

	ben_decode_int : CceText, I64, I64 -> Bencode.BenDecodeResult
	ben_decode_int = |s, pos, len| ({
		e_pos : I64
		e_pos = ben_find_char(s, pos, len, CceChar.code(CceText.char_at("e", 0)))
		(if (e_pos >= len) { ben_fail(pos) } else { ({
			neg : Bool
			neg = ((pos < e_pos) and (CceChar.code(CceText.char_at(s, pos)) == CceChar.code(CceText.char_at("-", 0))))
			start : I64
			start = (if neg { (pos + 1) } else { pos })
			n : I64
			n = ben_parse_digits(s, start, e_pos)
			(if (n < 0) { ben_fail(pos) } else { (if (neg and (n == 0)) { ben_fail(pos) } else { Bencode.BenDecodeResult.{ ben_value: BenInt((if neg { (0 - n) } else { n })), ben_pos: (e_pos + 1), ben_ok: True } }) })
		}) })
	})

	ben_decode_str : CceText, I64, I64 -> Bencode.BenDecodeResult
	ben_decode_str = |s, pos, len| ({
		colon : I64
		colon = ben_find_char(s, pos, len, CceChar.code(CceText.char_at(":", 0)))
		(if (colon >= len) { ben_fail(pos) } else { ({
			str_len : I64
			str_len = ben_parse_digits(s, pos, colon)
			str_start : I64
			str_start = (colon + 1)
			(if (str_len < 0) { ben_fail(pos) } else { (if (str_len > (len - str_start)) { ben_fail(pos) } else { Bencode.BenDecodeResult.{ ben_value: BenStr(CceText.substring(s, str_start, str_len)), ben_pos: (str_start + str_len), ben_ok: True } }) })
		}) })
	})

	ben_decode_list : CceText, I64, I64, List(Bencode.BenValue), I64 -> Bencode.BenDecodeResult
	ben_decode_list = |s, pos, len, acc, depth| (if (pos >= len) { ben_fail(pos) } else { (if (CceChar.code(CceText.char_at(s, pos)) == CceChar.code(CceText.char_at("e", 0))) { Bencode.BenDecodeResult.{ ben_value: BenList(acc), ben_pos: (pos + 1), ben_ok: True } } else { ({
		item = ben_decode_item(s, pos, len, depth)
		(if item.ben_ok { ben_decode_list(s, item.ben_pos, len, List.append(acc, item.ben_value), depth) } else { ben_fail(pos) })
	}) }) })

	ben_decode_dict : CceText, I64, I64, List(Bencode.BenPair), I64 -> Bencode.BenDecodeResult
	ben_decode_dict = |s, pos, len, acc, depth| (if (pos >= len) { ben_fail(pos) } else { (if (CceChar.code(CceText.char_at(s, pos)) == CceChar.code(CceText.char_at("e", 0))) { Bencode.BenDecodeResult.{ ben_value: BenDict(acc), ben_pos: (pos + 1), ben_ok: True } } else { ({
		key_result = ben_decode_str(s, pos, len)
		(if (key_result.ben_ok == False) { ben_fail(pos) } else { ({
			key : CceText
			key = (match key_result.ben_value {
				BenStr(k) => k
				_ => ""
			})
			val_result = ben_decode_item(s, key_result.ben_pos, len, depth)
			(if val_result.ben_ok { ben_decode_dict(s, val_result.ben_pos, len, List.append(acc, Bencode.BenPair.{ ben_key: key, ben_val: val_result.ben_value }), depth) } else { ben_fail(pos) })
		}) })
	}) }) })

	ben_find_char : CceText, I64, I64, I64 -> I64
	ben_find_char = |s, i, len, target| (if (i >= len) { len } else { (if (CceChar.code(CceText.char_at(s, i)) == target) { i } else { ben_find_char(s, (i + 1), len, target) }) })

	ben_parse_digits : CceText, I64, I64 -> I64
	ben_parse_digits = |s, start, stop| (if (start >= stop) { (0 - 1) } else { (if (((stop - start) > 1) and (ben_digit_value(CceChar.code(CceText.char_at(s, start))) == 0)) { (0 - 1) } else { ben_parse_digits_loop(s, start, stop, 0) }) })

	ben_parse_digits_loop : CceText, I64, I64, I64 -> I64
	ben_parse_digits_loop = |s, i, stop, acc| (if (i >= stop) { acc } else { ({
		d : I64
		d = ben_digit_value(CceChar.code(CceText.char_at(s, i)))
		(if (d < 0) { (0 - 1) } else { (if (acc > 922337203685477580) { (0 - 1) } else { (if ((acc == 922337203685477580) and (d > 7)) { (0 - 1) } else { ben_parse_digits_loop(s, (i + 1), stop, ((acc * 10) + d)) }) }) })
	}) })

	ben_digit_value : I64 -> I64
	ben_digit_value = |c| (if (c == CceChar.code(CceText.char_at("0", 0))) { 0 } else { (if (c == CceChar.code(CceText.char_at("1", 0))) { 1 } else { (if (c == CceChar.code(CceText.char_at("2", 0))) { 2 } else { (if (c == CceChar.code(CceText.char_at("3", 0))) { 3 } else { (if (c == CceChar.code(CceText.char_at("4", 0))) { 4 } else { (if (c == CceChar.code(CceText.char_at("5", 0))) { 5 } else { (if (c == CceChar.code(CceText.char_at("6", 0))) { 6 } else { (if (c == CceChar.code(CceText.char_at("7", 0))) { 7 } else { (if (c == CceChar.code(CceText.char_at("8", 0))) { 8 } else { (if (c == CceChar.code(CceText.char_at("9", 0))) { 9 } else { (0 - 1) }) }) }) }) }) }) }) }) }) })

	eq_BenValue : Bencode.BenValue, Bencode.BenValue -> Bool
	eq_BenValue = |ex, ey| (match ex {
		BenInt(exf0) => (match ey {
			BenInt(eyf0) => (exf0 == eyf0)
			_ => False
		})
		BenStr(exf0) => (match ey {
			BenStr(eyf0) => (exf0 == eyf0)
			_ => False
		})
		BenList(exf0) => (match ey {
			BenList(eyf0) => (exf0 == eyf0)
			_ => False
		})
		BenDict(exf0) => (match ey {
			BenDict(eyf0) => (exf0 == eyf0)
			_ => False
		})
	})
}
