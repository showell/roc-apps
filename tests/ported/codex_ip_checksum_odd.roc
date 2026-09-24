# ip-checksum-odd
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ip-checksum-odd.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     odd3-agrees=True
#     odd5-agrees=True
#     odd1-agrees=True
#     odd3-equals-padded=True
#     odd5-equals-padded=True
#     even4-agrees=True
#     even20-agrees=True
#     even4-value=64505
#     even20-value=25182
#     odd3-value=64509
#     odd5-value=47349

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Ethernet

# IpChecksumOdd -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

witness_checksum : List(I64), I64, I64, I64 -> I64
witness_checksum = |data, i, len, sum| (if (i >= len) { ({
	folded : I64
	folded = (I64.bitwise_and(sum, 65535) + I64.shr_zf_wrap(sum, I64.to_u8_wrap(16)))
	folded2 : I64
	folded2 = (I64.bitwise_and(folded, 65535) + I64.shr_zf_wrap(folded, I64.to_u8_wrap(16)))
	I64.bitwise_and(I64.bitwise_xor(folded2, 65535), 65535)
}) } else { (if ((i + 1) >= len) { witness_checksum(data, (i + 1), len, (sum + I64.shl_wrap((List.get(data, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), I64.to_u8_wrap(8)))) } else { witness_checksum(data, (i + 2), len, (sum + Ethernet.read_be16(data, i))) }) })

odd3 : List(I64)
odd3 = [1, 2, 3]

odd5 : List(I64)
odd5 = [255, 1, 128, 7, 200]

odd1 : List(I64)
odd1 = [171]

even4 : List(I64)
even4 = [1, 2, 3, 4]

even20 : List(I64)
even20 = [69, 0, 0, 40, 0, 0, 0, 0, 64, 6, 0, 0, 10, 0, 2, 15, 10, 0, 2, 100]

ip_of : List(I64) -> I64
ip_of = |xs| Ethernet.ip_checksum(xs, 0, U64.to_i64_wrap(List.len(xs)), 0)

witness_of : List(I64) -> I64
witness_of = |xs| witness_checksum(xs, 0, U64.to_i64_wrap(List.len(xs)), 0)

ip_padded : List(I64) -> I64
ip_padded = |xs| Ethernet.ip_checksum(List.concat(xs, [0]), 0, (U64.to_i64_wrap(List.len(xs)) + 1), 0)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("odd3-agrees=", (if (ip_of(odd3) == witness_of(odd3)) { "True" } else { "False" }))))
	line!(CceText.printed(CceText.concat("odd5-agrees=", (if (ip_of(odd5) == witness_of(odd5)) { "True" } else { "False" }))))
	line!(CceText.printed(CceText.concat("odd1-agrees=", (if (ip_of(odd1) == witness_of(odd1)) { "True" } else { "False" }))))
	line!(CceText.printed(CceText.concat("odd3-equals-padded=", (if (ip_of(odd3) == ip_padded(odd3)) { "True" } else { "False" }))))
	line!(CceText.printed(CceText.concat("odd5-equals-padded=", (if (ip_of(odd5) == ip_padded(odd5)) { "True" } else { "False" }))))
	line!(CceText.printed(CceText.concat("even4-agrees=", (if (ip_of(even4) == witness_of(even4)) { "True" } else { "False" }))))
	line!(CceText.printed(CceText.concat("even20-agrees=", (if (ip_of(even20) == witness_of(even20)) { "True" } else { "False" }))))
	line!(CceText.printed(CceText.concat("even4-value=", CceText.show_int(ip_of(even4)))))
	line!(CceText.printed(CceText.concat("even20-value=", CceText.show_int(ip_of(even20)))))
	line!(CceText.printed(CceText.concat("odd3-value=", CceText.show_int(ip_of(odd3)))))
	line!(CceText.printed(CceText.concat("odd5-value=", CceText.show_int(ip_of(odd5)))))
	Ok({})
}
