# asn1-der-write
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/asn1-der-write.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     der alg-matches-rfc8410=True
#     der len-5-is-one-octet=True
#     der len-223-matches-rfc8410=True
#     der len-300-matches-rfc8410=True
#     der len-127-is-one-octet=True
#     der len-128-takes-long-form=True
#     der small-int-round-trip=True
#     der int-128-content=True
#     der int-128-round-trip=True
#     der int-0-is-one-octet=True
#     der wide-int-round-trip=True
#     der bit-string-round-trip=True
#     der oid-round-trip=True
#     der long-sequence-round-trip=True
#     der reader-refuses-non-minimal=True
#     der writer-avoids-that-form=True

app [main!] { cdx: "./codex/main.roc" }

import cdx.Asn1
import cdx.Asn1Write
import cdx.Maybe
import cdx.Text

# Asn1DerWriteTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

v_ed25519_oid : List(I64)
v_ed25519_oid = [43, 101, 112]

v_ed25519_alg : List(I64)
v_ed25519_alg = [48, 5, 6, 3, 43, 101, 112]

v_len_223 : List(I64)
v_len_223 = [129, 223]

v_len_300 : List(I64)
v_len_300 = [130, 1, 44]

v_serial : List(I64)
v_serial = [86, 1, 71, 74, 42, 141, 195, 48]

yn : Bool -> List(U8)
yn = |b| (if b { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] })

bytes_eq : List(I64), List(I64) -> Bool
bytes_eq = |a, b| (if (U64.to_i64_wrap(List.len(a)) != U64.to_i64_wrap(List.len(b))) { False } else { bytes_eq_loop(a, b, 0, U64.to_i64_wrap(List.len(a))) })

bytes_eq_loop : List(I64), List(I64), I64, I64 -> Bool
bytes_eq_loop = |a, b, i, n| (if (i >= n) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { bytes_eq_loop(a, b, (i + 1), n) }) })

maybe_bytes_eq : Maybe.Maybe(List(I64)), List(I64) -> Bool
maybe_bytes_eq = |m, want| (match m {
	None => False
	Just(bs) => bytes_eq(bs, want)
})

maybe_int_is : Maybe.Maybe(I64), I64 -> Bool
maybe_int_is = |m, want| (match m {
	None => False
	Just(v) => (v == want)
})

filler : I64, List(I64) -> List(I64)
filler = |n, acc| (if (n <= 0) { acc } else { filler((n - 1), List.append(acc, 65)) })

a_alg : List(U8)
a_alg = List.concat([22, 13, 21, 2, 15, 23, 29, 73, 26, 15, 14, 24, 20, 13, 19, 73, 21, 28, 24, 11, 7, 4, 3, 77], yn(bytes_eq(Asn1Write.der_sequence(Asn1Write.der_oid(v_ed25519_oid)), v_ed25519_alg)))

a_len_short : List(U8)
a_len_short = List.concat([22, 13, 21, 2, 23, 13, 18, 73, 8, 73, 17, 19, 73, 16, 18, 13, 73, 16, 24, 14, 13, 14, 77], yn(bytes_eq(Asn1Write.der_len(5), [5])))

a_len_223 : List(U8)
a_len_223 = List.concat([22, 13, 21, 2, 23, 13, 18, 73, 5, 5, 6, 73, 26, 15, 14, 24, 20, 13, 19, 73, 21, 28, 24, 11, 7, 4, 3, 77], yn(bytes_eq(Asn1Write.der_len(223), v_len_223)))

a_len_300 : List(U8)
a_len_300 = List.concat([22, 13, 21, 2, 23, 13, 18, 73, 6, 3, 3, 73, 26, 15, 14, 24, 20, 13, 19, 73, 21, 28, 24, 11, 7, 4, 3, 77], yn(bytes_eq(Asn1Write.der_len(300), v_len_300)))

a_len_127 : List(U8)
a_len_127 = List.concat([22, 13, 21, 2, 23, 13, 18, 73, 4, 5, 10, 73, 17, 19, 73, 16, 18, 13, 73, 16, 24, 14, 13, 14, 77], yn(bytes_eq(Asn1Write.der_len(127), [127])))

a_len_128 : List(U8)
a_len_128 = List.concat([22, 13, 21, 2, 23, 13, 18, 73, 4, 5, 11, 73, 14, 15, 34, 13, 19, 73, 23, 16, 18, 29, 73, 28, 16, 21, 26, 77], yn(bytes_eq(Asn1Write.der_len(128), [129, 128])))

t_small : List(I64)
t_small = Asn1Write.der_small_int(2)

a_small : List(U8)
a_small = List.concat([22, 13, 21, 2, 19, 26, 15, 23, 23, 73, 17, 18, 14, 73, 21, 16, 25, 18, 22, 73, 14, 21, 17, 31, 77], yn(maybe_int_is(Asn1.asn1_small_int(t_small, 0), 2)))

