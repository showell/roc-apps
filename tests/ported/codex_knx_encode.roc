# knx-encode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/knx-encode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     4

app [main!] { cdx: "./codex/main.roc" }

import cdx.Knx

# KnxEncodeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bytes_eq : List(I64), List(I64) -> Bool
bytes_eq = |a, b| (if (U64.to_i64_wrap(List.len(a)) != U64.to_i64_wrap(List.len(b))) { False } else { bytes_eq_loop(a, b, 0, U64.to_i64_wrap(List.len(a))) })

bytes_eq_loop : List(I64), List(I64), I64, I64 -> Bool
bytes_eq_loop = |a, b, i, len| (if (i >= len) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { bytes_eq_loop(a, b, (i + 1), len) }) })

flag : Bool -> I64
flag = |b| (if b { 1 } else { 0 })

check_group_address : I64
check_group_address = flag((Knx.knx_group_address(1, 2, 3) == 2563))

check_individual_address : I64
check_individual_address = flag((Knx.knx_individual_address(1, 1, 1) == 4353))

check_cemi : I64
check_cemi = flag(bytes_eq(Knx.knx_cemi_group_write(4353, 2563, 1), [17, 0, 188, 224, 17, 1, 10, 3, 1, 0, 129]))

check_routing_frame : I64
check_routing_frame = flag(bytes_eq(Knx.knx_routing_group_write(4353, 2563, 1), [6, 16, 5, 48, 0, 17, 17, 0, 188, 224, 17, 1, 10, 3, 1, 0, 129]))

# --- Entry ---

main! = |_args| {
	a = check_group_address
	b = check_individual_address
	c = check_cemi
	d = check_routing_frame
	line!(I64.to_str((((a + b) + c) + d)))
	Ok({})
}
