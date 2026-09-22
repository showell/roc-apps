# Asn1 -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Maybe

Asn1 :: [].{
	Asn1Tlv : { tlv_tag : I64, tlv_hdr : I64, tlv_off : I64, tlv_len : I64 }

	asn1_boolean : I64
	asn1_boolean = 1

	asn1_integer : I64
	asn1_integer = 2

	asn1_bit_string_tag : I64
	asn1_bit_string_tag = 3

	asn1_octet_string : I64
	asn1_octet_string = 4

	asn1_null : I64
	asn1_null = 5

	asn1_oid : I64
	asn1_oid = 6

	asn1_utf8_string : I64
	asn1_utf8_string = 12

	asn1_printable_string : I64
	asn1_printable_string = 19

	asn1_ia5_string : I64
	asn1_ia5_string = 22

	asn1_utc_time : I64
	asn1_utc_time = 23

	asn1_general_time : I64
	asn1_general_time = 24

	asn1_sequence : I64
	asn1_sequence = 48

	asn1_set : I64
	asn1_set = 49

	asn1_ctx0 : I64
	asn1_ctx0 = 160

	asn1_ctx1 : I64
	asn1_ctx1 = 161

	asn1_ctx3 : I64
	asn1_ctx3 = 163

	asn1_read : List(I64), I64 -> Maybe.Maybe(Asn1.Asn1Tlv)
	asn1_read = |buf, off| (if (off < 0) { None } else { (if ((off + 1) >= U64.to_i64_wrap(List.len(buf))) { None } else { asn1_read_len(buf, off, (List.get(buf, I64.to_u64_wrap(off)) ?? crash("list-at out of range"))) }) })

	asn1_read_len : List(I64), I64, I64 -> Maybe.Maybe(Asn1.Asn1Tlv)
	asn1_read_len = |buf, off, tag| (if (I64.bitwise_and(tag, 31) == 31) { None } else { asn1_len_form(buf, off, tag, (List.get(buf, I64.to_u64_wrap((off + 1))) ?? crash("list-at out of range"))) })

	asn1_len_form : List(I64), I64, I64, I64 -> Maybe.Maybe(Asn1.Asn1Tlv)
	asn1_len_form = |buf, off, tag, l0| (if (l0 < 128) { asn1_mk(buf, tag, off, (off + 2), l0) } else { (if (l0 == 128) { None } else { (if (l0 == 255) { None } else { asn1_long_len(buf, off, tag, (l0 - 128)) }) }) })

	asn1_long_len : List(I64), I64, I64, I64 -> Maybe.Maybe(Asn1.Asn1Tlv)
	asn1_long_len = |buf, off, tag, n| (if (n > 4) { None } else { (if (((off + 2) + n) > U64.to_i64_wrap(List.len(buf))) { None } else { (if ((List.get(buf, I64.to_u64_wrap((off + 2))) ?? crash("list-at out of range")) == 0) { None } else { asn1_long_check(buf, off, tag, n, asn1_be(buf, (off + 2), n, 0)) }) }) })

	asn1_long_check : List(I64), I64, I64, I64, I64 -> Maybe.Maybe(Asn1.Asn1Tlv)
	asn1_long_check = |buf, off, tag, n, len| (if (n == 1) { (if (len < 128) { None } else { asn1_mk(buf, tag, off, ((off + 2) + n), len) }) } else { asn1_mk(buf, tag, off, ((off + 2) + n), len) })

	asn1_be : List(I64), I64, I64, I64 -> I64
	asn1_be = |buf, off, n, acc| (if (n <= 0) { acc } else { asn1_be(buf, (off + 1), (n - 1), ((acc * 256) + (List.get(buf, I64.to_u64_wrap(off)) ?? crash("list-at out of range")))) })

	asn1_mk : List(I64), I64, I64, I64, I64 -> Maybe.Maybe(Asn1.Asn1Tlv)
	asn1_mk = |buf, tag, hdr, off, len| (if (len < 0) { None } else { (if ((off + len) > U64.to_i64_wrap(List.len(buf))) { None } else { Just({ tlv_tag: tag, tlv_hdr: hdr, tlv_off: off, tlv_len: len }) }) })

	asn1_read_tag : List(I64), I64, I64 -> Maybe.Maybe(Asn1.Asn1Tlv)
	asn1_read_tag = |buf, off, want| (match asn1_read(buf, off) {
		None => None
		Just(t) => (if (t.tlv_tag == want) { Just(t) } else { None })
	})

	asn1_end : Asn1.Asn1Tlv -> I64
	asn1_end = |t| (t.tlv_off + t.tlv_len)

	asn1_content : List(I64), Asn1.Asn1Tlv -> List(I64)
	asn1_content = |buf, t| asn1_slice(buf, t.tlv_off, t.tlv_len)

	asn1_raw : List(I64), Asn1.Asn1Tlv -> List(I64)
	asn1_raw = |buf, t| asn1_slice(buf, t.tlv_hdr, (asn1_end(t) - t.tlv_hdr))

	asn1_slice : List(I64), I64, I64 -> List(I64)
	asn1_slice = |buf, off, n| asn1_slice_loop(buf, off, n, 0, [])

	asn1_slice_loop : List(I64), I64, I64, I64, List(I64) -> List(I64)
	asn1_slice_loop = |buf, off, n, i, acc| (if (i >= n) { acc } else { (if ((off + i) >= U64.to_i64_wrap(List.len(buf))) { acc } else { asn1_slice_loop(buf, off, n, (i + 1), List.append(acc, (List.get(buf, I64.to_u64_wrap((off + i))) ?? crash("list-at out of range")))) }) })

	asn1_bit_string : List(I64), I64 -> Maybe.Maybe(List(I64))
	asn1_bit_string = |buf, off| (match asn1_read_tag(buf, off, asn1_bit_string_tag) {
		None => None
		Just(t) => asn1_bit_body(buf, t)
	})

	asn1_bit_body : List(I64), Asn1.Asn1Tlv -> Maybe.Maybe(List(I64))
	asn1_bit_body = |buf, t| (if (t.tlv_len < 1) { None } else { (if ((List.get(buf, I64.to_u64_wrap(t.tlv_off)) ?? crash("list-at out of range")) != 0) { None } else { Just(asn1_slice(buf, (t.tlv_off + 1), (t.tlv_len - 1))) }) })

	asn1_oid_is : List(I64), Asn1.Asn1Tlv, List(I64) -> Bool
	asn1_oid_is = |buf, t, want| (if (t.tlv_tag != asn1_oid) { False } else { (if (t.tlv_len != U64.to_i64_wrap(List.len(want))) { False } else { asn1_bytes_eq(buf, t.tlv_off, want, 0, U64.to_i64_wrap(List.len(want))) }) })

	asn1_bytes_eq : List(I64), I64, List(I64), I64, I64 -> Bool
	asn1_bytes_eq = |buf, off, want, i, n| (if (i >= n) { True } else { (if ((List.get(buf, I64.to_u64_wrap((off + i))) ?? crash("list-at out of range")) != (List.get(want, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { asn1_bytes_eq(buf, off, want, (i + 1), n) }) })

	asn1_int_bytes : List(I64), I64 -> Maybe.Maybe(List(I64))
	asn1_int_bytes = |buf, off| (match asn1_read_tag(buf, off, asn1_integer) {
		None => None
		Just(t) => asn1_int_body(buf, t)
	})

	asn1_int_body : List(I64), Asn1.Asn1Tlv -> Maybe.Maybe(List(I64))
	asn1_int_body = |buf, t| (if (t.tlv_len < 1) { None } else { (if (t.tlv_len == 1) { Just(asn1_content(buf, t)) } else { asn1_int_minimal(buf, t, (List.get(buf, I64.to_u64_wrap(t.tlv_off)) ?? crash("list-at out of range")), (List.get(buf, I64.to_u64_wrap((t.tlv_off + 1))) ?? crash("list-at out of range"))) }) })

	asn1_int_minimal : List(I64), Asn1.Asn1Tlv, I64, I64 -> Maybe.Maybe(List(I64))
	asn1_int_minimal = |buf, t, b0, b1| (if (b0 == 0) { (if (I64.bitwise_and(b1, 128) == 128) { Just(asn1_content(buf, t)) } else { None }) } else { (if (b0 == 255) { (if (I64.bitwise_and(b1, 128) == 0) { Just(asn1_content(buf, t)) } else { None }) } else { Just(asn1_content(buf, t)) }) })

	asn1_small_int : List(I64), I64 -> Maybe.Maybe(I64)
	asn1_small_int = |buf, off| (match asn1_int_bytes(buf, off) {
		None => None
		Just(bs) => asn1_small_of(bs)
	})

	asn1_small_of : List(I64) -> Maybe.Maybe(I64)
	asn1_small_of = |bs| (if (U64.to_i64_wrap(List.len(bs)) < 1) { None } else { (if (U64.to_i64_wrap(List.len(bs)) > 4) { None } else { (if (I64.bitwise_and((List.get(bs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")), 128) == 128) { None } else { Just(asn1_small_loop(bs, 0, U64.to_i64_wrap(List.len(bs)), 0)) }) }) })

	asn1_small_loop : List(I64), I64, I64, I64 -> I64
	asn1_small_loop = |bs, i, n, acc| (if (i >= n) { acc } else { asn1_small_loop(bs, (i + 1), n, ((acc * 256) + (List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	asn1_children : List(I64), Asn1.Asn1Tlv -> List(Asn1.Asn1Tlv)
	asn1_children = |buf, parent| asn1_child_loop(buf, parent.tlv_off, asn1_end(parent), [])

	asn1_child_loop : List(I64), I64, I64, List(Asn1.Asn1Tlv) -> List(Asn1.Asn1Tlv)
	asn1_child_loop = |buf, off, stop, acc| (if (off >= stop) { acc } else { asn1_child_step(buf, off, stop, acc, asn1_read(buf, off)) })

	asn1_child_step : List(I64), I64, I64, List(Asn1.Asn1Tlv), Maybe.Maybe(Asn1.Asn1Tlv) -> List(Asn1.Asn1Tlv)
	asn1_child_step = |buf, _off, stop, acc, m| (match m {
		None => acc
		Just(t) => asn1_child_next(buf, stop, acc, t)
	})

	asn1_child_next : List(I64), I64, List(Asn1.Asn1Tlv), Asn1.Asn1Tlv -> List(Asn1.Asn1Tlv)
	asn1_child_next = |buf, stop, acc, t| (if (asn1_end(t) > stop) { acc } else { asn1_child_loop(buf, asn1_end(t), stop, List.append(acc, t)) })

	asn1_nth : List(Asn1.Asn1Tlv), I64 -> Maybe.Maybe(Asn1.Asn1Tlv)
	asn1_nth = |ts, i| (if (i < 0) { None } else { (if (i >= U64.to_i64_wrap(List.len(ts))) { None } else { Just((List.get(ts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) }) })
}
