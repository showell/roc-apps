# ble-att-encode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ble-att-encode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     5

app [main!] { cdx: "./codex/main.roc" }

import cdx.BleAtt

# BleAttEncodeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bytes_eq : List(I64), List(I64) -> Bool
bytes_eq = |a, b| (if (U64.to_i64_wrap(List.len(a)) != U64.to_i64_wrap(List.len(b))) { False } else { bytes_eq_loop(a, b, 0, U64.to_i64_wrap(List.len(a))) })

bytes_eq_loop : List(I64), List(I64), I64, I64 -> Bool
bytes_eq_loop = |a, b, i, len| (if (i >= len) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { bytes_eq_loop(a, b, (i + 1), len) }) })

flag : Bool -> I64
flag = |b| (if b { 1 } else { 0 })

check_read_request : I64
check_read_request = flag(bytes_eq(BleAtt.att_read_request(37), [10, 37, 0]))

check_write_request : I64
check_write_request = flag(bytes_eq(BleAtt.att_write_request(37, [1]), [18, 37, 0, 1]))

check_notification : I64
check_notification = flag(bytes_eq(BleAtt.att_notification(42, [100]), [27, 42, 0, 100]))

check_error_response : I64
check_error_response = flag(bytes_eq(BleAtt.att_error_response(BleAtt.att_op_read_request, 37, 10), [1, 10, 37, 0, 10]))

check_l2cap : I64
check_l2cap = flag(bytes_eq(BleAtt.att_l2cap(BleAtt.att_read_request(37)), [3, 0, 4, 0, 10, 37, 0]))

# --- Entry ---

main! = |_args| {
	a = check_read_request
	b = check_write_request
	c = check_notification
	d = check_error_response
	e = check_l2cap
	line!(I64.to_str(((((a + b) + c) + d) + e)))
	Ok({})
}
