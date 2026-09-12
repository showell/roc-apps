# enip-encode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/enip-encode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     5

app [main!] { cdx: "./codex/main.roc" }

import cdx.Enip

# EnipEncodeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bytes_eq : List(I64), List(I64) -> Bool
bytes_eq = |a, b| (if (U64.to_i64_wrap(List.len(a)) != U64.to_i64_wrap(List.len(b))) { False } else { bytes_eq_loop(a, b, 0, U64.to_i64_wrap(List.len(a))) })

bytes_eq_loop : List(I64), List(I64), I64, I64 -> Bool
bytes_eq_loop = |a, b, i, len| (if (i >= len) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { bytes_eq_loop(a, b, (i + 1), len) }) })

flag : Bool -> I64
flag = |b| (if b { 1 } else { 0 })

check_header : I64
check_header = flag(bytes_eq(Enip.enip_header(Enip.enip_cmd_register_session, 4, 0, 0, 0), [101, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))

check_register_session : I64
check_register_session = flag(bytes_eq(Enip.enip_register_session, [101, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0]))

check_cip_epath : I64
check_cip_epath = flag(bytes_eq(Enip.cip_epath_class_instance_attr(4, 1, 3), [32, 4, 36, 1, 48, 3]))

check_get_attr_single : I64
check_get_attr_single = flag(bytes_eq(Enip.cip_get_attr_single(4, 1, 3), [14, 3, 32, 4, 36, 1, 48, 3]))

check_send_rr_data : I64
check_send_rr_data = ({
	expect_ = [111, 0, 24, 0, 68, 51, 34, 17, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 2, 0, 0, 0, 0, 0, 178, 0, 8, 0, 14, 3, 32, 4, 36, 1, 48, 3]
	flag(bytes_eq(Enip.enip_send_rr_data(287454020, 10, Enip.cip_get_attr_single(4, 1, 3)), expect_))
})

# --- Entry ---

main! = |_args| {
	a = check_header
	b = check_register_session
	c = check_cip_epath
	d = check_get_attr_single
	e = check_send_rr_data
	line!(I64.to_str(((((a + b) + c) + d) + e)))
	Ok({})
}
