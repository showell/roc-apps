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
import cdx.CceText
import cdx.Maybe

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

yn : Bool -> CceText
yn = |b| (if b { "True" } else { "False" })

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

a_alg : CceText
a_alg = CceText.concat("der alg-matches-rfc8410=", yn(bytes_eq(Asn1Write.der_sequence(Asn1Write.der_oid(v_ed25519_oid)), v_ed25519_alg)))

a_len_short : CceText
a_len_short = CceText.concat("der len-5-is-one-octet=", yn(bytes_eq(Asn1Write.der_len(5), [5])))

a_len_223 : CceText
a_len_223 = CceText.concat("der len-223-matches-rfc8410=", yn(bytes_eq(Asn1Write.der_len(223), v_len_223)))

a_len_300 : CceText
a_len_300 = CceText.concat("der len-300-matches-rfc8410=", yn(bytes_eq(Asn1Write.der_len(300), v_len_300)))

a_len_127 : CceText
a_len_127 = CceText.concat("der len-127-is-one-octet=", yn(bytes_eq(Asn1Write.der_len(127), [127])))

a_len_128 : CceText
a_len_128 = CceText.concat("der len-128-takes-long-form=", yn(bytes_eq(Asn1Write.der_len(128), [129, 128])))

t_small : List(I64)
t_small = Asn1Write.der_small_int(2)

a_small : CceText
a_small = CceText.concat("der small-int-round-trip=", yn(maybe_int_is(Asn1.asn1_small_int(t_small, 0), 2)))

t_128 : List(I64)
t_128 = Asn1Write.der_small_int(128)

a_128_bytes : CceText
a_128_bytes = CceText.concat("der int-128-content=", yn(bytes_eq(t_128, [2, 2, 0, 128])))

a_128_round : CceText
a_128_round = CceText.concat("der int-128-round-trip=", yn(maybe_int_is(Asn1.asn1_small_int(t_128, 0), 128)))

t_zero : List(I64)
t_zero = Asn1Write.der_small_int(0)

a_zero : CceText
a_zero = CceText.concat("der int-0-is-one-octet=", yn(bytes_eq(t_zero, [2, 1, 0])))

t_serial : List(I64)
t_serial = Asn1Write.der_int_bytes(v_serial)

a_serial : CceText
a_serial = CceText.concat("der wide-int-round-trip=", yn(maybe_bytes_eq(Asn1.asn1_int_bytes(t_serial, 0), v_serial)))

t_bits : List(I64)
t_bits = Asn1Write.der_bit_string([1, 2, 3])

a_bits : CceText
a_bits = CceText.concat("der bit-string-round-trip=", yn(maybe_bytes_eq(Asn1.asn1_bit_string(t_bits, 0), [1, 2, 3])))

t_oid : List(I64)
t_oid = Asn1Write.der_oid(v_ed25519_oid)

a_oid : CceText
a_oid = CceText.concat("der oid-round-trip=", yn((match Asn1.asn1_read(t_oid, 0) {
	None => False
	Just(t) => Asn1.asn1_oid_is(t_oid, t, v_ed25519_oid)
})))

t_long : List(I64)
t_long = Asn1Write.der_sequence(filler(300, []))

a_long : CceText
a_long = CceText.concat("der long-sequence-round-trip=", yn((match Asn1.asn1_read(t_long, 0) {
	None => False
	Just(t) => ((t.tlv_len == 300) and (t.tlv_tag == 48))
})))

t_nonminimal : List(I64)
t_nonminimal = [48, 129, 5, 2, 1, 1, 5, 0]

a_nonminimal : CceText
a_nonminimal = CceText.concat("der reader-refuses-non-minimal=", yn((match Asn1.asn1_read(t_nonminimal, 0) {
	None => True
	Just(_t) => False
})))

a_writer_avoids : CceText
a_writer_avoids = CceText.concat("der writer-avoids-that-form=", yn(bytes_eq(Asn1Write.der_sequence([2, 1, 1, 5, 0]), [48, 5, 2, 1, 1, 5, 0])))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(a_alg))
	line!(CceText.printed(a_len_short))
	line!(CceText.printed(a_len_223))
	line!(CceText.printed(a_len_300))
	line!(CceText.printed(a_len_127))
	line!(CceText.printed(a_len_128))
	line!(CceText.printed(a_small))
	line!(CceText.printed(a_128_bytes))
	line!(CceText.printed(a_128_round))
	line!(CceText.printed(a_zero))
	line!(CceText.printed(a_serial))
	line!(CceText.printed(a_bits))
	line!(CceText.printed(a_oid))
	line!(CceText.printed(a_long))
	line!(CceText.printed(a_nonminimal))
	line!(CceText.printed(a_writer_avoids))
	Ok({})
}
