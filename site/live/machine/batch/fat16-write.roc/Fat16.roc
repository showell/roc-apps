# Fat16 -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CCE
import Cce
import Gpt
import Machine
import Maybe
import Prelude
import StringUtils

Fat16 :: [].{
	Fat16Volume : { vol_part_start : I64, vol_bytes_per_sector : I64, vol_sectors_per_cluster : I64, vol_reserved_sectors : I64, vol_num_fats : I64, vol_root_entry_count : I64, vol_fat_sectors : I64, vol_fat_start : I64, vol_root_start : I64, vol_data_start : I64, vol_total_sectors : I64, vol_cluster_count : I64 }
	Fat16DirEntry : { de_name : Str, de_attr : I64, de_cluster : I64, de_size : I64 }
	Fat16Source : { fs_head : List(I64), fs_buf : I64, fs_buf_len : I64, fs_tail : List(I64), fs_len : I64 }
	Fat16Lfn : { lf_name : Str, lf_ord : I64, lf_sum : I64, lf_live : Bool }
	Fat16Scan : { sc_found : Maybe.Maybe(Fat16.Fat16DirEntry), sc_lfn : Fat16.Fat16Lfn }
	Fat16Run : { rn_found : Bool, rn_at : I64, rn_streak : I64 }
	Fat16List : { li_entries : List(Fat16.Fat16DirEntry), li_lfn : Fat16.Fat16Lfn }

	fat16_read_u16! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	fat16_read_u16! = |machine, buf, off| ({
		(machine1, machine__77) = Machine.load!(machine, buf, off, 1)
		(machine2, machine__78) = Machine.load!(machine1, buf, (off + 1), 1)
		(machine2, I64.bitwise_or(machine__77, I64.shl_wrap(machine__78, I64.to_u8_wrap(8))))
	})

	fat16_read_u32! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	fat16_read_u32! = |machine, buf, off| ({
		(machine1, machine__79) = fat16_read_u16!(machine, buf, off)
		(machine2, machine__80) = fat16_read_u16!(machine1, buf, (off + 2))
		(machine2, I64.bitwise_or(machine__79, I64.shl_wrap(machine__80, I64.to_u8_wrap(16))))
	})

	fat16_init! : Machine.Machine, I64 => (Machine.Machine, Fat16.Fat16Volume)
	fat16_init! = |machine, part_start| ({
		(machine1, buf) = Machine.block_read_sector!(machine, part_start)
		fat16_parse_bpb!(machine1, part_start, buf)
	})

	fat16_zero_volume : I64 -> Fat16.Fat16Volume
	fat16_zero_volume = |part_start| { vol_part_start: part_start, vol_bytes_per_sector: 0, vol_sectors_per_cluster: 0, vol_reserved_sectors: 0, vol_num_fats: 0, vol_root_entry_count: 0, vol_fat_sectors: 0, vol_fat_start: 0, vol_root_start: 0, vol_data_start: 0, vol_total_sectors: 0, vol_cluster_count: 0 }

	fat16_parse_bpb! : Machine.Machine, I64, I64 => (Machine.Machine, Fat16.Fat16Volume)
	fat16_parse_bpb! = |machine, part_start, buf| ({
		(machine11, machine__84) = ({
		(machine1, bps) = fat16_read_u16!(machine, buf, 11)
		(machine2, spc) = Machine.load!(machine1, buf, 13, 1)
		({
			(machine10, machine__83) = (if (bps == 0) { (machine2, fat16_zero_volume(part_start)) } else { ({
			(machine9, machine__82) = (if (spc == 0) { (machine2, fat16_zero_volume(part_start)) } else { ({
			(machine8, machine__81) = ({
			(machine3, reserved) = fat16_read_u16!(machine2, buf, 14)
			(machine4, nfats) = Machine.load!(machine3, buf, 16, 1)
			(machine5, root_cnt) = fat16_read_u16!(machine4, buf, 17)
			(machine6, fat_sz) = fat16_read_u16!(machine5, buf, 22)
			fat_start = (part_start + reserved)
			root_dir_sectors = I64.div_trunc_by((((root_cnt * 32) + bps) - 1), bps)
			root_start = (fat_start + (nfats * fat_sz))
			data_start = (root_start + root_dir_sectors)
			(machine7, total) = fat16_total_sectors!(machine6, buf)
			data_sectors = (total - (data_start - part_start))
			raw_clusters = (if (data_sectors <= 0) { 0 } else { I64.div_trunc_by(data_sectors, spc) })
			clusters = (if (raw_clusters > 65524) { 65524 } else { raw_clusters })
			(machine7, { vol_part_start: part_start, vol_bytes_per_sector: bps, vol_sectors_per_cluster: spc, vol_reserved_sectors: reserved, vol_num_fats: nfats, vol_root_entry_count: root_cnt, vol_fat_sectors: fat_sz, vol_fat_start: fat_start, vol_root_start: root_start, vol_data_start: data_start, vol_total_sectors: total, vol_cluster_count: clusters })
		})
			(machine8, machine__81)
		}) })
			(machine9, machine__82)
		}) })
			(machine10, machine__83)
		})
	})
		(machine11, machine__84)
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

	fat16_read_fat_entry! : Machine.Machine, Fat16.Fat16Volume, I64, I64 => (Machine.Machine, I64)
	fat16_read_fat_entry! = |machine, vol, fat_index, cluster| ({
		(machine1, buf) = Machine.block_read_sector!(machine, fat16_fat_entry_sector(vol, fat_index, cluster))
		fat16_read_u16!(machine1, buf, fat16_fat_entry_offset(vol, cluster))
	})

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

	fat16_find_free_cluster! : Machine.Machine, Fat16.Fat16Volume => (Machine.Machine, I64)
	fat16_find_free_cluster! = |machine, vol| fat16_find_free_from!(machine, vol, 2)

	fat16_find_free_from! : Machine.Machine, Fat16.Fat16Volume, I64 => (Machine.Machine, I64)
	fat16_find_free_from! = |machine, vol, hint| ({
		(machine1, found) = fat16_scan_free_sectors!(machine, vol, (if (hint < 2) { 2 } else { hint }))
		(if (found > 0) { (machine1, found) } else { (if (hint <= 2) { (machine1, 0) } else { fat16_scan_free_sectors!(machine1, vol, 2) }) })
	})

	fat16_scan_free_sectors! : Machine.Machine, Fat16.Fat16Volume, I64 => (Machine.Machine, I64)
	fat16_scan_free_sectors! = |machine, vol, c| (if (c > fat16_last_cluster(vol)) { (machine, 0) } else { ({
		per_sector = I64.div_trunc_by(vol.vol_bytes_per_sector, 2)
		sector_last = (((I64.div_trunc_by(c, per_sector) * per_sector) + per_sector) - 1)
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
		(machine3, machine__85) = ({
		(machine1, found) = fat16_scan_free_in_sector!(machine, vol, buf, c, upto)
		(machine2, _z) = Machine.release(machine1, h)
		(machine2, found)
	})
		(machine3, machine__85)
	})

	fat16_scan_free_in_sector! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64 => (Machine.Machine, I64)
	fat16_scan_free_in_sector! = |machine, vol, buf, c, upto| (if (c > upto) { (machine, 0) } else { ({
		(machine1, machine__86) = fat16_read_u16!(machine, buf, fat16_fat_entry_offset(vol, c))
		(if (machine__86 == 0) { (machine1, c) } else { fat16_scan_free_in_sector!(machine1, vol, buf, (c + 1), upto) })
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

	fat16_clusters_needed : Fat16.Fat16Volume, I64 -> I64
	fat16_clusters_needed = |vol, n| (if (n == 0) { 1 } else { I64.div_trunc_by(((n + fat16_bytes_per_cluster(vol)) - 1), fat16_bytes_per_cluster(vol)) })

	fat16_src_of_list : List(I64) -> Fat16.Fat16Source
	fat16_src_of_list = |bs| { fs_head: bs, fs_buf: 0, fs_buf_len: 0, fs_tail: [], fs_len: U64.to_i64_wrap(List.len(bs)) }

	fat16_src_empty : Fat16.Fat16Source
	fat16_src_empty = fat16_src_of_list([])

	fat16_src_of_parts : List(I64), I64, I64, List(I64) -> Fat16.Fat16Source
	fat16_src_of_parts = |head, buf, blen, tail| { fs_head: head, fs_buf: buf, fs_buf_len: blen, fs_tail: tail, fs_len: ((U64.to_i64_wrap(List.len(head)) + blen) + U64.to_i64_wrap(List.len(tail))) }

	fat16_src_at! : Machine.Machine, Fat16.Fat16Source, I64 => (Machine.Machine, I64)
	fat16_src_at! = |machine, s, i| ({
		hn = U64.to_i64_wrap(List.len(s.fs_head))
		(if (i < hn) { (machine, (List.get(s.fs_head, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) } else { ({
			j = (i - hn)
			(if (j < s.fs_buf_len) { Machine.load!(machine, s.fs_buf, j, 1) } else { (machine, (List.get(s.fs_tail, I64.to_u64_wrap((j - s.fs_buf_len))) ?? crash("list-at out of range"))) })
		}) })
	})

	fat16_fill_sector! : Machine.Machine, I64, Fat16.Fat16Source, I64, I64, I64 => (Machine.Machine, I64)
	fat16_fill_sector! = |machine, buf, bytes, start, i, bps| (if (i >= bps) { (machine, 0) } else { ({
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
		sec = (fat16_cluster_sector(vol, cluster) + i)
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

	fat16_name_byte : Str, I64 -> I64
	fat16_name_byte = |s, i| (if (i >= Cce.length(s)) { 32 } else { CCE.to_unicode(Cce.at_or_crash(s, i)) })

	fat16_poke_83! : Machine.Machine, I64, I64, Str, Str => (Machine.Machine, I64)
	fat16_poke_83! = |machine, buf, off, base, ext| ({
		(machine1, _b) = fat16_poke_run!(machine, buf, off, base, 0, 8)
		fat16_poke_run!(machine1, buf, (off + 8), ext, 0, 3)
	})

	fat16_poke_run! : Machine.Machine, I64, I64, Str, I64, I64 => (Machine.Machine, I64)
	fat16_poke_run! = |machine, buf, off, s, i, n| (if (i >= n) { (machine, 0) } else { ({
		(machine1, _w) = Machine.store!(machine, buf, (off + i), fat16_name_byte(s, i), 1)
		fat16_poke_run!(machine1, buf, off, s, (i + 1), n)
	}) })

	fat16_name_fits_83 : Str -> Bool
	fat16_name_fits_83 = |name| ((Cce.length(fat16_base_of(name)) <= 8) and (Cce.length(fat16_ext_of(name)) <= 3))

	fat16_short_form : Str -> Str
	fat16_short_form = |name| ({
		b = fat16_base_of(name)
		e = fat16_ext_of(name)
		(if (Cce.length(e) == 0) { b } else { Str.concat(Str.concat(b, "."), e) })
	})

	fat16_needs_long : Str -> Bool
	fat16_needs_long = |name| (if (fat16_name_fits_83(name) == False) { True } else { (fat16_short_form(name) != name) })

	fat16_name_writable : Str -> Bool
	fat16_name_writable = |name| ({
		n = Cce.length(name)
		(if (n == 0) { False } else { (if (n > fat16_lfn_max_name) { False } else { fat16_lfn_name_spellable(name, 0, n) }) })
	})

	fat16_path_writable : Str -> Bool
	fat16_path_writable = |path| fat16_parts_writable(fat16_split_path(path), 0)

	fat16_parts_writable : List(Str), I64 -> Bool
	fat16_parts_writable = |parts, i| (if (i >= U64.to_i64_wrap(List.len(parts))) { True } else { (if (fat16_name_writable((List.get(parts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) == False) { False } else { fat16_parts_writable(parts, (i + 1)) }) })

	fat16_base_of : Str -> Str
	fat16_base_of = |name| ({
		dot = StringUtils.text_index_of(name, ".")
		(if (dot < 0) { fat16_upper(name) } else { fat16_upper(StringUtils.text_substring(name, 0, dot)) })
	})

	fat16_ext_of : Str -> Str
	fat16_ext_of = |name| ({
		dot = StringUtils.text_index_of(name, ".")
		(if (dot < 0) { "" } else { fat16_upper(StringUtils.text_substring(name, (dot + 1), ((Cce.length(name) - dot) - 1))) })
	})

	fat16_poke_dir_entry! : Machine.Machine, I64, I64, Str, I64, I64, I64 => (Machine.Machine, I64)
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

	fat16_create_file! : Machine.Machine, Fat16.Fat16Volume, Str, Fat16.Fat16Source => (Machine.Machine, Bool)
	fat16_create_file! = |machine, vol, name, bytes| ({
		(machine1, machine__87) = fat16_scope_admits!(machine, name)
		(if (machine__87 == False) { (machine1, False) } else { (if (fat16_path_writable(name) == False) { (machine1, False) } else { (if (fat16_vol_is_usable(vol) == False) { (machine1, False) } else { (if StringUtils.text_contains(name, "/") { fat16_create_in_subdir!(machine1, vol, name, bytes) } else { ({
		(machine2, found) = fat16_find_in_root!(machine1, vol, name)
		fat16_create_or_replace!(machine2, vol, name, bytes, found)
	}) }) }) }) })
	})

	fat16_create_or_replace! : Machine.Machine, Fat16.Fat16Volume, Str, Fat16.Fat16Source, Maybe.Maybe(Fat16.Fat16DirEntry) => (Machine.Machine, Bool)
	fat16_create_or_replace! = |machine, vol, name, bytes, found| (match found {
		Just(e) => fat16_replace_in_root!(machine, vol, name, bytes, e)
		None => fat16_create_fresh_in_root!(machine, vol, name, bytes)
	})

	fat16_replace_in_root! : Machine.Machine, Fat16.Fat16Volume, Str, Fat16.Fat16Source, Fat16.Fat16DirEntry => (Machine.Machine, Bool)
	fat16_replace_in_root! = |machine, vol, name, bytes, e| ({
		(machine1, slot) = fat16_find_name_slot!(machine, vol, e.de_name)
		fat16_replace_at_slot!(machine1, vol, name, bytes, slot, e.de_cluster)
	})

	fat16_replace_at_slot! : Machine.Machine, Fat16.Fat16Volume, Str, Fat16.Fat16Source, I64, I64 => (Machine.Machine, Bool)
	fat16_replace_at_slot! = |machine, vol, name, bytes, slot, old| (if (slot < 0) { (machine, False) } else { ({
		(machine1, _f) = fat16_free_chain!(machine, vol, old)
		fat16_erase_then_create_root!(machine1, vol, name, bytes, slot)
	}) })

	fat16_erase_then_create_root! : Machine.Machine, Fat16.Fat16Volume, Str, Fat16.Fat16Source, I64 => (Machine.Machine, Bool)
	fat16_erase_then_create_root! = |machine, vol, name, bytes, slot| ({
		(machine1, _d) = fat16_erase_entry!(machine, vol, slot)
		fat16_create_fresh_in_root!(machine1, vol, name, bytes)
	})

	fat16_create_fresh_in_root! : Machine.Machine, Fat16.Fat16Volume, Str, Fat16.Fat16Source => (Machine.Machine, Bool)
	fat16_create_fresh_in_root! = |machine, vol, name, bytes| ({
		(machine1, short) = fat16_pick_alias_root!(machine, vol, name, 1)
		fat16_place_in_root!(machine1, vol, name, short, bytes)
	})

	fat16_place_in_root! : Machine.Machine, Fat16.Fat16Volume, Str, Str, Fat16.Fat16Source => (Machine.Machine, Bool)
	fat16_place_in_root! = |machine, vol, name, short, bytes| (if (Cce.length(short) == 0) { (machine, False) } else { ({
		(machine1, slot) = fat16_find_run_in_root!(machine, vol, fat16_slots_for(name))
		fat16_create_at_run!(machine1, vol, name, short, bytes, slot)
	}) })

	fat16_pick_alias_root! : Machine.Machine, Fat16.Fat16Volume, Str, I64 => (Machine.Machine, Str)
	fat16_pick_alias_root! = |machine, vol, name, n| (if (fat16_needs_long(name) == False) { (machine, name) } else { (if (n > fat16_alias_max_tries) { (machine, "") } else { ({
		cand = fat16_alias_of(name, n)
		({
			(machine1, taken) = fat16_find_name_slot!(machine, vol, cand)
			(if (taken >= 0) { fat16_pick_alias_root!(machine1, vol, name, (n + 1)) } else { (machine1, cand) })
		})
	}) }) })

	fat16_pick_alias_dir! : Machine.Machine, Fat16.Fat16Volume, I64, Str, I64 => (Machine.Machine, Str)
	fat16_pick_alias_dir! = |machine, vol, cluster, name, n| (if (fat16_needs_long(name) == False) { (machine, name) } else { (if (n > fat16_alias_max_tries) { (machine, "") } else { ({
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
		(machine1, machine__88) = fat16_next_cluster!(machine, vol, cluster)
		fat16_free_chain_from!(machine1, vol, cluster, machine__88, saved, power, steps)
	}) }) })

	fat16_free_chain_from! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_free_chain_from! = |machine, vol, cluster, nxt, saved, power, steps| ({
		(machine1, _w) = fat16_write_fat_entry!(machine, vol, cluster, 0)
		(if (nxt == saved) { (machine1, 0) } else { (if ((steps + 1) == power) { fat16_free_chain_walk!(machine1, vol, nxt, nxt, (power * 2), 0) } else { fat16_free_chain_walk!(machine1, vol, nxt, saved, power, (steps + 1)) }) })
	})

	fat16_find_name_slot! : Machine.Machine, Fat16.Fat16Volume, Str => (Machine.Machine, I64)
	fat16_find_name_slot! = |machine, vol, name| fat16_name_slot_sectors!(machine, vol, name, vol.vol_root_start, fat16_root_sector_count(vol), 0)

	fat16_name_slot_sectors! : Machine.Machine, Fat16.Fat16Volume, Str, I64, I64, I64 => (Machine.Machine, I64)
	fat16_name_slot_sectors! = |machine, vol, name, sector, remaining, checked| (if (remaining == 0) { (machine, (0 - 1)) } else { (if (checked >= vol.vol_root_entry_count) { (machine, (0 - 1)) } else { ({
		(machine1, buf) = Machine.block_read_sector!(machine, sector)
		fat16_name_slot_step!(machine1, vol, name, sector, remaining, checked, buf)
	}) }) })

	fat16_name_slot_step! : Machine.Machine, Fat16.Fat16Volume, Str, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_name_slot_step! = |machine, vol, name, sector, remaining, checked, buf| ({
		eps = I64.div_trunc_by(vol.vol_bytes_per_sector, 32)
		(machine1, found) = fat16_name_slot_in_sector!(machine, buf, name, 0, eps)
		(if (found >= 0) { (machine1, ((sector * 512) + found)) } else { fat16_name_slot_sectors!(machine1, vol, name, (sector + 1), (remaining - 1), (checked + eps)) })
	})

	fat16_name_slot_in_sector! : Machine.Machine, I64, Str, I64, I64 => (Machine.Machine, I64)
	fat16_name_slot_in_sector! = |machine, buf, name, i, count| (if (i >= count) { (machine, (0 - 1)) } else { ({
		off = (i * 32)
		({
			(machine1, machine__89) = fat16_is_free_entry!(machine, buf, off)
			(if machine__89 { fat16_name_slot_in_sector!(machine1, buf, name, (i + 1), count) } else { ({
			(machine2, machine__90) = fat16_is_lfn_entry!(machine1, buf, off)
			(if machine__90 { fat16_name_slot_in_sector!(machine2, buf, name, (i + 1), count) } else { ({
			(machine3, machine__91) = fat16_is_volume_label!(machine2, buf, off)
			(if machine__91 { fat16_name_slot_in_sector!(machine3, buf, name, (i + 1), count) } else { ({
			(machine4, machine__92) = fat16_entry_name_at!(machine3, buf, off)
			(if fat16_name_matches(machine__92, name) { (machine4, off) } else { fat16_name_slot_in_sector!(machine4, buf, name, (i + 1), count) })
		}) })
		}) })
		}) })
		})
	}) })

	fat16_entry_name_at! : Machine.Machine, I64, I64 => (Machine.Machine, Str)
	fat16_entry_name_at! = |machine, buf, off| ({
		(machine1, machine__93) = fat16_read_dir_entry!(machine, buf, off)
		(machine1, machine__93.de_name)
	})

	fat16_find_name_slot_in_dir! : Machine.Machine, Fat16.Fat16Volume, I64, Str => (Machine.Machine, I64)
	fat16_find_name_slot_in_dir! = |machine, vol, cluster, name| fat16_find_name_slot_walk!(machine, vol, cluster, name, cluster, 1, 0)

	fat16_find_name_slot_walk! : Machine.Machine, Fat16.Fat16Volume, I64, Str, I64, I64, I64 => (Machine.Machine, I64)
	fat16_find_name_slot_walk! = |machine, vol, cluster, name, saved, power, steps| (if fat16_is_end(cluster) { (machine, (0 - 1)) } else { ({
		(machine1, found) = fat16_name_slot_dir_sectors!(machine, vol, name, fat16_cluster_sector(vol, cluster), vol.vol_sectors_per_cluster)
		fat16_name_slot_or_next!(machine1, vol, cluster, name, found, saved, power, steps)
	}) })

	fat16_name_slot_or_next! : Machine.Machine, Fat16.Fat16Volume, I64, Str, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_name_slot_or_next! = |machine, vol, cluster, name, found, saved, power, steps| ({
		(if (found >= 0) { (machine, found) } else { ({
			(machine1, nxt) = fat16_next_cluster!(machine, vol, cluster)
			(if (nxt == saved) { (machine1, (0 - 1)) } else { (if ((steps + 1) == power) { fat16_find_name_slot_walk!(machine1, vol, nxt, name, nxt, (power * 2), 0) } else { fat16_find_name_slot_walk!(machine1, vol, nxt, name, saved, power, (steps + 1)) }) })
		}) })
	})

	fat16_name_slot_dir_sectors! : Machine.Machine, Fat16.Fat16Volume, Str, I64, I64 => (Machine.Machine, I64)
	fat16_name_slot_dir_sectors! = |machine, vol, name, sector, remaining| (if (remaining == 0) { (machine, (0 - 1)) } else { ({
		(machine1, buf) = Machine.block_read_sector!(machine, sector)
		fat16_name_slot_dir_step!(machine1, vol, name, sector, remaining, buf)
	}) })

	fat16_name_slot_dir_step! : Machine.Machine, Fat16.Fat16Volume, Str, I64, I64, I64 => (Machine.Machine, I64)
	fat16_name_slot_dir_step! = |machine, vol, name, sector, remaining, buf| ({
		(machine1, found) = fat16_name_slot_in_sector!(machine, buf, name, 0, I64.div_trunc_by(vol.vol_bytes_per_sector, 32))
		(if (found >= 0) { (machine1, ((sector * 512) + found)) } else { fat16_name_slot_dir_sectors!(machine1, vol, name, (sector + 1), (remaining - 1)) })
	})

	fat16_create_in_subdir! : Machine.Machine, Fat16.Fat16Volume, Str, Fat16.Fat16Source => (Machine.Machine, Bool)
	fat16_create_in_subdir! = |machine, vol, path, bytes| ({
		parts = fat16_split_path(path)
		n = U64.to_i64_wrap(List.len(parts))
		(if (n < 2) { (machine, False) } else { ({
			(machine1, machine__94) = fat16_walk_path!(machine, vol, parts, 0, (n - 1))
			(match machine__94 {
			None => (machine1, False)
			Just(dir) => fat16_create_in_dir_entry!(machine1, vol, dir, (List.get(parts, I64.to_u64_wrap((n - 1))) ?? crash("list-at out of range")), bytes)
		})
		}) })
	})

	fat16_create_in_dir_entry! : Machine.Machine, Fat16.Fat16Volume, Fat16.Fat16DirEntry, Str, Fat16.Fat16Source => (Machine.Machine, Bool)
	fat16_create_in_dir_entry! = |machine, vol, dir, leaf, bytes| (if (I64.bitwise_and(dir.de_attr, 16) == 16) { fat16_create_in_cluster_dir!(machine, vol, dir.de_cluster, leaf, bytes) } else { (machine, False) })

	fat16_create_in_cluster_dir! : Machine.Machine, Fat16.Fat16Volume, I64, Str, Fat16.Fat16Source => (Machine.Machine, Bool)
	fat16_create_in_cluster_dir! = |machine, vol, cluster, leaf, bytes| ({
		(machine1, found) = fat16_find_in_cluster_dir!(machine, vol, cluster, leaf)
		fat16_create_or_replace_in_dir!(machine1, vol, cluster, leaf, bytes, found)
	})

	fat16_create_or_replace_in_dir! : Machine.Machine, Fat16.Fat16Volume, I64, Str, Fat16.Fat16Source, Maybe.Maybe(Fat16.Fat16DirEntry) => (Machine.Machine, Bool)
	fat16_create_or_replace_in_dir! = |machine, vol, cluster, leaf, bytes, found| (match found {
		Just(e) => fat16_replace_in_dir!(machine, vol, cluster, leaf, bytes, e)
		None => fat16_create_fresh_in_dir!(machine, vol, cluster, leaf, bytes)
	})

	fat16_replace_in_dir! : Machine.Machine, Fat16.Fat16Volume, I64, Str, Fat16.Fat16Source, Fat16.Fat16DirEntry => (Machine.Machine, Bool)
	fat16_replace_in_dir! = |machine, vol, cluster, leaf, bytes, e| ({
		(machine1, slot) = fat16_find_name_slot_in_dir!(machine, vol, cluster, e.de_name)
		fat16_replace_at_slot_in_dir!(machine1, vol, cluster, leaf, bytes, slot, e.de_cluster)
	})

	fat16_replace_at_slot_in_dir! : Machine.Machine, Fat16.Fat16Volume, I64, Str, Fat16.Fat16Source, I64, I64 => (Machine.Machine, Bool)
	fat16_replace_at_slot_in_dir! = |machine, vol, cluster, leaf, bytes, slot, old| (if (slot < 0) { (machine, False) } else { ({
		(machine1, _f) = fat16_free_chain!(machine, vol, old)
		fat16_erase_then_create_dir!(machine1, vol, cluster, leaf, bytes, slot)
	}) })

	fat16_erase_then_create_dir! : Machine.Machine, Fat16.Fat16Volume, I64, Str, Fat16.Fat16Source, I64 => (Machine.Machine, Bool)
	fat16_erase_then_create_dir! = |machine, vol, cluster, leaf, bytes, slot| ({
		(machine1, _d) = fat16_erase_entry!(machine, vol, slot)
		fat16_create_fresh_in_dir!(machine1, vol, cluster, leaf, bytes)
	})

	fat16_create_fresh_in_dir! : Machine.Machine, Fat16.Fat16Volume, I64, Str, Fat16.Fat16Source => (Machine.Machine, Bool)
	fat16_create_fresh_in_dir! = |machine, vol, cluster, leaf, bytes| ({
		(machine1, short) = fat16_pick_alias_dir!(machine, vol, cluster, leaf, 1)
		fat16_place_in_dir!(machine1, vol, cluster, leaf, short, bytes)
	})

	fat16_place_in_dir! : Machine.Machine, Fat16.Fat16Volume, I64, Str, Str, Fat16.Fat16Source => (Machine.Machine, Bool)
	fat16_place_in_dir! = |machine, vol, cluster, leaf, short, bytes| (if (Cce.length(short) == 0) { (machine, False) } else { ({
		(machine1, slot) = fat16_find_or_grow_run_in_dir!(machine, vol, cluster, fat16_slots_for(leaf))
		fat16_create_at_run!(machine1, vol, leaf, short, bytes, slot)
	}) })

	fat16_create_at_run! : Machine.Machine, Fat16.Fat16Volume, Str, Str, Fat16.Fat16Source, I64 => (Machine.Machine, Bool)
	fat16_create_at_run! = |machine, vol, name, short, bytes, slot| (if (slot < 0) { (machine, False) } else { ({
		(machine1, first) = fat16_alloc_cluster!(machine, vol)
		fat16_create_with_cluster!(machine1, vol, name, short, bytes, slot, first)
	}) })

	fat16_create_with_cluster! : Machine.Machine, Fat16.Fat16Volume, Str, Str, Fat16.Fat16Source, I64, I64 => (Machine.Machine, Bool)
	fat16_create_with_cluster! = |machine, vol, name, short, bytes, slot, first| (if (first == 0) { (machine, False) } else { ({
		(machine1, w) = fat16_write_chain!(machine, vol, first, bytes, 0)
		fat16_commit_entry!(machine1, vol, name, short, bytes, slot, first, w)
	}) })

	fat16_commit_entry! : Machine.Machine, Fat16.Fat16Volume, Str, Str, Fat16.Fat16Source, I64, I64, I64 => (Machine.Machine, Bool)
	fat16_commit_entry! = |machine, vol, name, short, bytes, slot, first, ok| (if (ok == 0) { (machine, False) } else { ({
		(machine1, r) = fat16_write_run!(machine, vol, name, short, slot, fat16_records_for(name))
		fat16_commit_short_if!(machine1, short, bytes, slot, first, fat16_records_for(name), r)
	}) })

	fat16_commit_short_if! : Machine.Machine, Str, Fat16.Fat16Source, I64, I64, I64, I64 => (Machine.Machine, Bool)
	fat16_commit_short_if! = |machine, short, bytes, slot, first, records, r| (if (r != 0) { (machine, False) } else { fat16_commit_short!(machine, short, bytes, slot, first, records) })

	fat16_commit_short! : Machine.Machine, Str, Fat16.Fat16Source, I64, I64, I64 => (Machine.Machine, Bool)
	fat16_commit_short! = |machine, short, bytes, slot, first, records| ({
		(machine1, buf) = Machine.block_read_sector!(machine, I64.div_trunc_by((slot + (records * 32)), 512))
		fat16_put_entry_and_write!(machine1, short, bytes, slot, first, records, buf)
	})

	fat16_put_entry_and_write! : Machine.Machine, Str, Fat16.Fat16Source, I64, I64, I64, I64 => (Machine.Machine, Bool)
	fat16_put_entry_and_write! = |machine, short, bytes, slot, first, records, buf| ({
		at = (slot + (records * 32))
		(machine1, _p) = fat16_poke_dir_entry!(machine, buf, Prelude.int_mod(at, 512), short, 32, first, bytes.fs_len)
		({
			(machine2, s) = Machine.block_write_sector!(machine1, I64.div_trunc_by(at, 512), buf)
			(machine2, (if (s == 0) { True } else { False }))
		})
	})

	fat16_create_directory! : Machine.Machine, Fat16.Fat16Volume, Str => (Machine.Machine, Bool)
	fat16_create_directory! = |machine, vol, path| ({
		(machine1, machine__95) = fat16_scope_admits!(machine, path)
		(if (machine__95 == False) { (machine1, False) } else { (if (fat16_path_writable(path) == False) { (machine1, False) } else { (if (fat16_vol_is_usable(vol) == False) { (machine1, False) } else { (if (Cce.length(path) == 0) { (machine1, False) } else { ({
		(machine2, taken) = fat16_resolve_path!(machine1, vol, path)
		fat16_mkdir_if_free!(machine2, vol, path, taken)
	}) }) }) }) })
	})

	fat16_mkdir_if_free! : Machine.Machine, Fat16.Fat16Volume, Str, Maybe.Maybe(Fat16.Fat16DirEntry) => (Machine.Machine, Bool)
	fat16_mkdir_if_free! = |machine, vol, path, taken| (match taken {
		Just(_e) => (machine, False)
		None => (if StringUtils.text_contains(path, "/") { fat16_mkdir_in_subdir!(machine, vol, path) } else { fat16_mkdir_in_root!(machine, vol, path) })
	})

	fat16_mkdir_in_root! : Machine.Machine, Fat16.Fat16Volume, Str => (Machine.Machine, Bool)
	fat16_mkdir_in_root! = |machine, vol, name| ({
		(machine1, short) = fat16_pick_alias_root!(machine, vol, name, 1)
		fat16_mkdir_place_root!(machine1, vol, name, short)
	})

	fat16_mkdir_place_root! : Machine.Machine, Fat16.Fat16Volume, Str, Str => (Machine.Machine, Bool)
	fat16_mkdir_place_root! = |machine, vol, name, short| (if (Cce.length(short) == 0) { (machine, False) } else { ({
		(machine1, slot) = fat16_find_run_in_root!(machine, vol, fat16_slots_for(name))
		fat16_mkdir_at_slot!(machine1, vol, name, short, slot, 0)
	}) })

	fat16_mkdir_in_subdir! : Machine.Machine, Fat16.Fat16Volume, Str => (Machine.Machine, Bool)
	fat16_mkdir_in_subdir! = |machine, vol, path| ({
		parts = fat16_split_path(path)
		n = U64.to_i64_wrap(List.len(parts))
		(if (n < 2) { (machine, False) } else { ({
			(machine1, machine__96) = fat16_walk_path!(machine, vol, parts, 0, (n - 1))
			(match machine__96 {
			None => (machine1, False)
			Just(dir) => fat16_mkdir_under!(machine1, vol, dir, (List.get(parts, I64.to_u64_wrap((n - 1))) ?? crash("list-at out of range")))
		})
		}) })
	})

	fat16_mkdir_under! : Machine.Machine, Fat16.Fat16Volume, Fat16.Fat16DirEntry, Str => (Machine.Machine, Bool)
	fat16_mkdir_under! = |machine, vol, dir, leaf| (if (I64.bitwise_and(dir.de_attr, 16) == 16) { fat16_mkdir_in_cluster!(machine, vol, dir.de_cluster, leaf) } else { (machine, False) })

	fat16_mkdir_in_cluster! : Machine.Machine, Fat16.Fat16Volume, I64, Str => (Machine.Machine, Bool)
	fat16_mkdir_in_cluster! = |machine, vol, parent, leaf| ({
		(machine1, short) = fat16_pick_alias_dir!(machine, vol, parent, leaf, 1)
		fat16_mkdir_place_dir!(machine1, vol, parent, leaf, short)
	})

	fat16_mkdir_place_dir! : Machine.Machine, Fat16.Fat16Volume, I64, Str, Str => (Machine.Machine, Bool)
	fat16_mkdir_place_dir! = |machine, vol, parent, leaf, short| (if (Cce.length(short) == 0) { (machine, False) } else { ({
		(machine1, slot) = fat16_find_or_grow_run_in_dir!(machine, vol, parent, fat16_slots_for(leaf))
		fat16_mkdir_at_slot!(machine1, vol, leaf, short, slot, parent)
	}) })

	fat16_mkdir_at_slot! : Machine.Machine, Fat16.Fat16Volume, Str, Str, I64, I64 => (Machine.Machine, Bool)
	fat16_mkdir_at_slot! = |machine, vol, name, short, slot, parent| (if (slot < 0) { (machine, False) } else { ({
		(machine1, first) = fat16_alloc_cluster!(machine, vol)
		fat16_mkdir_with_cluster!(machine1, vol, name, short, slot, parent, first)
	}) })

	fat16_mkdir_with_cluster! : Machine.Machine, Fat16.Fat16Volume, Str, Str, I64, I64, I64 => (Machine.Machine, Bool)
	fat16_mkdir_with_cluster! = |machine, vol, name, short, slot, parent, first| (if (first == 0) { (machine, False) } else { ({
		(machine1, _z) = fat16_mkdir_init_cluster!(machine, vol, first, parent, 0)
		fat16_mkdir_commit!(machine1, vol, name, short, slot, first)
	}) })

	fat16_mkdir_init_cluster! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64 => (Machine.Machine, I64)
	fat16_mkdir_init_cluster! = |machine, vol, cluster, parent, i| (if (i >= vol.vol_sectors_per_cluster) { fat16_mkdir_write_dots!(machine, vol, cluster, parent) } else { ({
		(machine1, _w) = fat16_write_data_sector!(machine, vol, (fat16_cluster_sector(vol, cluster) + i), fat16_src_empty, 0)
		fat16_mkdir_init_cluster!(machine1, vol, cluster, parent, (i + 1))
	}) })

	fat16_mkdir_write_dots! : Machine.Machine, Fat16.Fat16Volume, I64, I64 => (Machine.Machine, I64)
	fat16_mkdir_write_dots! = |machine, vol, cluster, parent| ({
		(machine1, buf) = Machine.block_read_sector!(machine, fat16_cluster_sector(vol, cluster))
		fat16_mkdir_poke_dots!(machine1, vol, cluster, parent, buf)
	})

	fat16_mkdir_poke_dots! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64 => (Machine.Machine, I64)
	fat16_mkdir_poke_dots! = |machine, vol, cluster, parent, buf| ({
		(machine1, _d1) = fat16_poke_dot_entry!(machine, buf, 0, 1, cluster)
		(machine2, _d2) = fat16_poke_dot_entry!(machine1, buf, 32, 2, parent)
		Machine.block_write_sector!(machine2, fat16_cluster_sector(vol, cluster), buf)
	})

	fat16_poke_dot_entry! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_poke_dot_entry! = |machine, buf, off, dots, cluster| ({
		(machine1, _n) = fat16_poke_dot_name!(machine, buf, off, dots)
		(machine2, _a) = Machine.store!(machine1, buf, (off + 11), 16, 1)
		(machine3, _z) = fat16_zero_run!(machine2, buf, (off + 12), 0, 14)
		(machine4, _c) = fat16_write_u16!(machine3, buf, (off + 26), cluster)
		(machine5, _s1) = fat16_write_u16!(machine4, buf, (off + 28), 0)
		fat16_write_u16!(machine5, buf, (off + 30), 0)
	})

	fat16_poke_dot_name! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	fat16_poke_dot_name! = |machine, buf, off, dots| ({
		(machine1, _d1) = Machine.store!(machine, buf, off, 46, 1)
		(machine2, _d2) = (if (dots > 1) { Machine.store!(machine1, buf, (off + 1), 46, 1) } else { (machine1, 0) })
		fat16_fill_run!(machine2, buf, (off + dots), 0, (11 - dots), 32)
	})

	fat16_fill_run! : Machine.Machine, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_fill_run! = |machine, buf, off, i, n, v| (if (i >= n) { (machine, 0) } else { ({
		(machine1, _w) = Machine.store!(machine, buf, (off + i), v, 1)
		fat16_fill_run!(machine1, buf, off, (i + 1), n, v)
	}) })

	fat16_mkdir_commit! : Machine.Machine, Fat16.Fat16Volume, Str, Str, I64, I64 => (Machine.Machine, Bool)
	fat16_mkdir_commit! = |machine, vol, name, short, slot, first| ({
		(machine1, r) = fat16_write_run!(machine, vol, name, short, slot, fat16_records_for(name))
		fat16_mkdir_place_if!(machine1, short, slot, first, fat16_records_for(name), r)
	})

	fat16_mkdir_place_if! : Machine.Machine, Str, I64, I64, I64, I64 => (Machine.Machine, Bool)
	fat16_mkdir_place_if! = |machine, short, slot, first, records, r| (if (r != 0) { (machine, False) } else { fat16_mkdir_place_entry!(machine, short, slot, first, records) })

	fat16_mkdir_place_entry! : Machine.Machine, Str, I64, I64, I64 => (Machine.Machine, Bool)
	fat16_mkdir_place_entry! = |machine, short, slot, first, records| ({
		(machine1, buf) = Machine.block_read_sector!(machine, I64.div_trunc_by((slot + (records * 32)), 512))
		fat16_mkdir_put_entry!(machine1, short, slot, first, records, buf)
	})

	fat16_mkdir_put_entry! : Machine.Machine, Str, I64, I64, I64, I64 => (Machine.Machine, Bool)
	fat16_mkdir_put_entry! = |machine, short, slot, first, records, buf| ({
		at = (slot + (records * 32))
		(machine1, _p) = fat16_poke_dir_entry!(machine, buf, Prelude.int_mod(at, 512), short, 16, first, 0)
		({
			(machine2, s) = Machine.block_write_sector!(machine1, I64.div_trunc_by(at, 512), buf)
			(machine2, (if (s == 0) { True } else { False }))
		})
	})

	fat16_read_dir_entry! : Machine.Machine, I64, I64 => (Machine.Machine, Fat16.Fat16DirEntry)
	fat16_read_dir_entry! = |machine, buf, off| ({
		(machine5, machine__97) = ({
		(machine1, name) = fat16_extract_name!(machine, buf, off)
		(machine2, attr) = Machine.load!(machine1, buf, (off + 11), 1)
		(machine3, cluster) = fat16_read_u16!(machine2, buf, (off + 26))
		(machine4, size) = fat16_read_u32!(machine3, buf, (off + 28))
		(machine4, { de_name: name, de_attr: attr, de_cluster: cluster, de_size: size })
	})
		(machine5, machine__97)
	})

	fat16_extract_name! : Machine.Machine, I64, I64 => (Machine.Machine, Str)
	fat16_extract_name! = |machine, buf, off| ({
		(machine3, machine__98) = ({
		(machine1, base) = fat16_extract_chars!(machine, buf, off, 8, "")
		(machine2, ext) = fat16_extract_chars!(machine1, buf, (off + 8), 3, "")
		trimmed_base = fat16_trim_spaces(base)
		trimmed_ext = fat16_trim_spaces(ext)
		(machine2, (if (Cce.length(trimmed_ext) == 0) { trimmed_base } else { Str.concat(Str.concat(trimmed_base, "."), trimmed_ext) }))
	})
		(machine3, machine__98)
	})

	fat16_extract_chars! : Machine.Machine, I64, I64, I64, Str => (Machine.Machine, Str)
	fat16_extract_chars! = |machine, buf, off, n, acc| (if (n == 0) { (machine, acc) } else { ({
		(machine1, c) = Machine.load!(machine, buf, off, 1)
		fat16_extract_chars!(machine1, buf, (off + 1), (n - 1), Str.concat(acc, Cce.text(CCE.from_unicode(c))))
	}) })

	fat16_trim_spaces : Str -> Str
	fat16_trim_spaces = |s| fat16_trim_loop(s, Cce.length(s))

	fat16_trim_loop : Str, I64 -> Str
	fat16_trim_loop = |s, len| (if (len == 0) { "" } else { (if (Cce.at_or_crash(s, (len - 1)) == CCE.from_unicode(32)) { fat16_trim_loop(s, (len - 1)) } else { Cce.substring(s, 0, len) }) })

	fat16_is_free_entry! : Machine.Machine, I64, I64 => (Machine.Machine, Bool)
	fat16_is_free_entry! = |machine, buf, off| ({
		(machine2, machine__99) = ({
		(machine1, first) = Machine.load!(machine, buf, off, 1)
		(machine1, ((first == 0) or (first == 229)))
	})
		(machine2, machine__99)
	})

	fat16_is_lfn_entry! : Machine.Machine, I64, I64 => (Machine.Machine, Bool)
	fat16_is_lfn_entry! = |machine, buf, off| ({
		(machine1, machine__100) = Machine.load!(machine, buf, (off + 11), 1)
		(machine1, (machine__100 == 15))
	})

	fat16_is_volume_label! : Machine.Machine, I64, I64 => (Machine.Machine, Bool)
	fat16_is_volume_label! = |machine, buf, off| ({
		(machine1, machine__101) = Machine.load!(machine, buf, (off + 11), 1)
		(machine1, (I64.bitwise_and(machine__101, 8) == 8))
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
		(machine1, machine__102) = Machine.load!(machine, buf, off, 1)
		(machine1, I64.bitwise_and(machine__102, 63))
	})

	fat16_lfn_is_last! : Machine.Machine, I64, I64 => (Machine.Machine, Bool)
	fat16_lfn_is_last! = |machine, buf, off| ({
		(machine1, machine__103) = Machine.load!(machine, buf, off, 1)
		(machine1, (I64.bitwise_and(machine__103, fat16_lfn_last) == fat16_lfn_last))
	})

	fat16_lfn_stored_sum! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	fat16_lfn_stored_sum! = |machine, buf, off| Machine.load!(machine, buf, (off + 13), 1)

	fat16_lfn_records_needed : I64 -> I64
	fat16_lfn_records_needed = |n| I64.div_trunc_by(((n + fat16_lfn_per_record) - 1), fat16_lfn_per_record)

	fat16_short_checksum! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	fat16_short_checksum! = |machine, buf, off| fat16_checksum_step!(machine, buf, off, 0, 0)

	fat16_checksum_step! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_checksum_step! = |machine, buf, off, i, sum| (if (i >= 11) { (machine, sum) } else { ({
		(machine1, machine__104) = Machine.load!(machine, buf, (off + i), 1)
		next = fat16_checksum_mix(sum, machine__104)
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
		(machine1, machine__105) = fat16_lfn_unit_at!(machine, buf, off, k)
		(if (CCE.from_unicode(machine__105) < 0) { (machine1, False) } else { fat16_lfn_units_decodable!(machine1, buf, off, (k + 1), n) })
	}) })

	fat16_lfn_decode_units! : Machine.Machine, I64, I64, I64, I64, Str => (Machine.Machine, Str)
	fat16_lfn_decode_units! = |machine, buf, off, k, n, acc| (if (k >= n) { (machine, acc) } else { ({
		(machine1, machine__106) = fat16_lfn_unit_at!(machine, buf, off, k)
		piece = Cce.text(CCE.from_unicode(machine__106))
		fat16_lfn_decode_units!(machine1, buf, off, (k + 1), n, Str.concat(acc, piece))
	}) })

	fat16_lfn_unit_of : Str, I64 -> I64
	fat16_lfn_unit_of = |name, i| ({
		c = Cce.at_or_crash(name, i)
		u = CCE.to_unicode(c)
		(if (CCE.from_unicode(u) == c) { u } else { (-1) })
	})

	fat16_lfn_name_spellable : Str, I64, I64 -> Bool
	fat16_lfn_name_spellable = |name, i, n| (if (i >= n) { True } else { (if (fat16_lfn_unit_of(name, i) < 0) { False } else { fat16_lfn_name_spellable(name, (i + 1), n) }) })

	fat16_poke_lfn_record! : Machine.Machine, I64, I64, Str, I64, I64, Bool => (Machine.Machine, I64)
	fat16_poke_lfn_record! = |machine, buf, off, name, seq, sum, last| ({
		(machine1, _o) = Machine.store!(machine, buf, off, (if last { I64.bitwise_or(seq, fat16_lfn_last) } else { seq }), 1)
		(machine2, _a) = Machine.store!(machine1, buf, (off + 11), fat16_lfn_attr, 1)
		(machine3, _t) = Machine.store!(machine2, buf, (off + 12), 0, 1)
		(machine4, _s) = Machine.store!(machine3, buf, (off + 13), sum, 1)
		(machine5, _c) = fat16_write_u16!(machine4, buf, (off + 26), 0)
		fat16_poke_lfn_units!(machine5, buf, off, name, ((seq - 1) * fat16_lfn_per_record), 0)
	})

	fat16_poke_lfn_units! : Machine.Machine, I64, I64, Str, I64, I64 => (Machine.Machine, I64)
	fat16_poke_lfn_units! = |machine, buf, off, name, base, k| (if (k >= fat16_lfn_per_record) { (machine, 0) } else { ({
		i = (base + k)
		n = Cce.length(name)
		u = (if (i < n) { fat16_lfn_unit_of(name, i) } else { (if (i == n) { 0 } else { 65535 }) })
		(machine1, _w) = fat16_write_u16!(machine, buf, (off + fat16_lfn_slot_offset(k)), u)
		fat16_poke_lfn_units!(machine1, buf, off, name, base, (k + 1))
	}) })

	fat16_lfn_none : Fat16.Fat16Lfn
	fat16_lfn_none = { lf_name: "", lf_ord: 0, lf_sum: 0, lf_live: False }

	fat16_lfn_reset : Fat16.Fat16Lfn -> Fat16.Fat16Lfn
	fat16_lfn_reset = |st| (if st.lf_live { fat16_lfn_none } else { st })

	fat16_lfn_absorb! : Machine.Machine, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Fat16.Fat16Lfn)
	fat16_lfn_absorb! = |machine, buf, off, st| ({
		(machine1, ord) = fat16_lfn_ord!(machine, buf, off)
		({
			(machine2, machine__107) = fat16_lfn_is_last!(machine1, buf, off)
			(if machine__107 { fat16_lfn_open!(machine2, buf, off, ord) } else { fat16_lfn_extend!(machine2, buf, off, ord, st) })
		})
	})

	fat16_lfn_open! : Machine.Machine, I64, I64, I64 => (Machine.Machine, Fat16.Fat16Lfn)
	fat16_lfn_open! = |machine, buf, off, ord| (if (ord < 1) { (machine, fat16_lfn_none) } else { (if (ord > fat16_lfn_max_records) { (machine, fat16_lfn_none) } else { ({
		(machine1, machine__108) = fat16_lfn_stored_sum!(machine, buf, off)
		fat16_lfn_take!(machine1, buf, off, ord, machine__108, "")
	}) }) })

	fat16_lfn_extend! : Machine.Machine, I64, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Fat16.Fat16Lfn)
	fat16_lfn_extend! = |machine, buf, off, ord, st| (if (st.lf_live == False) { (machine, fat16_lfn_none) } else { (if (ord != st.lf_ord) { (machine, fat16_lfn_none) } else { ({
		(machine1, machine__109) = fat16_lfn_stored_sum!(machine, buf, off)
		(if (machine__109 != st.lf_sum) { (machine1, fat16_lfn_none) } else { fat16_lfn_take!(machine1, buf, off, ord, st.lf_sum, st.lf_name) })
	}) }) })

	fat16_lfn_take! : Machine.Machine, I64, I64, I64, I64, Str => (Machine.Machine, Fat16.Fat16Lfn)
	fat16_lfn_take! = |machine, buf, off, ord, sum, rest| ({
		(machine6, machine__113) = ({
		(machine1, used) = fat16_lfn_units_used!(machine, buf, off, 0)
		({
			(machine2, machine__110) = fat16_lfn_units_decodable!(machine1, buf, off, 0, used)
			(machine5, machine__112) = (if (machine__110 == False) { (machine2, fat16_lfn_none) } else { ({
			(machine4, machine__111) = ({
			(machine3, part) = fat16_lfn_decode_units!(machine2, buf, off, 0, used, "")
			(machine3, { lf_name: Str.concat(part, rest), lf_ord: (ord - 1), lf_sum: sum, lf_live: True })
		})
			(machine4, machine__111)
		}) })
			(machine5, machine__112)
		})
	})
		(machine6, machine__113)
	})

	fat16_lfn_final! : Machine.Machine, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Maybe.Maybe(Str))
	fat16_lfn_final! = |machine, buf, off, st| ({
		(machine3, machine__116) = (if (st.lf_live == False) { (machine, None) } else { ({
		(machine2, machine__115) = (if (st.lf_ord != 0) { (machine, None) } else { ({
		(machine1, machine__114) = fat16_short_checksum!(machine, buf, off)
		(machine1, (if (machine__114 != st.lf_sum) { None } else { (if (Cce.length(st.lf_name) == 0) { None } else { (if (Cce.length(st.lf_name) > fat16_lfn_max_name) { None } else { Just(st.lf_name) }) }) }))
	}) })
		(machine2, machine__115)
	}) })
		(machine3, machine__116)
	})

	fat16_entry_matches! : Machine.Machine, Fat16.Fat16DirEntry, I64, I64, Fat16.Fat16Lfn, Str => (Machine.Machine, Bool)
	fat16_entry_matches! = |machine, entry, buf, off, st, name| ({
		(machine3, machine__119) = (if fat16_name_matches(entry.de_name, name) { (machine, True) } else { ({
		(machine2, machine__118) = (if (st.lf_live == False) { (machine, False) } else { ({
		(machine1, machine__117) = fat16_lfn_final!(machine, buf, off, st)
		(machine1, (match machine__117 {
		Just(n) => fat16_name_matches(n, name)
		None => False
	}))
	}) })
		(machine2, machine__118)
	}) })
		(machine3, machine__119)
	})

	fat16_alias_max_tries : I64
	fat16_alias_max_tries = 99

	fat16_alias_byte_ok : I64 -> Bool
	fat16_alias_byte_ok = |u| (if (u >= 65) { (u <= 90) } else { (if (u >= 48) { (u <= 57) } else { (if (u == 95) { True } else { (if (u == 45) { True } else { (if (u == 126) { True } else { False }) }) }) }) })

	fat16_alias_char : Str, I64 -> Str
	fat16_alias_char = |s, i| ({
		u = CCE.to_unicode(Cce.at_or_crash(s, i))
		up = (if (u >= 97) { (if (u <= 122) { (u - 32) } else { u }) } else { u })
		(if fat16_alias_byte_ok(up) { Cce.text(CCE.from_unicode(up)) } else { "_" })
	})

	fat16_alias_chars : Str, I64, I64, Str -> Str
	fat16_alias_chars = |s, i, upto, acc| (if (i >= upto) { acc } else { ({
		piece = fat16_alias_char(s, i)
		fat16_alias_chars(s, (i + 1), upto, Str.concat(acc, piece))
	}) })

	fat16_alias_base_len : Str -> I64
	fat16_alias_base_len = |name| ({
		dot = StringUtils.text_index_of(name, ".")
		(if (dot < 0) { Cce.length(name) } else { dot })
	})

	fat16_alias_ext_start : Str -> I64
	fat16_alias_ext_start = |name| ({
		dot = StringUtils.text_index_of(name, ".")
		(if (dot < 0) { Cce.length(name) } else { (dot + 1) })
	})

	fat16_alias_of : Str, I64 -> Str
	fat16_alias_of = |name, n| ({
		tag = Str.concat("~", I64.to_str(n))
		stem = fat16_alias_chars(name, 0, I64.min((8 - Cce.length(tag)), fat16_alias_base_len(name)), "")
		es = fat16_alias_ext_start(name)
		el = I64.min(3, (Cce.length(name) - es))
		(if (el <= 0) { Str.concat(stem, tag) } else { Str.concat(Str.concat(Str.concat(stem, tag), "."), fat16_alias_chars(name, es, (es + el), "")) })
	})

	fat16_short_checksum_of : Str -> I64
	fat16_short_checksum_of = |short| fat16_name_checksum_step(fat16_base_of(short), fat16_ext_of(short), 0, 0)

	fat16_name_checksum_step : Str, Str, I64, I64 -> I64
	fat16_name_checksum_step = |base, ext, i, sum| (if (i >= 11) { sum } else { ({
		b = (if (i < 8) { fat16_name_byte(base, i) } else { fat16_name_byte(ext, (i - 8)) })
		next = fat16_checksum_mix(sum, b)
		fat16_name_checksum_step(base, ext, (i + 1), next)
	}) })

	fat16_run_in_sector! : Machine.Machine, I64, I64, I64, I64, I64 => (Machine.Machine, Fat16.Fat16Run)
	fat16_run_in_sector! = |machine, buf, i, n, need, streak| (if (i >= n) { (machine, { rn_found: False, rn_at: 0, rn_streak: streak }) } else { ({
		(machine1, machine__120) = fat16_is_free_entry!(machine, buf, (i * 32))
		(if (machine__120 == False) { fat16_run_in_sector!(machine1, buf, (i + 1), n, need, 0) } else { (if ((streak + 1) >= need) { (machine1, { rn_found: True, rn_at: ((i + 1) - need), rn_streak: need }) } else { fat16_run_in_sector!(machine1, buf, (i + 1), n, need, (streak + 1)) }) })
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

	fat16_records_for : Str -> I64
	fat16_records_for = |name| (if (fat16_needs_long(name) == False) { 0 } else { fat16_lfn_records_needed(Cce.length(name)) })

	fat16_slots_for : Str -> I64
	fat16_slots_for = |name| (fat16_records_for(name) + 1)

	fat16_write_run! : Machine.Machine, Fat16.Fat16Volume, Str, Str, I64, I64 => (Machine.Machine, I64)
	fat16_write_run! = |machine, vol, name, short, slot, records| fat16_write_run_step!(machine, vol, name, fat16_short_checksum_of(short), slot, records, 0)

	fat16_write_run_step! : Machine.Machine, Fat16.Fat16Volume, Str, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_write_run_step! = |machine, vol, name, sum, slot, records, j| (if (j >= records) { (machine, 0) } else { ({
		(machine1, w) = fat16_write_lfn_slot!(machine, name, sum, (slot + (j * 32)), (records - j), (j == 0))
		fat16_write_run_next!(machine1, vol, name, sum, slot, records, j, w)
	}) })

	fat16_write_run_next! : Machine.Machine, Fat16.Fat16Volume, Str, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	fat16_write_run_next! = |machine, vol, name, sum, slot, records, j, w| (if (w != 0) { (machine, w) } else { fat16_write_run_step!(machine, vol, name, sum, slot, records, (j + 1)) })

	fat16_write_lfn_slot! : Machine.Machine, Str, I64, I64, I64, Bool => (Machine.Machine, I64)
	fat16_write_lfn_slot! = |machine, name, sum, at, seq, last| ({
		(machine1, h) = Machine.mark(machine)
		({
			(machine2, buf) = Machine.block_read_sector!(machine1, I64.div_trunc_by(at, 512))
			(machine3, r) = fat16_put_lfn_slot!(machine2, name, sum, at, seq, last, buf)
			(machine3, fat16_drop_to(h, r))
		})
	})

	fat16_put_lfn_slot! : Machine.Machine, Str, I64, I64, I64, Bool, I64 => (Machine.Machine, I64)
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
		off = Prelude.int_mod(at, 512)
		({
			(machine1, machine__121) = fat16_is_lfn_entry!(machine, buf, off)
			(if (machine__121 == False) { (machine1, 0) } else { ({
			(machine2, machine__122) = fat16_lfn_stored_sum!(machine1, buf, off)
			(if (machine__122 != sum) { (machine2, 0) } else { ({
			(machine3, _m) = fat16_mark_free!(machine2, at)
			fat16_erase_run!(machine3, (at - 32), sum, (steps + 1), floor)
		}) })
		}) })
		})
	})

	fat16_find_in_root! : Machine.Machine, Fat16.Fat16Volume, Str => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_find_in_root! = |machine, vol, name| ({
		root_sectors = I64.div_trunc_by((((vol.vol_root_entry_count * 32) + vol.vol_bytes_per_sector) - 1), vol.vol_bytes_per_sector)
		fat16_scan_root_sectors!(machine, vol, name, vol.vol_root_start, root_sectors, 0, fat16_lfn_none)
	})

	fat16_scan_root_sectors! : Machine.Machine, Fat16.Fat16Volume, Str, I64, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_scan_root_sectors! = |machine, vol, name, sector, remaining, entries_checked, st| (if (remaining == 0) { (machine, None) } else { (if (entries_checked >= vol.vol_root_entry_count) { (machine, None) } else { ({
		(machine1, buf) = Machine.block_read_sector!(machine, sector)
		fat16_scan_root_step!(machine1, vol, name, sector, remaining, entries_checked, buf, st)
	}) }) })

	fat16_scan_root_step! : Machine.Machine, Fat16.Fat16Volume, Str, I64, I64, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_scan_root_step! = |machine, vol, name, sector, remaining, entries_checked, buf, st| ({
		entries_per_sector = I64.div_trunc_by(vol.vol_bytes_per_sector, 32)
		(machine1, r) = fat16_scan_sector_lfn!(machine, buf, name, 0, entries_per_sector, st)
		(match r.sc_found {
			Just(entry) => (machine1, Just(entry))
			None => fat16_scan_root_sectors!(machine1, vol, name, (sector + 1), (remaining - 1), (entries_checked + entries_per_sector), r.sc_lfn)
		})
	})

	fat16_scan_sector_lfn! : Machine.Machine, I64, Str, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Fat16.Fat16Scan)
	fat16_scan_sector_lfn! = |machine, buf, name, i, count, st| (if (i >= count) { (machine, { sc_found: None, sc_lfn: st }) } else { ({
		off = (i * 32)
		({
			(machine1, machine__123) = fat16_is_free_entry!(machine, buf, off)
			(if machine__123 { ({
			(machine2, machine__124) = Machine.load!(machine1, buf, off, 1)
			(if (machine__124 == 0) { (machine2, { sc_found: None, sc_lfn: fat16_lfn_reset(st) }) } else { fat16_scan_sector_lfn!(machine2, buf, name, (i + 1), count, fat16_lfn_reset(st)) })
		}) } else { ({
			(machine3, machine__125) = fat16_is_lfn_entry!(machine1, buf, off)
			(if machine__125 { ({
			(machine4, machine__126) = fat16_lfn_absorb!(machine3, buf, off, st)
			fat16_scan_sector_lfn!(machine4, buf, name, (i + 1), count, machine__126)
		}) } else { ({
			(machine5, machine__127) = fat16_is_volume_label!(machine3, buf, off)
			(if machine__127 { fat16_scan_sector_lfn!(machine5, buf, name, (i + 1), count, fat16_lfn_reset(st)) } else { ({
			(machine6, entry) = fat16_read_dir_entry!(machine5, buf, off)
			({
				(machine7, machine__128) = fat16_entry_matches!(machine6, entry, buf, off, st, name)
				(if machine__128 { (machine7, { sc_found: Just(entry), sc_lfn: st }) } else { fat16_scan_sector_lfn!(machine7, buf, name, (i + 1), count, fat16_lfn_reset(st)) })
			})
		}) })
		}) })
		}) })
		})
	}) })

	fat16_scan_sector_entries! : Machine.Machine, I64, Str, I64, I64 => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_scan_sector_entries! = |machine, buf, name, i, count| (if (i >= count) { (machine, None) } else { ({
		off = (i * 32)
		({
			(machine1, machine__129) = fat16_is_free_entry!(machine, buf, off)
			(if machine__129 { ({
			(machine2, machine__130) = Machine.load!(machine1, buf, off, 1)
			(if (machine__130 == 0) { (machine2, None) } else { fat16_scan_sector_entries!(machine2, buf, name, (i + 1), count) })
		}) } else { ({
			(machine3, machine__131) = fat16_is_lfn_entry!(machine1, buf, off)
			(if machine__131 { fat16_scan_sector_entries!(machine3, buf, name, (i + 1), count) } else { ({
			(machine4, machine__132) = fat16_is_volume_label!(machine3, buf, off)
			(if machine__132 { fat16_scan_sector_entries!(machine4, buf, name, (i + 1), count) } else { ({
			(machine5, entry) = fat16_read_dir_entry!(machine4, buf, off)
			(if fat16_name_matches(entry.de_name, name) { (machine5, Just(entry)) } else { fat16_scan_sector_entries!(machine5, buf, name, (i + 1), count) })
		}) })
		}) })
		}) })
		})
	}) })

	fat16_find_in_cluster_dir! : Machine.Machine, Fat16.Fat16Volume, I64, Str => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_find_in_cluster_dir! = |machine, vol, cluster, name| fat16_find_in_cluster_walk!(machine, vol, cluster, name, cluster, 1, 0, fat16_lfn_none)

	fat16_find_in_cluster_walk! : Machine.Machine, Fat16.Fat16Volume, I64, Str, I64, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_find_in_cluster_walk! = |machine, vol, cluster, name, saved, power, steps, st| (if fat16_is_end(cluster) { (machine, None) } else { ({
		(machine1, r) = fat16_scan_cluster_sectors!(machine, vol, name, fat16_cluster_sector(vol, cluster), vol.vol_sectors_per_cluster, st)
		fat16_cluster_found_or_next!(machine1, vol, cluster, name, saved, power, steps, r)
	}) })

	fat16_cluster_found_or_next! : Machine.Machine, Fat16.Fat16Volume, I64, Str, I64, I64, I64, Fat16.Fat16Scan => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_cluster_found_or_next! = |machine, vol, cluster, name, saved, power, steps, r| (match r.sc_found {
		Just(entry) => (machine, Just(entry))
		None => fat16_find_in_cluster_step!(machine, vol, cluster, name, saved, power, steps, r.sc_lfn)
	})

	fat16_find_in_cluster_step! : Machine.Machine, Fat16.Fat16Volume, I64, Str, I64, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_find_in_cluster_step! = |machine, vol, cluster, name, saved, power, steps, st| ({
		(machine1, nxt) = fat16_next_cluster!(machine, vol, cluster)
		(if (nxt == saved) { (machine1, None) } else { (if ((steps + 1) == power) { fat16_find_in_cluster_walk!(machine1, vol, nxt, name, nxt, (power * 2), 0, st) } else { fat16_find_in_cluster_walk!(machine1, vol, nxt, name, saved, power, (steps + 1), st) }) })
	})

	fat16_scan_cluster_sectors! : Machine.Machine, Fat16.Fat16Volume, Str, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Fat16.Fat16Scan)
	fat16_scan_cluster_sectors! = |machine, vol, name, sector, remaining, st| (if (remaining == 0) { (machine, { sc_found: None, sc_lfn: st }) } else { ({
		(machine1, buf) = Machine.block_read_sector!(machine, sector)
		fat16_scan_cluster_step!(machine1, vol, name, sector, remaining, buf, st)
	}) })

	fat16_scan_cluster_step! : Machine.Machine, Fat16.Fat16Volume, Str, I64, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Fat16.Fat16Scan)
	fat16_scan_cluster_step! = |machine, vol, name, sector, remaining, buf, st| ({
		entries_per_sector = I64.div_trunc_by(vol.vol_bytes_per_sector, 32)
		(machine1, r) = fat16_scan_sector_lfn!(machine, buf, name, 0, entries_per_sector, st)
		(match r.sc_found {
			Just(_e) => (machine1, r)
			None => fat16_scan_cluster_sectors!(machine1, vol, name, (sector + 1), (remaining - 1), r.sc_lfn)
		})
	})

	fat16_name_matches : Str, Str -> Bool
	fat16_name_matches = |entry_name, search_name| (fat16_upper(entry_name) == fat16_upper(search_name))

	fat16_upper : Str -> Str
	fat16_upper = |s| fat16_upper_loop(s, 0, Cce.length(s), "")

	fat16_upper_loop : Str, I64, I64, Str -> Str
	fat16_upper_loop = |s, i, len, acc| (if (i >= len) { acc } else { ({
		c = Cce.at_or_crash(s, i)
		fat16_upper_loop(s, (i + 1), len, Str.concat(acc, Cce.text(CCE.to_upper(c))))
	}) })

	fat16_scope_admits! : Machine.Machine, Str => (Machine.Machine, Bool)
	fat16_scope_admits! = |machine, path| ({
		(machine3, machine__134) = ({
		(machine2, grant) = ({
			(machine1, machine__133) = Machine.process_get_pid(machine)
			Machine.process_get_scope(machine1, machine__133)
		})
		(machine2, (if (Cce.length(grant) == 0) { True } else { StringUtils.text_starts_with(path, grant) }))
	})
		(machine3, machine__134)
	})

	fat16_resolve_path! : Machine.Machine, Fat16.Fat16Volume, Str => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_resolve_path! = |machine, vol, path| ({
		(machine1, machine__135) = fat16_scope_admits!(machine, path)
		(if (machine__135 == False) { (machine1, None) } else { ({
		parts = fat16_split_path(path)
		fat16_walk_path!(machine1, vol, parts, 0, U64.to_i64_wrap(List.len(parts)))
	}) })
	})

	fat16_walk_path! : Machine.Machine, Fat16.Fat16Volume, List(Str), I64, I64 => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_walk_path! = |machine, vol, parts, depth, total| (if (depth >= total) { (machine, None) } else { ({
		name = (List.get(parts, I64.to_u64_wrap(depth)) ?? crash("list-at out of range"))
		({
			(machine1, machine__136) = (if (depth == 0) { fat16_find_in_root!(machine, vol, name) } else { (machine, None) })
			(match machine__136 {
			Just(entry) => (if (depth == (total - 1)) { (machine1, Just(entry)) } else { (if (I64.bitwise_and(entry.de_attr, 16) == 16) { fat16_walk_path_sub!(machine1, vol, parts, (depth + 1), total, entry.de_cluster) } else { (machine1, None) }) })
			None => (machine1, None)
		})
		})
	}) })

	fat16_walk_path_sub! : Machine.Machine, Fat16.Fat16Volume, List(Str), I64, I64, I64 => (Machine.Machine, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_walk_path_sub! = |machine, vol, parts, depth, total, cluster| (if (depth >= total) { (machine, None) } else { ({
		name = (List.get(parts, I64.to_u64_wrap(depth)) ?? crash("list-at out of range"))
		({
			(machine1, machine__137) = fat16_find_in_cluster_dir!(machine, vol, cluster, name)
			(match machine__137 {
			Just(entry) => (if (depth == (total - 1)) { (machine1, Just(entry)) } else { (if (I64.bitwise_and(entry.de_attr, 16) == 16) { fat16_walk_path_sub!(machine1, vol, parts, (depth + 1), total, entry.de_cluster) } else { (machine1, None) }) })
			None => (machine1, None)
		})
		})
	}) })

	fat16_split_path : Str -> List(Str)
	fat16_split_path = |path| fat16_split_loop(path, 0, Cce.length(path), 0, [])

	fat16_split_loop : Str, I64, I64, I64, List(Str) -> List(Str)
	fat16_split_loop = |s, i, len, start, acc| (if (i >= len) { (if (i > start) { List.append(acc, Cce.substring(s, start, (i - start))) } else { acc }) } else { (if (Cce.at_or_crash(s, i) == CCE.from_unicode(47)) { (if (i > start) { fat16_split_loop(s, (i + 1), len, (i + 1), List.append(acc, Cce.substring(s, start, (i - start)))) } else { fat16_split_loop(s, (i + 1), len, (i + 1), acc) }) } else { fat16_split_loop(s, (i + 1), len, start, acc) }) })

	fat16_read_cluster_bytes! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64, List(I64) => (Machine.Machine, List(I64))
	fat16_read_cluster_bytes! = |machine, vol, cluster, remaining, sector_off, acc| (if (remaining <= 0) { (machine, acc) } else { (if fat16_is_end(cluster) { (machine, acc) } else { ({
		(machine1, buf) = Machine.block_read_sector!(machine, (fat16_cluster_sector(vol, cluster) + sector_off))
		fat16_read_cluster_step!(machine1, vol, cluster, remaining, sector_off, acc, buf)
	}) }) })

	fat16_read_cluster_step! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64, List(I64), I64 => (Machine.Machine, List(I64))
	fat16_read_cluster_step! = |machine, vol, cluster, remaining, sector_off, acc, buf| ({
		bytes_this = (if (remaining < vol.vol_bytes_per_sector) { remaining } else { vol.vol_bytes_per_sector })
		(machine1, acc2) = fat16_copy_bytes!(machine, buf, 0, bytes_this, acc)
		next_sector_off = (sector_off + 1)
		(if (next_sector_off >= vol.vol_sectors_per_cluster) { ({
			(machine2, machine__138) = fat16_next_cluster!(machine1, vol, cluster)
			fat16_read_cluster_bytes!(machine2, vol, machine__138, (remaining - bytes_this), 0, acc2)
		}) } else { fat16_read_cluster_bytes!(machine1, vol, cluster, (remaining - bytes_this), next_sector_off, acc2) })
	})

	fat16_copy_bytes! : Machine.Machine, I64, I64, I64, List(I64) => (Machine.Machine, List(I64))
	fat16_copy_bytes! = |machine, buf, off, count, acc| (if (count <= 0) { (machine, acc) } else { ({
		(machine1, machine__139) = Machine.load!(machine, buf, off, 1)
		fat16_copy_bytes!(machine1, buf, (off + 1), (count - 1), List.append(acc, machine__139))
	}) })

	fat16_read_bytes! : Machine.Machine, Fat16.Fat16Volume, Str => (Machine.Machine, Maybe.Maybe(List(I64)))
	fat16_read_bytes! = |machine, vol, path| ({
		(machine4, machine__143) = (if (fat16_vol_is_usable(vol) == False) { (machine, None) } else { ({
		(machine1, machine__140) = fat16_resolve_path!(machine, vol, path)
		(machine3, machine__142) = (match machine__140 {
		Just(entry) => ({
			(machine2, machine__141) = fat16_read_cluster_bytes!(machine1, vol, entry.de_cluster, entry.de_size, 0, [])
			(machine2, Just(machine__141))
		})
		None => (machine1, None)
	})
		(machine3, machine__142)
	}) })
		(machine4, machine__143)
	})

	fat16_byte_to_cce : List(I64), I64 -> I64
	fat16_byte_to_cce = |tbl, b| ({
		t0 = CCE.from_unicode_tier0(tbl, b, 0, 128)
		(if (t0 >= 0) { t0 } else { CCE.from_unicode(b) })
	})

	fat16_bytes_to_chars : List(I64), List(I64), I64, I64, List(Str) -> List(Str)
	fat16_bytes_to_chars = |tbl, bs, i, len, acc| (if (i >= len) { acc } else { fat16_bytes_to_chars(tbl, bs, (i + 1), len, List.append(acc, Cce.text(fat16_byte_to_cce(tbl, (List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))) })

	fat16_bytes_to_text : List(I64), I64, I64, Str -> Str
	fat16_bytes_to_text = |bs, i, len, acc| Str.concat(acc, Str.join_with(fat16_bytes_to_chars(CCE.cce_to_unicode_table, bs, i, len, []), ""))

	fat16_read_text! : Machine.Machine, Fat16.Fat16Volume, Str => (Machine.Machine, Maybe.Maybe(Str))
	fat16_read_text! = |machine, vol, path| ({
		(machine1, machine__144) = fat16_read_bytes!(machine, vol, path)
		(machine1, (match machine__144 {
		Just(bs) => Just(fat16_bytes_to_text(bs, 0, U64.to_i64_wrap(List.len(bs)), ""))
		None => None
	}))
	})

	fat16_source_chars : List(I64), List(I64), I64, I64, List(Str) -> List(Str)
	fat16_source_chars = |tbl, bs, i, len, acc| (if (i >= len) { acc } else { (if ((List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) == 13) { fat16_source_chars(tbl, bs, (i + 1), len, acc) } else { fat16_source_chars(tbl, bs, (i + 1), len, List.append(acc, Cce.text(fat16_byte_to_cce(tbl, (List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))) }) })

	fat16_read_source! : Machine.Machine, Fat16.Fat16Volume, Str => (Machine.Machine, Maybe.Maybe(Str))
	fat16_read_source! = |machine, vol, path| ({
		(machine1, machine__145) = fat16_read_bytes!(machine, vol, path)
		(machine1, (match machine__145 {
		Just(bs) => Just(Str.join_with(fat16_source_chars(CCE.cce_to_unicode_table, bs, 0, U64.to_i64_wrap(List.len(bs)), []), ""))
		None => None
	}))
	})

	fat16_file_exists! : Machine.Machine, Fat16.Fat16Volume, Str => (Machine.Machine, Bool)
	fat16_file_exists! = |machine, vol, path| ({
		(machine1, machine__146) = fat16_resolve_path!(machine, vol, path)
		(machine1, (match machine__146 {
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
		(machine1, machine__147) = Machine.load!(machine, buf, 11, 1)
		(machine2, machine__148) = Machine.load!(machine1, buf, 12, 1)
		bps = (machine__147 + (machine__148 * 256))
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

	file_exists! : Machine.Machine, Str => (Machine.Machine, Bool)
	file_exists! = |machine, path| fat16_exists_on_disk!(machine, path)

	fat16_exists_on_disk! : Machine.Machine, Str => (Machine.Machine, Bool)
	fat16_exists_on_disk! = |machine, path| ({
		(machine1, vol) = fat16_boot_volume!(machine)
		(if (fat16_vol_is_usable(vol) == False) { (machine1, False) } else { fat16_file_exists!(machine1, vol, path) })
	})

	fat16_text_bytes : Str, I64, I64, List(I64) -> List(I64)
	fat16_text_bytes = |s, i, n, acc| (if (i >= n) { acc } else { ({
		b = CCE.to_unicode(Cce.at_or_crash(s, i))
		fat16_text_bytes(s, (i + 1), n, List.append(acc, b))
	}) })

	fat16_write_file! : Machine.Machine, Str, Str => (Machine.Machine, Bool)
	fat16_write_file! = |machine, path, content| ({
		bytes = fat16_text_bytes(content, 0, Cce.length(content), [])
		fat16_write_binary_file!(machine, path, bytes)
	})

	fat16_write_binary_file! : Machine.Machine, Str, List(I64) => (Machine.Machine, Bool)
	fat16_write_binary_file! = |machine, path, bytes| fat16_write_source!(machine, path, fat16_src_of_list(bytes))

	fat16_write_segments! : Machine.Machine, Str, List(I64), I64, I64, List(I64) => (Machine.Machine, Bool)
	fat16_write_segments! = |machine, path, head, buf, blen, tail| fat16_write_source!(machine, path, fat16_src_of_parts(head, buf, blen, tail))

	fat16_write_source! : Machine.Machine, Str, Fat16.Fat16Source => (Machine.Machine, Bool)
	fat16_write_source! = |machine, path, src| ({
		(machine1, vol) = fat16_boot_volume!(machine)
		fat16_create_file!(machine1, vol, path, src)
	})

	fat16_list_root! : Machine.Machine, Fat16.Fat16Volume => (Machine.Machine, List(Str))
	fat16_list_root! = |machine, vol| ({
		(machine1, machine__149) = fat16_scope_admits!(machine, "/")
		(if (machine__149 == False) { (machine1, []) } else { ({
		(machine2, es) = fat16_root_entries!(machine1, vol)
		(machine2, fat16_entry_names(es, 0, U64.to_i64_wrap(List.len(es)), []))
	}) })
	})

	fat16_entry_names : List(Fat16.Fat16DirEntry), I64, I64, List(Str) -> List(Str)
	fat16_entry_names = |es, i, n, acc| (if (i >= n) { acc } else { fat16_entry_names(es, (i + 1), n, List.append(acc, (List.get(es, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).de_name)) })

	fat16_list_sector_entries! : Machine.Machine, I64, I64, I64, List(Str) => (Machine.Machine, List(Str))
	fat16_list_sector_entries! = |machine, buf, i, count, acc| (if (i >= count) { (machine, acc) } else { ({
		off = (i * 32)
		({
			(machine1, machine__150) = fat16_is_free_entry!(machine, buf, off)
			(if machine__150 { ({
			(machine2, machine__151) = Machine.load!(machine1, buf, off, 1)
			(if (machine__151 == 0) { (machine2, acc) } else { fat16_list_sector_entries!(machine2, buf, (i + 1), count, acc) })
		}) } else { ({
			(machine3, machine__152) = fat16_is_lfn_entry!(machine1, buf, off)
			(if machine__152 { fat16_list_sector_entries!(machine3, buf, (i + 1), count, acc) } else { ({
			(machine4, machine__153) = fat16_is_volume_label!(machine3, buf, off)
			(if machine__153 { fat16_list_sector_entries!(machine4, buf, (i + 1), count, acc) } else { ({
			(machine5, entry) = fat16_read_dir_entry!(machine4, buf, off)
			fat16_list_sector_entries!(machine5, buf, (i + 1), count, List.append(acc, entry.de_name))
		}) })
		}) })
		}) })
		})
	}) })

	fat16_read_entry_named! : Machine.Machine, I64, I64, Fat16.Fat16Lfn => (Machine.Machine, Fat16.Fat16DirEntry)
	fat16_read_entry_named! = |machine, buf, off, st| ({
		(machine3, machine__155) = ({
		(machine1, e) = fat16_read_dir_entry!(machine, buf, off)
		({
			(machine2, machine__154) = fat16_lfn_final!(machine1, buf, off, st)
			(machine2, (match machine__154 {
			Just(n) => { de_name: n, de_attr: e.de_attr, de_cluster: e.de_cluster, de_size: e.de_size }
			None => e
		}))
		})
	})
		(machine3, machine__155)
	})

	fat16_entries_in_sector! : Machine.Machine, I64, I64, I64, List(Fat16.Fat16DirEntry), Fat16.Fat16Lfn => (Machine.Machine, Fat16.Fat16List)
	fat16_entries_in_sector! = |machine, buf, i, count, acc, st| (if (i >= count) { (machine, { li_entries: acc, li_lfn: st }) } else { ({
		off = (i * 32)
		({
			(machine1, machine__156) = fat16_is_free_entry!(machine, buf, off)
			(if machine__156 { ({
			(machine2, machine__157) = Machine.load!(machine1, buf, off, 1)
			(if (machine__157 == 0) { (machine2, { li_entries: acc, li_lfn: fat16_lfn_reset(st) }) } else { fat16_entries_in_sector!(machine2, buf, (i + 1), count, acc, fat16_lfn_reset(st)) })
		}) } else { ({
			(machine3, machine__158) = fat16_is_lfn_entry!(machine1, buf, off)
			(if machine__158 { ({
			(machine4, machine__159) = fat16_lfn_absorb!(machine3, buf, off, st)
			fat16_entries_in_sector!(machine4, buf, (i + 1), count, acc, machine__159)
		}) } else { ({
			(machine5, machine__160) = fat16_is_volume_label!(machine3, buf, off)
			(if machine__160 { fat16_entries_in_sector!(machine5, buf, (i + 1), count, acc, fat16_lfn_reset(st)) } else { ({
			(machine6, named) = fat16_read_entry_named!(machine5, buf, off, st)
			fat16_entries_in_sector!(machine6, buf, (i + 1), count, List.append(acc, named), fat16_lfn_reset(st))
		}) })
		}) })
		}) })
		})
	}) })

	fat16_root_entries! : Machine.Machine, Fat16.Fat16Volume => (Machine.Machine, List(Fat16.Fat16DirEntry))
	fat16_root_entries! = |machine, vol| ({
		(machine1, machine__161) = fat16_scope_admits!(machine, "/")
		(if (machine__161 == False) { (machine1, []) } else { ({
		root_sectors = I64.div_trunc_by((((vol.vol_root_entry_count * 32) + vol.vol_bytes_per_sector) - 1), vol.vol_bytes_per_sector)
		fat16_root_entry_sectors!(machine1, vol, vol.vol_root_start, root_sectors, 0, [], fat16_lfn_none)
	}) })
	})

	fat16_root_entry_sectors! : Machine.Machine, Fat16.Fat16Volume, I64, I64, I64, List(Fat16.Fat16DirEntry), Fat16.Fat16Lfn => (Machine.Machine, List(Fat16.Fat16DirEntry))
	fat16_root_entry_sectors! = |machine, vol, sector, remaining, checked, acc, st| (if (remaining == 0) { (machine, acc) } else { (if (checked >= vol.vol_root_entry_count) { (machine, acc) } else { ({
		(machine1, buf) = Machine.block_read_sector!(machine, sector)
		({
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
	fat16_cluster_entry_sectors! = |machine, vol, sector, remaining, acc, st| (if (remaining == 0) { (machine, { li_entries: acc, li_lfn: st }) } else { ({
		(machine1, buf) = Machine.block_read_sector!(machine, sector)
		({
			per = I64.div_trunc_by(vol.vol_bytes_per_sector, 32)
			(machine2, r) = fat16_entries_in_sector!(machine1, buf, 0, per, acc, st)
			fat16_cluster_entry_sectors!(machine2, vol, (sector + 1), (remaining - 1), r.li_entries, r.li_lfn)
		})
	}) })

	fat16_is_root_path : Str -> Bool
	fat16_is_root_path = |p| (((Cce.length(p) == 0) or (p == "/")) or (p == "."))

	fat16_is_dir_entry : Fat16.Fat16DirEntry -> Bool
	fat16_is_dir_entry = |e| (I64.bitwise_and(e.de_attr, 16) == 16)

	fat16_list_dir! : Machine.Machine, Fat16.Fat16Volume, Str => (Machine.Machine, List(Fat16.Fat16DirEntry))
	fat16_list_dir! = |machine, vol, path| (if fat16_is_root_path(path) { fat16_root_entries!(machine, vol) } else { ({
		(machine1, found) = fat16_resolve_path!(machine, vol, path)
		(match found {
			Just(entry) => (if fat16_is_dir_entry(entry) { fat16_cluster_entries!(machine1, vol, entry.de_cluster, []) } else { (machine1, []) })
			None => (machine1, [])
		})
	}) })

	list_files! : Machine.Machine, Str, Str => (Machine.Machine, List(Str))
	list_files! = |machine, dir, ext| ({
		(machine1, vol) = fat16_boot_volume!(machine)
		(if (fat16_vol_is_usable(vol) == False) { (machine1, []) } else { ({
			(machine2, entries) = fat16_list_dir!(machine1, vol, dir)
			(machine2, fat16_pick_files(entries, 0, U64.to_i64_wrap(List.len(entries)), ext, []))
		}) })
	})

	fat16_pick_files : List(Fat16.Fat16DirEntry), I64, I64, Str, List(Str) -> List(Str)
	fat16_pick_files = |es, i, n, ext, acc| (if (i >= n) { acc } else { ({
		e = (List.get(es, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if fat16_is_dir_entry(e) { fat16_pick_files(es, (i + 1), n, ext, acc) } else { (if fat16_name_has_ext(e.de_name, ext) { fat16_pick_files(es, (i + 1), n, ext, List.append(acc, e.de_name)) } else { fat16_pick_files(es, (i + 1), n, ext, acc) }) })
	}) })

	fat16_name_has_ext : Str, Str -> Bool
	fat16_name_has_ext = |name, ext| (if (Cce.length(ext) == 0) { True } else { StringUtils.text_ends_with(fat16_upper(name), fat16_upper(ext)) })

	list_directories! : Machine.Machine, Str => (Machine.Machine, List(Str))
	list_directories! = |machine, dir| ({
		(machine1, vol) = fat16_boot_volume!(machine)
		(if (fat16_vol_is_usable(vol) == False) { (machine1, []) } else { ({
			(machine2, entries) = fat16_list_dir!(machine1, vol, dir)
			(machine2, fat16_pick_dirs(entries, 0, U64.to_i64_wrap(List.len(entries)), []))
		}) })
	})

	fat16_pick_dirs : List(Fat16.Fat16DirEntry), I64, I64, List(Str) -> List(Str)
	fat16_pick_dirs = |es, i, n, acc| (if (i >= n) { acc } else { ({
		e = (List.get(es, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (fat16_is_dir_entry(e) == False) { fat16_pick_dirs(es, (i + 1), n, acc) } else { (if (e.de_name == ".") { fat16_pick_dirs(es, (i + 1), n, acc) } else { (if (e.de_name == "..") { fat16_pick_dirs(es, (i + 1), n, acc) } else { fat16_pick_dirs(es, (i + 1), n, List.append(acc, e.de_name)) }) }) })
	}) })
}