t_128 : List(I64)
t_128 = Asn1Write.der_small_int(128)

a_128_bytes : List(U8)
a_128_bytes = List.concat([22, 13, 21, 2, 17, 18, 14, 73, 4, 5, 11, 73, 24, 16, 18, 14, 13, 18, 14, 77], yn(bytes_eq(t_128, [2, 2, 0, 128])))

a_128_round : List(U8)
a_128_round = List.concat([22, 13, 21, 2, 17, 18, 14, 73, 4, 5, 11, 73, 21, 16, 25, 18, 22, 73, 14, 21, 17, 31, 77], yn(maybe_int_is(Asn1.asn1_small_int(t_128, 0), 128)))

t_zero : List(I64)
t_zero = Asn1Write.der_small_int(0)

a_zero : List(U8)
a_zero = List.concat([22, 13, 21, 2, 17, 18, 14, 73, 3, 73, 17, 19, 73, 16, 18, 13, 73, 16, 24, 14, 13, 14, 77], yn(bytes_eq(t_zero, [2, 1, 0])))

t_serial : List(I64)
t_serial = Asn1Write.der_int_bytes(v_serial)

a_serial : List(U8)
a_serial = List.concat([22, 13, 21, 2, 27, 17, 22, 13, 73, 17, 18, 14, 73, 21, 16, 25, 18, 22, 73, 14, 21, 17, 31, 77], yn(maybe_bytes_eq(Asn1.asn1_int_bytes(t_serial, 0), v_serial)))

t_bits : List(I64)
t_bits = Asn1Write.der_bit_string([1, 2, 3])

a_bits : List(U8)
a_bits = List.concat([22, 13, 21, 2, 32, 17, 14, 73, 19, 14, 21, 17, 18, 29, 73, 21, 16, 25, 18, 22, 73, 14, 21, 17, 31, 77], yn(maybe_bytes_eq(Asn1.asn1_bit_string(t_bits, 0), [1, 2, 3])))

t_oid : List(I64)
t_oid = Asn1Write.der_oid(v_ed25519_oid)

a_oid : List(U8)
a_oid = List.concat([22, 13, 21, 2, 16, 17, 22, 73, 21, 16, 25, 18, 22, 73, 14, 21, 17, 31, 77], yn((match Asn1.asn1_read(t_oid, 0) {
	None => False
	Just(t) => Asn1.asn1_oid_is(t_oid, t, v_ed25519_oid)
})))

t_long : List(I64)
t_long = Asn1Write.der_sequence(filler(300, []))

a_long : List(U8)
a_long = List.concat([22, 13, 21, 2, 23, 16, 18, 29, 73, 19, 13, 37, 25, 13, 18, 24, 13, 73, 21, 16, 25, 18, 22, 73, 14, 21, 17, 31, 77], yn((match Asn1.asn1_read(t_long, 0) {
	None => False
	Just(t) => ((t.tlv_len == 300) and (t.tlv_tag == 48))
})))

t_nonminimal : List(I64)
t_nonminimal = [48, 129, 5, 2, 1, 1, 5, 0]

a_nonminimal : List(U8)
a_nonminimal = List.concat([22, 13, 21, 2, 21, 13, 15, 22, 13, 21, 73, 21, 13, 28, 25, 19, 13, 19, 73, 18, 16, 18, 73, 26, 17, 18, 17, 26, 15, 23, 77], yn((match Asn1.asn1_read(t_nonminimal, 0) {
	None => True
	Just(_t) => False
})))

a_writer_avoids : List(U8)
a_writer_avoids = List.concat([22, 13, 21, 2, 27, 21, 17, 14, 13, 21, 73, 15, 33, 16, 17, 22, 19, 73, 14, 20, 15, 14, 73, 28, 16, 21, 26, 77], yn(bytes_eq(Asn1Write.der_sequence([2, 1, 1, 5, 0]), [48, 5, 2, 1, 1, 5, 0])))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(a_alg))
	line!(Text.printed(a_len_short))
	line!(Text.printed(a_len_223))
	line!(Text.printed(a_len_300))
	line!(Text.printed(a_len_127))
	line!(Text.printed(a_len_128))
	line!(Text.printed(a_small))
	line!(Text.printed(a_128_bytes))
	line!(Text.printed(a_128_round))
	line!(Text.printed(a_zero))
	line!(Text.printed(a_serial))
	line!(Text.printed(a_bits))
	line!(Text.printed(a_oid))
	line!(Text.printed(a_long))
	line!(Text.printed(a_nonminimal))
	line!(Text.printed(a_writer_avoids))
	Ok({})
}
