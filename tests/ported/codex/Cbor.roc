# Cbor -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceChar
import CceText
import Maybe

Cbor :: [].{
	CborValue := [CborUint(I64), CborNint(I64), CborBytes(List(I64)), CborText(CceText), CborArray(List(Cbor.CborValue)), CborMap(List(Cbor.CborMapEntry)), CborBool(Bool), CborNull, CborTag(I64, Cbor.CborValue)].{
		is_eq : Cbor.CborValue, Cbor.CborValue -> Bool
		is_eq = |a, b| eq_CborValue(a, b)
	}
	CborMapEntry := { cme_key : Cbor.CborValue, cme_value : Cbor.CborValue }.{
		is_eq : Cbor.CborMapEntry, Cbor.CborMapEntry -> Bool
		is_eq = |a, b| a.cme_key == b.cme_key and a.cme_value == b.cme_value
	}
	CborDecodeResult := { cdr_value : Cbor.CborValue, cdr_offset : I64 }.{
		is_eq : Cbor.CborDecodeResult, Cbor.CborDecodeResult -> Bool
		is_eq = |a, b| a.cdr_value == b.cdr_value and a.cdr_offset == b.cdr_offset
	}
	CborHeadResult := { arg : I64, next : I64 }.{
		is_eq : Cbor.CborHeadResult, Cbor.CborHeadResult -> Bool
		is_eq = |a, b| a.arg == b.arg and a.next == b.next
	}

	cbor_mt_uint : I64
	cbor_mt_uint = 0

	cbor_mt_nint : I64
	cbor_mt_nint = 1

	cbor_mt_bytes : I64
	cbor_mt_bytes = 2

	cbor_mt_text : I64
	cbor_mt_text = 3

	cbor_mt_array : I64
	cbor_mt_array = 4

	cbor_mt_map : I64
	cbor_mt_map = 5

	cbor_mt_tag : I64
	cbor_mt_tag = 6

	cbor_mt_simple : I64
	cbor_mt_simple = 7

	cbor_encode : Cbor.CborValue -> List(I64)
	cbor_encode = |v| (match v {
		CborUint(n) => cbor_encode_head(cbor_mt_uint, n)
		CborNint(n) => cbor_encode_head(cbor_mt_nint, ((0 - 1) - n))
		CborBytes(bs) => List.concat(cbor_encode_head(cbor_mt_bytes, U64.to_i64_wrap(List.len(bs))), bs)
		CborText(s) => cbor_encode_text_value(s)
		CborArray(items) => List.concat(cbor_encode_head(cbor_mt_array, U64.to_i64_wrap(List.len(items))), cbor_encode_array(items, 0, U64.to_i64_wrap(List.len(items)), []))
		CborMap(entries) => List.concat(cbor_encode_head(cbor_mt_map, U64.to_i64_wrap(List.len(entries))), cbor_encode_map(entries, 0, U64.to_i64_wrap(List.len(entries)), []))
		CborBool(b) => [(if b { 245 } else { 244 })]
		CborNull => [246]
		CborTag(tag, inner) => List.concat(cbor_encode_head(cbor_mt_tag, tag), cbor_encode(inner))
	})

	cbor_encode_head : I64, I64 -> List(I64)
	cbor_encode_head = |mt, n| ({
		major = I64.shl_wrap(mt, I64.to_u8_wrap(5))
		(if (n < 24) { [I64.bitwise_or(major, n)] } else { (if (n < 256) { [I64.bitwise_or(major, 24), n] } else { (if (n < 65536) { [I64.bitwise_or(major, 25), I64.shr_zf_wrap(n, I64.to_u8_wrap(8)), I64.bitwise_and(n, 255)] } else { [I64.bitwise_or(major, 26), I64.bitwise_and(I64.shr_zf_wrap(n, I64.to_u8_wrap(24)), 255), I64.bitwise_and(I64.shr_zf_wrap(n, I64.to_u8_wrap(16)), 255), I64.bitwise_and(I64.shr_zf_wrap(n, I64.to_u8_wrap(8)), 255), I64.bitwise_and(n, 255)] }) }) })
	})

	cbor_encode_text_value : CceText -> List(I64)
	cbor_encode_text_value = |s| ({
		bytes = cbor_text_to_bytes(s, 0, CceText.len(s), [])
		List.concat(cbor_encode_head(cbor_mt_text, U64.to_i64_wrap(List.len(bytes))), bytes)
	})

	cbor_text_to_bytes : CceText, I64, I64, List(I64) -> List(I64)
	cbor_text_to_bytes = |s, i, len, acc| (if (i >= len) { acc } else { cbor_text_to_bytes(s, (i + 1), len, List.append(acc, CceChar.code(CceText.char_at(s, i)))) })

	cbor_encode_array : List(Cbor.CborValue), I64, I64, List(I64) -> List(I64)
	cbor_encode_array = |items, i, len, acc| (if (i >= len) { acc } else { cbor_encode_array(items, (i + 1), len, List.concat(acc, cbor_encode((List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	cbor_encode_map : List(Cbor.CborMapEntry), I64, I64, List(I64) -> List(I64)
	cbor_encode_map = |entries, i, len, acc| (if (i >= len) { acc } else { ({
		e = (List.get(entries, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		cbor_encode_map(entries, (i + 1), len, List.concat(List.concat(acc, cbor_encode(e.cme_key)), cbor_encode(e.cme_value)))
	}) })

	cbor_encode_int : I64 -> List(I64)
	cbor_encode_int = |n| (if (n >= 0) { cbor_encode(CborUint(n)) } else { cbor_encode(CborNint(n)) })

	cbor_encode_text : CceText -> List(I64)
	cbor_encode_text = |s| cbor_encode(CborText(s))

	cbor_encode_bytes : List(I64) -> List(I64)
	cbor_encode_bytes = |bs| cbor_encode(CborBytes(bs))

	cbor_decode : List(I64) -> Maybe.Maybe(Cbor.CborValue)
	cbor_decode = |bs| (if (U64.to_i64_wrap(List.len(bs)) == 0) { None } else { ({
		r = cbor_decode_at(bs, 0)
		Just(r.cdr_value)
	}) })

	cbor_decode_at : List(I64), I64 -> Cbor.CborDecodeResult
	cbor_decode_at = |bs, off| ({
		initial = (List.get(bs, I64.to_u64_wrap(off)) ?? crash("list-at out of range"))
		mt = I64.shr_zf_wrap(initial, I64.to_u8_wrap(5))
		ai = I64.bitwise_and(initial, 31)
		hr = cbor_read_arg(bs, (off + 1), ai)
		cbor_dispatch(mt, hr.arg, bs, hr.next)
	})

	cbor_read_arg : List(I64), I64, I64 -> Cbor.CborHeadResult
	cbor_read_arg = |bs, off, ai| (if (ai < 24) { Cbor.CborHeadResult.{ arg: ai, next: off } } else { (if (ai == 24) { Cbor.CborHeadResult.{ arg: (List.get(bs, I64.to_u64_wrap(off)) ?? crash("list-at out of range")), next: (off + 1) } } else { (if (ai == 25) { Cbor.CborHeadResult.{ arg: I64.bitwise_or(I64.shl_wrap((List.get(bs, I64.to_u64_wrap(off)) ?? crash("list-at out of range")), I64.to_u8_wrap(8)), (List.get(bs, I64.to_u64_wrap((off + 1))) ?? crash("list-at out of range"))), next: (off + 2) } } else { ({
		hi = I64.bitwise_or(I64.shl_wrap((List.get(bs, I64.to_u64_wrap(off)) ?? crash("list-at out of range")), I64.to_u8_wrap(24)), I64.shl_wrap((List.get(bs, I64.to_u64_wrap((off + 1))) ?? crash("list-at out of range")), I64.to_u8_wrap(16)))
		lo = I64.bitwise_or(I64.shl_wrap((List.get(bs, I64.to_u64_wrap((off + 2))) ?? crash("list-at out of range")), I64.to_u8_wrap(8)), (List.get(bs, I64.to_u64_wrap((off + 3))) ?? crash("list-at out of range")))
		Cbor.CborHeadResult.{ arg: I64.bitwise_or(hi, lo), next: (off + 4) }
	}) }) }) })

	cbor_dispatch : I64, I64, List(I64), I64 -> Cbor.CborDecodeResult
	cbor_dispatch = |mt, arg, bs, off| (if (mt == cbor_mt_uint) { Cbor.CborDecodeResult.{ cdr_value: CborUint(arg), cdr_offset: off } } else { (if (mt == cbor_mt_nint) { Cbor.CborDecodeResult.{ cdr_value: CborNint(((0 - 1) - arg)), cdr_offset: off } } else { (if (mt == cbor_mt_bytes) { cbor_decode_bytes(bs, off, arg) } else { (if (mt == cbor_mt_text) { cbor_decode_text(bs, off, arg) } else { (if (mt == cbor_mt_array) { cbor_decode_array(bs, off, arg) } else { (if (mt == cbor_mt_map) { cbor_decode_map_items(bs, off, arg) } else { (if (mt == cbor_mt_simple) { cbor_decode_simple(arg, off) } else { Cbor.CborDecodeResult.{ cdr_value: CborNull, cdr_offset: off } }) }) }) }) }) }) })

	cbor_decode_bytes : List(I64), I64, I64 -> Cbor.CborDecodeResult
	cbor_decode_bytes = |bs, off, len| ({
		data = cbor_slice(bs, off, len, 0, [])
		Cbor.CborDecodeResult.{ cdr_value: CborBytes(data), cdr_offset: (off + len) }
	})

	cbor_decode_text : List(I64), I64, I64 -> Cbor.CborDecodeResult
	cbor_decode_text = |bs, off, len| ({
		bytes = cbor_slice(bs, off, len, 0, [])
		s = cbor_bytes_to_text(bytes, 0, U64.to_i64_wrap(List.len(bytes)), "")
		Cbor.CborDecodeResult.{ cdr_value: CborText(s), cdr_offset: (off + len) }
	})

	cbor_decode_array : List(I64), I64, I64 -> Cbor.CborDecodeResult
	cbor_decode_array = |bs, off, count| cbor_decode_array_loop(bs, off, count, 0, [])

	cbor_decode_array_loop : List(I64), I64, I64, I64, List(Cbor.CborValue) -> Cbor.CborDecodeResult
	cbor_decode_array_loop = |bs, off, count, i, acc| (if (i >= count) { Cbor.CborDecodeResult.{ cdr_value: CborArray(acc), cdr_offset: off } } else { ({
		r = cbor_decode_at(bs, off)
		cbor_decode_array_loop(bs, r.cdr_offset, count, (i + 1), List.append(acc, r.cdr_value))
	}) })

	cbor_decode_map_items : List(I64), I64, I64 -> Cbor.CborDecodeResult
	cbor_decode_map_items = |bs, off, count| cbor_decode_map_loop(bs, off, count, 0, [])

	cbor_decode_map_loop : List(I64), I64, I64, I64, List(Cbor.CborMapEntry) -> Cbor.CborDecodeResult
	cbor_decode_map_loop = |bs, off, count, i, acc| (if (i >= count) { Cbor.CborDecodeResult.{ cdr_value: CborMap(acc), cdr_offset: off } } else { ({
		kr = cbor_decode_at(bs, off)
		vr = cbor_decode_at(bs, kr.cdr_offset)
		cbor_decode_map_loop(bs, vr.cdr_offset, count, (i + 1), List.append(acc, Cbor.CborMapEntry.{ cme_key: kr.cdr_value, cme_value: vr.cdr_value }))
	}) })

	cbor_decode_simple : I64, I64 -> Cbor.CborDecodeResult
	cbor_decode_simple = |val, off| (if (val == 20) { Cbor.CborDecodeResult.{ cdr_value: CborBool(False), cdr_offset: off } } else { (if (val == 21) { Cbor.CborDecodeResult.{ cdr_value: CborBool(True), cdr_offset: off } } else { Cbor.CborDecodeResult.{ cdr_value: CborNull, cdr_offset: off } }) })

	cbor_slice : List(I64), I64, I64, I64, List(I64) -> List(I64)
	cbor_slice = |bs, off, len, i, acc| (if (i >= len) { acc } else { cbor_slice(bs, off, len, (i + 1), List.append(acc, (List.get(bs, I64.to_u64_wrap((off + i))) ?? crash("list-at out of range")))) })

	cbor_bytes_to_text : List(I64), I64, I64, CceText -> CceText
	cbor_bytes_to_text = |bs, i, len, acc| (if (i >= len) { acc } else { cbor_bytes_to_text(bs, (i + 1), len, CceText.concat(acc, CceText.char_to_text(CceChar.of_code((List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))) })

	eq_CborValue : Cbor.CborValue, Cbor.CborValue -> Bool
	eq_CborValue = |ex, ey| (match ex {
		CborUint(exf0) => (match ey {
			CborUint(eyf0) => (exf0 == eyf0)
			_ => False
		})
		CborNint(exf0) => (match ey {
			CborNint(eyf0) => (exf0 == eyf0)
			_ => False
		})
		CborBytes(exf0) => (match ey {
			CborBytes(eyf0) => (exf0 == eyf0)
			_ => False
		})
		CborText(exf0) => (match ey {
			CborText(eyf0) => (exf0 == eyf0)
			_ => False
		})
		CborArray(exf0) => (match ey {
			CborArray(eyf0) => (exf0 == eyf0)
			_ => False
		})
		CborMap(exf0) => (match ey {
			CborMap(eyf0) => (exf0 == eyf0)
			_ => False
		})
		CborBool(exf0) => (match ey {
			CborBool(eyf0) => (exf0 == eyf0)
			_ => False
		})
		CborNull => (match ey {
			CborNull => True
			_ => False
		})
		CborTag(exf0, exf1) => (match ey {
			CborTag(eyf0, eyf1) => ((exf0 == eyf0) and eq_CborValue(exf1, eyf1))
			_ => False
		})
	})
}
