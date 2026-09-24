# factlog-layout
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/factlog-layout.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     u16=4660 want=4660
#     u32=305419896 want=305419896
#     u64=81985529216486895 want=81985529216486895
#     u64-high=-9223372036854775808
#     kind=30 ts=1234567890123 clen=4321
#     log-head=777 index-gen=42
#     off kind=32 ts=66 clen=74 hdr=78 sec=512
#     magic-ok=yes
#     magic-corrupt=no
#     sectors 0=1 434=1 435=2 1024=3
#     text=hello
#     text-cps=200 1 255 len=3

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.FactLog
import cdx.Mem

# FactLogLayout -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

poke_le! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
poke_le! = |mem, buf, off, v, n| poke_le_loop!(mem, buf, off, v, 0, n)

poke_le_loop! : Mem.Mem, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
poke_le_loop! = |mem, buf, off, v, i, n| (if (i >= n) { (mem, 0) } else { ({
	b : I64
	b = I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap((i * 8))), 255)
	(mem1, _p) = Mem.store!(mem, buf, (off + i), b, 1)
	poke_le_loop!(mem1, buf, off, v, (i + 1), n)
}) })

pack_cce! : Mem.Mem, I64, I64, CceText, I64, I64 => (Mem.Mem, I64)
pack_cce! = |mem, buf, off, txt, i, n| (if (i >= n) { (mem, 0) } else { ({
	(mem1, _p) = Mem.store!(mem, buf, (off + i), CceText.char_code_at(txt, i), 1)
	pack_cce!(mem1, buf, off, txt, (i + 1), n)
}) })

test_u16! : Mem.Mem => (Mem.Mem, CceText)
test_u16! = |mem| ({
	(mem5, mem__2) = ({
	(mem1, buf) = Mem.alloc(mem, 64)
	(mem2, _a) = Mem.store!(mem1, buf, 0, 52, 1)
	(mem3, _b) = Mem.store!(mem2, buf, 1, 18, 1)
	({
		(mem4, mem__1) = FactLog.fl_u16!(mem3, buf, 0)
		(mem4, CceText.concat(CceText.concat("u16=", CceText.show_int(mem__1)), " want=4660"))
	})
})
	(mem5, mem__2)
})

test_u32! : Mem.Mem => (Mem.Mem, CceText)
test_u32! = |mem| ({
	(mem7, mem__2) = ({
	(mem1, buf) = Mem.alloc(mem, 64)
	(mem2, _a) = Mem.store!(mem1, buf, 0, 120, 1)
	(mem3, _b) = Mem.store!(mem2, buf, 1, 86, 1)
	(mem4, _c) = Mem.store!(mem3, buf, 2, 52, 1)
	(mem5, _d) = Mem.store!(mem4, buf, 3, 18, 1)
	({
		(mem6, mem__1) = FactLog.fl_u32!(mem5, buf, 0)
		(mem6, CceText.concat(CceText.concat("u32=", CceText.show_int(mem__1)), " want=305419896"))
	})
})
	(mem7, mem__2)
})

test_u64! : Mem.Mem => (Mem.Mem, CceText)
test_u64! = |mem| ({
	(mem4, mem__2) = ({
	(mem1, buf) = Mem.alloc(mem, 64)
	(mem2, _p) = poke_le!(mem1, buf, 0, 81985529216486895, 8)
	({
		(mem3, mem__1) = FactLog.fl_u64!(mem2, buf, 0)
		(mem3, CceText.concat(CceText.concat("u64=", CceText.show_int(mem__1)), " want=81985529216486895"))
	})
})
	(mem4, mem__2)
})

test_u64_high! : Mem.Mem => (Mem.Mem, CceText)
test_u64_high! = |mem| ({
	(mem4, mem__2) = ({
	(mem1, buf) = Mem.alloc(mem, 64)
	(mem2, _p) = poke_le!(mem1, buf, 0, I64.shl_wrap(128, I64.to_u8_wrap(56)), 8)
	({
		(mem3, mem__1) = FactLog.fl_u64!(mem2, buf, 0)
		(mem3, CceText.concat("u64-high=", CceText.show_int(mem__1)))
	})
})
	(mem4, mem__2)
})

test_entry_fields! : Mem.Mem => (Mem.Mem, CceText)
test_entry_fields! = |mem| ({
	(mem8, mem__4) = ({
	(mem1, buf) = Mem.alloc(mem, 512)
	(mem2, _k) = poke_le!(mem1, buf, FactLog.fl_off_kind, 30, 2)
	(mem3, _t) = poke_le!(mem2, buf, FactLog.fl_off_timestamp, 1234567890123, 8)
	(mem4, _c) = poke_le!(mem3, buf, FactLog.fl_off_content_len, 4321, 4)
	({
		(mem5, mem__1) = FactLog.fl_entry_kind!(mem4, buf)
		(mem6, mem__2) = FactLog.fl_entry_timestamp!(mem5, buf)
		(mem7, mem__3) = FactLog.fl_entry_content_len!(mem6, buf)
		(mem7, CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("kind=", CceText.show_int(mem__1)), " ts="), CceText.show_int(mem__2)), " clen="), CceText.show_int(mem__3)))
	})
})
	(mem8, mem__4)
})

