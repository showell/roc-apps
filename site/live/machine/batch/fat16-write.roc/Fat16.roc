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

	fat16_write_u16! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	fat16_write_u16! = |machine, buf, off, val| ({
		(machine1, _lo) = Machine.store!(machine, buf, off, I64.bitwise_and(val, 255), 1)
		Machine.store!(machine1, buf, (off + 1), I64.bitwise_and(I64.shr_zf_wrap(val, I64.to_u8_wrap(8)), 255), 1)
	})

	fat16_fat_entry_sector : Fat16.Fat16Volume, I64, I64 -> I64
	fat16_fat_entry_sector = |vol, fat_index, cluster| ((vol.vol_fat_start + (fat_index * vol.vol_fat_sectors)) + I64.div_trunc_by((cluster * 2), vol.vol_bytes_per_sector))

	fat16_fat_entry_offset : Fat16.Fat16Volume, I64 -> I64
	fat16_fat_entry_offset = |vol, cluster| Prelude.int_mod((cluster * 2), vol.vol_bytes_per_sector)

	fat16_write_fat_entry! : Machine.Machine, Fat16.Fat16Volume, I64, I64 => (Machine.Machine, I64)
	fat16_write_fat_entry! = |machine, vol, cluster, value| fat16_write_fat_copies!(machine, vol, 0, cluster, value)

	fat16_write_fat_copies! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64 => (Machine.Machine, I64)
	fat16_write_fat_copies! = |machine, vol, i, cluster, value| (if (i >= vol.vol_num_fats) { (machine, 0) } else { ({
		(machine1, h) = Machine.mark(machine)
		({
			(machine2, buf) = Machine.block_read_sector!(machine1, fat16_fat_entry_sector(vol, i, cluster))
			(machine3, _s) = fat16_put_fat_entry!(machine2, vol, i, cluster, value, buf)
			fat16_fat_copy_next!(machine3, vol, i, cluster, value, h)
		})
	}) })

	fat16_fat_copy_next! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_fat_copy_next! = |machine, vol, i, cluster, value, h| ({
		(machine1, _z) = Machine.release(machine, h)
		fat16_write_fat_copies!(machine1, vol, (i + 1), cluster, value)
	})

	fat16_put_fat_entry! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_put_fat_entry! = |machine, vol, fat_index, cluster, value, buf| ({
		(machine1, _w) = fat16_write_u16!(machine, buf, fat16_fat_entry_offset(vol, cluster), value)
		Machine.block_write_sector!(machine1, fat16_fat_entry_sector(vol, fat_index, cluster), buf)
	})

	fat16_last_cluster : Fat16.Fat16Volume -> I64
	fat16_last_cluster = |vol| (vol.vol_cluster_count + 1)

	fat16_find_free_from! : Machine.Machine, Fat16.Fat16Volume, I64 => (Machine.Machine, I64)
	fat16_find_free_from! = |machine, vol, hint| ({
		(machine1, found) = fat16_scan_free_sectors!(machine, vol, (if (hint < 2) { 2 } else { hint }))
		(if (found > 0) { (machine1, found) } else { (if (hint <= 2) { (machine1, 0) } else { fat16_scan_free_sectors!(machine1, vol, 2) }) })
	})

	fat16_scan_free_sectors! : Machine.Machine, Fat16.Fat16Volume, I64 => (Machine.Machine, I64)
	fat16_scan_free_sectors! = |machine, vol, c| (if (c > fat16_last_cluster(vol)) { (machine, 0) } else { ({
		per_sector : I64
		per_sector = I64.div_trunc_by(vol.vol_bytes_per_sector, 2)
		sector_last : I64
		sector_last = (((I64.div_trunc_by(c, per_sector) * per_sector) + per_sector) - 1)
		upto : I64
		upto = I64.min(sector_last, fat16_last_cluster(vol))
		({
			(machine1, found) = fat16_scan_free_sector!(machine, vol, c, upto)
			(if (found > 0) { (machine1, found) } else { fat16_scan_free_sectors!(machine1, vol, (sector_last + 1)) })
		})
	}) })

	fat16_scan_free_sector! : Machine.Machine, Fat16.Fat16Volume, I64, I64 => (Machine.Machine, I64)
	fat16_scan_free_sector! = |machine, vol, c, upto| ({
		(machine1, h) = Machine.mark(machine)
		({
			(machine2, buf) = Machine.block_read_sector!(machine1, fat16_fat_entry_sector(vol, 0, c))
			fat16_scan_free_done!(machine2, vol, buf, c, upto, h)
		})
	})

	fat16_scan_free_done! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_scan_free_done! = |machine, vol, buf, c, upto, h| ({
		(machine3, machine__1) = ({
		(machine1, found) = fat16_scan_free_in_sector!(machine, vol, buf, c, upto)
		(machine2, _z) = Machine.release(machine1, h)
		(machine2, found)
	})
		(machine3, machine__1)
	})

	fat16_scan_free_in_sector! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64 => (Machine.Machine, I64)
	fat16_scan_free_in_sector! = |machine, vol, buf, c, upto| (if (c > upto) { (machine, 0) } else { ({
		(machine1, machine__1) = fat16_read_u16!(machine, buf, fat16_fat_entry_offset(vol, c))
		(if (machine__1 == 0) { (machine1, c) } else { fat16_scan_free_in_sector!(machine1, vol, buf, (c + 1), upto) })
	}) })

	fat16_alloc_cluster! : Machine.Machine, Fat16.Fat16Volume => (Machine.Machine, I64)
	fat16_alloc_cluster! = |machine, vol| fat16_alloc_cluster_from!(machine, vol, 2)

	fat16_alloc_cluster_from! : Machine.Machine, Fat16.Fat16Volume, I64 => (Machine.Machine, I64)
	fat16_alloc_cluster_from! = |machine, vol, hint| ({
		(machine1, c) = fat16_find_free_from!(machine, vol, hint)
		fat16_claim_cluster!(machine1, vol, c)
	})

	fat16_claim_cluster! : Machine.Machine, Fat16.Fat16Volume, I64 => (Machine.Machine, I64)
	fat16_claim_cluster! = |machine, vol, c| (if (c == 0) { (machine, 0) } else { ({
		(machine1, w) = fat16_write_fat_entry!(machine, vol, c, 65535)
		(machine1, (if (w == 0) { c } else { 0 }))
	}) })

	fat16_bytes_per_cluster : Fat16.Fat16Volume -> I64
	fat16_bytes_per_cluster = |vol| (vol.vol_bytes_per_sector * vol.vol_sectors_per_cluster)

	fat16_src_of_list : List(I64) -> Fat16.Fat16Source
	fat16_src_of_list = |bs| Fat16.Fat16Source.{ fs_head: bs, fs_buf: 0, fs_buf_len: 0, fs_tail: [], fs_len: U64.to_i64_wrap(List.len(bs)) }

	fat16_src_empty : Fat16.Fat16Source
	fat16_src_empty = fat16_src_of_list([])

	fat16_src_at! : Machine.Machine, Fat16.Fat16Source, I64 => (Machine.Machine, I64)
	fat16_src_at! = |machine, s, i| ({
		hn : I64
		hn = U64.to_i64_wrap(List.len(s.fs_head))
		(if (i < hn) { (machine, (List.get(s.fs_head, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) } else { ({
			j : I64
			j = (i - hn)
			(if (j < s.fs_buf_len) { Machine.load!(machine, s.fs_buf, j, 1) } else { (machine, (List.get(s.fs_tail, I64.to_u64_wrap((j - s.fs_buf_len))) ?? crash("list-at out of range"))) })
		}) })
	})

	fat16_fill_sector! : Machine.Machine, I64, Fat16.Fat16Source, I64, I64, I64 => (Machine.Machine, I64)
	fat16_fill_sector! = |machine, buf, bytes, start, i, bps| (if (i >= bps) { (machine, 0) } else { ({
		src : I64
		src = (start + i)
		(machine1, b) = (if (src < bytes.fs_len) { fat16_src_at!(machine, bytes, src) } else { (machine, 0) })
		(machine2, _w) = Machine.store!(machine1, buf, i, b, 1)
		fat16_fill_sector!(machine2, buf, bytes, start, (i + 1), bps)
	}) })

	fat16_write_data_sector! : Machine.Machine, Fat16.Fat16Volume, I64, Fat16.Fat16Source, I64 => (Machine.Machine, I64)
	fat16_write_data_sector! = |machine, vol, sector, bytes, start| ({
		(machine1, h) = Machine.mark(machine)
		({
			(machine2, buf) = Machine.block_read_sector!(machine1, sector)
			(machine3, r) = fat16_put_data_sector!(machine2, vol, sector, bytes, start, buf)
			(machine3, fat16_drop_to(h, r))
		})
	})

	fat16_drop_to : I64, I64 -> I64
	fat16_drop_to = |_h, r| ({
		_z = 0
		r
	})

	fat16_put_data_sector! : Machine.Machine, Fat16.Fat16Volume, I64, Fat16.Fat16Source, I64, I64 => (Machine.Machine, I64)
	fat16_put_data_sector! = |machine, vol, sector, bytes, start, buf| ({
		(machine1, _f) = fat16_fill_sector!(machine, buf, bytes, start, 0, vol.vol_bytes_per_sector)
		Machine.block_write_sector!(machine1, sector, buf)
	})

	fat16_write_cluster! : Machine.Machine, Fat16.Fat16Volume, I64, Fat16.Fat16Source, I64, I64 => (Machine.Machine, I64)
	fat16_write_cluster! = |machine, vol, cluster, bytes, start, i| (if (i >= vol.vol_sectors_per_cluster) { (machine, 0) } else { ({
		sec : I64
		sec = (fat16_cluster_sector(vol, cluster) + i)
		at : I64
		at = (start + (i * vol.vol_bytes_per_sector))
		({
			(machine1, _w) = fat16_write_data_sector!(machine, vol, sec, bytes, at)
			fat16_write_cluster!(machine1, vol, cluster, bytes, start, (i + 1))
		})
	}) })

	fat16_write_chain! : Machine.Machine, Fat16.Fat16Volume, I64, Fat16.Fat16Source, I64 => (Machine.Machine, I64)
	fat16_write_chain! = |machine, vol, cluster, bytes, start| ({
		(machine1, _w) = fat16_write_cluster!(machine, vol, cluster, bytes, start, 0)
		fat16_extend_chain!(machine1, vol, cluster, bytes, (start + fat16_bytes_per_cluster(vol)))
	})

	fat16_extend_chain! : Machine.Machine, Fat16.Fat16Volume, I64, Fat16.Fat16Source, I64 => (Machine.Machine, I64)
	fat16_extend_chain! = |machine, vol, prev, bytes, start| (if (start >= bytes.fs_len) { (machine, 1) } else { ({
		(machine1, next) = fat16_alloc_cluster_from!(machine, vol, prev)
		fat16_link_and_continue!(machine1, vol, prev, next, bytes, start)
	}) })

	fat16_link_and_continue! : Machine.Machine, Fat16.Fat16Volume, I64, I64, Fat16.Fat16Source, I64 => (Machine.Machine, I64)
	fat16_link_and_continue! = |machine, vol, prev, next, bytes, start| (if (next == 0) { (machine, 0) } else { ({
		(machine1, _l) = fat16_write_fat_entry!(machine, vol, prev, next)
		fat16_write_chain!(machine1, vol, next, bytes, start)
	}) })

	fat16_name_byte : CceText, I64 -> I64
	fat16_name_byte = |s, i| (if (i >= CceText.len(s)) { 32 } else { CCE.to_unicode(CceChar.code(CceText.char_at(s, i))) })

	fat16_poke_83! : Machine.Machine, I64, I64, CceText, CceText => (Machine.Machine, I64)
	fat16_poke_83! = |machine, buf, off, base, ext| ({
		(machine1, _b) = fat16_poke_run!(machine, buf, off, base, 0, 8)
		fat16_poke_run!(machine1, buf, (off + 8), ext, 0, 3)
	})

	fat16_poke_run! : Machine.Machine, I64, I64, CceText, I64, I64 => (Machine.Machine, I64)
	fat16_poke_run! = |machine, buf, off, s, i, n| (if (i >= n) { (machine, 0) } else { ({
		(machine1, _w) = Machine.store!(machine, buf, (off + i), fat16_name_byte(s, i), 1)
		fat16_poke_run!(machine1, buf, off, s, (i + 1), n)
	}) })

	fat16_name_fits_83 : CceText -> Bool
	fat16_name_fits_83 = |name| ((CceText.len(fat16_base_of(name)) <= 8) and (CceText.len(fat16_ext_of(name)) <= 3))

	fat16_short_form : CceText -> CceText
	fat16_short_form = |name| ({
		b : CceText
		b = fat16_base_of(name)
		e : CceText
		e = fat16_ext_of(name)
		(if (CceText.len(e) == 0) { b } else { CceText.concat(CceText.concat(b, "."), e) })
	})

	fat16_needs_long : CceText -> Bool
	fat16_needs_long = |name| (if (fat16_name_fits_83(name) == False) { True } else { (fat16_short_form(name) != name) })

	fat16_name_writable : CceText -> Bool
	fat16_name_writable = |name| ({
		n : I64
		n = CceText.len(name)
		(if (n == 0) { False } else { (if (n > fat16_lfn_max_name) { False } else { fat16_lfn_name_spellable(name, 0, n) }) })
	})

	fat16_path_writable : CceText -> Bool
	fat16_path_writable = |path| fat16_parts_writable(fat16_split_path(path), 0)

	fat16_parts_writable : List(CceText), I64 -> Bool
	fat16_parts_writable = |parts, i| (if (i >= U64.to_i64_wrap(List.len(parts))) { True } else { (if (fat16_name_writable((List.get(parts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) == False) { False } else { fat16_parts_writable(parts, (i + 1)) }) })

	fat16_base_of : CceText -> CceText
	fat16_base_of = |name| ({
		dot : I64
		dot = StringUtils.text_index_of(name, ".")
		(if (dot < 0) { fat16_upper(name) } else { fat16_upper(StringUtils.text_substring(name, 0, dot)) })
	})

	fat16_ext_of : CceText -> CceText
	fat16_ext_of = |name| ({
		dot : I64
		dot = StringUtils.text_index_of(name, ".")
		(if (dot < 0) { "" } else { fat16_upper(StringUtils.text_substring(name, (dot + 1), ((CceText.len(name) - dot) - 1))) })
	})

	fat16_poke_dir_entry! : Machine.Machine, I64, I64, CceText, I64, I64, I64 => (Machine.Machine, I64)
	fat16_poke_dir_entry! = |machine, buf, off, name, attr, cluster, size| ({
		(machine1, _n) = fat16_poke_83!(machine, buf, off, fat16_base_of(name), fat16_ext_of(name))
		(machine2, _a) = Machine.store!(machine1, buf, (off + 11), attr, 1)
		(machine3, _z) = fat16_zero_run!(machine2, buf, (off + 12), 0, 14)
		(machine4, _c) = fat16_write_u16!(machine3, buf, (off + 26), cluster)
		(machine5, _s1) = fat16_write_u16!(machine4, buf, (off + 28), I64.bitwise_and(size, 65535))
		fat16_write_u16!(machine5, buf, (off + 30), I64.bitwise_and(I64.shr_zf_wrap(size, I64.to_u8_wrap(16)), 65535))
	})

	fat16_zero_run! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_zero_run! = |machine, buf, off, i, n| (if (i >= n) { (machine, 0) } else { ({
		(machine1, _w) = Machine.store!(machine, buf, (off + i), 0, 1)
		fat16_zero_run!(machine1, buf, off, (i + 1), n)
	}) })

	fat16_root_sector_count : Fat16.Fat16Volume -> I64
	fat16_root_sector_count = |vol| I64.div_trunc_by((((vol.vol_root_entry_count * 32) + vol.vol_bytes_per_sector) - 1), vol.vol_bytes_per_sector)

	fat16_dir_chain_ends_at : I64 -> Bool
	fat16_dir_chain_ends_at = |c| (if (c < 2) { True } else { fat16_is_end(c) })

	fat16_last_cluster_of! : Machine.Machine, Fat16.Fat16Volume, I64 => (Machine.Machine, I64)
	fat16_last_cluster_of! = |machine, vol, cluster| ({
		(machine1, next) = fat16_next_cluster!(machine, vol, cluster)
		(if fat16_dir_chain_ends_at(next) { (machine1, cluster) } else { fat16_last_cluster_of!(machine1, vol, next) })
	})

	fat16_grow_dir_at! : Machine.Machine, Fat16.Fat16Volume, I64 => (Machine.Machine, I64)
	fat16_grow_dir_at! = |machine, vol, last| ({
		(machine1, fresh) = fat16_alloc_cluster!(machine, vol)
		fat16_grow_dir_with!(machine1, vol, last, fresh)
	})

	fat16_grow_dir_with! : Machine.Machine, Fat16.Fat16Volume, I64, I64 => (Machine.Machine, I64)
	fat16_grow_dir_with! = |machine, vol, last, fresh| (if (fresh == 0) { (machine, (0 - 1)) } else { ({
		(machine1, _z) = fat16_zero_dir_cluster!(machine, vol, fresh, 0)
		fat16_link_grown_dir!(machine1, vol, last, fresh)
	}) })

	fat16_zero_dir_cluster! : Machine.Machine, Fat16.Fat16Volume, I64, I64 => (Machine.Machine, I64)
	fat16_zero_dir_cluster! = |machine, vol, cluster, i| (if (i >= vol.vol_sectors_per_cluster) { (machine, 0) } else { ({
		(machine1, _w) = fat16_write_data_sector!(machine, vol, (fat16_cluster_sector(vol, cluster) + i), fat16_src_empty, 0)
		fat16_zero_dir_cluster!(machine1, vol, cluster, (i + 1))
	}) })

	fat16_link_grown_dir! : Machine.Machine, Fat16.Fat16Volume, I64, I64 => (Machine.Machine, I64)
	fat16_link_grown_dir! = |machine, vol, last, fresh| ({
		(machine1, l) = fat16_write_fat_entry!(machine, vol, last, fresh)
		(machine1, (if (l == 0) { (fat16_cluster_sector(vol, fresh) * 512) } else { (0 - 1) }))
	})

	fat16_create_file! : Machine.Machine, Fat16.Fat16Volume, CceText, Fat16.Fat16Source => (Machine.Machine, Bool)
	fat16_create_file! = |machine, vol, name, bytes| ({
		(machine1, machine__1) = fat16_scope_admits!(machine, name)
		(if (machine__1 == False) { (machine1, False) } else { (if (fat16_path_writable(name) == False) { (machine1, False) } else { (if (fat16_vol_is_usable(vol) == False) { (machine1, False) } else { (if StringUtils.text_contains(name, "/") { fat16_create_in_subdir!(machine1, vol, name, bytes) } else { ({
		(machine2, found) = fat16_find_in_root!(machine1, vol, name)
		fat16_create_or_replace!(machine2, vol, name, bytes, found)
	}) }) }) }) })
	})

	fat16_create_or_replace! : Machine.Machine, Fat16.Fat16Volume, CceText, Fat16.Fat16Source, Maybe.Maybe(Fat16.Fat16DirEntry) => (Machine.Machine, Bool)
	fat16_create_or_replace! = |machine, vol, name, bytes, found| (match found {
		Just(e) => fat16_replace_in_root!(machine, vol, name, bytes, e)
		None => fat16_create_fresh_in_root!(machine, vol, name, bytes)
	})

	fat16_replace_in_root! : Machine.Machine, Fat16.Fat16Volume, CceText, Fat16.Fat16Source, Fat16.Fat16DirEntry => (Machine.Machine, Bool)
	fat16_replace_in_root! = |machine, vol, name, bytes, e| ({
		(machine1, slot) = fat16_find_name_slot!(machine, vol, e.de_name)
		fat16_replace_at_slot!(machine1, vol, name, bytes, slot, e.de_cluster)
	})

	fat16_replace_at_slot! : Machine.Machine, Fat16.Fat16Volume, CceText, Fat16.Fat16Source, I64, I64 => (Machine.Machine, Bool)
	fat16_replace_at_slot! = |machine, vol, name, bytes, slot, old| (if (slot < 0) { (machine, False) } else { ({
		(machine1, _f) = fat16_free_chain!(machine, vol, old)
		fat16_erase_then_create_root!(machine1, vol, name, bytes, slot)
	}) })

	fat16_erase_then_create_root! : Machine.Machine, Fat16.Fat16Volume, CceText, Fat16.Fat16Source, I64 => (Machine.Machine, Bool)
	fat16_erase_then_create_root! = |machine, vol, name, bytes, slot| ({
		(machine1, _d) = fat16_erase_entry!(machine, vol, slot)
		fat16_create_fresh_in_root!(machine1, vol, name, bytes)
	})

	fat16_create_fresh_in_root! : Machine.Machine, Fat16.Fat16Volume, CceText, Fat16.Fat16Source => (Machine.Machine, Bool)
	fat16_create_fresh_in_root! = |machine, vol, name, bytes| ({
		(machine1, short) = fat16_pick_alias_root!(machine, vol, name, 1)
		fat16_place_in_root!(machine1, vol, name, short, bytes)
	})

	fat16_place_in_root! : Machine.Machine, Fat16.Fat16Volume, CceText, CceText, Fat16.Fat16Source => (Machine.Machine, Bool)
	fat16_place_in_root! = |machine, vol, name, short, bytes| (if (CceText.len(short) == 0) { (machine, False) } else { ({
		(machine1, slot) = fat16_find_run_in_root!(machine, vol, fat16_slots_for(name))
		fat16_create_at_run!(machine1, vol, name, short, bytes, slot)
	}) })

	fat16_pick_alias_root! : Machine.Machine, Fat16.Fat16Volume, CceText, I64 => (Machine.Machine, CceText)
	fat16_pick_alias_root! = |machine, vol, name, n| (if (fat16_needs_long(name) == False) { (machine, name) } else { (if (n > fat16_alias_max_tries) { (machine, "") } else { ({
		cand : CceText
		cand = fat16_alias_of(name, n)
		({
			(machine1, taken) = fat16_find_name_slot!(machine, vol, cand)
			(if (taken >= 0) { fat16_pick_alias_root!(machine1, vol, name, (n + 1)) } else { (machine1, cand) })
		})
	}) }) })

	fat16_pick_alias_dir! : Machine.Machine, Fat16.Fat16Volume, I64, CceText, I64 => (Machine.Machine, CceText)
	fat16_pick_alias_dir! = |machine, vol, cluster, name, n| (if (fat16_needs_long(name) == False) { (machine, name) } else { (if (n > fat16_alias_max_tries) { (machine, "") } else { ({
		cand : CceText
		cand = fat16_alias_of(name, n)
		({
			(machine1, taken) = fat16_find_name_slot_in_dir!(machine, vol, cluster, cand)
			(if (taken >= 0) { fat16_pick_alias_dir!(machine1, vol, cluster, name, (n + 1)) } else { (machine1, cand) })
		})
	}) }) })

	fat16_free_chain! : Machine.Machine, Fat16.Fat16Volume, I64 => (Machine.Machine, I64)
	fat16_free_chain! = |machine, vol, cluster| fat16_free_chain_walk!(machine, vol, cluster, cluster, 1, 0)

	fat16_free_chain_walk! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_free_chain_walk! = |machine, vol, cluster, saved, power, steps| (if (cluster < 2) { (machine, 0) } else { (if fat16_is_end(cluster) { (machine, 0) } else { ({
		(machine1, machine__1) = fat16_next_cluster!(machine, vol, cluster)
		fat16_free_chain_from!(machine1, vol, cluster, machine__1, saved, power, steps)
	}) }) })

	fat16_free_chain_from! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_free_chain_from! = |machine, vol, cluster, nxt, saved, power, steps| ({
		(machine1, _w) = fat16_write_fat_entry!(machine, vol, cluster, 0)
		(if (nxt == saved) { (machine1, 0) } else { (if ((steps + 1) == power) { fat16_free_chain_walk!(machine1, vol, nxt, nxt, (power * 2), 0) } else { fat16_free_chain_walk!(machine1, vol, nxt, saved, power, (steps + 1)) }) })
	})

	fat16_find_name_slot! : Machine.Machine, Fat16.Fat16Volume, CceText => (Machine.Machine, I64)
	fat16_find_name_slot! = |machine, vol, name| fat16_name_slot_sectors!(machine, vol, name, vol.vol_root_start, fat16_root_sector_count(vol), 0)

	fat16_name_slot_sectors! : Machine.Machine, Fat16.Fat16Volume, CceText, I64, I64, I64 => (Machine.Machine, I64)
	fat16_name_slot_sectors! = |machine, vol, name, sector, remaining, checked| (if (remaining == 0) { (machine, (0 - 1)) } else { (if (checked >= vol.vol_root_entry_count) { (machine, (0 - 1)) } else { ({
		(machine1, buf) = Machine.block_read_sector!(machine, sector)
		fat16_name_slot_step!(machine1, vol, name, sector, remaining, checked, buf)
	}) }) })

	fat16_name_slot_step! : Machine.Machine, Fat16.Fat16Volume, CceText, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_name_slot_step! = |machine, vol, name, sector, remaining, checked, buf| ({
		eps : I64
		eps = I64.div_trunc_by(vol.vol_bytes_per_sector, 32)
		(machine1, found) = fat16_name_slot_in_sector!(machine, buf, name, 0, eps)
		(if (found >= 0) { (machine1, ((sector * 512) + found)) } else { fat16_name_slot_sectors!(machine1, vol, name, (sector + 1), (remaining - 1), (checked + eps)) })
	})

	fat16_name_slot_in_sector! : Machine.Machine, I64, CceText, I64, I64 => (Machine.Machine, I64)
	fat16_name_slot_in_sector! = |machine, buf, name, i, count| (if (i >= count) { (machine, (0 - 1)) } else { ({
		off : I64
		off = (i * 32)
		({
			(machine1, machine__1) = fat16_is_free_entry!(machine, buf, off)
			(if machine__1 { fat16_name_slot_in_sector!(machine1, buf, name, (i + 1), count) } else { ({
			(machine2, machine__2) = fat16_is_lfn_entry!(machine1, buf, off)
			(if machine__2 { fat16_name_slot_in_sector!(machine2, buf, name, (i + 1), count) } else { ({
			(machine3, machine__3) = fat16_is_volume_label!(machine2, buf, off)
			(if machine__3 { fat16_name_slot_in_sector!(machine3, buf, name, (i + 1), count) } else { ({
			(machine4, machine__4) = fat16_entry_name_at!(machine3, buf, off)
			(if fat16_name_matches(machine__4, name) { (machine4, off) } else { fat16_name_slot_in_sector!(machine4, buf, name, (i + 1), count) })
		}) })
		}) })
		}) })
		})
	}) })

	fat16_entry_name_at! : Machine.Machine, I64, I64 => (Machine.Machine, CceText)
	fat16_entry_name_at! = |machine, buf, off| ({
		(machine1, machine__1) = fat16_read_dir_entry!(machine, buf, off)
		(machine1, machine__1.de_name)
	})

	fat16_find_name_slot_in_dir! : Machine.Machine, Fat16.Fat16Volume, I64, CceText => (Machine.Machine, I64)
	fat16_find_name_slot_in_dir! = |machine, vol, cluster, name| fat16_find_name_slot_walk!(machine, vol, cluster, name, cluster, 1, 0)

	fat16_find_name_slot_walk! : Machine.Machine, Fat16.Fat16Volume, I64, CceText, I64, I64, I64 => (Machine.Machine, I64)
	fat16_find_name_slot_walk! = |machine, vol, cluster, name, saved, power, steps| (if fat16_is_end(cluster) { (machine, (0 - 1)) } else { ({
		(machine1, found) = fat16_name_slot_dir_sectors!(machine, vol, name, fat16_cluster_sector(vol, cluster), vol.vol_sectors_per_cluster)
		fat16_name_slot_or_next!(machine1, vol, cluster, name, found, saved, power, steps)
	}) })

	fat16_name_slot_or_next! : Machine.Machine, Fat16.Fat16Volume, I64, CceText, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_name_slot_or_next! = |machine, vol, cluster, name, found, saved, power, steps| ({
		(if (found >= 0) { (machine, found) } else { ({
			(machine1, nxt) = fat16_next_cluster!(machine, vol, cluster)
			(if (nxt == saved) { (machine1, (0 - 1)) } else { (if ((steps + 1) == power) { fat16_find_name_slot_walk!(machine1, vol, nxt, name, nxt, (power * 2), 0) } else { fat16_find_name_slot_walk!(machine1, vol, nxt, name, saved, power, (steps + 1)) }) })
		}) })
	})

	fat16_name_slot_dir_sectors! : Machine.Machine, Fat16.Fat16Volume, CceText, I64, I64 => (Machine.Machine, I64)
	fat16_name_slot_dir_sectors! = |machine, vol, name, sector, remaining| (if (remaining == 0) { (machine, (0 - 1)) } else { ({
		(machine1, buf) = Machine.block_read_sector!(machine, sector)
		fat16_name_slot_dir_step!(machine1, vol, name, sector, remaining, buf)
	}) })

	fat16_name_slot_dir_step! : Machine.Machine, Fat16.Fat16Volume, CceText, I64, I64, I64 => (Machine.Machine, I64)
	fat16_name_slot_dir_step! = |machine, vol, name, sector, remaining, buf| ({
		(machine1, found) = fat16_name_slot_in_sector!(machine, buf, name, 0, I64.div_trunc_by(vol.vol_bytes_per_sector, 32))
		(if (found >= 0) { (machine1, ((sector * 512) + found)) } else { fat16_name_slot_dir_sectors!(machine1, vol, name, (sector + 1), (remaining - 1)) })
	})

	fat16_create_in_subdir! : Machine.Machine, Fat16.Fat16Volume, CceText, Fat16.Fat16Source => (Machine.Machine, Bool)
	fat16_create_in_subdir! = |machine, vol, path, bytes| ({
		parts : List(CceText)
		parts = fat16_split_path(path)
		n : I64
		n = U64.to_i64_wrap(List.len(parts))
		(if (n < 2) { (machine, False) } else { ({
			(machine1, machine__1) = fat16_walk_path!(machine, vol, parts, 0, (n - 1))
			(match machine__1 {
			None => (machine1, False)
			Just(dir) => fat16_create_in_dir_entry!(machine1, vol, dir, (List.get(parts, I64.to_u64_wrap((n - 1))) ?? crash("list-at out of range")), bytes)
		})
		}) })
	})

	fat16_create_in_dir_entry! : Machine.Machine, Fat16.Fat16Volume, Fat16.Fat16DirEntry, CceText, Fat16.Fat16Source => (Machine.Machine, Bool)
	fat16_create_in_dir_entry! = |machine, vol, dir, leaf, bytes| (if (I64.bitwise_and(dir.de_attr, 16) == 16) { fat16_create_in_cluster_dir!(machine, vol, dir.de_cluster, leaf, bytes) } else { (machine, False) })

	fat16_create_in_cluster_dir! : Machine.Machine, Fat16.Fat16Volume, I64, CceText, Fat16.Fat16Source => (Machine.Machine, Bool)
	fat16_create_in_cluster_dir! = |machine, vol, cluster, leaf, bytes| ({
		(machine1, found) = fat16_find_in_cluster_dir!(machine, vol, cluster, leaf)
		fat16_create_or_replace_in_dir!(machine1, vol, cluster, leaf, bytes, found)
	})

	fat16_create_or_replace_in_dir! : Machine.Machine, Fat16.Fat16Volume, I64, CceText, Fat16.Fat16Source, Maybe.Maybe(Fat16.Fat16DirEntry) => (Machine.Machine, Bool)
	fat16_create_or_replace_in_dir! = |machine, vol, cluster, leaf, bytes, found| (match found {
		Just(e) => fat16_replace_in_dir!(machine, vol, cluster, leaf, bytes, e)
		None => fat16_create_fresh_in_dir!(machine, vol, cluster, leaf, bytes)
	})

	fat16_replace_in_dir! : Machine.Machine, Fat16.Fat16Volume, I64, CceText, Fat16.Fat16Source, Fat16.Fat16DirEntry => (Machine.Machine, Bool)
	fat16_replace_in_dir! = |machine, vol, cluster, leaf, bytes, e| ({
		(machine1, slot) = fat16_find_name_slot_in_dir!(machine, vol, cluster, e.de_name)
		fat16_replace_at_slot_in_dir!(machine1, vol, cluster, leaf, bytes, slot, e.de_cluster)
	})

	fat16_replace_at_slot_in_dir! : Machine.Machine, Fat16.Fat16Volume, I64, CceText, Fat16.Fat16Source, I64, I64 => (Machine.Machine, Bool)
	fat16_replace_at_slot_in_dir! = |machine, vol, cluster, leaf, bytes, slot, old| (if (slot < 0) { (machine, False) } else { ({
		(machine1, _f) = fat16_free_chain!(machine, vol, old)
		fat16_erase_then_create_dir!(machine1, vol, cluster, leaf, bytes, slot)
	}) })

	fat16_erase_then_create_dir! : Machine.Machine, Fat16.Fat16Volume, I64, CceText, Fat16.Fat16Source, I64 => (Machine.Machine, Bool)
	fat16_erase_then_create_dir! = |machine, vol, cluster, leaf, bytes, slot| ({
		(machine1, _d) = fat16_erase_entry!(machine, vol, slot)
		fat16_create_fresh_in_dir!(machine1, vol, cluster, leaf, bytes)
	})

	fat16_create_fresh_in_dir! : Machine.Machine, Fat16.Fat16Volume, I64, CceText, Fat16.Fat16Source => (Machine.Machine, Bool)
	fat16_create_fresh_in_dir! = |machine, vol, cluster, leaf, bytes| ({
		(machine1, short) = fat16_pick_alias_dir!(machine, vol, cluster, leaf, 1)
		fat16_place_in_dir!(machine1, vol, cluster, leaf, short, bytes)
	})

	fat16_place_in_dir! : Machine.Machine, Fat16.Fat16Volume, I64, CceText, CceText, Fat16.Fat16Source => (Machine.Machine, Bool)
	fat16_place_in_dir! = |machine, vol, cluster, leaf, short, bytes| (if (CceText.len(short) == 0) { (machine, False) } else { ({
		(machine1, slot) = fat16_find_or_grow_run_in_dir!(machine, vol, cluster, fat16_slots_for(leaf))
		fat16_create_at_run!(machine1, vol, leaf, short, bytes, slot)
	}) })

	fat16_create_at_run! : Machine.Machine, Fat16.Fat16Volume, CceText, CceText, Fat16.Fat16Source, I64 => (Machine.Machine, Bool)
	fat16_create_at_run! = |machine, vol, name, short, bytes, slot| (if (slot < 0) { (machine, False) } else { ({
		(machine1, first) = fat16_alloc_cluster!(machine, vol)
		fat16_create_with_cluster!(machine1, vol, name, short, bytes, slot, first)
	}) })

	fat16_create_with_cluster! : Machine.Machine, Fat16.Fat16Volume, CceText, CceText, Fat16.Fat16Source, I64, I64 => (Machine.Machine, Bool)
	fat16_create_with_cluster! = |machine, vol, name, short, bytes, slot, first| (if (first == 0) { (machine, False) } else { ({
		(machine1, w) = fat16_write_chain!(machine, vol, first, bytes, 0)
		fat16_commit_entry!(machine1, vol, name, short, bytes, slot, first, w)
	}) })

	fat16_commit_entry! : Machine.Machine, Fat16.Fat16Volume, CceText, CceText, Fat16.Fat16Source, I64, I64, I64 => (Machine.Machine, Bool)
	fat16_commit_entry! = |machine, vol, name, short, bytes, slot, first, ok| (if (ok == 0) { (machine, False) } else { ({
		(machine1, r) = fat16_write_run!(machine, vol, name, short, slot, fat16_records_for(name))
		fat16_commit_short_if!(machine1, short, bytes, slot, first, fat16_records_for(name), r)
	}) })

	fat16_commit_short_if! : Machine.Machine, CceText, Fat16.Fat16Source, I64, I64, I64, I64 => (Machine.Machine, Bool)
	fat16_commit_short_if! = |machine, short, bytes, slot, first, records, r| (if (r != 0) { (machine, False) } else { fat16_commit_short!(machine, short, bytes, slot, first, records) })

	fat16_commit_short! : Machine.Machine, CceText, Fat16.Fat16Source, I64, I64, I64 => (Machine.Machine, Bool)
	fat16_commit_short! = |machine, short, bytes, slot, first, records| ({
		(machine1, buf) = Machine.block_read_sector!(machine, I64.div_trunc_by((slot + (records * 32)), 512))
		fat16_put_entry_and_write!(machine1, short, bytes, slot, first, records, buf)
	})

	fat16_put_entry_and_write! : Machine.Machine, CceText, Fat16.Fat16Source, I64, I64, I64, I64 => (Machine.Machine, Bool)
	fat16_put_entry_and_write! = |machine, short, bytes, slot, first, records, buf| ({
		at : I64
		at = (slot + (records * 32))
		(machine1, _p) = fat16_poke_dir_entry!(machine, buf, Prelude.int_mod(at, 512), short, 32, first, bytes.fs_len)
		({
			(machine2, s) = Machine.block_write_sector!(machine1, I64.div_trunc_by(at, 512), buf)
			(machine2, (if (s == 0) { True } else { False }))
		})
	})

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

	fat16_lfn_attr : I64
	fat16_lfn_attr = 15

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

	fat16_lfn_records_needed : I64 -> I64
	fat16_lfn_records_needed = |n| I64.div_trunc_by(((n + fat16_lfn_per_record) - 1), fat16_lfn_per_record)

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

	fat16_lfn_unit_of : CceText, I64 -> I64
	fat16_lfn_unit_of = |name, i| ({
		c : I64
		c = CceChar.code(CceText.char_at(name, i))
		u : I64
		u = CCE.to_unicode(c)
		(if (CCE.from_unicode(u) == c) { u } else { (-1) })
	})

	fat16_lfn_name_spellable : CceText, I64, I64 -> Bool
	fat16_lfn_name_spellable = |name, i, n| (if (i >= n) { True } else { (if (fat16_lfn_unit_of(name, i) < 0) { False } else { fat16_lfn_name_spellable(name, (i + 1), n) }) })

	fat16_poke_lfn_record! : Machine.Machine, I64, I64, CceText, I64, I64, Bool => (Machine.Machine, I64)
	fat16_poke_lfn_record! = |machine, buf, off, name, seq, sum, last| ({
		(machine1, _o) = Machine.store!(machine, buf, off, (if last { I64.bitwise_or(seq, fat16_lfn_last) } else { seq }), 1)
		(machine2, _a) = Machine.store!(machine1, buf, (off + 11), fat16_lfn_attr, 1)
		(machine3, _t) = Machine.store!(machine2, buf, (off + 12), 0, 1)
		(machine4, _s) = Machine.store!(machine3, buf, (off + 13), sum, 1)
		(machine5, _c) = fat16_write_u16!(machine4, buf, (off + 26), 0)
		fat16_poke_lfn_units!(machine5, buf, off, name, ((seq - 1) * fat16_lfn_per_record), 0)
	})

	fat16_poke_lfn_units! : Machine.Machine, I64, I64, CceText, I64, I64 => (Machine.Machine, I64)
	fat16_poke_lfn_units! = |machine, buf, off, name, base, k| (if (k >= fat16_lfn_per_record) { (machine, 0) } else { ({
		i : I64
		i = (base + k)
		n : I64
		n = CceText.len(name)
		u : I64
		u = (if (i < n) { fat16_lfn_unit_of(name, i) } else { (if (i == n) { 0 } else { 65535 }) })
		(machine1, _w) = fat16_write_u16!(machine, buf, (off + fat16_lfn_slot_offset(k)), u)
		fat16_poke_lfn_units!(machine1, buf, off, name, base, (k + 1))
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

	fat16_alias_max_tries : I64
	fat16_alias_max_tries = 99

	fat16_alias_byte_ok : I64 -> Bool
	fat16_alias_byte_ok = |u| (if (u >= 65) { (u <= 90) } else { (if (u >= 48) { (u <= 57) } else { (if (u == 95) { True } else { (if (u == 45) { True } else { (if (u == 126) { True } else { False }) }) }) }) })

	fat16_alias_char : CceText, I64 -> CceText
	fat16_alias_char = |s, i| ({
		u : I64
		u = CCE.to_unicode(CceChar.code(CceText.char_at(s, i)))
		up : I64
		up = (if (u >= 97) { (if (u <= 122) { (u - 32) } else { u }) } else { u })
		(if fat16_alias_byte_ok(up) { CceText.char_encode(CceChar.of_code(CCE.from_unicode(up))) } else { "_" })
	})

	fat16_alias_chars : CceText, I64, I64, CceText -> CceText
	fat16_alias_chars = |s, i, upto, acc| (if (i >= upto) { acc } else { ({
		piece : CceText
		piece = fat16_alias_char(s, i)
		fat16_alias_chars(s, (i + 1), upto, CceText.concat(acc, piece))
	}) })

	fat16_alias_base_len : CceText -> I64
	fat16_alias_base_len = |name| ({
		dot : I64
		dot = StringUtils.text_index_of(name, ".")
		(if (dot < 0) { CceText.len(name) } else { dot })
	})

	fat16_alias_ext_start : CceText -> I64
	fat16_alias_ext_start = |name| ({
		dot : I64
		dot = StringUtils.text_index_of(name, ".")
		(if (dot < 0) { CceText.len(name) } else { (dot + 1) })
	})

	fat16_alias_of : CceText, I64 -> CceText
	fat16_alias_of = |name, n| ({
		tag : CceText
		tag = CceText.concat("~", CceText.show_int(n))
		stem : CceText
		stem = fat16_alias_chars(name, 0, I64.min((8 - CceText.len(tag)), fat16_alias_base_len(name)), "")
		es : I64
		es = fat16_alias_ext_start(name)
		el : I64
		el = I64.min(3, (CceText.len(name) - es))
		(if (el <= 0) { CceText.concat(stem, tag) } else { CceText.concat(CceText.concat(CceText.concat(stem, tag), "."), fat16_alias_chars(name, es, (es + el), "")) })
	})

	fat16_short_checksum_of : CceText -> I64
	fat16_short_checksum_of = |short| fat16_name_checksum_step(fat16_base_of(short), fat16_ext_of(short), 0, 0)

	fat16_name_checksum_step : CceText, CceText, I64, I64 -> I64
	fat16_name_checksum_step = |base, ext, i, sum| (if (i >= 11) { sum } else { ({
		b : I64
		b = (if (i < 8) { fat16_name_byte(base, i) } else { fat16_name_byte(ext, (i - 8)) })
		next : I64
		next = fat16_checksum_mix(sum, b)
		fat16_name_checksum_step(base, ext, (i + 1), next)
	}) })

	fat16_run_in_sector! : Machine.Machine, I64, I64, I64, I64, I64 => (Machine.Machine, Fat16.Fat16Run)
	fat16_run_in_sector! = |machine, buf, i, n, need, streak| (if (i >= n) { (machine, Fat16.Fat16Run.{ rn_found: False, rn_at: 0, rn_streak: streak }) } else { ({
		(machine1, machine__1) = fat16_is_free_entry!(machine, buf, (i * 32))
		(if (machine__1 == False) { fat16_run_in_sector!(machine1, buf, (i + 1), n, need, 0) } else { (if ((streak + 1) >= need) { (machine1, Fat16.Fat16Run.{ rn_found: True, rn_at: ((i + 1) - need), rn_streak: need }) } else { fat16_run_in_sector!(machine1, buf, (i + 1), n, need, (streak + 1)) }) })
	}) })

	fat16_find_run_in_root! : Machine.Machine, Fat16.Fat16Volume, I64 => (Machine.Machine, I64)
	fat16_find_run_in_root! = |machine, vol, need| fat16_run_root_sectors!(machine, vol, need, vol.vol_root_start, fat16_root_sector_count(vol), 0)

	fat16_run_root_sectors! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_run_root_sectors! = |machine, vol, need, sector, remaining, streak| (if (remaining == 0) { (machine, (0 - 1)) } else { ({
		(machine1, buf) = Machine.block_read_sector!(machine, sector)
		fat16_run_root_step!(machine1, vol, need, sector, remaining, streak, buf)
	}) })

	fat16_run_root_step! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_run_root_step! = |machine, vol, need, sector, remaining, streak, buf| ({
		eps : I64
		eps = I64.div_trunc_by(vol.vol_bytes_per_sector, 32)
		(machine1, r) = fat16_run_in_sector!(machine, buf, 0, eps, need, streak)
		(if r.rn_found { (machine1, ((sector * 512) + (r.rn_at * 32))) } else { fat16_run_root_sectors!(machine1, vol, need, (sector + 1), (remaining - 1), r.rn_streak) })
	})

	fat16_find_run_in_dir! : Machine.Machine, Fat16.Fat16Volume, I64, I64 => (Machine.Machine, I64)
	fat16_find_run_in_dir! = |machine, vol, cluster, need| fat16_run_dir_walk!(machine, vol, cluster, need, cluster, 1, 0)

	fat16_run_dir_walk! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_run_dir_walk! = |machine, vol, cluster, need, saved, power, steps| (if fat16_is_end(cluster) { (machine, (0 - 1)) } else { ({
		(machine1, found) = fat16_run_dir_sectors!(machine, vol, need, fat16_cluster_sector(vol, cluster), vol.vol_sectors_per_cluster, 0)
		fat16_run_dir_or_next!(machine1, vol, cluster, need, found, saved, power, steps)
	}) })

	fat16_run_dir_or_next! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_run_dir_or_next! = |machine, vol, cluster, need, found, saved, power, steps| ({
		(if (found >= 0) { (machine, found) } else { ({
			(machine1, nxt) = fat16_next_cluster!(machine, vol, cluster)
			(if (nxt == saved) { (machine1, (0 - 1)) } else { (if ((steps + 1) == power) { fat16_run_dir_walk!(machine1, vol, nxt, need, nxt, (power * 2), 0) } else { fat16_run_dir_walk!(machine1, vol, nxt, need, saved, power, (steps + 1)) }) })
		}) })
	})

	fat16_run_dir_sectors! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_run_dir_sectors! = |machine, vol, need, sector, remaining, streak| (if (remaining == 0) { (machine, (0 - 1)) } else { ({
		(machine1, buf) = Machine.block_read_sector!(machine, sector)
		fat16_run_dir_step!(machine1, vol, need, sector, remaining, streak, buf)
	}) })

	fat16_run_dir_step! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_run_dir_step! = |machine, vol, need, sector, remaining, streak, buf| ({
		eps : I64
		eps = I64.div_trunc_by(vol.vol_bytes_per_sector, 32)
		(machine1, r) = fat16_run_in_sector!(machine, buf, 0, eps, need, streak)
		(if r.rn_found { (machine1, ((sector * 512) + (r.rn_at * 32))) } else { fat16_run_dir_sectors!(machine1, vol, need, (sector + 1), (remaining - 1), r.rn_streak) })
	})

	fat16_find_or_grow_run_in_dir! : Machine.Machine, Fat16.Fat16Volume, I64, I64 => (Machine.Machine, I64)
	fat16_find_or_grow_run_in_dir! = |machine, vol, cluster, need| ({
		(machine1, found) = fat16_find_run_in_dir!(machine, vol, cluster, need)
		fat16_run_or_grow!(machine1, vol, cluster, need, found)
	})

	fat16_run_or_grow! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64 => (Machine.Machine, I64)
	fat16_run_or_grow! = |machine, vol, cluster, need, found| (if (found >= 0) { (machine, found) } else { (if ((need * 32) > fat16_bytes_per_cluster(vol)) { (machine, (0 - 1)) } else { ({
		(machine1, last) = fat16_last_cluster_of!(machine, vol, cluster)
		fat16_grow_dir_at!(machine1, vol, last)
	}) }) })

	fat16_records_for : CceText -> I64
	fat16_records_for = |name| (if (fat16_needs_long(name) == False) { 0 } else { fat16_lfn_records_needed(CceText.len(name)) })

	fat16_slots_for : CceText -> I64
	fat16_slots_for = |name| (fat16_records_for(name) + 1)

	fat16_write_run! : Machine.Machine, Fat16.Fat16Volume, CceText, CceText, I64, I64 => (Machine.Machine, I64)
	fat16_write_run! = |machine, vol, name, short, slot, records| fat16_write_run_step!(machine, vol, name, fat16_short_checksum_of(short), slot, records, 0)

	fat16_write_run_step! : Machine.Machine, Fat16.Fat16Volume, CceText, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_write_run_step! = |machine, vol, name, sum, slot, records, j| (if (j >= records) { (machine, 0) } else { ({
		(machine1, w) = fat16_write_lfn_slot!(machine, name, sum, (slot + (j * 32)), (records - j), (j == 0))
		fat16_write_run_next!(machine1, vol, name, sum, slot, records, j, w)
	}) })

	fat16_write_run_next! : Machine.Machine, Fat16.Fat16Volume, CceText, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_write_run_next! = |machine, vol, name, sum, slot, records, j, w| (if (w != 0) { (machine, w) } else { fat16_write_run_step!(machine, vol, name, sum, slot, records, (j + 1)) })

	fat16_write_lfn_slot! : Machine.Machine, CceText, I64, I64, I64, Bool => (Machine.Machine, I64)
	fat16_write_lfn_slot! = |machine, name, sum, at, seq, last| ({
		(machine1, h) = Machine.mark(machine)
		({
			(machine2, buf) = Machine.block_read_sector!(machine1, I64.div_trunc_by(at, 512))
			(machine3, r) = fat16_put_lfn_slot!(machine2, name, sum, at, seq, last, buf)
			(machine3, fat16_drop_to(h, r))
		})
	})

	fat16_put_lfn_slot! : Machine.Machine, CceText, I64, I64, I64, Bool, I64 => (Machine.Machine, I64)
	fat16_put_lfn_slot! = |machine, name, sum, at, seq, last, buf| ({
		(machine1, _p) = fat16_poke_lfn_record!(machine, buf, Prelude.int_mod(at, 512), name, seq, sum, last)
		Machine.block_write_sector!(machine1, I64.div_trunc_by(at, 512), buf)
	})

	fat16_erase_entry! : Machine.Machine, Fat16.Fat16Volume, I64 => (Machine.Machine, I64)
	fat16_erase_entry! = |machine, vol, slot| ({
		(machine1, sum) = fat16_sum_at!(machine, slot)
		(machine2, _e) = fat16_mark_free!(machine1, slot)
		fat16_erase_run!(machine2, (slot - 32), sum, 0, (vol.vol_root_start * 512))
	})

	fat16_sum_at! : Machine.Machine, I64 => (Machine.Machine, I64)
	fat16_sum_at! = |machine, slot| ({
		(machine1, buf) = Machine.block_read_sector!(machine, I64.div_trunc_by(slot, 512))
		fat16_short_checksum!(machine1, buf, Prelude.int_mod(slot, 512))
	})

	fat16_mark_free! : Machine.Machine, I64 => (Machine.Machine, I64)
	fat16_mark_free! = |machine, at| ({
		(machine1, buf) = Machine.block_read_sector!(machine, I64.div_trunc_by(at, 512))
		fat16_put_mark_free!(machine1, at, buf)
	})

	fat16_put_mark_free! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	fat16_put_mark_free! = |machine, at, buf| ({
		(machine1, _p) = Machine.store!(machine, buf, Prelude.int_mod(at, 512), 229, 1)
		Machine.block_write_sector!(machine1, I64.div_trunc_by(at, 512), buf)
	})

	fat16_erase_run! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_erase_run! = |machine, at, sum, steps, floor| (if (steps >= fat16_lfn_max_records) { (machine, 0) } else { (if (at < floor) { (machine, 0) } else { ({
		(machine1, buf) = Machine.block_read_sector!(machine, I64.div_trunc_by(at, 512))
		fat16_erase_run_step!(machine1, at, sum, steps, floor, buf)
	}) }) })

	fat16_erase_run_step! : Machine.Machine, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_erase_run_step! = |machine, at, sum, steps, floor, buf| ({
		off : I64
		off = Prelude.int_mod(at, 512)
		({
			(machine1, machine__1) = fat16_is_lfn_entry!(machine, buf, off)
			(if (machine__1 == False) { (machine1, 0) } else { ({
			(machine2, machine__2) = fat16_lfn_stored_sum!(machine1, buf, off)
			(if (machine__2 != sum) { (machine2, 0) } else { ({
			(machine3, _m) = fat16_mark_free!(machine2, at)
			fat16_erase_run!(machine3, (at - 32), sum, (steps + 1), floor)
		}) })
		}) })
		})
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

	fat16_read_cluster_bytes! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64, List(I64), I64, I64, I64 => (Machine.Machine, Maybe.Maybe(List(I64)))
	fat16_read_cluster_bytes! = |machine, vol, cluster, remaining, sector_off, acc, saved, power, steps| (if (remaining <= 0) { (machine, Just(acc)) } else { (if (fat16_cluster_ok(vol, cluster) == False) { (machine, None) } else { ({
		(machine1, buf) = Machine.block_read_sector!(machine, (fat16_cluster_sector(vol, cluster) + sector_off))
		fat16_read_cluster_step!(machine1, vol, cluster, remaining, sector_off, acc, buf, saved, power, steps)
	}) }) })

	fat16_read_cluster_step! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64, List(I64), I64, I64, I64, I64 => (Machine.Machine, Maybe.Maybe(List(I64)))
	fat16_read_cluster_step! = |machine, vol, cluster, remaining, sector_off, acc, buf, saved, power, steps| ({
		bytes_this : I64
		bytes_this = (if (remaining < vol.vol_bytes_per_sector) { remaining } else { vol.vol_bytes_per_sector })
		(machine1, acc2) = fat16_copy_bytes!(machine, buf, 0, bytes_this, acc)
		next_sector_off : I64
		next_sector_off = (sector_off + 1)
		(if ((remaining - bytes_this) <= 0) { (machine1, Just(acc2)) } else { (if (next_sector_off >= vol.vol_sectors_per_cluster) { fat16_read_next_cluster!(machine1, vol, cluster, (remaining - bytes_this), acc2, saved, power, steps) } else { fat16_read_cluster_bytes!(machine1, vol, cluster, (remaining - bytes_this), next_sector_off, acc2, saved, power, steps) }) })
	})

	fat16_read_next_cluster! : Machine.Machine, Fat16.Fat16Volume, I64, I64, List(I64), I64, I64, I64 => (Machine.Machine, Maybe.Maybe(List(I64)))
	fat16_read_next_cluster! = |machine, vol, cluster, remaining, acc, saved, power, steps| ({
		(machine1, nxt) = fat16_next_cluster!(machine, vol, cluster)
		(if (nxt == saved) { (machine1, None) } else { (if ((steps + 1) == power) { fat16_read_cluster_bytes!(machine1, vol, nxt, remaining, 0, acc, nxt, (power * 2), 0) } else { fat16_read_cluster_bytes!(machine1, vol, nxt, remaining, 0, acc, saved, power, (steps + 1)) }) })
	})

	fat16_copy_bytes! : Machine.Machine, I64, I64, I64, List(I64) => (Machine.Machine, List(I64))
	fat16_copy_bytes! = |machine, buf, off, count, acc| (if (count <= 0) { (machine, acc) } else { ({
		(machine1, machine__1) = Machine.load!(machine, buf, off, 1)
		fat16_copy_bytes!(machine1, buf, (off + 1), (count - 1), List.append(acc, machine__1))
	}) })

	fat16_read_bytes! : Machine.Machine, Fat16.Fat16Volume, CceText => (Machine.Machine, Maybe.Maybe(List(I64)))
	fat16_read_bytes! = |machine, vol, path| (if (fat16_vol_is_usable(vol) == False) { (machine, None) } else { ({
		(machine1, machine__1) = fat16_resolve_path!(machine, vol, path)
		(match machine__1 {
		Just(entry) => fat16_read_cluster_bytes!(machine1, vol, entry.de_cluster, entry.de_size, 0, [], entry.de_cluster, 1, 0)
		None => (machine1, None)
	})
	}) })

	fat16_byte_to_cce : List(I64), I64 -> I64
	fat16_byte_to_cce = |tbl, b| ({
		t0 : I64
		t0 = CCE.from_unicode_tier0(tbl, b, 0, 128)
		(if (t0 >= 0) { t0 } else { CCE.from_unicode(b) })
	})

	fat16_bytes_to_chars : List(I64), List(I64), I64, I64, List(CceText) -> List(CceText)
	fat16_bytes_to_chars = |tbl, bs, i, len, acc| (if (i >= len) { acc } else { fat16_bytes_to_chars(tbl, bs, (i + 1), len, List.append(acc, fat16_byte_text(tbl, (List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	fat16_byte_text : List(I64), I64 -> CceText
	fat16_byte_text = |tbl, b| ({
		c : I64
		c = fat16_byte_to_cce(tbl, b)
		(if (c >= 0) { CceText.char_to_text(CceChar.of_code(c)) } else { (if (b == 9) { " " } else { "" }) })
	})

	fat16_bytes_to_text : List(I64), I64, I64, CceText -> CceText
	fat16_bytes_to_text = |bs, i, len, acc| CceText.concat(acc, CceText.concat_list(fat16_bytes_to_chars(CCE.cce_to_unicode_table, bs, i, len, [])))

	fat16_read_text! : Machine.Machine, Fat16.Fat16Volume, CceText => (Machine.Machine, Maybe.Maybe(CceText))
	fat16_read_text! = |machine, vol, path| ({
		(machine1, machine__1) = fat16_read_bytes!(machine, vol, path)
		(machine1, (match machine__1 {
		Just(bs) => Just(fat16_bytes_to_text(bs, 0, U64.to_i64_wrap(List.len(bs)), ""))
		None => None
	}))
	})

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

	fat16_text_bytes : CceText, I64, I64, List(I64) -> List(I64)
	fat16_text_bytes = |s, i, n, acc| (if (i >= n) { acc } else { ({
		b : I64
		b = CCE.to_unicode(CceChar.code(CceText.char_at(s, i)))
		fat16_text_bytes(s, (i + 1), n, List.append(acc, b))
	}) })

	fat16_write_file! : Machine.Machine, CceText, CceText => (Machine.Machine, Bool)
	fat16_write_file! = |machine, path, content| ({
		bytes : List(I64)
		bytes = fat16_text_bytes(content, 0, CceText.len(content), [])
		fat16_write_binary_file!(machine, path, bytes)
	})

	fat16_write_binary_file! : Machine.Machine, CceText, List(I64) => (Machine.Machine, Bool)
	fat16_write_binary_file! = |machine, path, bytes| fat16_write_source!(machine, path, fat16_src_of_list(bytes))

	fat16_write_source! : Machine.Machine, CceText, Fat16.Fat16Source => (Machine.Machine, Bool)
	fat16_write_source! = |machine, path, src| ({
		(machine1, vol) = fat16_boot_volume!(machine)
		fat16_create_file!(machine1, vol, path, src)
	})

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
