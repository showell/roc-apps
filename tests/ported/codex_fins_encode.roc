# fins-encode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/fins-encode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     4

app [main!] { cdx: "./codex/main.roc" }

import cdx.Fins

# FinsEncodeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bytes_eq : List(I64), List(I64) -> Bool
bytes_eq = |a, b| (if (U64.to_i64_wrap(List.len(a)) != U64.to_i64_wrap(List.len(b))) { False } else { bytes_eq_loop(a, b, 0, U64.to_i64_wrap(List.len(a))) })

bytes_eq_loop : List(I64), List(I64), I64, I64 -> Bool
bytes_eq_loop = |a, b, i, len| (if (i >= len) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { bytes_eq_loop(a, b, (i + 1), len) }) })

flag : Bool -> I64
flag = |b| (if b { 1 } else { 0 })

check_header : I64
check_header = flag(bytes_eq(Fins.fins_header(1, 0, 0), [128, 0, 2, 0, 1, 0, 0, 0, 0, 0]))

check_read_dm : I64
check_read_dm = flag(bytes_eq(Fins.fins_mem_read(1, 0, 0, Fins.fins_area_dm, 100, 10), [128, 0, 2, 0, 1, 0, 0, 0, 0, 0, 1, 1, 130, 0, 100, 0, 0, 10]))

check_read_cio : I64
check_read_cio = flag(bytes_eq(Fins.fins_mem_read(1, 0, 0, Fins.fins_area_cio, 0, 1), [128, 0, 2, 0, 1, 0, 0, 0, 0, 0, 1, 1, 176, 0, 0, 0, 0, 1]))

check_write_dm : I64
check_write_dm = ({
	expect_ : List(I64)
	expect_ = [128, 0, 2, 0, 1, 0, 0, 0, 0, 0, 1, 2, 130, 0, 200, 0, 0, 2, 18, 52, 86, 120]
	flag(bytes_eq(Fins.fins_mem_write(1, 0, 0, Fins.fins_area_dm, 200, [4660, 22136]), expect_))
})

# --- Entry ---

main! = |_args| {
	a = check_header
	b = check_read_dm
	c = check_read_cio
	d = check_write_dm
	line!(I64.to_str((((a + b) + c) + d)))
	Ok({})
}
