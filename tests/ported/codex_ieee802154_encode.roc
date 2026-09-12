# ieee802154-encode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ieee802154-encode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     4

app [main!] { cdx: "./codex/main.roc" }

import cdx.Ieee802154

# Ieee802154EncodeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bytes_eq : List(I64), List(I64) -> Bool
bytes_eq = |a, b| (if (U64.to_i64_wrap(List.len(a)) != U64.to_i64_wrap(List.len(b))) { False } else { bytes_eq_loop(a, b, 0, U64.to_i64_wrap(List.len(a))) })

bytes_eq_loop : List(I64), List(I64), I64, I64 -> Bool
bytes_eq_loop = |a, b, i, len| (if (i >= len) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { bytes_eq_loop(a, b, (i + 1), len) }) })

flag : Bool -> I64
flag = |b| (if b { 1 } else { 0 })

check_fcf : I64
check_fcf = flag((Ieee802154.ieee_fcf(Ieee802154.ieee_type_data, 0, 0, 0, 1, Ieee802154.ieee_addr_short, 0, Ieee802154.ieee_addr_short) == 34881))

check_fcs : I64
check_fcs = flag((Ieee802154.ieee_fcs([65, 136, 1, 205, 171, 52, 18, 120, 86, 1, 2]) == 15549))

check_u16_le : I64
check_u16_le = flag(bytes_eq(Ieee802154.ieee_u16_le(34881), [65, 136]))

check_frame : I64
check_frame = flag(bytes_eq(Ieee802154.ieee_build_data_short(1, 43981, 4660, 22136, [1, 2]), [65, 136, 1, 205, 171, 52, 18, 120, 86, 1, 2, 189, 60]))

# --- Entry ---

main! = |_args| {
	a = check_fcf
	b = check_fcs
	c = check_u16_le
	d = check_frame
	line!(I64.to_str((((a + b) + c) + d)))
	Ok({})
}
