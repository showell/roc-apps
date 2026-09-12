# canopen-encode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/canopen-encode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     4

app [main!] { cdx: "./codex/main.roc" }

import cdx.Canopen

# CanopenEncodeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bytes_eq : List(I64), List(I64) -> Bool
bytes_eq = |a, b| (if (U64.to_i64_wrap(List.len(a)) != U64.to_i64_wrap(List.len(b))) { False } else { bytes_eq_loop(a, b, 0, U64.to_i64_wrap(List.len(a))) })

bytes_eq_loop : List(I64), List(I64), I64, I64 -> Bool
bytes_eq_loop = |a, b, i, len| (if (i >= len) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { bytes_eq_loop(a, b, (i + 1), len) }) })

flag : Bool -> I64
flag = |b| (if b { 1 } else { 0 })

check_tpdo1 : I64
check_tpdo1 = flag((Canopen.co_cob_id(Canopen.co_fc_tpdo1, 5) == 389))

check_sdo_cob : I64
check_sdo_cob = flag((if (Canopen.co_cob_id(Canopen.co_fc_sdo_rx, 5) == 1541) { (Canopen.co_cob_id(Canopen.co_fc_heartbeat, 5) == 1797) } else { False }))

check_nmt : I64
check_nmt = flag(bytes_eq(Canopen.co_nmt_command(Canopen.co_nmt_start, 5), [1, 5]))

check_sdo_download : I64
check_sdo_download = flag(bytes_eq(Canopen.co_sdo_download_expedited(24640, 0, [15, 0]), [43, 64, 96, 0, 15, 0, 0, 0]))

# --- Entry ---

main! = |_args| {
	a = check_tpdo1
	b = check_sdo_cob
	c = check_nmt
	d = check_sdo_download
	line!(I64.to_str((((a + b) + c) + d)))
	Ok({})
}
