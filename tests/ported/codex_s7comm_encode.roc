# s7comm-encode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/s7comm-encode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     8

app [main!] { cdx: "./codex/main.roc" }

import cdx.S7comm

# S7commEncodeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bytes_eq : List(I64), List(I64) -> Bool
bytes_eq = |a, b| (if (U64.to_i64_wrap(List.len(a)) != U64.to_i64_wrap(List.len(b))) { False } else { bytes_eq_loop(a, b, 0, U64.to_i64_wrap(List.len(a))) })

bytes_eq_loop : List(I64), List(I64), I64, I64 -> Bool
bytes_eq_loop = |a, b, i, len| (if (i >= len) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { bytes_eq_loop(a, b, (i + 1), len) }) })

flag : Bool -> I64
flag = |b| (if b { 1 } else { 0 })

sample_cr : List(I64)
sample_cr = S7comm.s7_cotp_cr(1, 0, 10, [1, 0], [1, 2])

sample_setup : List(I64)
sample_setup = S7comm.s7_setup(1024, 1, 1, 480)

sample_item : List(I64)
sample_item = S7comm.s7_read_item(S7comm.s7_area_db, 1, 4, 0)

sample_read : List(I64)
sample_read = S7comm.s7_read_var_single(1280, sample_item)

check_tpkt : I64
check_tpkt = flag(bytes_eq(S7comm.s7_tpkt([1, 2, 3]), [3, 0, 0, 7, 1, 2, 3]))

check_cotp_cr : I64
check_cotp_cr = flag(bytes_eq(sample_cr, [17, 224, 0, 0, 0, 1, 0, 192, 1, 10, 193, 2, 1, 0, 194, 2, 1, 2]))

check_tpkt_cr : I64
check_tpkt_cr = flag(bytes_eq(S7comm.s7_tpkt(sample_cr), [3, 0, 0, 22, 17, 224, 0, 0, 0, 1, 0, 192, 1, 10, 193, 2, 1, 0, 194, 2, 1, 2]))

check_cotp_dt : I64
check_cotp_dt = flag(bytes_eq(S7comm.s7_cotp_dt, [2, 240, 128]))

check_setup : I64
check_setup = flag(bytes_eq(sample_setup, [50, 1, 0, 0, 4, 0, 0, 8, 0, 0, 240, 0, 0, 1, 0, 1, 1, 224]))

check_read_item : I64
check_read_item = flag(bytes_eq(sample_item, [18, 10, 16, 2, 0, 4, 0, 1, 132, 0, 0, 0]))

check_read_var : I64
check_read_var = flag(bytes_eq(sample_read, [50, 1, 0, 0, 5, 0, 0, 14, 0, 0, 4, 1, 18, 10, 16, 2, 0, 4, 0, 1, 132, 0, 0, 0]))

check_stacked : I64
check_stacked = ({
	expect_ : List(I64)
	expect_ = [3, 0, 0, 31, 2, 240, 128, 50, 1, 0, 0, 5, 0, 0, 14, 0, 0, 4, 1, 18, 10, 16, 2, 0, 4, 0, 1, 132, 0, 0, 0]
	flag(bytes_eq(S7comm.s7_tpkt(List.concat(S7comm.s7_cotp_dt, sample_read)), expect_))
})

# --- Entry ---

main! = |_args| {
	a = check_tpkt
	b = check_cotp_cr
	c = check_tpkt_cr
	d = check_cotp_dt
	e = check_setup
	f = check_read_item
	g = check_read_var
	h = check_stacked
	line!(I64.to_str((((((((a + b) + c) + d) + e) + f) + g) + h)))
	Ok({})
}
