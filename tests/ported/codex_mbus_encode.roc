# mbus-encode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/mbus-encode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     4

app [main!] { cdx: "./codex/main.roc" }

import cdx.Mbus

# MbusEncodeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bytes_eq : List(I64), List(I64) -> Bool
bytes_eq = |a, b| (if (U64.to_i64_wrap(List.len(a)) != U64.to_i64_wrap(List.len(b))) { False } else { bytes_eq_loop(a, b, 0, U64.to_i64_wrap(List.len(a))) })

bytes_eq_loop : List(I64), List(I64), I64, I64 -> Bool
bytes_eq_loop = |a, b, i, len| (if (i >= len) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { bytes_eq_loop(a, b, (i + 1), len) }) })

flag : Bool -> I64
flag = |b| (if b { 1 } else { 0 })

check_checksum : I64
check_checksum = flag((Mbus.mbus_checksum([83, 1, 81, 1, 2]) == 168))

check_ack : I64
check_ack = flag(bytes_eq(Mbus.mbus_ack_frame, [229]))

check_short : I64
check_short = flag(bytes_eq(Mbus.mbus_short_frame(Mbus.mbus_c_snd_nke, 1), [16, 64, 1, 65, 22]))

check_long : I64
check_long = flag(bytes_eq(Mbus.mbus_long_frame(Mbus.mbus_c_snd_ud, 1, Mbus.mbus_ci_data_send, [1, 2]), [104, 5, 5, 104, 83, 1, 81, 1, 2, 168, 22]))

# --- Entry ---

main! = |_args| {
	a = check_checksum
	b = check_ack
	c = check_short
	d = check_long
	line!(I64.to_str((((a + b) + c) + d)))
	Ok({})
}
