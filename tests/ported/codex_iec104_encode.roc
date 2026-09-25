# iec104-encode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/iec104-encode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     11

app [main!] { cdx: "./codex/main.roc" }

import cdx.Iec104

# Iec104EncodeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bytes_eq : List(I64), List(I64) -> Bool
bytes_eq = |a, b| (if (U64.to_i64_wrap(List.len(a)) != U64.to_i64_wrap(List.len(b))) { False } else { bytes_eq_loop(a, b, 0, U64.to_i64_wrap(List.len(a))) })

bytes_eq_loop : List(I64), List(I64), I64, I64 -> Bool
bytes_eq_loop = |a, b, i, len| (if (i >= len) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { bytes_eq_loop(a, b, (i + 1), len) }) })

flag : Bool -> I64
flag = |b| (if b { 1 } else { 0 })

asdu_single_point : List(I64)
asdu_single_point = List.concat(Iec104.i104_asdu_header(Iec104.i104_type_single_point, Iec104.i104_vsq(False, 1), Iec104.i104_cot_spontaneous, 0, 1), Iec104.i104_io_single_point(100, 1))

asdu_interrogation : List(I64)
asdu_interrogation = List.concat(Iec104.i104_asdu_header(Iec104.i104_type_interrogation, Iec104.i104_vsq(False, 1), Iec104.i104_cot_activation, 0, 1), Iec104.i104_io_interrogation(0, Iec104.i104_qoi_station))

asdu_short_float : List(I64)
asdu_short_float = List.concat(Iec104.i104_asdu_header(Iec104.i104_type_measured_short_float, Iec104.i104_vsq(False, 1), Iec104.i104_cot_spontaneous, 0, 1), Iec104.i104_io_measured_short_float(200, F64.to_f32_wrap(42.5), 0))

check_ctrl_i_seq : I64
check_ctrl_i_seq = flag(bytes_eq(Iec104.i104_ctrl_i(300, 127), [88, 2, 254, 0]))

check_ctrl_s : I64
check_ctrl_s = flag(bytes_eq(Iec104.i104_ctrl_s(5), [1, 0, 10, 0]))

check_ctrl_u : I64
check_ctrl_u = flag(bytes_eq(Iec104.i104_ctrl_u(Iec104.i104_u_startdt_act), [7, 0, 0, 0]))

check_frame_u_startdt : I64
check_frame_u_startdt = flag(bytes_eq(Iec104.i104_frame_u(Iec104.i104_u_startdt_act), [104, 4, 7, 0, 0, 0]))

check_frame_u_testfr : I64
check_frame_u_testfr = flag(bytes_eq(Iec104.i104_frame_u(Iec104.i104_u_testfr_act), [104, 4, 67, 0, 0, 0]))

check_frame_s : I64
check_frame_s = flag(bytes_eq(Iec104.i104_frame_s(5), [104, 4, 1, 0, 10, 0]))

check_asdu_single_point : I64
check_asdu_single_point = flag(bytes_eq(asdu_single_point, [1, 1, 3, 0, 1, 0, 100, 0, 0, 1]))

check_frame_i_single_point : I64
check_frame_i_single_point = flag(bytes_eq(Iec104.i104_frame_i(0, 0, asdu_single_point), [104, 14, 0, 0, 0, 0, 1, 1, 3, 0, 1, 0, 100, 0, 0, 1]))

check_asdu_interrogation : I64
check_asdu_interrogation = flag(bytes_eq(asdu_interrogation, [100, 1, 6, 0, 1, 0, 0, 0, 0, 20]))

check_f32_le : I64
check_f32_le = flag(bytes_eq(Iec104.i104_f32_le(F64.to_f32_wrap(42.5)), [0, 0, 42, 66]))

check_asdu_short_float : I64
check_asdu_short_float = flag(bytes_eq(asdu_short_float, [13, 1, 3, 0, 1, 0, 200, 0, 0, 0, 0, 42, 66, 0]))

# --- Entry ---

main! = |_args| {
	a = check_ctrl_i_seq
	b = check_ctrl_s
	c = check_ctrl_u
	d = check_frame_u_startdt
	e = check_frame_u_testfr
	f = check_frame_s
	g = check_asdu_single_point
	h = check_frame_i_single_point
	i = check_asdu_interrogation
	j = check_f32_le
	k = check_asdu_short_float
	line!(I64.to_str(((((((((((a + b) + c) + d) + e) + f) + g) + h) + i) + j) + k)))
	Ok({})
}
