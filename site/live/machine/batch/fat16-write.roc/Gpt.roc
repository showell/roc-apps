# Gpt -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceChar
import CceText
import Machine
import Maybe

Gpt :: [].{
	GptPartition := { gp_type_guid : List(I64), gp_unique_guid : List(I64), gp_start_lba : I64, gp_end_lba : I64, gp_attributes : I64, gp_name : CceText }.{
		is_eq : Gpt.GptPartition, Gpt.GptPartition -> Bool
		is_eq = |a, b| eq_GptPartition(a, b)
	}
	GptDisk := { gd_disk_guid : List(I64), gd_partition_count : I64, gd_partitions : List(Gpt.GptPartition), gd_total_sectors : I64 }.{
		is_eq : Gpt.GptDisk, Gpt.GptDisk -> Bool
		is_eq = |a, b| eq_GptDisk(a, b)
	}
	GptPartitionSpec := { gs_type_guid : List(I64), gs_name : CceText, gs_size_sectors : I64 }.{
		is_eq : Gpt.GptPartitionSpec, Gpt.GptPartitionSpec -> Bool
		is_eq = |a, b| eq_GptPartitionSpec(a, b)
	}
	GptPartEntry := { ge_type_guid : List(I64), ge_unique_guid : List(I64), ge_start_lba : I64, ge_end_lba : I64, ge_name : CceText }.{
		is_eq : Gpt.GptPartEntry, Gpt.GptPartEntry -> Bool
		is_eq = |a, b| eq_GptPartEntry(a, b)
	}

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

	gpt_lba_ceiling : I64
	gpt_lba_ceiling = 281474976710656

	gpt_lba_ok : I64 -> Bool
	gpt_lba_ok = |v| (if (v < 0) { False } else { (v < gpt_lba_ceiling) })

	gpt_read_u16! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	gpt_read_u16! = |machine, buf, off| ({
		(machine1, machine__1) = Machine.load!(machine, buf, off, 1)
		(machine2, machine__2) = Machine.load!(machine1, buf, (off + 1), 1)
		(machine2, I64.bitwise_or(machine__1, I64.shl_wrap(machine__2, I64.to_u8_wrap(8))))
	})

	gpt_read_u32! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	gpt_read_u32! = |machine, buf, off| ({
		(machine1, machine__1) = gpt_read_u16!(machine, buf, off)
		(machine2, machine__2) = gpt_read_u16!(machine1, buf, (off + 2))
		(machine2, I64.bitwise_or(machine__1, I64.shl_wrap(machine__2, I64.to_u8_wrap(16))))
	})

	gpt_read_u64! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	gpt_read_u64! = |machine, buf, off| ({
		(machine1, machine__1) = gpt_read_u32!(machine, buf, off)
		(machine2, machine__2) = gpt_read_u32!(machine1, buf, (off + 4))
		(machine2, I64.bitwise_or(machine__1, I64.shl_wrap(machine__2, I64.to_u8_wrap(32))))
	})

	gpt_read_guid! : Machine.Machine, I64, I64 => (Machine.Machine, List(I64))
	gpt_read_guid! = |machine, buf, off| gpt_read_guid_loop!(machine, buf, off, 0, [])

	gpt_read_guid_loop! : Machine.Machine, I64, I64, I64, List(I64) => (Machine.Machine, List(I64))
	gpt_read_guid_loop! = |machine, buf, off, i, acc| (if (i >= 16) { (machine, acc) } else { ({
		(machine1, machine__1) = Machine.load!(machine, buf, (off + i), 1)
		gpt_read_guid_loop!(machine1, buf, off, (i + 1), List.append(acc, machine__1))
	}) })

	gpt_guid_is_zero : List(I64) -> Bool
	gpt_guid_is_zero = |guid| gpt_guid_zero_loop(guid, 0)

	gpt_guid_zero_loop : List(I64), I64 -> Bool
	gpt_guid_zero_loop = |guid, i| (if (i >= 16) { True } else { (if ((List.get(guid, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != 0) { False } else { gpt_guid_zero_loop(guid, (i + 1)) }) })

	gpt_read_name! : Machine.Machine, I64, I64 => (Machine.Machine, CceText)
	gpt_read_name! = |machine, buf, off| gpt_read_name_loop!(machine, buf, off, 0, 36, "")

	gpt_read_name_loop! : Machine.Machine, I64, I64, I64, I64, CceText => (Machine.Machine, CceText)
	gpt_read_name_loop! = |machine, buf, off, i, max_chars, acc| (if (i >= max_chars) { (machine, acc) } else { ({
		(machine1, lo) = Machine.load!(machine, buf, (off + (i * 2)), 1)
		(machine2, hi) = Machine.load!(machine1, buf, ((off + (i * 2)) + 1), 1)
		code : I64
		code = I64.bitwise_or(lo, I64.shl_wrap(hi, I64.to_u8_wrap(8)))
		(if (code == 0) { (machine2, acc) } else { gpt_read_name_loop!(machine2, buf, off, (i + 1), max_chars, CceText.concat(acc, CceText.char_to_text(CceChar.of_code(code)))) })
	}) })

	gpt_check_signature! : Machine.Machine, I64 => (Machine.Machine, Bool)
	gpt_check_signature! = |machine, buf| ({
		(machine1, machine__1) = Machine.load!(machine, buf, 0, 1)
		(machine3, machine__3) = (if (machine__1 == gpt_sig_0) { ({
		(machine2, machine__2) = Machine.load!(machine1, buf, 1, 1)
		(machine2, (machine__2 == gpt_sig_1))
	}) } else { (machine1, False) })
		(machine5, machine__5) = (if machine__3 { ({
		(machine4, machine__4) = Machine.load!(machine3, buf, 2, 1)
		(machine4, (machine__4 == gpt_sig_2))
	}) } else { (machine3, False) })
		(machine7, machine__7) = (if machine__5 { ({
		(machine6, machine__6) = Machine.load!(machine5, buf, 3, 1)
		(machine6, (machine__6 == gpt_sig_3))
	}) } else { (machine5, False) })
		(machine9, machine__9) = (if machine__7 { ({
		(machine8, machine__8) = Machine.load!(machine7, buf, 4, 1)
		(machine8, (machine__8 == gpt_sig_4))
	}) } else { (machine7, False) })
		(machine11, machine__11) = (if machine__9 { ({
		(machine10, machine__10) = Machine.load!(machine9, buf, 5, 1)
		(machine10, (machine__10 == gpt_sig_5))
	}) } else { (machine9, False) })
		(machine13, machine__13) = (if machine__11 { ({
		(machine12, machine__12) = Machine.load!(machine11, buf, 6, 1)
		(machine12, (machine__12 == gpt_sig_6))
	}) } else { (machine11, False) })
		(machine15, machine__15) = (if machine__13 { ({
		(machine14, machine__14) = Machine.load!(machine13, buf, 7, 1)
		(machine14, (machine__14 == gpt_sig_7))
	}) } else { (machine13, False) })
		(machine15, machine__15)
	})

	gpt_parse_entry! : Machine.Machine, I64, I64 => (Machine.Machine, Gpt.GptPartition)
	gpt_parse_entry! = |machine, buf, off| ({
		(machine1, machine__1) = gpt_read_guid!(machine, buf, off)
		(machine2, machine__2) = gpt_read_guid!(machine1, buf, (off + 16))
		(machine3, machine__3) = gpt_read_u64!(machine2, buf, (off + 32))
		(machine4, machine__4) = gpt_read_u64!(machine3, buf, (off + 40))
		(machine5, machine__5) = gpt_read_u64!(machine4, buf, (off + 48))
		(machine6, machine__6) = gpt_read_name!(machine5, buf, (off + 56))
		(machine6, Gpt.GptPartition.{ gp_type_guid: machine__1, gp_unique_guid: machine__2, gp_start_lba: machine__3, gp_end_lba: machine__4, gp_attributes: machine__5, gp_name: machine__6 })
	})

	gpt_read_entries! : Machine.Machine, I64, I64, I64, I64, List(Gpt.GptPartition) => (Machine.Machine, List(Gpt.GptPartition))
	gpt_read_entries! = |machine, start_lba, entry_size, count, i, acc| (if (i >= count) { (machine, acc) } else { ({
		(machine1, buf) = Machine.block_read_sector!(machine, (start_lba + I64.div_trunc_by(i, I64.div_trunc_by(512, entry_size))))
		gpt_read_entries_step!(machine1, start_lba, entry_size, count, i, acc, buf)
	}) })

	gpt_read_entries_step! : Machine.Machine, I64, I64, I64, I64, List(Gpt.GptPartition), I64 => (Machine.Machine, List(Gpt.GptPartition))
	gpt_read_entries_step! = |machine, start_lba, entry_size, count, i, acc, buf| ({
		entries_per_sector : I64
		entries_per_sector = I64.div_trunc_by(512, entry_size)
		off_in_sector : I64
		off_in_sector = ((i - (I64.div_trunc_by(i, entries_per_sector) * entries_per_sector)) * entry_size)
		(machine1, entry) = gpt_parse_entry!(machine, buf, off_in_sector)
		(if gpt_guid_is_zero(entry.gp_type_guid) { (machine1, acc) } else { gpt_read_entries!(machine1, start_lba, entry_size, count, (i + 1), List.append(acc, entry)) })
	})

	gpt_check_mbr! : Machine.Machine, I64 => (Machine.Machine, Bool)
	gpt_check_mbr! = |machine, buf| ({
		(machine1, machine__1) = Machine.load!(machine, buf, 510, 1)
		(machine3, machine__3) = (if (machine__1 == 85) { ({
		(machine2, machine__2) = Machine.load!(machine1, buf, 511, 1)
		(machine2, (machine__2 == 170))
	}) } else { (machine1, False) })
		(machine3, machine__3)
	})

	gpt_read! : Machine.Machine => (Machine.Machine, Maybe.Maybe(Gpt.GptDisk))
	gpt_read! = |machine| ({
		(machine1, mbr_buf) = Machine.block_read_sector!(machine, 0)
		gpt_read_after_mbr!(machine1, mbr_buf)
	})

	gpt_read_after_mbr! : Machine.Machine, I64 => (Machine.Machine, Maybe.Maybe(Gpt.GptDisk))
	gpt_read_after_mbr! = |machine, mbr_buf| ({
		(machine1, machine__1) = gpt_check_mbr!(machine, mbr_buf)
		(if (machine__1 == False) { (machine1, None) } else { ({
		(machine2, hdr_buf) = Machine.block_read_sector!(machine1, 1)
		gpt_read_after_hdr!(machine2, hdr_buf)
	}) })
	})

	gpt_header_geom_ok! : Machine.Machine, I64 => (Machine.Machine, Bool)
	gpt_header_geom_ok! = |machine, buf| ({
		(machine8, machine__4) = ({
		(machine1, lba) = gpt_read_u64!(machine, buf, 72)
		(machine2, cnt) = gpt_read_u32!(machine1, buf, 80)
		(machine3, sz) = gpt_read_u32!(machine2, buf, 84)
		(machine4, first_usable) = gpt_read_u64!(machine3, buf, 40)
		({
			(machine7, machine__3) = (if (lba < 2) { (machine4, False) } else { ({
			(machine6, machine__2) = (if (gpt_lba_ok(first_usable) == False) { (machine4, False) } else { ({
			(machine5, machine__1) = gpt_read_u64!(machine4, buf, 32)
			(machine5, (if (gpt_lba_ok(machine__1) == False) { False } else { (if ((cnt < 1) or (cnt > 1024)) { False } else { (if ((sz < 128) or (sz > 512)) { False } else { (if ((sz - (I64.div_trunc_by(sz, 128) * 128)) != 0) { False } else { (if (first_usable < lba) { False } else { (I64.div_trunc_by(((cnt * sz) + 511), 512) <= (first_usable - lba)) }) }) }) }) }))
		}) })
			(machine6, machine__2)
		}) })
			(machine7, machine__3)
		})
	})
		(machine8, machine__4)
	})

	gpt_parts_ok : List(Gpt.GptPartition), I64 -> Bool
	gpt_parts_ok = |parts, i| (if (i >= U64.to_i64_wrap(List.len(parts))) { True } else { ({
		p = (List.get(parts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (gpt_lba_ok(p.gp_start_lba) == False) { False } else { (if (gpt_lba_ok(p.gp_end_lba) == False) { False } else { (if (p.gp_end_lba < p.gp_start_lba) { False } else { gpt_parts_ok(parts, (i + 1)) }) }) })
	}) })

	gpt_read_after_hdr! : Machine.Machine, I64 => (Machine.Machine, Maybe.Maybe(Gpt.GptDisk))
	gpt_read_after_hdr! = |machine, hdr_buf| ({
		(machine1, machine__1) = gpt_check_signature!(machine, hdr_buf)
		(if (machine__1 == False) { (machine1, None) } else { ({
		(machine2, machine__2) = gpt_header_geom_ok!(machine1, hdr_buf)
		(if (machine__2 == False) { (machine2, None) } else { ({
		(machine3, entry_size) = gpt_read_u32!(machine2, hdr_buf, 84)
		(machine4, disk_guid) = gpt_read_guid!(machine3, hdr_buf, 56)
		(machine5, machine__3) = gpt_read_u64!(machine4, hdr_buf, 32)
		total_sectors : I64
		total_sectors = (machine__3 + 1)
		({
			(machine8, parts) = ({
				(machine6, machine__4) = gpt_read_u64!(machine5, hdr_buf, 72)
				(machine7, machine__5) = gpt_read_u32!(machine6, hdr_buf, 80)
				gpt_read_entries!(machine7, machine__4, entry_size, machine__5, 0, [])
			})
			(machine8, (if gpt_parts_ok(parts, 0) { gpt_make_disk(disk_guid, total_sectors, parts) } else { None }))
		})
	}) })
	}) })
	})

	gpt_make_disk : List(I64), I64, List(Gpt.GptPartition) -> Maybe.Maybe(Gpt.GptDisk)
	gpt_make_disk = |disk_guid, total_sectors, parts| Just(Gpt.GptDisk.{ gd_disk_guid: disk_guid, gd_partition_count: U64.to_i64_wrap(List.len(parts)), gd_partitions: parts, gd_total_sectors: total_sectors })

	eq_GptPartition : Gpt.GptPartition, Gpt.GptPartition -> Bool
	eq_GptPartition = |ex, ey| ((((((ex.gp_type_guid == ey.gp_type_guid) and (ex.gp_unique_guid == ey.gp_unique_guid)) and (ex.gp_start_lba == ey.gp_start_lba)) and (ex.gp_end_lba == ey.gp_end_lba)) and (ex.gp_attributes == ey.gp_attributes)) and (ex.gp_name == ey.gp_name))

	eq_GptDisk : Gpt.GptDisk, Gpt.GptDisk -> Bool
	eq_GptDisk = |ex, ey| ((((ex.gd_disk_guid == ey.gd_disk_guid) and (ex.gd_partition_count == ey.gd_partition_count)) and (ex.gd_partitions == ey.gd_partitions)) and (ex.gd_total_sectors == ey.gd_total_sectors))

	eq_GptPartitionSpec : Gpt.GptPartitionSpec, Gpt.GptPartitionSpec -> Bool
	eq_GptPartitionSpec = |ex, ey| (((ex.gs_type_guid == ey.gs_type_guid) and (ex.gs_name == ey.gs_name)) and (ex.gs_size_sectors == ey.gs_size_sectors))

	eq_GptPartEntry : Gpt.GptPartEntry, Gpt.GptPartEntry -> Bool
	eq_GptPartEntry = |ex, ey| (((((ex.ge_type_guid == ey.ge_type_guid) and (ex.ge_unique_guid == ey.ge_unique_guid)) and (ex.ge_start_lba == ey.ge_start_lba)) and (ex.ge_end_lba == ey.ge_end_lba)) and (ex.ge_name == ey.ge_name))
}
