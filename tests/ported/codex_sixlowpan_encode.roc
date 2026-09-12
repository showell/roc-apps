# sixlowpan-encode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/sixlowpan-encode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     4

app [main!] { cdx: "./codex/main.roc" }

import cdx.Sixlowpan

# SixlowpanEncodeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bytes_eq : List(I64), List(I64) -> Bool
bytes_eq = |a, b| (if (U64.to_i64_wrap(List.len(a)) != U64.to_i64_wrap(List.len(b))) { False } else { bytes_eq_loop(a, b, 0, U64.to_i64_wrap(List.len(a))) })

bytes_eq_loop : List(I64), List(I64), I64, I64 -> Bool
bytes_eq_loop = |a, b, i, len| (if (i >= len) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { bytes_eq_loop(a, b, (i + 1), len) }) })

flag : Bool -> I64
flag = |b| (if b { 1 } else { 0 })

check_iphc : I64
check_iphc = flag(bytes_eq(Sixlowpan.lowpan_iphc(3, 0, 2, 0, 0, 1, 0, 0, 1), [122, 17]))

check_frag1 : I64
check_frag1 = flag(bytes_eq(Sixlowpan.lowpan_frag1(1280, 171), [197, 0, 0, 171]))

check_fragn : I64
check_fragn = flag(bytes_eq(Sixlowpan.lowpan_fragn(1280, 171, 16), [229, 0, 0, 171, 16]))

check_dispatch : I64
check_dispatch = flag((if (Sixlowpan.lowpan_dispatch_frag1 == 192) { (Sixlowpan.lowpan_dispatch_fragn == 224) } else { False }))

# --- Entry ---

main! = |_args| {
	a = check_iphc
	b = check_frag1
	c = check_fragn
	d = check_dispatch
	line!(I64.to_str((((a + b) + c) + d)))
	Ok({})
}
