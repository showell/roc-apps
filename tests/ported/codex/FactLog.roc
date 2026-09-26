# FactLog -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import Mem

FactLog :: [].{

	fl_sector_size : I64
	fl_sector_size = 512

	fl_fact_log_start : I64
	fl_fact_log_start = 2

	fl_header_size : I64
	fl_header_size = 78

	fl_magic : CceText
	fl_magic = "CODEXFS1"

	fl_kind_definition : I64
	fl_kind_definition = 30

	fl_off_kind : I64
	fl_off_kind = 32

	fl_off_timestamp : I64
	fl_off_timestamp = 66

	fl_off_content_len : I64
	fl_off_content_len = 74

	fl_off_sb_log_head : I64
	fl_off_sb_log_head = 8

	fl_off_sb_index_gen : I64
	fl_off_sb_index_gen = 24

	fl_u16! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	fl_u16! = |mem, buf, off| ({
		(mem1, mem__1) = Mem.load!(mem, buf, off, 1)
		(mem2, mem__2) = Mem.load!(mem1, buf, (off + 1), 1)
		(mem2, I64.bitwise_or(mem__1, I64.shl_wrap(mem__2, I64.to_u8_wrap(8))))
	})

	fl_u32! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	fl_u32! = |mem, buf, off| ({
		(mem5, mem__4) = ({
		(mem1, b0) = Mem.load!(mem, buf, off, 1)
		(mem2, mem__1) = Mem.load!(mem1, buf, (off + 1), 1)
		b1 : I64
		b1 = I64.shl_wrap(mem__1, I64.to_u8_wrap(8))
		(mem3, mem__2) = Mem.load!(mem2, buf, (off + 2), 1)
		b2 : I64
		b2 = I64.shl_wrap(mem__2, I64.to_u8_wrap(16))
		(mem4, mem__3) = Mem.load!(mem3, buf, (off + 3), 1)
		b3 : I64
		b3 = I64.shl_wrap(mem__3, I64.to_u8_wrap(24))
		(mem4, I64.bitwise_or(b0, I64.bitwise_or(b1, I64.bitwise_or(b2, b3))))
	})
		(mem5, mem__4)
	})

	fl_u64! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	fl_u64! = |mem, buf, off| ({
		(mem9, mem__8) = ({
		(mem1, b0) = Mem.load!(mem, buf, off, 1)
		(mem2, mem__1) = Mem.load!(mem1, buf, (off + 1), 1)
		b1 : I64
		b1 = I64.shl_wrap(mem__1, I64.to_u8_wrap(8))
		(mem3, mem__2) = Mem.load!(mem2, buf, (off + 2), 1)
		b2 : I64
		b2 = I64.shl_wrap(mem__2, I64.to_u8_wrap(16))
		(mem4, mem__3) = Mem.load!(mem3, buf, (off + 3), 1)
		b3 : I64
		b3 = I64.shl_wrap(mem__3, I64.to_u8_wrap(24))
		(mem5, mem__4) = Mem.load!(mem4, buf, (off + 4), 1)
		b4 : I64
		b4 = I64.shl_wrap(mem__4, I64.to_u8_wrap(32))
		(mem6, mem__5) = Mem.load!(mem5, buf, (off + 5), 1)
		b5 : I64
		b5 = I64.shl_wrap(mem__5, I64.to_u8_wrap(40))
		(mem7, mem__6) = Mem.load!(mem6, buf, (off + 6), 1)
		b6 : I64
		b6 = I64.shl_wrap(mem__6, I64.to_u8_wrap(48))
		(mem8, mem__7) = Mem.load!(mem7, buf, (off + 7), 1)
		b7 : I64
		b7 = I64.shl_wrap(mem__7, I64.to_u8_wrap(56))
		(mem8, I64.bitwise_or(b0, I64.bitwise_or(b1, I64.bitwise_or(b2, I64.bitwise_or(b3, I64.bitwise_or(b4, I64.bitwise_or(b5, I64.bitwise_or(b6, b7))))))))
	})
		(mem9, mem__8)
	})

	fl_text! : Mem.Mem, I64, I64, I64 => (Mem.Mem, CceText)
	fl_text! = |mem, buf, off, len| ({
		(mem1, mem__1) = fl_text_loop!(mem, buf, off, len, 0, List.with_capacity(I64.to_u64_wrap((len + 1))))
		(mem1, CceText.of_bytes(mem__1))
	})

	fl_text_loop! : Mem.Mem, I64, I64, I64, I64, List(I64) => (Mem.Mem, List(I64))
	fl_text_loop! = |mem, buf, off, len, i, acc| (if (i >= len) { (mem, acc) } else { ({
		(mem1, mem__1) = Mem.load!(mem, buf, (off + i), 1)
		fl_text_loop!(mem1, buf, off, len, (i + 1), List.append(acc, mem__1))
	}) })

	fl_sectors_for : I64 -> I64
	fl_sectors_for = |content_len| I64.div_trunc_by((((fl_header_size + content_len) + fl_sector_size) - 1), fl_sector_size)

	fl_magic_ok! : Mem.Mem, I64 => (Mem.Mem, Bool)
	fl_magic_ok! = |mem, buf| ({
		(mem1, mem__1) = fl_text!(mem, buf, 0, 8)
		(mem1, (mem__1 == fl_magic))
	})

	fl_entry_kind! : Mem.Mem, I64 => (Mem.Mem, I64)
	fl_entry_kind! = |mem, buf| fl_u16!(mem, buf, fl_off_kind)

	fl_entry_timestamp! : Mem.Mem, I64 => (Mem.Mem, I64)
	fl_entry_timestamp! = |mem, buf| fl_u64!(mem, buf, fl_off_timestamp)

	fl_entry_content_len! : Mem.Mem, I64 => (Mem.Mem, I64)
	fl_entry_content_len! = |mem, buf| fl_u32!(mem, buf, fl_off_content_len)

	fl_sb_log_head! : Mem.Mem, I64 => (Mem.Mem, I64)
	fl_sb_log_head! = |mem, buf| fl_u64!(mem, buf, fl_off_sb_log_head)

	fl_sb_index_gen! : Mem.Mem, I64 => (Mem.Mem, I64)
	fl_sb_index_gen! = |mem, buf| fl_u64!(mem, buf, fl_off_sb_index_gen)
}
