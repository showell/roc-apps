# melsec-encode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/melsec-encode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     4

app [main!] { cdx: "./codex/main.roc" }

import cdx.Melsec

# MelsecEncodeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bytes_eq : List(I64), List(I64) -> Bool
bytes_eq = |a, b| (if (U64.to_i64_wrap(List.len(a)) != U64.to_i64_wrap(List.len(b))) { False } else { bytes_eq_loop(a, b, 0, U64.to_i64_wrap(List.len(a))) })

bytes_eq_loop : List(I64), List(I64), I64, I64 -> Bool
bytes_eq_loop = |a, b, i, len| (if (i >= len) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { bytes_eq_loop(a, b, (i + 1), len) }) })

flag : Bool -> I64
flag = |b| (if b { 1 } else { 0 })

check_device : I64
check_device = flag(bytes_eq(Melsec.melsec_device(Melsec.melsec_dev_d, 100, 5), [100, 0, 0, 168, 5, 0]))

check_read_d : I64
check_read_d = flag(bytes_eq(Melsec.melsec_batch_read_words(Melsec.melsec_dev_d, 100, 5), [80, 0, 0, 255, 255, 3, 0, 12, 0, 16, 0, 1, 4, 0, 0, 100, 0, 0, 168, 5, 0]))

check_read_m : I64
check_read_m = flag(bytes_eq(Melsec.melsec_batch_read_words(Melsec.melsec_dev_m, 0, 16), [80, 0, 0, 255, 255, 3, 0, 12, 0, 16, 0, 1, 4, 0, 0, 0, 0, 0, 144, 16, 0]))

check_write_d : I64
check_write_d = ({
	expect_ : List(I64)
	expect_ = [80, 0, 0, 255, 255, 3, 0, 16, 0, 16, 0, 1, 20, 0, 0, 200, 0, 0, 168, 2, 0, 52, 18, 5, 0]
	flag(bytes_eq(Melsec.melsec_batch_write_words(Melsec.melsec_dev_d, 200, [4660, 5]), expect_))
})

# --- Entry ---

main! = |_args| {
	a = check_device
	b = check_read_d
	c = check_read_m
	d = check_write_d
	line!(I64.to_str((((a + b) + c) + d)))
	Ok({})
}
