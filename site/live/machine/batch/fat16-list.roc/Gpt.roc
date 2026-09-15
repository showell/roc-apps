# Gpt -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Cce
import Machine
import Maybe

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

	gpt_read_u16! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	gpt_read_u16! = |machine, buf, off| ({
		(machine1, machine__1) = Machine.load!(machine, buf, off, 1)
		(machine2, machine__2) = Machine.load!(machine1, buf, (off + 1), 1)
		(machine2, I64.bitwise_or(machine__1, I64.shl_wrap(machine__2, I64.to_u8_wrap(8))))
	})

	gpt_read_u32! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	gpt_read_u32! = |machine, buf, off| ({
		(machine1, machine__3) = gpt_read_u16!(machine, buf, off)
		(machine2, machine__4) = gpt_read_u16!(machine1, buf, (off + 2))
		(machine2, I64.bitwise_or(machine__3, I64.shl_wrap(machine__4, I64.to_u8_wrap(16))))
	})

	gpt_read_u64! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	gpt_read_u64! = |machine, buf, off| ({
		(machine1, machine__5) = gpt_read_u32!(machine, buf, off)
		(machine2, machine__6) = gpt_read_u32!(machine1, buf, (off + 4))
		(machine2, I64.bitwise_or(machine__5, I64.shl_wrap(machine__6, I64.to_u8_wrap(32))))
	})

	gpt_write_u16! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	gpt_write_u16! = |machine, buf, off, v| ({
		(machine3, machine__7) = ({
		(machine1, _w0) = Machine.store!(machine, buf, off, I64.bitwise_and(v, 255), 1)
		(machine2, _w1) = Machine.store!(machine1, buf, (off + 1), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255), 1)
		(machine2, (off + 2))
	})
		(machine3, machine__7)
	})

	gpt_write_u32! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	gpt_write_u32! = |machine, buf, off, v| ({
		(machine5, machine__8) = ({
		(machine1, _w0) = Machine.store!(machine, buf, off, I64.bitwise_and(v, 255), 1)
		(machine2, _w1) = Machine.store!(machine1, buf, (off + 1), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255), 1)
		(machine3, _w2) = Machine.store!(machine2, buf, (off + 2), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(16)), 255), 1)
		(machine4, _w3) = Machine.store!(machine3, buf, (off + 3), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(24)), 255), 1)
		(machine4, (off + 4))
	})
		(machine5, machine__8)
	})

	gpt_write_u64! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	gpt_write_u64! = |machine, buf, off, v| ({
		(machine1, _w0) = gpt_write_u32!(machine, buf, off, v)
		gpt_write_u32!(machine1, buf, (off + 4), I64.shr_zf_wrap(v, I64.to_u8_wrap(32)))
	})

	gpt_read_guid! : Machine.Machine, I64, I64 => (Machine.Machine, List(I64))
	gpt_read_guid! = |machine, buf, off| gpt_read_guid_loop!(machine, buf, off, 0, [])

	gpt_read_guid_loop! : Machine.Machine, I64, I64, I64, List(I64) => (Machine.Machine, List(I64))
	gpt_read_guid_loop! = |machine, buf, off, i, acc| (if (i >= 16) { (machine, acc) } else { ({
		(machine1, machine__9) = Machine.load!(machine, buf, (off + i), 1)
		gpt_read_guid_loop!(machine1, buf, off, (i + 1), List.append(acc, machine__9))
	}) })

	gpt_write_guid! : Machine.Machine, I64, I64, List(I64) => (Machine.Machine, I64)
	gpt_write_guid! = |machine, buf, off, guid| gpt_write_guid_loop!(machine, buf, off, guid, 0)

	gpt_write_guid_loop! : Machine.Machine, I64, I64, List(I64), I64 => (Machine.Machine, I64)
	gpt_write_guid_loop! = |machine, buf, off, guid, i| (if (i >= 16) { (machine, (off + 16)) } else { ({
		(machine1, _w) = Machine.store!(machine, buf, (off + i), (List.get(guid, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), 1)
		gpt_write_guid_loop!(machine1, buf, off, guid, (i + 1))
	}) })

	gpt_guid_is_zero : List(I64) -> Bool
	gpt_guid_is_zero = |guid| gpt_guid_zero_loop(guid, 0)

	gpt_guid_zero_loop : List(I64), I64 -> Bool
	gpt_guid_zero_loop = |guid, i| (if (i >= 16) { True } else { (if ((List.get(guid, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != 0) { False } else { gpt_guid_zero_loop(guid, (i + 1)) }) })

	gpt_read_name! : Machine.Machine, I64, I64 => (Machine.Machine, Str)
	gpt_read_name! = |machine, buf, off| gpt_read_name_loop!(machine, buf, off, 0, 36, "")

	gpt_read_name_loop! : Machine.Machine, I64, I64, I64, I64, Str => (Machine.Machine, Str)
	gpt_read_name_loop! = |machine, buf, off, i, max_chars, acc| (if (i >= max_chars) { (machine, acc) } else { ({
		(machine1, lo) = Machine.load!(machine, buf, (off + (i * 2)), 1)
		(machine2, hi) = Machine.load!(machine1, buf, ((off + (i * 2)) + 1), 1)
		code = I64.bitwise_or(lo, I64.shl_wrap(hi, I64.to_u8_wrap(8)))
		(if (code == 0) { (machine2, acc) } else { gpt_read_name_loop!(machine2, buf, off, (i + 1), max_chars, Str.concat(acc, Cce.text(code))) })
	}) })

	gpt_check_signature! : Machine.Machine, I64 => (Machine.Machine, Bool)
	gpt_check_signature! = |machine, buf| ({
		(machine1, machine__10) = Machine.load!(machine, buf, 0, 1)
		(machine3, machine__12) = (if (machine__10 == gpt_sig_0) { ({
		(machine2, machine__11) = Machine.load!(machine1, buf, 1, 1)
		(machine2, (machine__11 == gpt_sig_1))
	}) } else { (machine1, False) })
		(machine5, machine__14) = (if machine__12 { ({
		(machine4, machine__13) = Machine.load!(machine3, buf, 2, 1)
		(machine4, (machine__13 == gpt_sig_2))
	}) } else { (machine3, False) })
		(machine7, machine__16) = (if machine__14 { ({
		(machine6, machine__15) = Machine.load!(machine5, buf, 3, 1)
		(machine6, (machine__15 == gpt_sig_3))
	}) } else { (machine5, False) })
		(machine9, machine__18) = (if machine__16 { ({
		(machine8, machine__17) = Machine.load!(machine7, buf, 4, 1)
		(machine8, (machine__17 == gpt_sig_4))
	}) } else { (machine7, False) })
		(machine11, machine__20) = (if machine__18 { ({
		(machine10, machine__19) = Machine.load!(machine9, buf, 5, 1)
		(machine10, (machine__19 == gpt_sig_5))
	}) } else { (machine9, False) })
		(machine13, machine__22) = (if machine__20 { ({
		(machine12, machine__21) = Machine.load!(machine11, buf, 6, 1)
		(machine12, (machine__21 == gpt_sig_6))
	}) } else { (machine11, False) })
		(machine15, machine__24) = (if machine__22 { ({
		(machine14, machine__23) = Machine.load!(machine13, buf, 7, 1)
		(machine14, (machine__23 == gpt_sig_7))
	}) } else { (machine13, False) })
		(machine15, machine__24)
	})

	gpt_parse_entry! : Machine.Machine, I64, I64 => (Machine.Machine, Gpt.GptPartition)
	gpt_parse_entry! = |machine, buf, off| ({
		(machine1, machine__25) = gpt_read_guid!(machine, buf, off)
		(machine2, machine__26) = gpt_read_guid!(machine1, buf, (off + 16))
		(machine3, machine__27) = gpt_read_u64!(machine2, buf, (off + 32))
		(machine4, machine__28) = gpt_read_u64!(machine3, buf, (off + 40))
		(machine5, machine__29) = gpt_read_u64!(machine4, buf, (off + 48))
		(machine6, machine__30) = gpt_read_name!(machine5, buf, (off + 56))
		(machine6, { gp_type_guid: machine__25, gp_unique_guid: machine__26, gp_start_lba: machine__27, gp_end_lba: machine__28, gp_attributes: machine__29, gp_name: machine__30 })
	})

	gpt_read_entries! : Machine.Machine, I64, I64, I64, I64, List(Gpt.GptPartition) => (Machine.Machine, List(Gpt.GptPartition))
	gpt_read_entries! = |machine, start_lba, entry_size, count, i, acc| (if (i >= count) { (machine, acc) } else { ({
		(machine1, buf) = Machine.block_read_sector!(machine, (start_lba + I64.div_trunc_by(i, I64.div_trunc_by(512, entry_size))))
		gpt_read_entries_step!(machine1, start_lba, entry_size, count, i, acc, buf)
	}) })

	gpt_read_entries_step! : Machine.Machine, I64, I64, I64, I64, List(Gpt.GptPartition), I64 => (Machine.Machine, List(Gpt.GptPartition))
	gpt_read_entries_step! = |machine, start_lba, entry_size, count, i, acc, buf| ({
		entries_per_sector = I64.div_trunc_by(512, entry_size)
		off_in_sector = ((i - (I64.div_trunc_by(i, entries_per_sector) * entries_per_sector)) * entry_size)
		(machine1, entry) = gpt_parse_entry!(machine, buf, off_in_sector)
		(if gpt_guid_is_zero(entry.gp_type_guid) { (machine1, acc) } else { gpt_read_entries!(machine1, start_lba, entry_size, count, (i + 1), List.append(acc, entry)) })
	})

	gpt_check_mbr! : Machine.Machine, I64 => (Machine.Machine, Bool)
	gpt_check_mbr! = |machine, buf| ({
		(machine1, machine__31) = Machine.load!(machine, buf, 510, 1)
		(machine3, machine__33) = (if (machine__31 == 85) { ({
		(machine2, machine__32) = Machine.load!(machine1, buf, 511, 1)
		(machine2, (machine__32 == 170))
	}) } else { (machine1, False) })
		(machine3, machine__33)
	})

	gpt_read! : Machine.Machine => (Machine.Machine, Maybe.Maybe(Gpt.GptDisk))
	gpt_read! = |machine| ({
		(machine1, mbr_buf) = Machine.block_read_sector!(machine, 0)
		gpt_read_after_mbr!(machine1, mbr_buf)
	})

	gpt_read_after_mbr! : Machine.Machine, I64 => (Machine.Machine, Maybe.Maybe(Gpt.GptDisk))
	gpt_read_after_mbr! = |machine, mbr_buf| ({
		(machine1, machine__34) = gpt_check_mbr!(machine, mbr_buf)
		(if (machine__34 == False) { (machine1, None) } else { ({
		(machine2, hdr_buf) = Machine.block_read_sector!(machine1, 1)
		gpt_read_after_hdr!(machine2, hdr_buf)
	}) })
	})

	gpt_header_geom_ok! : Machine.Machine, I64 => (Machine.Machine, Bool)
	gpt_header_geom_ok! = |machine, buf| ({
		(machine5, machine__35) = ({
		(machine1, lba) = gpt_read_u64!(machine, buf, 72)
		(machine2, cnt) = gpt_read_u32!(machine1, buf, 80)
		(machine3, sz) = gpt_read_u32!(machine2, buf, 84)
		(machine4, first_usable) = gpt_read_u64!(machine3, buf, 40)
		(machine4, (((((((lba >= 2) and (cnt >= 1)) and (cnt <= 1024)) and (sz >= 128)) and (sz <= 512)) and ((sz - (I64.div_trunc_by(sz, 128) * 128)) == 0)) and ((lba + I64.div_trunc_by(((cnt * sz) + 511), 512)) <= first_usable)))
	})
		(machine5, machine__35)
	})

	gpt_read_after_hdr! : Machine.Machine, I64 => (Machine.Machine, Maybe.Maybe(Gpt.GptDisk))
	gpt_read_after_hdr! = |machine, hdr_buf| ({
		(machine1, machine__36) = gpt_check_signature!(machine, hdr_buf)
		(if (machine__36 == False) { (machine1, None) } else { ({
		(machine2, machine__37) = gpt_header_geom_ok!(machine1, hdr_buf)
		(if (machine__37 == False) { (machine2, None) } else { ({
		(machine3, entry_size) = gpt_read_u32!(machine2, hdr_buf, 84)
		(machine4, disk_guid) = gpt_read_guid!(machine3, hdr_buf, 56)
		(machine5, machine__38) = gpt_read_u64!(machine4, hdr_buf, 32)
		total_sectors = (machine__38 + 1)
		({
			(machine8, parts) = ({
				(machine6, machine__39) = gpt_read_u64!(machine5, hdr_buf, 72)
				(machine7, machine__40) = gpt_read_u32!(machine6, hdr_buf, 80)
				gpt_read_entries!(machine7, machine__39, entry_size, machine__40, 0, [])
			})
			(machine8, gpt_make_disk(disk_guid, total_sectors, parts))
		})
	}) })
	}) })
	})

	gpt_make_disk : List(I64), I64, List(Gpt.GptPartition) -> Maybe.Maybe(Gpt.GptDisk)
	gpt_make_disk = |disk_guid, total_sectors, parts| Just({ gd_disk_guid: disk_guid, gd_partition_count: U64.to_i64_wrap(List.len(parts)), gd_partitions: parts, gd_total_sectors: total_sectors })

	gpt_read_partition! : Machine.Machine, I64 => (Machine.Machine, Maybe.Maybe(Gpt.GptPartition))
	gpt_read_partition! = |machine, index| ({
		(machine1, machine__41) = gpt_read!(machine)
		(machine1, (match machine__41 {
		Just(disk) => (if (index >= disk.gd_partition_count) { None } else { Just((List.get(disk.gd_partitions, I64.to_u64_wrap(index)) ?? crash("list-at out of range"))) })
		None => None
	}))
	})

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

	gpt_rt_crc32_sector! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	gpt_rt_crc32_sector! = |machine, start_lba, sector_count, byte_len| gpt_rt_crc32_sectors_loop!(machine, start_lba, sector_count, byte_len, 4294967295, 0)

	gpt_rt_crc32_sectors_loop! : Machine.Machine, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	gpt_rt_crc32_sectors_loop! = |machine, lba, remaining, byte_len, crc, bytes_done| (if (remaining <= 0) { (machine, I64.bitwise_xor(crc, 4294967295)) } else { (if (bytes_done >= byte_len) { (machine, I64.bitwise_xor(crc, 4294967295)) } else { ({
		(machine1, buf) = Machine.block_read_sector!(machine, lba)
		gpt_rt_crc32_sectors_step!(machine1, lba, remaining, byte_len, crc, bytes_done, buf)
	}) }) })

	gpt_rt_crc32_sectors_step! : Machine.Machine, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	gpt_rt_crc32_sectors_step! = |machine, lba, remaining, byte_len, crc, bytes_done, buf| ({
		this_bytes = (if ((byte_len - bytes_done) < 512) { (byte_len - bytes_done) } else { 512 })
		(machine1, new_crc) = gpt_rt_crc32_buf_loop!(machine, buf, crc, 0, this_bytes)
		gpt_rt_crc32_sectors_loop!(machine1, (lba + 1), (remaining - 1), byte_len, new_crc, (bytes_done + this_bytes))
	})

	gpt_rt_crc32_buf_loop! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	gpt_rt_crc32_buf_loop! = |machine, buf, crc, i, len| (if (i >= len) { (machine, crc) } else { ({
		(machine1, b) = Machine.load!(machine, buf, i, 1)
		idx = I64.bitwise_and(I64.bitwise_xor(crc, b), 255)
		gpt_rt_crc32_buf_loop!(machine1, buf, I64.bitwise_xor(I64.shr_zf_wrap(crc, I64.to_u8_wrap(8)), (List.get(gpt_rt_crc32_table, I64.to_u64_wrap(idx)) ?? crash("list-at out of range"))), (i + 1), len)
	}) })

	gpt_done : I64 -> Bool
	gpt_done = |_w| True

	gpt_write_name_utf16! : Machine.Machine, I64, I64, Str, I64 => (Machine.Machine, I64)
	gpt_write_name_utf16! = |machine, buf, off, name, i| (if (i >= Cce.length(name)) { (machine, (off + (Cce.length(name) * 2))) } else { ({
		c = Cce.at_or_crash(name, i)
		(machine1, _w0) = Machine.store!(machine, buf, (off + (i * 2)), I64.bitwise_and(c, 255), 1)
		(machine2, _w1) = Machine.store!(machine1, buf, ((off + (i * 2)) + 1), I64.bitwise_and(I64.shr_zf_wrap(c, I64.to_u8_wrap(8)), 255), 1)
		gpt_write_name_utf16!(machine2, buf, off, name, (i + 1))
	}) })

	gpt_zero_sector! : Machine.Machine, I64 => (Machine.Machine, I64)
	gpt_zero_sector! = |machine, buf| gpt_zero_loop!(machine, buf, 0)

	gpt_zero_loop! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	gpt_zero_loop! = |machine, buf, i| (if (i >= 512) { (machine, 0) } else { ({
		(machine1, _w) = Machine.store!(machine, buf, i, 0, 1)
		gpt_zero_loop!(machine1, buf, (i + 1))
	}) })

	gpt_write_table! : Machine.Machine, List(Gpt.GptPartitionSpec), I64, List(I64) => (Machine.Machine, Bool)
	gpt_write_table! = |machine, specs, total_sectors, disk_guid| ({
		(machine1, entry_buf) = Machine.alloc(machine, 512)
		(machine2, hdr_buf) = Machine.alloc(machine1, 512)
		(machine3, mbr_buf) = Machine.alloc(machine2, 512)
		(machine4, _m) = gpt_build_protective_mbr!(machine3, mbr_buf, total_sectors)
		({
			(machine5, _) = Machine.block_write_sector!(machine4, 0, mbr_buf)
			(machine6, pe_crc) = gpt_write_entries!(machine5, gpt_layout_partitions(specs, total_sectors, 2048, []), entry_buf, 2, 0)
			(machine7, _) = gpt_build_header!(machine6, hdr_buf, total_sectors, disk_guid, pe_crc)
			({
				(machine8, machine__42) = Machine.block_write_sector!(machine7, 1, hdr_buf)
				(machine8, gpt_done(machine__42))
			})
		})
	})

	gpt_build_protective_mbr! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	gpt_build_protective_mbr! = |machine, mbr_buf, total_sectors| ({
		(machine1, _z0) = gpt_zero_sector!(machine, mbr_buf)
		(machine2, _w0) = Machine.store!(machine1, mbr_buf, 446, 0, 1)
		(machine3, _w1) = Machine.store!(machine2, mbr_buf, 449, 2, 1)
		(machine4, _w2) = Machine.store!(machine3, mbr_buf, 450, 238, 1)
		(machine5, _w3) = Machine.store!(machine4, mbr_buf, 451, 255, 1)
		(machine6, _w4) = Machine.store!(machine5, mbr_buf, 452, 255, 1)
		(machine7, _w5) = Machine.store!(machine6, mbr_buf, 453, 255, 1)
		mbr_sec = (if ((total_sectors - 1) > 4294967295) { 4294967295 } else { (total_sectors - 1) })
		(machine8, _w6) = gpt_write_u32!(machine7, mbr_buf, 454, 1)
		(machine9, _w7) = gpt_write_u32!(machine8, mbr_buf, 458, mbr_sec)
		(machine10, _w8) = Machine.store!(machine9, mbr_buf, 510, 85, 1)
		Machine.store!(machine10, mbr_buf, 511, 170, 1)
	})

	gpt_build_header! : Machine.Machine, I64, I64, List(I64), I64 => (Machine.Machine, I64)
	gpt_build_header! = |machine, hdr_buf, total_sectors, disk_guid, pe_crc| ({
		(machine1, _z1) = gpt_zero_sector!(machine, hdr_buf)
		(machine2, _w11) = Machine.store!(machine1, hdr_buf, 0, 69, 1)
		(machine3, _w12) = Machine.store!(machine2, hdr_buf, 1, 70, 1)
		(machine4, _w13) = Machine.store!(machine3, hdr_buf, 2, 73, 1)
		(machine5, _w14) = Machine.store!(machine4, hdr_buf, 3, 32, 1)
		(machine6, _w15) = Machine.store!(machine5, hdr_buf, 4, 80, 1)
		(machine7, _w16) = Machine.store!(machine6, hdr_buf, 5, 65, 1)
		(machine8, _w17) = Machine.store!(machine7, hdr_buf, 6, 82, 1)
		(machine9, _w18) = Machine.store!(machine8, hdr_buf, 7, 84, 1)
		(machine10, _w19) = gpt_write_u32!(machine9, hdr_buf, 8, 65536)
		(machine11, _w20) = gpt_write_u32!(machine10, hdr_buf, 12, 92)
		(machine12, _w21) = gpt_write_u64!(machine11, hdr_buf, 24, 1)
		(machine13, _w22) = gpt_write_u64!(machine12, hdr_buf, 32, (total_sectors - 1))
		(machine14, _w23) = gpt_write_u64!(machine13, hdr_buf, 40, 34)
		(machine15, _w24) = gpt_write_u64!(machine14, hdr_buf, 48, (total_sectors - 34))
		(machine16, _w25) = gpt_write_guid!(machine15, hdr_buf, 56, disk_guid)
		(machine17, _w26) = gpt_write_u64!(machine16, hdr_buf, 72, 2)
		(machine18, _w27) = gpt_write_u32!(machine17, hdr_buf, 80, 128)
		(machine19, _w28) = gpt_write_u32!(machine18, hdr_buf, 84, 128)
		(machine20, _w29) = gpt_write_u32!(machine19, hdr_buf, 88, pe_crc)
		(machine21, hdr_bytes) = gpt_read_buf_bytes!(machine20, hdr_buf, 0, 92, [])
		hdr_crc = gpt_rt_crc32_bytes(hdr_bytes, 92)
		gpt_write_u32!(machine21, hdr_buf, 16, hdr_crc)
	})

	gpt_read_buf_bytes! : Machine.Machine, I64, I64, I64, List(I64) => (Machine.Machine, List(I64))
	gpt_read_buf_bytes! = |machine, buf, off, len, acc| (if (len <= 0) { (machine, acc) } else { ({
		(machine1, machine__43) = Machine.load!(machine, buf, off, 1)
		gpt_read_buf_bytes!(machine1, buf, (off + 1), (len - 1), List.append(acc, machine__43))
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

	gpt_write_entries! : Machine.Machine, List(Gpt.GptPartEntry), I64, I64, I64 => (Machine.Machine, I64)
	gpt_write_entries! = |machine, parts, buf, start_lba, i| ({
		entries_per_sector = I64.div_trunc_by(512, 128)
		slot = (i - (I64.div_trunc_by(i, entries_per_sector) * entries_per_sector))
		sector = (start_lba + I64.div_trunc_by(i, entries_per_sector))
		(if (i >= 128) { gpt_rt_crc32_sector!(machine, start_lba, 32, (32 * 512)) } else { (if (i >= U64.to_i64_wrap(List.len(parts))) { (if (slot != 0) { ({
			(machine1, _) = Machine.block_write_sector!(machine, sector, buf)
			gpt_write_entries!(machine1, parts, buf, start_lba, (i + (entries_per_sector - slot)))
		}) } else { ({
			(machine2, _z) = gpt_zero_sector!(machine, buf)
			({
				(machine3, _) = Machine.block_write_sector!(machine2, sector, buf)
				gpt_write_entries!(machine3, parts, buf, start_lba, (i + entries_per_sector))
			})
		}) }) } else { ({
			part = (List.get(parts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
			off = (slot * 128)
			(machine4, _z) = (if (off == 0) { gpt_zero_sector!(machine, buf) } else { (machine, 0) })
			(machine5, _w0) = gpt_write_guid!(machine4, buf, off, part.ge_type_guid)
			(machine6, _w1) = gpt_write_guid!(machine5, buf, (off + 16), part.ge_unique_guid)
			(machine7, _w2) = gpt_write_u64!(machine6, buf, (off + 32), part.ge_start_lba)
			(machine8, _w3) = gpt_write_u64!(machine7, buf, (off + 40), part.ge_end_lba)
			(machine9, _w4) = gpt_write_name_utf16!(machine8, buf, (off + 56), part.ge_name, 0)
			(if ((off + 128) >= 512) { ({
				(machine10, _) = Machine.block_write_sector!(machine9, sector, buf)
				gpt_write_entries!(machine10, parts, buf, start_lba, (i + 1))
			}) } else { gpt_write_entries!(machine9, parts, buf, start_lba, (i + 1)) })
		}) }) })
	})

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

	gpt_wipe_quick! : Machine.Machine, I64 => (Machine.Machine, Bool)
	gpt_wipe_quick! = |machine, total_sectors| ({
		(machine1, buf) = Machine.alloc(machine, 512)
		(machine2, _z) = gpt_zero_sector!(machine1, buf)
		({
			(machine3, _) = gpt_wipe_sectors!(machine2, buf, 0, 2048)
			({
				(machine4, machine__44) = gpt_wipe_sectors!(machine3, buf, (total_sectors - 34), 34)
				(machine4, gpt_done(machine__44))
			})
		})
	})

	gpt_wipe_sectors! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	gpt_wipe_sectors! = |machine, buf, start, count| (if (count <= 0) { (machine, 0) } else { ({
		(machine1, _) = Machine.block_write_sector!(machine, start, buf)
		gpt_wipe_sectors!(machine1, buf, (start + 1), (count - 1))
	}) })
}
