# Fat16 -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CCE
import CceChar
import CceText
import Gpt
import Machine
import Maybe
import Prelude
import StringUtils

Fat16 :: [].{
	Fat16Volume := { vol_part_start : I64, vol_bytes_per_sector : I64, vol_sectors_per_cluster : I64, vol_reserved_sectors : I64, vol_num_fats : I64, vol_root_entry_count : I64, vol_fat_sectors : I64, vol_fat_start : I64, vol_root_start : I64, vol_data_start : I64, vol_total_sectors : I64, vol_cluster_count : I64 }.{
		is_eq : Fat16.Fat16Volume, Fat16.Fat16Volume -> Bool
		is_eq = |a, b| eq_Fat16Volume(a, b)
	}
	Fat16DirEntry := { de_name : CceText, de_attr : I64, de_cluster : I64, de_size : I64 }.{
		is_eq : Fat16.Fat16DirEntry, Fat16.Fat16DirEntry -> Bool
		is_eq = |a, b| eq_Fat16DirEntry(a, b)
	}
	Fat16Source := { fs_head : List(I64), fs_buf : I64, fs_buf_len : I64, fs_tail : List(I64), fs_len : I64 }.{
		is_eq : Fat16.Fat16Source, Fat16.Fat16Source -> Bool
		is_eq = |a, b| eq_Fat16Source(a, b)
	}
	Fat16Lfn := { lf_name : CceText, lf_ord : I64, lf_sum : I64, lf_live : Bool }.{
		is_eq : Fat16.Fat16Lfn, Fat16.Fat16Lfn -> Bool
		is_eq = |a, b| eq_Fat16Lfn(a, b)
	}
	Fat16Scan := { sc_found : Maybe.Maybe(Fat16.Fat16DirEntry), sc_lfn : Fat16.Fat16Lfn }.{
		is_eq : Fat16.Fat16Scan, Fat16.Fat16Scan -> Bool
		is_eq = |a, b| eq_Fat16Scan(a, b)
	}
	Fat16Run := { rn_found : Bool, rn_at : I64, rn_streak : I64 }.{
		is_eq : Fat16.Fat16Run, Fat16.Fat16Run -> Bool
		is_eq = |a, b| eq_Fat16Run(a, b)
	}
	Fat16List := { li_entries : List(Fat16.Fat16DirEntry), li_lfn : Fat16.Fat16Lfn }.{
		is_eq : Fat16.Fat16List, Fat16.Fat16List -> Bool
		is_eq = |a, b| eq_Fat16List(a, b)
	}

	fat16_read_u16! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	fat16_read_u16! = |machine, buf, off| ({
		(machine1, machine__1) = Machine.load!(machine, buf, off, 1)
		(machine2, machine__2) = Machine.load!(machine1, buf, (off + 1), 1)
		(machine2, I64.bitwise_or(machine__1, I64.shl_wrap(machine__2, I64.to_u8_wrap(8))))
	})

	fat16_read_u32! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	fat16_read_u32! = |machine, buf, off| ({
		(machine1, machine__1) = fat16_read_u16!(machine, buf, off)
		(machine2, machine__2) = fat16_read_u16!(machine1, buf, (off + 2))
		(machine2, I64.bitwise_or(machine__1, I64.shl_wrap(machine__2, I64.to_u8_wrap(16))))
	})

	fat16_init! : Machine.Machine, I64 => (Machine.Machine, Fat16.Fat16Volume)
	fat16_init! = |machine, part_start| ({
		(machine1, buf) = Machine.block_read_sector!(machine, part_start)
		fat16_parse_bpb!(machine1, part_start, buf)
	})

	fat16_zero_volume : I64 -> Fat16.Fat16Volume
	fat16_zero_volume = |part_start| Fat16.Fat16Volume.{ vol_part_start: part_start, vol_bytes_per_sector: 0, vol_sectors_per_cluster: 0, vol_reserved_sectors: 0, vol_num_fats: 0, vol_root_entry_count: 0, vol_fat_sectors: 0, vol_fat_start: 0, vol_root_start: 0, vol_data_start: 0, vol_total_sectors: 0, vol_cluster_count: 0 }

	fat16_parse_bpb! : Machine.Machine, I64, I64 => (Machine.Machine, Fat16.Fat16Volume)
	fat16_parse_bpb! = |machine, part_start, buf| ({
		(machine11, machine__4) = ({
		(machine1, bps) = fat16_read_u16!(machine, buf, 11)
		(machine2, spc) = Machine.load!(machine1, buf, 13, 1)
		({
			(machine10, machine__3) = (if (bps == 0) { (machine2, fat16_zero_volume(part_start)) } else { ({
			(machine9, machine__2) = (if (spc == 0) { (machine2, fat16_zero_volume(part_start)) } else { ({
			(machine8, machine__1) = ({
			(machine3, reserved) = fat16_read_u16!(machine2, buf, 14)
			(machine4, nfats) = Machine.load!(machine3, buf, 16, 1)
			(machine5, root_cnt) = fat16_read_u16!(machine4, buf, 17)
			(machine6, fat_sz) = fat16_read_u16!(machine5, buf, 22)
			fat_start : I64
			fat_start = (part_start + reserved)
			root_dir_sectors : I64
			root_dir_sectors = I64.div_trunc_by((((root_cnt * 32) + bps) - 1), bps)
			root_start : I64
			root_start = (fat_start + (nfats * fat_sz))
			data_start : I64
			data_start = (root_start + root_dir_sectors)
			(machine7, total) = fat16_total_sectors!(machine6, buf)
			data_sectors : I64
			data_sectors = (total - (data_start - part_start))
			raw_clusters : I64
			raw_clusters = (if (data_sectors <= 0) { 0 } else { I64.div_trunc_by(data_sectors, spc) })
			clusters : I64
			clusters = (if (raw_clusters > 65524) { 65524 } else { raw_clusters })
			(machine7, Fat16.Fat16Volume.{ vol_part_start: part_start, vol_bytes_per_sector: bps, vol_sectors_per_cluster: spc, vol_reserved_sectors: reserved, vol_num_fats: nfats, vol_root_entry_count: root_cnt, vol_fat_sectors: fat_sz, vol_fat_start: fat_start, vol_root_start: root_start, vol_data_start: data_start, vol_total_sectors: total, vol_cluster_count: clusters })
		})
			(machine8, machine__1)
		}) })
			(machine9, machine__2)
		}) })
			(machine10, machine__3)
		})
	})
		(machine11, machine__4)
	})

	fat16_total_sectors! : Machine.Machine, I64 => (Machine.Machine, I64)
	fat16_total_sectors! = |machine, buf| ({
		(machine1, small) = fat16_read_u16!(machine, buf, 19)
		(if (small == 0) { fat16_read_u32!(machine1, buf, 32) } else { (machine1, small) })
	})

	fat16_cluster_ok : Fat16.Fat16Volume, I64 -> Bool
	fat16_cluster_ok = |vol, cluster| ((cluster >= 2) and (cluster <= fat16_last_cluster(vol)))

	fat16_next_cluster! : Machine.Machine, Fat16.Fat16Volume, I64 => (Machine.Machine, I64)
	fat16_next_cluster! = |machine, vol, cluster| ({
		(if (fat16_cluster_ok(vol, cluster) == False) { (machine, 65535) } else { ({
			(machine1, buf) = Machine.block_read_sector!(machine, (vol.vol_fat_start + I64.div_trunc_by((cluster * 2), vol.vol_bytes_per_sector)))
			fat16_read_u16!(machine1, buf, Prelude.int_mod((cluster * 2), vol.vol_bytes_per_sector))
		}) })
	})

	fat16_is_end : I64 -> Bool
	fat16_is_end = |cluster| (cluster >= 65528)

	fat16_cluster_sector : Fat16.Fat16Volume, I64 -> I64
	fat16_cluster_sector = |vol, cluster| (vol.vol_data_start + ((cluster - 2) * vol.vol_sectors_per_cluster))

	fat16_last_cluster : Fat16.Fat16Volume -> I64
	fat16_last_cluster = |vol| (vol.vol_cluster_count + 1)

	fat16_read_dir_entry! : Machine.Machine, I64, I64 => (Machine.Machine, Fat16.Fat16DirEntry)
	fat16_read_dir_entry! = |machine, buf, off| ({
		(machine5, machine__1) = ({
		(machine1, name) = fat16_extract_name!(machine, buf, off)
		(machine2, attr) = Machine.load!(machine1, buf, (off + 11), 1)
		(machine3, cluster) = fat16_read_u16!(machine2, buf, (off + 26))
		(machine4, size) = fat16_read_u32!(machine3, buf, (off + 28))
		(machine4, Fat16.Fat16DirEntry.{ de_name: name, de_attr: attr, de_cluster: cluster, de_size: size })
	})
		(machine5, machine__1)
	})

	fat16_extract_name! : Machine.Machine, I64, I64 => (Machine.Machine, CceText)
	fat16_extract_name! = |machine, buf, off| ({
		(machine3, machine__1) = ({
		(machine1, base) = fat16_extract_chars!(machine, buf, off, 8, "")
		(machine2, ext) = fat16_extract_chars!(machine1, buf, (off + 8), 3, "")
		trimmed_base : CceText
		trimmed_base = fat16_trim_spaces(base)
		trimmed_ext : CceText
		trimmed_ext = fat16_trim_spaces(ext)
		(machine2, (if (CceText.len(trimmed_ext) == 0) { trimmed_base } else { CceText.concat(CceText.concat(trimmed_base, "."), trimmed_ext) }))
	})
		(machine3, machine__1)
	})

	fat16_extract_chars! : Machine.Machine, I64, I64, I64, CceText => (Machine.Machine, CceText)
	fat16_extract_chars! = |machine, buf, off, n, acc| (if (n == 0) { (machine, acc) } else { ({
		(machine1, c) = Machine.load!(machine, buf, off, 1)
		fat16_extract_chars!(machine1, buf, (off + 1), (n - 1), CceText.concat(acc, CCE.cce_foreign_byte_text(c)))
	}) })

	fat16_trim_spaces : CceText -> CceText
	fat16_trim_spaces = |s| fat16_trim_loop(s, CceText.len(s))

	fat16_trim_loop : CceText, I64 -> CceText
	fat16_trim_loop = |s, len| (if (len == 0) { "" } else { (if (CceChar.code(CceText.char_at(s, (len - 1))) == CCE.from_unicode(32)) { fat16_trim_loop(s, (len - 1)) } else { CceText.substring(s, 0, len) }) })

	fat16_is_free_entry! : Machine.Machine, I64, I64 => (Machine.Machine, Bool)
	fat16_is_free_entry! = |machine, buf, off| ({
		(machine2, machine__1) = ({
		(machine1, first) = Machine.load!(machine, buf, off, 1)
		(machine1, ((first == 0) or (first == 229)))
	})
		(machine2, machine__1)
	})

	fat16_is_lfn_entry! : Machine.Machine, I64, I64 => (Machine.Machine, Bool)
	fat16_is_lfn_entry! = |machine, buf, off| ({
		(machine1, machine__1) = Machine.load!(machine, buf, (off + 11), 1)
		(machine1, (machine__1 == 15))
	})

	fat16_is_volume_label! : Machine.Machine, I64, I64 => (Machine.Machine, Bool)
	fat16_is_volume_label! = |machine, buf, off| ({
		(machine1, machine__1) = Machine.load!(machine, buf, (off + 11), 1)
		(machine1, (I64.bitwise_and(machine__1, 8) == 8))
	})

	fat16_lfn_last : I64
	fat16_lfn_last = 64

	fat16_lfn_per_record : I64
	fat16_lfn_per_record = 13

	fat16_lfn_max_records : I64
	fat16_lfn_max_records = 20

	fat16_lfn_max_name : I64
	fat16_lfn_max_name = 255

	fat16_lfn_ord! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	fat16_lfn_ord! = |machine, buf, off| ({
		(machine1, machine__1) = Machine.load!(machine, buf, off, 1)
		(machine1, I64.bitwise_and(machine__1, 63))
	})

	fat16_lfn_is_last! : Machine.Machine, I64, I64 => (Machine.Machine, Bool)
	fat16_lfn_is_last! = |machine, buf, off| ({
		(machine1, machine__1) = Machine.load!(machine, buf, off, 1)
		(machine1, (I64.bitwise_and(machine__1, fat16_lfn_last) == fat16_lfn_last))
	})

	fat16_lfn_stored_sum! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	fat16_lfn_stored_sum! = |machine, buf, off| Machine.load!(machine, buf, (off + 13), 1)

	fat16_short_checksum! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	fat16_short_checksum! = |machine, buf, off| fat16_checksum_step!(machine, buf, off, 0, 0)

	fat16_checksum_step! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_checksum_step! = |machine, buf, off, i, sum| (if (i >= 11) { (machine, sum) } else { ({
		(machine1, machine__1) = Machine.load!(machine, buf, (off + i), 1)
		next : I64
		next = fat16_checksum_mix(sum, machine__1)
		fat16_checksum_step!(machine1, buf, off, (i + 1), next)
	}) })

	fat16_checksum_mix : I64, I64 -> I64
	fat16_checksum_mix = |sum, b| I64.bitwise_and(((I64.shl_wrap(I64.bitwise_and(sum, 1), I64.to_u8_wrap(7)) + I64.shr_zf_wrap(sum, I64.to_u8_wrap(1))) + b), 255)

	fat16_lfn_slot_offset : I64 -> I64
	fat16_lfn_slot_offset = |k| (if (k < 5) { (1 + (k * 2)) } else { (if (k < 11) { (14 + ((k - 5) * 2)) } else { (28 + ((k - 11) * 2)) }) })

	fat16_lfn_unit_at! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	fat16_lfn_unit_at! = |machine, buf, off, k| fat16_read_u16!(machine, buf, (off + fat16_lfn_slot_offset(k)))

	fat16_lfn_units_used! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	fat16_lfn_units_used! = |machine, buf, off, k| (if (k >= fat16_lfn_per_record) { (machine, k) } else { ({
		(machine1, u) = fat16_lfn_unit_at!(machine, buf, off, k)
		(if (u == 0) { (machine1, k) } else { (if (u == 65535) { (machine1, k) } else { fat16_lfn_units_used!(machine1, buf, off, (k + 1)) }) })
	}) })

	fat16_lfn_units_decodable! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, Bool)
	fat16_lfn_units_decodable! = |machine, buf, off, k, n| (if (k >= n) { (machine, True) } else { ({
		(machine1, machine__1) = fat16_lfn_unit_at!(machine, buf, off, k)
		(if (CCE.from_unicode(machine__1) < 0) { (machine1, False) } else { fat16_lfn_units_decodable!(machine1, buf, off, (k + 1), n) })
	}) })

	fat16_lfn_decode_units! : Machine.Machine, I64, I64, I64, I64, CceText => (Machine.Machine, CceText)
	fat16_lfn_decode_units! = |machine, buf, off, k, n, acc| (if (k >= n) { (machine, acc) } else { ({
		(machine1, machine__1) = fat16_lfn_unit_at!(machine, buf, off, k)
		piece : CceText
		piece = CceText.char_encode(CceChar.of_code(CCE.from_unicode(machine__1)))
		fat16_lfn_decode_units!(machine1, buf, off, (k + 1), n, CceText.concat(acc, piece))
	}) })

	fat16_lfn_none : Fat16.Fat16Lfn
	fat16_lfn_none = Fat16.Fat16Lfn.{ lf_name: "", lf_ord: 0, lf_sum: 0, lf_live: False }

	fat16_lfn_reset : Fat16.Fat16Lfn -> Fat16.Fat16Lfn
	fat16_lfn_reset = |st| (if st.lf_live { fat16_lfn_none } else { st })

	fat16_lfn_absorb! : Machine.Machine, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Fat16.Fat16Lfn)
	fat16_lfn_absorb! = |machine, buf, off, st| ({
		(machine1, ord) = fat16_lfn_ord!(machine, buf, off)
		({
			(machine2, machine__1) = fat16_lfn_is_last!(machine1, buf, off)
			(if machine__1 { fat16_lfn_open!(machine2, buf, off, ord) } else { fat16_lfn_extend!(machine2, buf, off, ord, st) })
		})
	})

	fat16_lfn_open! : Machine.Machine, I64, I64, I64 => (Machine.Machine, Fat16.Fat16Lfn)
	fat16_lfn_open! = |machine, buf, off, ord| (if (ord < 1) { (machine, fat16_lfn_none) } else { (if (ord > fat16_lfn_max_records) { (machine, fat16_lfn_none) } else { ({
		(machine1, machine__1) = fat16_lfn_stored_sum!(machine, buf, off)
		fat16_lfn_take!(machine1, buf, off, ord, machine__1, "")
	}) }) })

	fat16_lfn_extend! : Machine.Machine, I64, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Fat16.Fat16Lfn)
	fat16_lfn_extend! = |machine, buf, off, ord, st| (if (st.lf_live == False) { (machine, fat16_lfn_none) } else { (if (ord != st.lf_ord) { (machine, fat16_lfn_none) } else { ({
		(machine1, machine__1) = fat16_lfn_stored_sum!(machine, buf, off)
		(if (machine__1 != st.lf_sum) { (machine1, fat16_lfn_none) } else { fat16_lfn_take!(machine1, buf, off, ord, st.lf_sum, st.lf_name) })
	}) }) })

	fat16_lfn_take! : Machine.Machine, I64, I64, I64, I64, CceText => (Machine.Machine, Fat16.Fat16Lfn)
	fat16_lfn_take! = |machine, buf, off, ord, sum, rest| ({
		(machine6, machine__4) = ({
		(machine1, used) = fat16_lfn_units_used!(machine, buf, off, 0)
		({
			(machine2, machine__1) = fat16_lfn_units_decodable!(machine1, buf, off, 0, used)
			(machine5, machine__3) = (if (machine__1 == False) { (machine2, fat16_lfn_none) } else { ({
			(machine4, machine__2) = ({
			(machine3, part) = fat16_lfn_decode_units!(machine2, buf, off, 0, used, "")
			(machine3, Fat16.Fat16Lfn.{ lf_name: CceText.concat(part, rest), lf_ord: (ord - 1), lf_sum: sum, lf_live: True })
		})
			(machine4, machine__2)
		}) })
			(machine5, machine__3)
		})
	})
		(machine6, machine__4)
	})

	fat16_lfn_final! : Machine.Machine, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Maybe.Maybe(CceText))
	fat16_lfn_final! = |machine, buf, off, st| ({
		(machine3, machine__3) = (if (st.lf_live == False) { (machine, None) } else { ({
		(machine2, machine__2) = (if (st.lf_ord != 0) { (machine, None) } else { ({
		(machine1, machine__1) = fat16_short_checksum!(machine, buf, off)
		(machine1, (if (machine__1 != st.lf_sum) { None } else { (if (CceText.len(st.lf_name) == 0) { None } else { (if (CceText.len(st.lf_name) > fat16_lfn_max_name) { None } else { Just(st.lf_name) }) }) }))
	}) })
		(machine2, machine__2)
	}) })
		(machine3, machine__3)
	})

	fat16_entry_matches! : Machine.Machine, Fat16.Fat16DirEntry, I64, I64, Fat16.Fat16Lfn, CceText => (Machine.Machine, Bool)
	fat16_entry_matches! = |machine, entry, buf, off, st, name| ({
		(machine3, machine__3) = (if fat16_name_matches(entry.de_name, name) { (machine, True) } else { ({
		(machine2, machine__2) = (if (st.lf_live == False) { (machine, False) } else { ({
		(machine1, machine__1) = fat16_lfn_final!(machine, buf, off, st)
		(machine1, (match machine__1 {
		Just(n) => fat16_name_matches(n, name)
		None => False
	}))
	}) })
		(machine2, machine__2)
	}) })
		(machine3, machine__3)
	})

	fat16_find_in_root! : Machine.Machine, Fat16.Fat16Volume, CceText => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_find_in_root! = |machine, vol, name| ({
		root_sectors : I64
		root_sectors = I64.div_trunc_by((((vol.vol_root_entry_count * 32) + vol.vol_bytes_per_sector) - 1), vol.vol_bytes_per_sector)
		fat16_scan_root_sectors!(machine, vol, name, vol.vol_root_start, root_sectors, 0, fat16_lfn_none)
	})

	fat16_scan_root_sectors! : Machine.Machine, Fat16.Fat16Volume, CceText, I64, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_scan_root_sectors! = |machine, vol, name, sector, remaining, entries_checked, st| (if (remaining == 0) { (machine, None) } else { (if (entries_checked >= vol.vol_root_entry_count) { (machine, None) } else { ({
		(machine1, buf) = Machine.block_read_sector!(machine, sector)
		fat16_scan_root_step!(machine1, vol, name, sector, remaining, entries_checked, buf, st)
	}) }) })

	fat16_scan_root_step! : Machine.Machine, Fat16.Fat16Volume, CceText, I64, I64, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_scan_root_step! = |machine, vol, name, sector, remaining, entries_checked, buf, st| ({
		entries_per_sector : I64
		entries_per_sector = I64.div_trunc_by(vol.vol_bytes_per_sector, 32)
		(machine1, r) = fat16_scan_sector_lfn!(machine, buf, name, 0, entries_per_sector, st)
		(match r.sc_found {
			Just(entry) => (machine1, Just(entry))
			None => fat16_scan_root_sectors!(machine1, vol, name, (sector + 1), (remaining - 1), (entries_checked + entries_per_sector), r.sc_lfn)
		})
	})

	fat16_scan_sector_lfn! : Machine.Machine, I64, CceText, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Fat16.Fat16Scan)
	fat16_scan_sector_lfn! = |machine, buf, name, i, count, st| (if (i >= count) { (machine, Fat16.Fat16Scan.{ sc_found: None, sc_lfn: st }) } else { ({
		off : I64
		off = (i * 32)
		({
			(machine1, machine__1) = fat16_is_free_entry!(machine, buf, off)
			(if machine__1 { ({
			(machine2, machine__2) = Machine.load!(machine1, buf, off, 1)
			(if (machine__2 == 0) { (machine2, Fat16.Fat16Scan.{ sc_found: None, sc_lfn: fat16_lfn_reset(st) }) } else { fat16_scan_sector_lfn!(machine2, buf, name, (i + 1), count, fat16_lfn_reset(st)) })
		}) } else { ({
			(machine3, machine__3) = fat16_is_lfn_entry!(machine1, buf, off)
			(if machine__3 { ({
			(machine4, machine__4) = fat16_lfn_absorb!(machine3, buf, off, st)
			fat16_scan_sector_lfn!(machine4, buf, name, (i + 1), count, machine__4)
		}) } else { ({
			(machine5, machine__5) = fat16_is_volume_label!(machine3, buf, off)
			(if machine__5 { fat16_scan_sector_lfn!(machine5, buf, name, (i + 1), count, fat16_lfn_reset(st)) } else { ({
			(machine6, entry) = fat16_read_dir_entry!(machine5, buf, off)
			({
				(machine7, machine__6) = fat16_entry_matches!(machine6, entry, buf, off, st, name)
				(if machine__6 { (machine7, Fat16.Fat16Scan.{ sc_found: Just(entry), sc_lfn: st }) } else { fat16_scan_sector_lfn!(machine7, buf, name, (i + 1), count, fat16_lfn_reset(st)) })
			})
		}) })
		}) })
		}) })
		})
	}) })

	fat16_find_in_cluster_dir! : Machine.Machine, Fat16.Fat16Volume, I64, CceText => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_find_in_cluster_dir! = |machine, vol, cluster, name| fat16_find_in_cluster_walk!(machine, vol, cluster, name, cluster, 1, 0, fat16_lfn_none)

	fat16_find_in_cluster_walk! : Machine.Machine, Fat16.Fat16Volume, I64, CceText, I64, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_find_in_cluster_walk! = |machine, vol, cluster, name, saved, power, steps, st| (if fat16_is_end(cluster) { (machine, None) } else { ({
		(machine1, r) = fat16_scan_cluster_sectors!(machine, vol, name, fat16_cluster_sector(vol, cluster), vol.vol_sectors_per_cluster, st)
		fat16_cluster_found_or_next!(machine1, vol, cluster, name, saved, power, steps, r)
	}) })

	fat16_cluster_found_or_next! : Machine.Machine, Fat16.Fat16Volume, I64, CceText, I64, I64, I64, Fat16.Fat16Scan => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_cluster_found_or_next! = |machine, vol, cluster, name, saved, power, steps, r| (match r.sc_found {
		Just(entry) => (machine, Just(entry))
		None => fat16_find_in_cluster_step!(machine, vol, cluster, name, saved, power, steps, r.sc_lfn)
	})

	fat16_find_in_cluster_step! : Machine.Machine, Fat16.Fat16Volume, I64, CceText, I64, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_find_in_cluster_step! = |machine, vol, cluster, name, saved, power, steps, st| ({
		(machine1, nxt) = fat16_next_cluster!(machine, vol, cluster)
		(if (nxt == saved) { (machine1, None) } else { (if ((steps + 1) == power) { fat16_find_in_cluster_walk!(machine1, vol, nxt, name, nxt, (power * 2), 0, st) } else { fat16_find_in_cluster_walk!(machine1, vol, nxt, name, saved, power, (steps + 1), st) }) })
	})

	fat16_scan_cluster_sectors! : Machine.Machine, Fat16.Fat16Volume, CceText, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Fat16.Fat16Scan)
	fat16_scan_cluster_sectors! = |machine, vol, name, sector, remaining, st| (if (remaining == 0) { (machine, Fat16.Fat16Scan.{ sc_found: None, sc_lfn: st }) } else { ({
		(machine1, buf) = Machine.block_read_sector!(machine, sector)
		fat16_scan_cluster_step!(machine1, vol, name, sector, remaining, buf, st)
	}) })

	fat16_scan_cluster_step! : Machine.Machine, Fat16.Fat16Volume, CceText, I64, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Fat16.Fat16Scan)
	fat16_scan_cluster_step! = |machine, vol, name, sector, remaining, buf, st| ({
		entries_per_sector : I64
		entries_per_sector = I64.div_trunc_by(vol.vol_bytes_per_sector, 32)
		(machine1, r) = fat16_scan_sector_lfn!(machine, buf, name, 0, entries_per_sector, st)
		(match r.sc_found {
			Just(_e) => (machine1, r)
			None => fat16_scan_cluster_sectors!(machine1, vol, name, (sector + 1), (remaining - 1), r.sc_lfn)
		})
	})

	fat16_name_matches : CceText, CceText -> Bool
	fat16_name_matches = |entry_name, search_name| (fat16_upper(entry_name) == fat16_upper(search_name))

	fat16_upper : CceText -> CceText
	fat16_upper = |s| fat16_upper_loop(s, 0, CceText.len(s), "")

	fat16_upper_loop : CceText, I64, I64, CceText -> CceText
	fat16_upper_loop = |s, i, len, acc| (if (i >= len) { acc } else { ({
		c : CceChar
		c = CceText.char_at(s, i)
		fat16_upper_loop(s, (i + 1), len, CceText.concat(acc, CceText.char_to_text(CCE.to_upper(c))))
	}) })

	fat16_scope_admits! : Machine.Machine, CceText => (Machine.Machine, Bool)
	fat16_scope_admits! = |machine, path| ({
		(machine3, machine__2) = ({
		(machine2, grant) = ({
			(machine1, machine__1) = Machine.process_get_pid(machine)
			CceText.answer_units(Machine.process_get_scope(machine1, machine__1))
		})
		(machine2, (if (CceText.len(grant) == 0) { True } else { StringUtils.text_starts_with(path, grant) }))
	})
		(machine3, machine__2)
	})

	fat16_resolve_path! : Machine.Machine, Fat16.Fat16Volume, CceText => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_resolve_path! = |machine, vol, path| ({
		(machine1, machine__1) = fat16_scope_admits!(machine, path)
		(if (machine__1 == False) { (machine1, None) } else { ({
		parts : List(CceText)
		parts = fat16_split_path(path)
		fat16_walk_path!(machine1, vol, parts, 0, U64.to_i64_wrap(List.len(parts)))
	}) })
	})

	fat16_walk_path! : Machine.Machine, Fat16.Fat16Volume, List(CceText), I64, I64 => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_walk_path! = |machine, vol, parts, depth, total| (if (depth >= total) { (machine, None) } else { ({
		name : CceText
		name = (List.get(parts, I64.to_u64_wrap(depth)) ?? crash("list-at out of range"))
		({
			(machine1, machine__1) = (if (depth == 0) { fat16_find_in_root!(machine, vol, name) } else { (machine, None) })
			(match machine__1 {
			Just(entry) => (if (depth == (total - 1)) { (machine1, Just(entry)) } else { (if (I64.bitwise_and(entry.de_attr, 16) == 16) { fat16_walk_path_sub!(machine1, vol, parts, (depth + 1), total, entry.de_cluster) } else { (machine1, None) }) })
			None => (machine1, None)
		})
		})
	}) })

	fat16_walk_path_sub! : Machine.Machine, Fat16.Fat16Volume, List(CceText), I64, I64, I64 => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_walk_path_sub! = |machine, vol, parts, depth, total, cluster| (if (depth >= total) { (machine, None) } else { ({
		name : CceText
		name = (List.get(parts, I64.to_u64_wrap(depth)) ?? crash("list-at out of range"))
		({
			(machine1, machine__1) = fat16_find_in_cluster_dir!(machine, vol, cluster, name)
			(match machine__1 {
			Just(entry) => (if (depth == (total - 1)) { (machine1, Just(entry)) } else { (if (I64.bitwise_and(entry.de_attr, 16) == 16) { fat16_walk_path_sub!(machine1, vol, parts, (depth + 1), total, entry.de_cluster) } else { (machine1, None) }) })
			None => (machine1, None)
		})
		})
	}) })

	fat16_split_path : CceText -> List(CceText)
	fat16_split_path = |path| fat16_split_loop(path, 0, CceText.len(path), 0, [])

	fat16_split_loop : CceText, I64, I64, I64, List(CceText) -> List(CceText)
	fat16_split_loop = |s, i, len, start, acc| (if (i >= len) { (if (i > start) { List.append(acc, CceText.substring(s, start, (i - start))) } else { acc }) } else { (if (CceChar.code(CceText.char_at(s, i)) == CCE.from_unicode(47)) { (if (i > start) { fat16_split_loop(s, (i + 1), len, (i + 1), List.append(acc, CceText.substring(s, start, (i - start)))) } else { fat16_split_loop(s, (i + 1), len, (i + 1), acc) }) } else { fat16_split_loop(s, (i + 1), len, start, acc) }) })

	fat16_file_exists! : Machine.Machine, Fat16.Fat16Volume, CceText => (Machine.Machine, Bool)
	fat16_file_exists! = |machine, vol, path| ({
		(machine1, machine__1) = fat16_resolve_path!(machine, vol, path)
		(machine1, (match machine__1 {
		Just(_entry) => True
		None => False
	}))
	})

	fat16_fallback_partition_start : I64
	fat16_fallback_partition_start = 2048

	fat16_vol_is_usable : Fat16.Fat16Volume -> Bool
	fat16_vol_is_usable = |vol| ((vol.vol_bytes_per_sector > 0) and (vol.vol_sectors_per_cluster > 0))

	fat16_boot_volume! : Machine.Machine => (Machine.Machine, Fat16.Fat16Volume)
	fat16_boot_volume! = |machine| ({
		(machine1, disk) = Gpt.gpt_read!(machine)
		(match disk {
			Just(d) => fat16_first_usable!(machine1, d.gd_partitions, 0, U64.to_i64_wrap(List.len(d.gd_partitions)))
			None => fat16_boot_volume_nogpt!(machine1)
		})
	})

	fat16_boot_volume_nogpt! : Machine.Machine => (Machine.Machine, Fat16.Fat16Volume)
	fat16_boot_volume_nogpt! = |machine| ({
		(machine1, buf) = Machine.block_read_sector!(machine, 0)
		fat16_boot_volume_probe!(machine1, buf)
	})

	fat16_boot_volume_probe! : Machine.Machine, I64 => (Machine.Machine, Fat16.Fat16Volume)
	fat16_boot_volume_probe! = |machine, buf| ({
		(machine1, machine__1) = Machine.load!(machine, buf, 11, 1)
		(machine2, machine__2) = Machine.load!(machine1, buf, 12, 1)
		bps : I64
		bps = (machine__1 + (machine__2 * 256))
		(machine3, spc) = Machine.load!(machine2, buf, 13, 1)
		(if ((bps == 512) and (spc > 0)) { fat16_init!(machine3, 0) } else { fat16_init!(machine3, fat16_fallback_partition_start) })
	})

	fat16_first_usable! : Machine.Machine, List(Gpt.GptPartition), I64, I64 => (Machine.Machine, Fat16.Fat16Volume)
	fat16_first_usable! = |machine, parts, i, n| (if (i >= n) { fat16_init!(machine, fat16_fallback_partition_start) } else { ({
		p = (List.get(parts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		({
			(machine1, vol) = fat16_init!(machine, p.gp_start_lba)
			(if fat16_vol_is_usable(vol) { (machine1, vol) } else { fat16_first_usable!(machine1, parts, (i + 1), n) })
		})
	}) })

	file_exists! : Machine.Machine, CceText => (Machine.Machine, Bool)
	file_exists! = |machine, path| fat16_exists_on_disk!(machine, path)

	fat16_exists_on_disk! : Machine.Machine, CceText => (Machine.Machine, Bool)
	fat16_exists_on_disk! = |machine, path| ({
		(machine1, vol) = fat16_boot_volume!(machine)
		(if (fat16_vol_is_usable(vol) == False) { (machine1, False) } else { fat16_file_exists!(machine1, vol, path) })
	})

	fat16_read_entry_named! : Machine.Machine, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Fat16.Fat16DirEntry)
	fat16_read_entry_named! = |machine, buf, off, st| ({
		(machine3, machine__2) = ({
		(machine1, e) = fat16_read_dir_entry!(machine, buf, off)
		({
			(machine2, machine__1) = fat16_lfn_final!(machine1, buf, off, st)
			(machine2, (match machine__1 {
			Just(n) => Fat16.Fat16DirEntry.{ de_name: n, de_attr: e.de_attr, de_cluster: e.de_cluster, de_size: e.de_size }
			None => e
		}))
		})
	})
		(machine3, machine__2)
	})

	fat16_entries_in_sector! : Machine.Machine, I64, I64, I64, List(Fat16.Fat16DirEntry), Fat16.Fat16Lfn => (Machine.Machine, Fat16.Fat16List)
	fat16_entries_in_sector! = |machine, buf, i, count, acc, st| (if (i >= count) { (machine, Fat16.Fat16List.{ li_entries: acc, li_lfn: st }) } else { ({
		off : I64
		off = (i * 32)
		({
			(machine1, machine__1) = fat16_is_free_entry!(machine, buf, off)
			(if machine__1 { ({
			(machine2, machine__2) = Machine.load!(machine1, buf, off, 1)
			(if (machine__2 == 0) { (machine2, Fat16.Fat16List.{ li_entries: acc, li_lfn: fat16_lfn_reset(st) }) } else { fat16_entries_in_sector!(machine2, buf, (i + 1), count, acc, fat16_lfn_reset(st)) })
		}) } else { ({
			(machine3, machine__3) = fat16_is_lfn_entry!(machine1, buf, off)
			(if machine__3 { ({
			(machine4, machine__4) = fat16_lfn_absorb!(machine3, buf, off, st)
			fat16_entries_in_sector!(machine4, buf, (i + 1), count, acc, machine__4)
		}) } else { ({
			(machine5, machine__5) = fat16_is_volume_label!(machine3, buf, off)
			(if machine__5 { fat16_entries_in_sector!(machine5, buf, (i + 1), count, acc, fat16_lfn_reset(st)) } else { ({
			(machine6, named) = fat16_read_entry_named!(machine5, buf, off, st)
			fat16_entries_in_sector!(machine6, buf, (i + 1), count, List.append(acc, named), fat16_lfn_reset(st))
		}) })
		}) })
		}) })
		})
	}) })

	fat16_root_entries! : Machine.Machine, Fat16.Fat16Volume => (Machine.Machine, List(Fat16.Fat16DirEntry))
	fat16_root_entries! = |machine, vol| ({
		(machine1, machine__1) = fat16_scope_admits!(machine, "/")
		(if (machine__1 == False) { (machine1, []) } else { ({
		root_sectors : I64
		root_sectors = I64.div_trunc_by((((vol.vol_root_entry_count * 32) + vol.vol_bytes_per_sector) - 1), vol.vol_bytes_per_sector)
		fat16_root_entry_sectors!(machine1, vol, vol.vol_root_start, root_sectors, 0, [], fat16_lfn_none)
	}) })
	})

	fat16_root_entry_sectors! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64, List(Fat16.Fat16DirEntry), Fat16.Fat16Lfn => (Machine.Machine, List(Fat16.Fat16DirEntry))
	fat16_root_entry_sectors! = |machine, vol, sector, remaining, checked, acc, st| (if (remaining == 0) { (machine, acc) } else { (if (checked >= vol.vol_root_entry_count) { (machine, acc) } else { ({
		(machine1, buf) = Machine.block_read_sector!(machine, sector)
		({
			per : I64
			per = I64.div_trunc_by(vol.vol_bytes_per_sector, 32)
			(machine2, r) = fat16_entries_in_sector!(machine1, buf, 0, per, acc, st)
			fat16_root_entry_sectors!(machine2, vol, (sector + 1), (remaining - 1), (checked + per), r.li_entries, r.li_lfn)
		})
	}) }) })

	fat16_cluster_entries! : Machine.Machine, Fat16.Fat16Volume, I64, List(Fat16.Fat16DirEntry) => (Machine.Machine, List(Fat16.Fat16DirEntry))
	fat16_cluster_entries! = |machine, vol, cluster, acc| fat16_cluster_entries_walk!(machine, vol, cluster, acc, cluster, 1, 0, fat16_lfn_none)

	fat16_cluster_entries_walk! : Machine.Machine, Fat16.Fat16Volume, I64, List(Fat16.Fat16DirEntry), I64, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, List(Fat16.Fat16DirEntry))
	fat16_cluster_entries_walk! = |machine, vol, cluster, acc, saved, power, steps, st| (if fat16_is_end(cluster) { (machine, acc) } else { ({
		(machine1, here) = fat16_cluster_entry_sectors!(machine, vol, fat16_cluster_sector(vol, cluster), vol.vol_sectors_per_cluster, acc, st)
		(machine2, next) = fat16_next_cluster!(machine1, vol, cluster)
		(if (next == saved) { (machine2, here.li_entries) } else { (if ((steps + 1) == power) { fat16_cluster_entries_walk!(machine2, vol, next, here.li_entries, next, (power * 2), 0, here.li_lfn) } else { fat16_cluster_entries_walk!(machine2, vol, next, here.li_entries, saved, power, (steps + 1), here.li_lfn) }) })
	}) })

	fat16_cluster_entry_sectors! : Machine.Machine, Fat16.Fat16Volume, I64, I64, List(Fat16.Fat16DirEntry), Fat16.Fat16Lfn => (Machine.Machine, Fat16.Fat16List)
	fat16_cluster_entry_sectors! = |machine, vol, sector, remaining, acc, st| (if (remaining == 0) { (machine, Fat16.Fat16List.{ li_entries: acc, li_lfn: st }) } else { ({
		(machine1, buf) = Machine.block_read_sector!(machine, sector)
		({
			per : I64
			per = I64.div_trunc_by(vol.vol_bytes_per_sector, 32)
			(machine2, r) = fat16_entries_in_sector!(machine1, buf, 0, per, acc, st)
			fat16_cluster_entry_sectors!(machine2, vol, (sector + 1), (remaining - 1), r.li_entries, r.li_lfn)
		})
	}) })

	fat16_is_root_path : CceText -> Bool
	fat16_is_root_path = |p| (((CceText.len(p) == 0) or (p == "/")) or (p == "."))

	fat16_is_dir_entry : Fat16.Fat16DirEntry -> Bool
	fat16_is_dir_entry = |e| (I64.bitwise_and(e.de_attr, 16) == 16)

	fat16_list_dir! : Machine.Machine, Fat16.Fat16Volume, CceText => (Machine.Machine, List(Fat16.Fat16DirEntry))
	fat16_list_dir! = |machine, vol, path| (if fat16_is_root_path(path) { fat16_root_entries!(machine, vol) } else { ({
		(machine1, found) = fat16_resolve_path!(machine, vol, path)
		(match found {
			Just(entry) => (if fat16_is_dir_entry(entry) { fat16_cluster_entries!(machine1, vol, entry.de_cluster, []) } else { (machine1, []) })
			None => (machine1, [])
		})
	}) })

	list_files! : Machine.Machine, CceText, CceText => (Machine.Machine, List(CceText))
	list_files! = |machine, dir, ext| ({
		(machine1, vol) = fat16_boot_volume!(machine)
		(if (fat16_vol_is_usable(vol) == False) { (machine1, []) } else { ({
			(machine2, entries) = fat16_list_dir!(machine1, vol, dir)
			(machine2, fat16_pick_files(entries, 0, U64.to_i64_wrap(List.len(entries)), ext, []))
		}) })
	})

	fat16_pick_files : List(Fat16.Fat16DirEntry), I64, I64, CceText, List(CceText) -> List(CceText)
	fat16_pick_files = |es, i, n, ext, acc| (if (i >= n) { acc } else { ({
		e = (List.get(es, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if fat16_is_dir_entry(e) { fat16_pick_files(es, (i + 1), n, ext, acc) } else { (if fat16_name_has_ext(e.de_name, ext) { fat16_pick_files(es, (i + 1), n, ext, List.append(acc, e.de_name)) } else { fat16_pick_files(es, (i + 1), n, ext, acc) }) })
	}) })

	fat16_name_has_ext : CceText, CceText -> Bool
	fat16_name_has_ext = |name, ext| (if (CceText.len(ext) == 0) { True } else { StringUtils.text_ends_with(fat16_upper(name), fat16_upper(ext)) })

	list_directories! : Machine.Machine, CceText => (Machine.Machine, List(CceText))
	list_directories! = |machine, dir| ({
		(machine1, vol) = fat16_boot_volume!(machine)
		(if (fat16_vol_is_usable(vol) == False) { (machine1, []) } else { ({
			(machine2, entries) = fat16_list_dir!(machine1, vol, dir)
			(machine2, fat16_pick_dirs(entries, 0, U64.to_i64_wrap(List.len(entries)), []))
		}) })
	})

	fat16_pick_dirs : List(Fat16.Fat16DirEntry), I64, I64, List(CceText) -> List(CceText)
	fat16_pick_dirs = |es, i, n, acc| (if (i >= n) { acc } else { ({
		e = (List.get(es, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (fat16_is_dir_entry(e) == False) { fat16_pick_dirs(es, (i + 1), n, acc) } else { (if (e.de_name == ".") { fat16_pick_dirs(es, (i + 1), n, acc) } else { (if (e.de_name == "..") { fat16_pick_dirs(es, (i + 1), n, acc) } else { fat16_pick_dirs(es, (i + 1), n, List.append(acc, e.de_name)) }) }) })
	}) })

	eq_Fat16Volume : Fat16.Fat16Volume, Fat16.Fat16Volume -> Bool
	eq_Fat16Volume = |ex, ey| ((((((((((((ex.vol_part_start == ey.vol_part_start) and (ex.vol_bytes_per_sector == ey.vol_bytes_per_sector)) and (ex.vol_sectors_per_cluster == ey.vol_sectors_per_cluster)) and (ex.vol_reserved_sectors == ey.vol_reserved_sectors)) and (ex.vol_num_fats == ey.vol_num_fats)) and (ex.vol_root_entry_count == ey.vol_root_entry_count)) and (ex.vol_fat_sectors == ey.vol_fat_sectors)) and (ex.vol_fat_start == ey.vol_fat_start)) and (ex.vol_root_start == ey.vol_root_start)) and (ex.vol_data_start == ey.vol_data_start)) and (ex.vol_total_sectors == ey.vol_total_sectors)) and (ex.vol_cluster_count == ey.vol_cluster_count))

	eq_Fat16DirEntry : Fat16.Fat16DirEntry, Fat16.Fat16DirEntry -> Bool
	eq_Fat16DirEntry = |ex, ey| ((((ex.de_name == ey.de_name) and (ex.de_attr == ey.de_attr)) and (ex.de_cluster == ey.de_cluster)) and (ex.de_size == ey.de_size))

	eq_Fat16Source : Fat16.Fat16Source, Fat16.Fat16Source -> Bool
	eq_Fat16Source = |ex, ey| (((((ex.fs_head == ey.fs_head) and (ex.fs_buf == ey.fs_buf)) and (ex.fs_buf_len == ey.fs_buf_len)) and (ex.fs_tail == ey.fs_tail)) and (ex.fs_len == ey.fs_len))

	eq_Fat16Lfn : Fat16.Fat16Lfn, Fat16.Fat16Lfn -> Bool
	eq_Fat16Lfn = |ex, ey| ((((ex.lf_name == ey.lf_name) and (ex.lf_ord == ey.lf_ord)) and (ex.lf_sum == ey.lf_sum)) and (ex.lf_live == ey.lf_live))

	eq_Fat16Scan : Fat16.Fat16Scan, Fat16.Fat16Scan -> Bool
	eq_Fat16Scan = |ex, ey| (Maybe.eq_Maybe(ex.sc_found, ey.sc_found) and eq_Fat16Lfn(ex.sc_lfn, ey.sc_lfn))

	eq_Fat16Run : Fat16.Fat16Run, Fat16.Fat16Run -> Bool
	eq_Fat16Run = |ex, ey| (((ex.rn_found == ey.rn_found) and (ex.rn_at == ey.rn_at)) and (ex.rn_streak == ey.rn_streak))

	eq_Fat16List : Fat16.Fat16List, Fat16.Fat16List -> Bool
	eq_Fat16List = |ex, ey| ((ex.li_entries == ey.li_entries) and eq_Fat16Lfn(ex.li_lfn, ey.li_lfn))
}
