# Asn1Write -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Asn1

Asn1Write :: [].{

	der_len : I64 -> List(I64)
	der_len = |n| (if (n < 128) { [n] } else { (if (n < 256) { [129, n] } else { (if (n < 65536) { [130, I64.shr_zf_wrap(n, I64.to_u8_wrap(8)), I64.bitwise_and(n, 255)] } else { (if (n < 16777216) { [131, I64.shr_zf_wrap(n, I64.to_u8_wrap(16)), I64.bitwise_and(I64.shr_zf_wrap(n, I64.to_u8_wrap(8)), 255), I64.bitwise_and(n, 255)] } else { [132, I64.shr_zf_wrap(n, I64.to_u8_wrap(24)), I64.bitwise_and(I64.shr_zf_wrap(n, I64.to_u8_wrap(16)), 255), I64.bitwise_and(I64.shr_zf_wrap(n, I64.to_u8_wrap(8)), 255), I64.bitwise_and(n, 255)] }) }) }) })

	der_tlv : I64, List(I64) -> List(I64)
	der_tlv = |tag, content| List.concat(List.concat([tag], der_len(U64.to_i64_wrap(List.len(content)))), content)

	der_int_content : I64 -> List(I64)
	der_int_content = |v| (if (v == 0) { [0] } else { der_int_pad(der_be_min(v, [])) })

	der_be_min : I64, List(I64) -> List(I64)
	der_be_min = |v, acc| (if (v == 0) { acc } else { der_be_min(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), List.concat([I64.bitwise_and(v, 255)], acc)) })

	der_int_pad : List(I64) -> List(I64)
	der_int_pad = |bs| (if (U64.to_i64_wrap(List.len(bs)) < 1) { [0] } else { (if (I64.bitwise_and((List.get(bs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")), 128) == 128) { List.concat([0], bs) } else { bs }) })

	der_small_int : I64 -> List(I64)
	der_small_int = |v| der_tlv(Asn1.asn1_integer, der_int_content(v))

	der_int_bytes : List(I64) -> List(I64)
	der_int_bytes = |bs| der_tlv(Asn1.asn1_integer, bs)

	der_bool : Bool -> List(I64)
	der_bool = |b| der_tlv(Asn1.asn1_boolean, (if b { [255] } else { [0] }))

	der_null : List(I64)
	der_null = [Asn1.asn1_null, 0]

	der_octet_string : List(I64) -> List(I64)
	der_octet_string = |bs| der_tlv(Asn1.asn1_octet_string, bs)

	der_bit_string : List(I64) -> List(I64)
	der_bit_string = |bs| der_tlv(Asn1.asn1_bit_string_tag, List.concat([0], bs))

	der_oid : List(I64) -> List(I64)
	der_oid = |content| der_tlv(Asn1.asn1_oid, content)

	der_utf8_string : List(I64) -> List(I64)
	der_utf8_string = |bs| der_tlv(Asn1.asn1_utf8_string, bs)

	der_printable_string : List(I64) -> List(I64)
	der_printable_string = |bs| der_tlv(Asn1.asn1_printable_string, bs)

	der_ia5_string : List(I64) -> List(I64)
	der_ia5_string = |bs| der_tlv(Asn1.asn1_ia5_string, bs)

	der_utc_time : List(I64) -> List(I64)
	der_utc_time = |bs| der_tlv(Asn1.asn1_utc_time, bs)

	der_general_time : List(I64) -> List(I64)
	der_general_time = |bs| der_tlv(Asn1.asn1_general_time, bs)

	der_sequence : List(I64) -> List(I64)
	der_sequence = |children| der_tlv(Asn1.asn1_sequence, children)

	der_set : List(I64) -> List(I64)
	der_set = |children| der_tlv(Asn1.asn1_set, children)

	der_ctx0 : List(I64) -> List(I64)
	der_ctx0 = |children| der_tlv(Asn1.asn1_ctx0, children)

	der_ctx1 : List(I64) -> List(I64)
	der_ctx1 = |children| der_tlv(Asn1.asn1_ctx1, children)

	der_ctx3 : List(I64) -> List(I64)
	der_ctx3 = |children| der_tlv(Asn1.asn1_ctx3, children)
}
