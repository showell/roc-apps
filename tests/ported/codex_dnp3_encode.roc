# dnp3-encode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/dnp3-encode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     8

app [main!] { cdx: "./codex/main.roc" }

import cdx.Dnp3

# Dnp3EncodeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bytes_eq : List(I64), List(I64) -> Bool
bytes_eq = |a, b| (if (U64.to_i64_wrap(List.len(a)) != U64.to_i64_wrap(List.len(b))) { False } else { bytes_eq_loop(a, b, 0, U64.to_i64_wrap(List.len(a))) })

bytes_eq_loop : List(I64), List(I64), I64, I64 -> Bool
bytes_eq_loop = |a, b, i, len| (if (i >= len) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { bytes_eq_loop(a, b, (i + 1), len) }) })

flag : Bool -> I64
flag = |b| (if b { 1 } else { 0 })

check_crc_check_value : I64
check_crc_check_value = flag((Dnp3.dnp3_crc16([49, 50, 51, 52, 53, 54, 55, 56, 57]) == 60034))

check_crc_block : I64
check_crc_block = flag((Dnp3.dnp3_crc16([1, 2, 3]) == 42816))

check_frame : I64
check_frame = flag(bytes_eq(Dnp3.dnp3_build_frame(Dnp3.dnp3_ctrl_unconfirmed_data, 4, 3, [1, 2, 3]), [5, 100, 8, 196, 4, 0, 3, 0, 180, 184, 1, 2, 3, 64, 167]))

check_empty_frame : I64
check_empty_frame = flag(bytes_eq(Dnp3.dnp3_build_frame(Dnp3.dnp3_ctrl_unconfirmed_data, 4, 3, []), [5, 100, 5, 196, 4, 0, 3, 0, 225, 218]))

check_multiblock : I64
check_multiblock = flag(bytes_eq(Dnp3.dnp3_data_blocks([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 242, 165, 17, 202, 123]))

check_app_header : I64
check_app_header = flag(bytes_eq(Dnp3.dnp3_app_header(0, Dnp3.dnp3_app_fc_read), [192, 1]))

check_read_class0 : I64
check_read_class0 = flag(bytes_eq(Dnp3.dnp3_read_class(0, 1), [192, 1, 60, 1, 6]))

check_read_range : I64
check_read_range = flag(bytes_eq(Dnp3.dnp3_read_range(0, 1, 2, 0, 9), [192, 1, 1, 2, 0, 0, 9]))

# --- Entry ---

main! = |_args| {
	a = check_crc_check_value
	b = check_crc_block
	c = check_frame
	d = check_empty_frame
	e = check_multiblock
	f = check_app_header
	g = check_read_class0
	h = check_read_range
	line!(I64.to_str((((((((a + b) + c) + d) + e) + f) + g) + h)))
	Ok({})
}
