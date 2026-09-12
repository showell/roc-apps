# zigbee-encode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/zigbee-encode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     4

app [main!] { cdx: "./codex/main.roc" }

import cdx.Zigbee

# ZigbeeEncodeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bytes_eq : List(I64), List(I64) -> Bool
bytes_eq = |a, b| (if (U64.to_i64_wrap(List.len(a)) != U64.to_i64_wrap(List.len(b))) { False } else { bytes_eq_loop(a, b, 0, U64.to_i64_wrap(List.len(a))) })

bytes_eq_loop : List(I64), List(I64), I64, I64 -> Bool
bytes_eq_loop = |a, b, i, len| (if (i >= len) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { bytes_eq_loop(a, b, (i + 1), len) }) })

flag : Bool -> I64
flag = |b| (if b { 1 } else { 0 })

check_nwk_fc : I64
check_nwk_fc = flag((Zigbee.zb_nwk_fc(Zigbee.zb_nwk_type_data, Zigbee.zb_nwk_version, 0, 0) == 8))

check_nwk_frame : I64
check_nwk_frame = flag(bytes_eq(Zigbee.zb_build_nwk_data(4660, 22136, 30, 5, [1, 2, 3]), [8, 0, 52, 18, 120, 86, 30, 5, 1, 2, 3]))

check_aps_ack : I64
check_aps_ack = flag((Zigbee.zb_aps_fc(Zigbee.zb_aps_type_data, 0, 1, 0) == 64))

check_aps_frame : I64
check_aps_frame = flag(bytes_eq(Zigbee.zb_build_aps_data(1, 6, 260, 1, 10, [1]), [0, 1, 6, 0, 4, 1, 1, 10, 1]))

# --- Entry ---

main! = |_args| {
	a = check_nwk_fc
	b = check_nwk_frame
	c = check_aps_ack
	d = check_aps_frame
	line!(I64.to_str((((a + b) + c) + d)))
	Ok({})
}
