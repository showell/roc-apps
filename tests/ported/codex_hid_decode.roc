# hid-decode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/hid-decode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     events: 42 35 23 163 170 151 80 28 208 156
#     prev-drained: 0

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.GopHid
import cdx.Mem

# HidDecodeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

report_count : I64
report_count = 7

reports : List(I64)
reports = [2, 0, 11, 0, 0, 0, 0, 0, 0, 0, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 81, 0, 0, 0, 0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

zero8! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
zero8! = |mem, b, i| (if (i >= 8) { (mem, 0) } else { ({
	(mem1, _p) = Mem.store!(mem, b, i, 0, 1)
	zero8!(mem1, b, (i + 1))
}) })

load_report! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
load_report! = |mem, cur, r, i| (if (i >= 8) { (mem, 0) } else { ({
	(mem1, _p) = Mem.store!(mem, cur, i, (List.get(reports, I64.to_u64_wrap(((r * 8) + i))) ?? crash("list-at out of range")), 1)
	load_report!(mem1, cur, r, (i + 1))
}) })

drain! : Mem.Mem, I64, I64, CceText, I64 => (Mem.Mem, CceText)
drain! = |mem, prev, cur, acc, fuel| (if (fuel <= 0) { (mem, CceText.concat(acc, " OVERRUN")) } else { ({
	(mem1, e) = GopHid.hid_step!(mem, prev, cur)
	(if (e == 0) { (mem1, acc) } else { drain!(mem1, prev, cur, CceText.concat(CceText.concat(acc, " "), CceText.show_int(e)), (fuel - 1)) })
}) })

run_reports! : Mem.Mem, I64, I64, CceText, I64 => (Mem.Mem, CceText)
run_reports! = |mem, prev, cur, acc, r| (if (r >= report_count) { (mem, acc) } else { ({
	(mem1, _l) = load_report!(mem, cur, r, 0)
	({
		(mem2, mem__1) = drain!(mem1, prev, cur, acc, 32)
		run_reports!(mem2, prev, cur, mem__1, (r + 1))
	})
}) })

# --- Entry ---

main! = |args| {
	mem = Mem.new(U64.to_i64_wrap(List.len(args)))
	(_mem10, mem__5) = ({
		(mem1, b) = Mem.mark(mem)
		(mem2, _adv) = Mem.advance(mem1, 64)
		prev = b
		cur = (b + 8)
		(mem3, _z0) = zero8!(mem2, prev, 0)
		(mem4, _z1) = zero8!(mem3, cur, 0)
		({
			({
				(mem5, flat) = run_reports!(mem4, prev, cur, "", 0)
				({
					_ = line!(CceText.printed(CceText.concat("events:", flat)))
					({
						(mem9, mem__4) = ({
						(mem6, mem__1) = Mem.load!(mem5, prev, 0, 1)
						(mem7, mem__2) = Mem.load!(mem6, prev, 2, 1)
						(mem8, mem__3) = Mem.load!(mem7, prev, 3, 1)
						held = ((mem__1 + mem__2) + mem__3)
						(mem8, line!(CceText.printed(CceText.concat("prev-drained: ", CceText.show_int(held)))))
					})
						(mem9, mem__4)
					})
				})
			})
		})
	})
	mem__5
	Ok({})
}