test_superblock_fields! : Mem.Mem => (Mem.Mem, CceText)
test_superblock_fields! = |mem| ({
	(mem6, mem__3) = ({
	(mem1, buf) = Mem.alloc(mem, 512)
	(mem2, _h) = poke_le!(mem1, buf, FactLog.fl_off_sb_log_head, 777, 8)
	(mem3, _g) = poke_le!(mem2, buf, FactLog.fl_off_sb_index_gen, 42, 8)
	({
		(mem4, mem__1) = FactLog.fl_sb_log_head!(mem3, buf)
		(mem5, mem__2) = FactLog.fl_sb_index_gen!(mem4, buf)
		(mem5, CceText.concat(CceText.concat(CceText.concat("log-head=", CceText.show_int(mem__1)), " index-gen="), CceText.show_int(mem__2)))
	})
})
	(mem6, mem__3)
})

test_offsets : CceText
test_offsets = CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("off kind=", CceText.show_int(FactLog.fl_off_kind)), " ts="), CceText.show_int(FactLog.fl_off_timestamp)), " clen="), CceText.show_int(FactLog.fl_off_content_len)), " hdr="), CceText.show_int(FactLog.fl_header_size)), " sec="), CceText.show_int(FactLog.fl_sector_size))

test_magic_ok! : Mem.Mem => (Mem.Mem, CceText)
test_magic_ok! = |mem| ({
	(mem4, mem__2) = ({
	(mem1, buf) = Mem.alloc(mem, 512)
	(mem2, _p) = pack_cce!(mem1, buf, 0, FactLog.fl_magic, 0, 8)
	({
		(mem3, mem__1) = FactLog.fl_magic_ok!(mem2, buf)
		(mem3, CceText.concat("magic-ok=", (if mem__1 { "yes" } else { "no" })))
	})
})
	(mem4, mem__2)
})

test_magic_bad! : Mem.Mem => (Mem.Mem, CceText)
test_magic_bad! = |mem| ({
	(mem5, mem__2) = ({
	(mem1, buf) = Mem.alloc(mem, 512)
	(mem2, _p) = pack_cce!(mem1, buf, 0, FactLog.fl_magic, 0, 8)
	(mem3, _corrupt) = Mem.store!(mem2, buf, 3, 99, 1)
	({
		(mem4, mem__1) = FactLog.fl_magic_ok!(mem3, buf)
		(mem4, CceText.concat("magic-corrupt=", (if mem__1 { "yes" } else { "no" })))
	})
})
	(mem5, mem__2)
})

test_sectors : CceText
test_sectors = CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("sectors 0=", CceText.show_int(FactLog.fl_sectors_for(0))), " 434="), CceText.show_int(FactLog.fl_sectors_for(434))), " 435="), CceText.show_int(FactLog.fl_sectors_for(435))), " 1024="), CceText.show_int(FactLog.fl_sectors_for(1024)))

test_text! : Mem.Mem => (Mem.Mem, CceText)
test_text! = |mem| ({
	(mem4, mem__2) = ({
	(mem1, buf) = Mem.alloc(mem, 512)
	(mem2, _p) = pack_cce!(mem1, buf, 16, "hello", 0, 5)
	({
		(mem3, mem__1) = FactLog.fl_text!(mem2, buf, 16, 5)
		(mem3, CceText.concat("text=", mem__1))
	})
})
	(mem4, mem__2)
})

test_text_bytes! : Mem.Mem => (Mem.Mem, CceText)
test_text_bytes! = |mem| ({
	(mem6, mem__1) = ({
	(mem1, buf) = Mem.alloc(mem, 512)
	(mem2, _a) = Mem.store!(mem1, buf, 0, 200, 1)
	(mem3, _b) = Mem.store!(mem2, buf, 1, 1, 1)
	(mem4, _c) = Mem.store!(mem3, buf, 2, 255, 1)
	(mem5, s) = FactLog.fl_text!(mem4, buf, 0, 3)
	(mem5, CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("text-cps=", CceText.show_int(CceText.char_code_at(s, 0))), " "), CceText.show_int(CceText.char_code_at(s, 1))), " "), CceText.show_int(CceText.char_code_at(s, 2))), " len="), CceText.show_int(CceText.len(s))))
})
	(mem6, mem__1)
})

# --- Entry ---

main! = |args| {
	mem = Mem.new(U64.to_i64_wrap(List.len(args)))
	(mem1, mem__1) = test_u16!(mem)
	line!(CceText.printed(mem__1))
	(mem2, mem__2) = test_u32!(mem1)
	line!(CceText.printed(mem__2))
	(mem3, mem__3) = test_u64!(mem2)
	line!(CceText.printed(mem__3))
	(mem4, mem__4) = test_u64_high!(mem3)
	line!(CceText.printed(mem__4))
	(mem5, mem__5) = test_entry_fields!(mem4)
	line!(CceText.printed(mem__5))
	(mem6, mem__6) = test_superblock_fields!(mem5)
	line!(CceText.printed(mem__6))
	line!(CceText.printed(test_offsets))
	(mem7, mem__7) = test_magic_ok!(mem6)
	line!(CceText.printed(mem__7))
	(mem8, mem__8) = test_magic_bad!(mem7)
	line!(CceText.printed(mem__8))
	line!(CceText.printed(test_sectors))
	(mem9, mem__9) = test_text!(mem8)
	line!(CceText.printed(mem__9))
	(_mem10, mem__10) = test_text_bytes!(mem9)
	line!(CceText.printed(mem__10))
	Ok({})
}
