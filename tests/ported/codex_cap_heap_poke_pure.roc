# cap-heap-poke-pure
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/cap-heap-poke-pure.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     42

app [main!] { cdx: "./codex/main.roc" }

import cdx.Mem
import cdx.Text

# CapHeapPokePure -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

raw_mem! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
raw_mem! = |mem, addr, val| ({
	(mem1, _w) = Mem.store!(mem, addr, 0, val, 1)
	Mem.load!(mem1, addr, 0, 1)
})

# --- Entry ---

main! = |args| {
	mem = Mem.new(U64.to_i64_wrap(List.len(args)))
	(_mem1, mem__1) = raw_mem!(mem, 786432, 42)
	line!(Text.printed(Text.show_int(mem__1)))
	Ok({})
}
