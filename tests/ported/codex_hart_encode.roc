# hart-encode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/hart-encode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     6

app [main!] { cdx: "./codex/main.roc" }

import cdx.Hart

# HartEncodeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bytes_eq : List(I64), List(I64) -> Bool
bytes_eq = |a, b| (if (U64.to_i64_wrap(List.len(a)) != U64.to_i64_wrap(List.len(b))) { False } else { bytes_eq_loop(a, b, 0, U64.to_i64_wrap(List.len(a))) })

bytes_eq_loop : List(I64), List(I64), I64, I64 -> Bool
bytes_eq_loop = |a, b, i, len| (if (i >= len) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { bytes_eq_loop(a, b, (i + 1), len) }) })

flag : Bool -> I64
flag = |b| (if b { 1 } else { 0 })

check_checksum : I64
check_checksum = flag((Hart.hart_checksum([1, 2, 3]) == 0))

check_short_address : I64
check_short_address = flag((Hart.hart_short_address(0, True) == 128))

check_short_cmd0 : I64
check_short_cmd0 = flag(bytes_eq(Hart.hart_short_frame(Hart.hart_short_address(0, True), Hart.hart_cmd_read_unique_id, []), [255, 255, 255, 255, 255, 2, 128, 0, 0, 130]))

check_short_cmd1 : I64
check_short_cmd1 = flag(bytes_eq(Hart.hart_short_frame(Hart.hart_short_address(0, True), Hart.hart_cmd_read_pv, []), [255, 255, 255, 255, 255, 2, 128, 1, 0, 131]))

check_short_cmd6 : I64
check_short_cmd6 = flag(bytes_eq(Hart.hart_short_frame(Hart.hart_short_address(0, True), Hart.hart_cmd_set_polling_address, [5]), [255, 255, 255, 255, 255, 2, 128, 6, 1, 5, 128]))

check_long_cmd0 : I64
check_long_cmd0 = flag(bytes_eq(Hart.hart_long_frame([38, 6, 18, 52, 86], Hart.hart_cmd_read_unique_id, []), [255, 255, 255, 255, 255, 130, 38, 6, 18, 52, 86, 0, 0, 210]))

# --- Entry ---

main! = |_args| {
	a = check_checksum
	b = check_short_address
	c = check_short_cmd0
	d = check_short_cmd1
	e = check_short_cmd6
	f = check_long_cmd0
	line!(I64.to_str((((((a + b) + c) + d) + e) + f)))
	Ok({})
}
