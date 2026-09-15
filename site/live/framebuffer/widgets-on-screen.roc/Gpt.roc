# Gpt -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Cce
import Maybe
import Mem

Gpt :: [].{
	GptPartition : { gp_type_guid : List(I64), gp_unique_guid : List(I64), gp_start_lba : I64, gp_end_lba : I64, gp_attributes : I64, gp_name : Str }
	GptDisk : { gd_disk_guid : List(I64), gd_partition_count : I64, gd_partitions : List(Gpt.GptPartition), gd_total_sectors : I64 }
	GptPartitionSpec : { gs_type_guid : List(I64), gs_name : Str, gs_size_sectors : I64 }
	GptPartEntry : { ge_type_guid : List(I64), ge_unique_guid : List(I64), ge_start_lba : I64, ge_end_lba : I64, ge_name : Str }

	gpt_sig_0 : I64
	gpt_sig_0 = 69

	gpt_sig_1 : I64
	gpt_sig_1 = 70

	gpt_sig_2 : I64
	gpt_sig_2 = 73

	gpt_sig_3 : I64
	gpt_sig_3 = 32

	gpt_sig_4 : I64
	gpt_sig_4 = 80

	gpt_sig_5 : I64
	gpt_sig_5 = 65

	gpt_sig_6 : I64
	gpt_sig_6 = 82

	gpt_sig_7 : I64
	gpt_sig_7 = 84

	gpt_read_u16! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	gpt_read_u16! = |mem, buf, off| ({
		(mem1, mem__262) = Mem.load!(mem, buf, off, 1)
		(mem2, mem__263) = Mem.load!(mem1, buf, (off + 1), 1)
		(mem2, I64.bitwise_or(mem__262, I64.shl_wrap(mem__263, I64.to_u8_wrap(8))))
	})

	gpt_read_u32! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	gpt_read_u32! = |mem, buf, off| ({
		(mem1, mem__264) = gpt_read_u16!(mem, buf, off)
		(mem2, mem__265) = gpt_read_u16!(mem1, buf, (off + 2))
		(mem2, I64.bitwise_or(mem__264, I64.shl_wrap(mem__265, I64.to_u8_wrap(16))))
	})

	gpt_read_u64! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	gpt_read_u64! = |mem, buf, off| ({
		(mem1, mem__266) = gpt_read_u32!(mem, buf, off)
		(mem2, mem__267) = gpt_read_u32!(mem1, buf, (off + 4))
		(mem2, I64.bitwise_or(mem__266, I64.shl_wrap(mem__267, I64.to_u8_wrap(32))))
	})

	gpt_write_u16! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	gpt_write_u16! = |mem, buf, off, v| ({
		(mem3, mem__268) = ({
		(mem1, _w0) = Mem.store!(mem, buf, off, I64.bitwise_and(v, 255), 1)
		(mem2, _w1) = Mem.store!(mem1, buf, (off + 1), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255), 1)
		(mem2, (off + 2))
	})
		(mem3, mem__268)
	})

	gpt_write_u32! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	gpt_write_u32! = |mem, buf, off, v| ({
		(mem5, mem__269) = ({
		(mem1, _w0) = Mem.store!(mem, buf, off, I64.bitwise_and(v, 255), 1)
		(mem2, _w1) = Mem.store!(mem1, buf, (off + 1), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255), 1)
		(mem3, _w2) = Mem.store!(mem2, buf, (off + 2), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(16)), 255), 1)
		(mem4, _w3) = Mem.store!(mem3, buf, (off + 3), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(24)), 255), 1)
		(mem4, (off + 4))
	})
		(mem5, mem__269)
	})

	gpt_write_u64! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	gpt_write_u64! = |mem, buf, off, v| ({
		(mem1, _w0) = gpt_write_u32!(mem, buf, off, v)
		gpt_write_u32!(mem1, buf, (off + 4), I64.shr_zf_wrap(v, I64.to_u8_wrap(32)))
	})

	gpt_read_guid! : Mem.Mem, I64, I64 => (Mem.Mem, List(I64))
	gpt_read_guid! = |mem, buf, off| gpt_read_guid_loop!(mem, buf, off, 0, [])

	gpt_read_guid_loop! : Mem.Mem, I64, I64, I64, List(I64) => (Mem.Mem, List(I64))
	gpt_read_guid_loop! = |mem, buf, off, i, acc| (if (i >= 16) { (mem, acc) } else { ({
		(mem1, mem__270) = Mem.load!(mem, buf, (off + i), 1)
		gpt_read_guid_loop!(mem1, buf, off, (i + 1), List.append(acc, mem__270))
	}) })

	gpt_write_guid! : Mem.Mem, I64, I64, List(I64) => (Mem.Mem, I64)
	gpt_write_guid! = |mem, buf, off, guid| gpt_write_guid_loop!(mem, buf, off, guid, 0)

	gpt_write_guid_loop! : Mem.Mem, I64, I64, List(I64), I64 => (Mem.Mem, I64)
	gpt_write_guid_loop! = |mem, buf, off, guid, i| (if (i >= 16) { (mem, (off + 16)) } else { ({
		(mem1, _w) = Mem.store!(mem, buf, (off + i), (List.get(guid, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), 1)
		gpt_write_guid_loop!(mem1, buf, off, guid, (i + 1))
	}) })

	gpt_guid_is_zero : List(I64) -> Bool
	gpt_guid_is_zero = |guid| gpt_guid_zero_loop(guid, 0)

	gpt_guid_zero_loop : List(I64), I64 -> Bool
	gpt_guid_zero_loop = |guid, i| (if (i >= 16) { True } else { (if ((List.get(guid, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != 0) { False } else { gpt_guid_zero_loop(guid, (i + 1)) }) })

	gpt_read_name! : Mem.Mem, I64, I64 => (Mem.Mem, Str)
	gpt_read_name! = |mem, buf, off| gpt_read_name_loop!(mem, buf, off, 0, 36, "")

	gpt_read_name_loop! : Mem.Mem, I64, I64, I64, I64, Str => (Mem.Mem, Str)
	gpt_read_name_loop! = |mem, buf, off, i, max_chars, acc| (if (i >= max_chars) { (mem, acc) } else { ({
		(mem1, lo) = Mem.load!(mem, buf, (off + (i * 2)), 1)
		(mem2, hi) = Mem.load!(mem1, buf, ((off + (i * 2)) + 1), 1)
		code = I64.bitwise_or(lo, I64.shl_wrap(hi, I64.to_u8_wrap(8)))
		(if (code == 0) { (mem2, acc) } else { gpt_read_name_loop!(mem2, buf, off, (i + 1), max_chars, Str.concat(acc, Cce.text(code))) })
	}) })

	gpt_check_signature! : Mem.Mem, I64 => (Mem.Mem, Bool)
	gpt_check_signature! = |mem, buf| ({
		(mem1, mem__271) = Mem.load!(mem, buf, 0, 1)
		(mem3, mem__273) = (if (mem__271 == gpt_sig_0) { ({
		(mem2, mem__272) = Mem.load!(mem1, buf, 1, 1)
		(mem2, (mem__272 == gpt_sig_1))
	}) } else { (mem1, False) })
		(mem5, mem__275) = (if mem__273 { ({
		(mem4, mem__274) = Mem.load!(mem3, buf, 2, 1)
		(mem4, (mem__274 == gpt_sig_2))
	}) } else { (mem3, False) })
		(mem7, mem__277) = (if mem__275 { ({
		(mem6, mem__276) = Mem.load!(mem5, buf, 3, 1)
		(mem6, (mem__276 == gpt_sig_3))
	}) } else { (mem5, False) })
		(mem9, mem__279) = (if mem__277 { ({
		(mem8, mem__278) = Mem.load!(mem7, buf, 4, 1)
		(mem8, (mem__278 == gpt_sig_4))
	}) } else { (mem7, False) })
		(mem11, mem__281) = (if mem__279 { ({
		(mem10, mem__280) = Mem.load!(mem9, buf, 5, 1)
		(mem10, (mem__280 == gpt_sig_5))
	}) } else { (mem9, False) })
		(mem13, mem__283) = (if mem__281 { ({
		(mem12, mem__282) = Mem.load!(mem11, buf, 6, 1)
		(mem12, (mem__282 == gpt_sig_6))
	}) } else { (mem11, False) })
		(mem15, mem__285) = (if mem__283 { ({
		(mem14, mem__284) = Mem.load!(mem13, buf, 7, 1)
		(mem14, (mem__284 == gpt_sig_7))
	}) } else { (mem13, False) })
		(mem15, mem__285)
	})

	gpt_parse_entry! : Mem.Mem, I64, I64 => (Mem.Mem, Gpt.GptPartition)
	gpt_parse_entry! = |mem, buf, off| ({
		(mem1, mem__286) = gpt_read_guid!(mem, buf, off)
		(mem2, mem__287) = gpt_read_guid!(mem1, buf, (off + 16))
		(mem3, mem__288) = gpt_read_u64!(mem2, buf, (off + 32))
		(mem4, mem__289) = gpt_read_u64!(mem3, buf, (off + 40))
		(mem5, mem__290) = gpt_read_u64!(mem4, buf, (off + 48))
		(mem6, mem__291) = gpt_read_name!(mem5, buf, (off + 56))
		(mem6, { gp_type_guid: mem__286, gp_unique_guid: mem__287, gp_start_lba: mem__288, gp_end_lba: mem__289, gp_attributes: mem__290, gp_name: mem__291 })
	})

	gpt_read_entries! : Mem.Mem, I64, I64, I64, I64, List(Gpt.GptPartition) => (Mem.Mem, List(Gpt.GptPartition))
	gpt_read_entries! = |_, _, _, _, _, _| crash("`gpt-read-entries` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	gpt_read_entries_step! : Mem.Mem, I64, I64, I64, I64, List(Gpt.GptPartition), I64 => (Mem.Mem, List(Gpt.GptPartition))
	gpt_read_entries_step! = |_, _, _, _, _, _, _| crash("`gpt-read-entries-step` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	gpt_check_mbr! : Mem.Mem, I64 => (Mem.Mem, Bool)
	gpt_check_mbr! = |mem, buf| ({
		(mem1, mem__292) = Mem.load!(mem, buf, 510, 1)
		(mem3, mem__294) = (if (mem__292 == 85) { ({
		(mem2, mem__293) = Mem.load!(mem1, buf, 511, 1)
		(mem2, (mem__293 == 170))
	}) } else { (mem1, False) })
		(mem3, mem__294)
	})

	gpt_read! : Mem.Mem => (Mem.Mem, Maybe.Maybe(Gpt.GptDisk))
	gpt_read! = |_| crash("`gpt-read` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	gpt_read_after_mbr! : Mem.Mem, I64 => (Mem.Mem, Maybe.Maybe(Gpt.GptDisk))
	gpt_read_after_mbr! = |_, _| crash("`gpt-read-after-mbr` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	gpt_header_geom_ok! : Mem.Mem, I64 => (Mem.Mem, Bool)
	gpt_header_geom_ok! = |mem, buf| ({
		(mem5, mem__295) = ({
		(mem1, lba) = gpt_read_u64!(mem, buf, 72)
		(mem2, cnt) = gpt_read_u32!(mem1, buf, 80)
		(mem3, sz) = gpt_read_u32!(mem2, buf, 84)
		(mem4, first_usable) = gpt_read_u64!(mem3, buf, 40)
		(mem4, (((((((lba >= 2) and (cnt >= 1)) and (cnt <= 1024)) and (sz >= 128)) and (sz <= 512)) and ((sz - (I64.div_trunc_by(sz, 128) * 128)) == 0)) and ((lba + I64.div_trunc_by(((cnt * sz) + 511), 512)) <= first_usable)))
	})
		(mem5, mem__295)
	})

	gpt_read_after_hdr! : Mem.Mem, I64 => (Mem.Mem, Maybe.Maybe(Gpt.GptDisk))
	gpt_read_after_hdr! = |_, _| crash("`gpt-read-after-hdr` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	gpt_make_disk : List(I64), I64, List(Gpt.GptPartition) -> Maybe.Maybe(Gpt.GptDisk)
	gpt_make_disk = |disk_guid, total_sectors, parts| Just({ gd_disk_guid: disk_guid, gd_partition_count: U64.to_i64_wrap(List.len(parts)), gd_partitions: parts, gd_total_sectors: total_sectors })

	gpt_read_partition! : Mem.Mem, I64 => (Mem.Mem, Maybe.Maybe(Gpt.GptPartition))
	gpt_read_partition! = |_, _| crash("`gpt-read-partition` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	gpt_rt_crc32_table : List(I64)
	gpt_rt_crc32_table = gpt_rt_build_crc32(0, [])

	gpt_rt_build_crc32 : I64, List(I64) -> List(I64)
	gpt_rt_build_crc32 = |i, acc| (if (i >= 256) { acc } else { gpt_rt_build_crc32((i + 1), List.append(acc, gpt_rt_crc32_entry(i, 0))) })

	gpt_rt_crc32_entry : I64, I64 -> I64
	gpt_rt_crc32_entry = |v, j| (if (j >= 8) { v } else { (if (I64.bitwise_and(v, 1) == 1) { gpt_rt_crc32_entry(I64.bitwise_xor(I64.shr_zf_wrap(v, I64.to_u8_wrap(1)), 3988292384), (j + 1)) } else { gpt_rt_crc32_entry(I64.shr_zf_wrap(v, I64.to_u8_wrap(1)), (j + 1)) }) })

	gpt_rt_crc32_bytes : List(I64), I64 -> I64
	gpt_rt_crc32_bytes = |data, len| I64.bitwise_xor(gpt_rt_crc32_loop(data, 4294967295, 0, len), 4294967295)

	gpt_rt_crc32_loop : List(I64), I64, I64, I64 -> I64
	gpt_rt_crc32_loop = |data, crc, i, len| (if (i >= len) { crc } else { ({
		b = (List.get(data, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		idx = I64.bitwise_and(I64.bitwise_xor(crc, b), 255)
		gpt_rt_crc32_loop(data, I64.bitwise_xor(I64.shr_zf_wrap(crc, I64.to_u8_wrap(8)), (List.get(gpt_rt_crc32_table, I64.to_u64_wrap(idx)) ?? crash("list-at out of range"))), (i + 1), len)
	}) })

	gpt_rt_crc32_sector! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	gpt_rt_crc32_sector! = |_, _, _, _| crash("`gpt-rt-crc32-sector` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	gpt_rt_crc32_sectors_loop! : Mem.Mem, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gpt_rt_crc32_sectors_loop! = |_, _, _, _, _, _| crash("`gpt-rt-crc32-sectors-loop` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	gpt_rt_crc32_sectors_step! : Mem.Mem, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gpt_rt_crc32_sectors_step! = |_, _, _, _, _, _, _| crash("`gpt-rt-crc32-sectors-step` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	gpt_rt_crc32_buf_loop! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	gpt_rt_crc32_buf_loop! = |mem, buf, crc, i, len| (if (i >= len) { (mem, crc) } else { ({
		(mem1, b) = Mem.load!(mem, buf, i, 1)
		idx = I64.bitwise_and(I64.bitwise_xor(crc, b), 255)
		gpt_rt_crc32_buf_loop!(mem1, buf, I64.bitwise_xor(I64.shr_zf_wrap(crc, I64.to_u8_wrap(8)), (List.get(gpt_rt_crc32_table, I64.to_u64_wrap(idx)) ?? crash("list-at out of range"))), (i + 1), len)
	}) })

	gpt_done : I64 -> Bool
	gpt_done = |_w| True

	gpt_write_name_utf16! : Mem.Mem, I64, I64, Str, I64 => (Mem.Mem, I64)
	gpt_write_name_utf16! = |mem, buf, off, name, i| (if (i >= Cce.length(name)) { (mem, (off + (Cce.length(name) * 2))) } else { ({
		c = Cce.at_or_crash(name, i)
		(mem1, _w0) = Mem.store!(mem, buf, (off + (i * 2)), I64.bitwise_and(c, 255), 1)
		(mem2, _w1) = Mem.store!(mem1, buf, ((off + (i * 2)) + 1), I64.bitwise_and(I64.shr_zf_wrap(c, I64.to_u8_wrap(8)), 255), 1)
		gpt_write_name_utf16!(mem2, buf, off, name, (i + 1))
	}) })

	gpt_zero_sector! : Mem.Mem, I64 => (Mem.Mem, I64)
	gpt_zero_sector! = |mem, buf| gpt_zero_loop!(mem, buf, 0)

	gpt_zero_loop! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	gpt_zero_loop! = |mem, buf, i| (if (i >= 512) { (mem, 0) } else { ({
		(mem1, _w) = Mem.store!(mem, buf, i, 0, 1)
		gpt_zero_loop!(mem1, buf, (i + 1))
	}) })

	gpt_write_table! : Mem.Mem, List(Gpt.GptPartitionSpec), I64, List(I64) => (Mem.Mem, Bool)
	gpt_write_table! = |_, _, _, _| crash("`gpt-write-table` reaches `block-write-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	gpt_build_protective_mbr! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	gpt_build_protective_mbr! = |mem, mbr_buf, total_sectors| ({
		(mem1, _z0) = gpt_zero_sector!(mem, mbr_buf)
		(mem2, _w0) = Mem.store!(mem1, mbr_buf, 446, 0, 1)
		(mem3, _w1) = Mem.store!(mem2, mbr_buf, 449, 2, 1)
		(mem4, _w2) = Mem.store!(mem3, mbr_buf, 450, 238, 1)
		(mem5, _w3) = Mem.store!(mem4, mbr_buf, 451, 255, 1)
		(mem6, _w4) = Mem.store!(mem5, mbr_buf, 452, 255, 1)
		(mem7, _w5) = Mem.store!(mem6, mbr_buf, 453, 255, 1)
		mbr_sec = (if ((total_sectors - 1) > 4294967295) { 4294967295 } else { (total_sectors - 1) })
		(mem8, _w6) = gpt_write_u32!(mem7, mbr_buf, 454, 1)
		(mem9, _w7) = gpt_write_u32!(mem8, mbr_buf, 458, mbr_sec)
		(mem10, _w8) = Mem.store!(mem9, mbr_buf, 510, 85, 1)
		Mem.store!(mem10, mbr_buf, 511, 170, 1)
	})

	gpt_build_header! : Mem.Mem, I64, I64, List(I64), I64 => (Mem.Mem, I64)
	gpt_build_header! = |mem, hdr_buf, total_sectors, disk_guid, pe_crc| ({
		(mem1, _z1) = gpt_zero_sector!(mem, hdr_buf)
		(mem2, _w11) = Mem.store!(mem1, hdr_buf, 0, 69, 1)
		(mem3, _w12) = Mem.store!(mem2, hdr_buf, 1, 70, 1)
		(mem4, _w13) = Mem.store!(mem3, hdr_buf, 2, 73, 1)
		(mem5, _w14) = Mem.store!(mem4, hdr_buf, 3, 32, 1)
		(mem6, _w15) = Mem.store!(mem5, hdr_buf, 4, 80, 1)
		(mem7, _w16) = Mem.store!(mem6, hdr_buf, 5, 65, 1)
		(mem8, _w17) = Mem.store!(mem7, hdr_buf, 6, 82, 1)
		(mem9, _w18) = Mem.store!(mem8, hdr_buf, 7, 84, 1)
		(mem10, _w19) = gpt_write_u32!(mem9, hdr_buf, 8, 65536)
		(mem11, _w20) = gpt_write_u32!(mem10, hdr_buf, 12, 92)
		(mem12, _w21) = gpt_write_u64!(mem11, hdr_buf, 24, 1)
		(mem13, _w22) = gpt_write_u64!(mem12, hdr_buf, 32, (total_sectors - 1))
		(mem14, _w23) = gpt_write_u64!(mem13, hdr_buf, 40, 34)
		(mem15, _w24) = gpt_write_u64!(mem14, hdr_buf, 48, (total_sectors - 34))
		(mem16, _w25) = gpt_write_guid!(mem15, hdr_buf, 56, disk_guid)
		(mem17, _w26) = gpt_write_u64!(mem16, hdr_buf, 72, 2)
		(mem18, _w27) = gpt_write_u32!(mem17, hdr_buf, 80, 128)
		(mem19, _w28) = gpt_write_u32!(mem18, hdr_buf, 84, 128)
		(mem20, _w29) = gpt_write_u32!(mem19, hdr_buf, 88, pe_crc)
		(mem21, hdr_bytes) = gpt_read_buf_bytes!(mem20, hdr_buf, 0, 92, [])
		hdr_crc = gpt_rt_crc32_bytes(hdr_bytes, 92)
		gpt_write_u32!(mem21, hdr_buf, 16, hdr_crc)
	})

	gpt_read_buf_bytes! : Mem.Mem, I64, I64, I64, List(I64) => (Mem.Mem, List(I64))
	gpt_read_buf_bytes! = |mem, buf, off, len, acc| (if (len <= 0) { (mem, acc) } else { ({
		(mem1, mem__296) = Mem.load!(mem, buf, off, 1)
		gpt_read_buf_bytes!(mem1, buf, (off + 1), (len - 1), List.append(acc, mem__296))
	}) })

	gpt_layout_partitions : List(Gpt.GptPartitionSpec), I64, I64, List(Gpt.GptPartEntry) -> List(Gpt.GptPartEntry)
	gpt_layout_partitions = |specs, total_sectors, next_lba, acc| (if (U64.to_i64_wrap(List.len(specs)) == 0) { acc } else { (if (U64.to_i64_wrap(List.len(acc)) >= U64.to_i64_wrap(List.len(specs))) { acc } else { ({
		idx = U64.to_i64_wrap(List.len(acc))
		spec = (List.get(specs, I64.to_u64_wrap(idx)) ?? crash("list-at out of range"))
		backup_start = ((total_sectors - 1) - 32)
		available = (backup_start - next_lba)
		size = (if (spec.gs_size_sectors == 0) { available } else { spec.gs_size_sectors })
		end_lba = ((next_lba + size) - 1)
		part_guid = gpt_make_part_guid(idx)
		entry = { ge_type_guid: spec.gs_type_guid, ge_unique_guid: part_guid, ge_start_lba: next_lba, ge_end_lba: end_lba, ge_name: spec.gs_name }
		gpt_layout_partitions(specs, total_sectors, (end_lba + 1), List.append(acc, entry))
	}) }) })

	gpt_make_part_guid : I64 -> List(I64)
	gpt_make_part_guid = |idx| [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, I64.bitwise_and((idx + 1), 255)]

	gpt_write_entries! : Mem.Mem, List(Gpt.GptPartEntry), I64, I64, I64 => (Mem.Mem, I64)
	gpt_write_entries! = |_, _, _, _, _| crash("`gpt-write-entries` reaches `block-write-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	gpt_esp_type_guid : List(I64)
	gpt_esp_type_guid = [40, 115, 42, 193, 31, 248, 210, 17, 186, 75, 0, 160, 201, 62, 201, 59]

	gpt_basic_data_guid : List(I64)
	gpt_basic_data_guid = [160, 163, 192, 235, 181, 233, 51, 72, 135, 197, 38, 214, 19, 38, 97, 69]

	gpt_codex_facts_guid : List(I64)
	gpt_codex_facts_guid = [17, 26, 222, 192, 199, 250, 13, 76, 158, 117, 192, 222, 192, 222, 94, 237]

	gpt_is_esp : Gpt.GptPartition -> Bool
	gpt_is_esp = |part| gpt_guid_eq(part.gp_type_guid, gpt_esp_type_guid)

	gpt_is_codex_facts : Gpt.GptPartition -> Bool
	gpt_is_codex_facts = |part| gpt_guid_eq(part.gp_type_guid, gpt_codex_facts_guid)

	gpt_guid_eq : List(I64), List(I64) -> Bool
	gpt_guid_eq = |a, b| gpt_guid_eq_loop(a, b, 0)

	gpt_guid_eq_loop : List(I64), List(I64), I64 -> Bool
	gpt_guid_eq_loop = |a, b, i| (if (i >= 16) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { gpt_guid_eq_loop(a, b, (i + 1)) }) })

	gpt_find_by_type : Gpt.GptDisk, List(I64) -> Maybe.Maybe(Gpt.GptPartition)
	gpt_find_by_type = |disk, type_guid| gpt_find_by_type_loop(disk.gd_partitions, type_guid, 0, U64.to_i64_wrap(List.len(disk.gd_partitions)))

	gpt_find_by_type_loop : List(Gpt.GptPartition), List(I64), I64, I64 -> Maybe.Maybe(Gpt.GptPartition)
	gpt_find_by_type_loop = |parts, type_guid, i, len| (if (i >= len) { None } else { ({
		p = (List.get(parts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if gpt_guid_eq(p.gp_type_guid, type_guid) { Just(p) } else { gpt_find_by_type_loop(parts, type_guid, (i + 1), len) })
	}) })

	gpt_wipe_quick! : Mem.Mem, I64 => (Mem.Mem, Bool)
	gpt_wipe_quick! = |_, _| crash("`gpt-wipe-quick` reaches `block-write-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	gpt_wipe_sectors! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	gpt_wipe_sectors! = |_, _, _, _| crash("`gpt-wipe-sectors` reaches `block-write-sector`, a device builtin this program's opening never calls, and the program runs without the machine")
}
