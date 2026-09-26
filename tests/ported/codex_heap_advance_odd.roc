# heap-advance-odd
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/heap-advance-odd.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     record 42
#     list 9
#     closure 42

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Mem

# HeapAdvanceOdd -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Pair := { pa : I64, pb : I64 }.{
	is_eq : Pair, Pair -> Bool
	is_eq = |a, b| eq_Pair(a, b)
}

mk_pair : I64, I64 -> Pair
mk_pair = |a, b| Pair.{ pa: a, pb: b }

mk_list : I64 -> List(I64)
mk_list = |x| [x, (x + 1), (x + 2)]

adder : I64, I64 -> I64
adder = |k, v| (v + k)

eq_Pair : Pair, Pair -> Bool
eq_Pair = |ex, ey| ((ex.pa == ey.pa) and (ex.pb == ey.pb))

# --- Entry ---

main! = |args| {
	mem = Mem.new(U64.to_i64_wrap(List.len(args)))
	(_mem2, mem__3) = ({
		(mem1, _a) = Mem.advance(mem, 3)
		p = mk_pair(40, 2)
		xs : List(I64)
		xs = mk_list(7)
		f = ({
			mem__1 = 30
			|mem__2| adder(mem__1, mem__2)
		})
		({
			_ = line!(CceText.printed(CceText.concat("record ", CceText.show_int((p.pa + p.pb)))))
			_ = line!(CceText.printed(CceText.concat("list ", CceText.show_int((List.get(xs, I64.to_u64_wrap(2)) ?? crash("list-at out of range"))))))
			(mem1, line!(CceText.printed(CceText.concat("closure ", CceText.show_int(f(12))))))
		})
	})
	mem__3
	Ok({})
}
