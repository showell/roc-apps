# Fat16 -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CCE
import Cce
import Gpt
import Maybe
import Mem
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

	fat16_read_u16! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	fat16_read_u16! = |mem, buf, off| ({
		(mem1, mem__329) = Mem.load!(mem, buf, off, 1)
		(mem2, mem__330) = Mem.load!(mem1, buf, (off + 1), 1)
		(mem2, I64.bitwise_or(mem__329, I64.shl_wrap(mem__330, I64.to_u8_wrap(8))))
	})

	fat16_read_u32! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	fat16_read_u32! = |mem, buf, off| ({
		(mem1, mem__331) = fat16_read_u16!(mem, buf, off)
		(mem2, mem__332) = fat16_read_u16!(mem1, buf, (off + 2))
		(mem2, I64.bitwise_or(mem__331, I64.shl_wrap(mem__332, I64.to_u8_wrap(16))))
	})

	fat16_init! : Mem.Mem, I64 => (Mem.Mem, Fat16.Fat16Volume)
	fat16_init! = |_, _| crash("`fat16-init` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_zero_volume : I64 -> Fat16.Fat16Volume
	fat16_zero_volume = |part_start| { vol_part_start: part_start, vol_bytes_per_sector: 0, vol_sectors_per_cluster: 0, vol_reserved_sectors: 0, vol_num_fats: 0, vol_root_entry_count: 0, vol_fat_sectors: 0, vol_fat_start: 0, vol_root_start: 0, vol_data_start: 0, vol_total_sectors: 0, vol_cluster_count: 0 }

	fat16_parse_bpb! : Mem.Mem, I64, I64 => (Mem.Mem, Fat16.Fat16Volume)
	fat16_parse_bpb! = |mem, part_start, buf| ({
		(mem11, mem__336) = ({
		(mem1, bps) = fat16_read_u16!(mem, buf, 11)
		(mem2, spc) = Mem.load!(mem1, buf, 13, 1)
		({
			(mem10, mem__335) = (if (bps == 0) { (mem2, fat16_zero_volume(part_start)) } else { ({
			(mem9, mem__334) = (if (spc == 0) { (mem2, fat16_zero_volume(part_start)) } else { ({
			(mem8, mem__333) = ({
			(mem3, reserved) = fat16_read_u16!(mem2, buf, 14)
			(mem4, nfats) = Mem.load!(mem3, buf, 16, 1)
			(mem5, root_cnt) = fat16_read_u16!(mem4, buf, 17)
			(mem6, fat_sz) = fat16_read_u16!(mem5, buf, 22)
			fat_start = (part_start + reserved)
			root_dir_sectors = I64.div_trunc_by((((root_cnt * 32) + bps) - 1), bps)
			root_start = (fat_start + (nfats * fat_sz))
			data_start = (root_start + root_dir_sectors)
			(mem7, total) = fat16_total_sectors!(mem6, buf)
			data_sectors = (total - (data_start - part_start))
			raw_clusters = (if (data_sectors <= 0) { 0 } else { I64.div_trunc_by(data_sectors, spc) })
			clusters = (if (raw_clusters > 65524) { 65524 } else { raw_clusters })
			(mem7, { vol_part_start: part_start, vol_bytes_per_sector: bps, vol_sectors_per_cluster: spc, vol_reserved_sectors: reserved, vol_num_fats: nfats, vol_root_entry_count: root_cnt, vol_fat_sectors: fat_sz, vol_fat_start: fat_start, vol_root_start: root_start, vol_data_start: data_start, vol_total_sectors: total, vol_cluster_count: clusters })
		})
			(mem8, mem__333)
		}) })
			(mem9, mem__334)
		}) })
			(mem10, mem__335)
		})
	})
		(mem11, mem__336)
	})

	fat16_total_sectors! : Mem.Mem, I64 => (Mem.Mem, I64)
	fat16_total_sectors! = |mem, buf| ({
		(mem1, small) = fat16_read_u16!(mem, buf, 19)
		(if (small == 0) { fat16_read_u32!(mem1, buf, 32) } else { (mem1, small) })
	})

	fat16_cluster_ok : Fat16.Fat16Volume, I64 -> Bool
	fat16_cluster_ok = |vol, cluster| ((cluster >= 2) and (cluster <= fat16_last_cluster(vol)))

	fat16_next_cluster! : Mem.Mem, Fat16.Fat16Volume, I64 => (Mem.Mem, I64)
	fat16_next_cluster! = |_, _, _| crash("`fat16-next-cluster` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_is_end : I64 -> Bool
	fat16_is_end = |cluster| (cluster >= 65528)

	fat16_cluster_sector : Fat16.Fat16Volume, I64 -> I64
	fat16_cluster_sector = |vol, cluster| (vol.vol_data_start + ((cluster - 2) * vol.vol_sectors_per_cluster))

	fat16_write_u16! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	fat16_write_u16! = |mem, buf, off, val| ({
		(mem1, _lo) = Mem.store!(mem, buf, off, I64.bitwise_and(val, 255), 1)
		Mem.store!(mem1, buf, (off + 1), I64.bitwise_and(I64.shr_zf_wrap(val, I64.to_u8_wrap(8)), 255), 1)
	})

	fat16_fat_entry_sector : Fat16.Fat16Volume, I64, I64 -> I64
	fat16_fat_entry_sector = |vol, fat_index, cluster| ((vol.vol_fat_start + (fat_index * vol.vol_fat_sectors)) + I64.div_trunc_by((cluster * 2), vol.vol_bytes_per_sector))

	fat16_fat_entry_offset : Fat16.Fat16Volume, I64 -> I64
	fat16_fat_entry_offset = |vol, cluster| Prelude.int_mod((cluster * 2), vol.vol_bytes_per_sector)

	fat16_read_fat_entry! : Mem.Mem, Fat16.Fat16Volume, I64, I64 => (Mem.Mem, I64)
	fat16_read_fat_entry! = |_, _, _, _| crash("`fat16-read-fat-entry` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_write_fat_entry! : Mem.Mem, Fat16.Fat16Volume, I64, I64 => (Mem.Mem, I64)
	fat16_write_fat_entry! = |_, _, _, _| crash("`fat16-write-fat-entry` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_write_fat_copies! : Mem.Mem, Fat16.Fat16Volume, I64, I64, I64 => (Mem.Mem, I64)
	fat16_write_fat_copies! = |_, _, _, _, _| crash("`fat16-write-fat-copies` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_fat_copy_next! : Mem.Mem, Fat16.Fat16Volume, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_fat_copy_next! = |_, _, _, _, _, _| crash("`fat16-fat-copy-next` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_put_fat_entry! : Mem.Mem, Fat16.Fat16Volume, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_put_fat_entry! = |_, _, _, _, _, _| crash("`fat16-put-fat-entry` reaches `block-write-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_last_cluster : Fat16.Fat16Volume -> I64
	fat16_last_cluster = |vol| (vol.vol_cluster_count + 1)

	fat16_find_free_cluster! : Mem.Mem, Fat16.Fat16Volume => (Mem.Mem, I64)
	fat16_find_free_cluster! = |_, _| crash("`fat16-find-free-cluster` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_find_free_from! : Mem.Mem, Fat16.Fat16Volume, I64 => (Mem.Mem, I64)
	fat16_find_free_from! = |_, _, _| crash("`fat16-find-free-from` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_scan_free_sectors! : Mem.Mem, Fat16.Fat16Volume, I64 => (Mem.Mem, I64)
	fat16_scan_free_sectors! = |_, _, _| crash("`fat16-scan-free-sectors` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_scan_free_sector! : Mem.Mem, Fat16.Fat16Volume, I64, I64 => (Mem.Mem, I64)
	fat16_scan_free_sector! = |_, _, _, _| crash("`fat16-scan-free-sector` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_scan_free_done! : Mem.Mem, Fat16.Fat16Volume, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_scan_free_done! = |mem, vol, buf, c, upto, h| ({
		(mem3, mem__337) = ({
		(mem1, found) = fat16_scan_free_in_sector!(mem, vol, buf, c, upto)
		(mem2, _z) = Mem.release(mem1, h)
		(mem2, found)
	})
		(mem3, mem__337)
	})

	fat16_scan_free_in_sector! : Mem.Mem, Fat16.Fat16Volume, I64, I64, I64 => (Mem.Mem, I64)
	fat16_scan_free_in_sector! = |mem, vol, buf, c, upto| (if (c > upto) { (mem, 0) } else { ({
		(mem1, mem__338) = fat16_read_u16!(mem, buf, fat16_fat_entry_offset(vol, c))
		(if (mem__338 == 0) { (mem1, c) } else { fat16_scan_free_in_sector!(mem1, vol, buf, (c + 1), upto) })
	}) })

	fat16_alloc_cluster! : Mem.Mem, Fat16.Fat16Volume => (Mem.Mem, I64)
	fat16_alloc_cluster! = |_, _| crash("`fat16-alloc-cluster` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_alloc_cluster_from! : Mem.Mem, Fat16.Fat16Volume, I64 => (Mem.Mem, I64)
	fat16_alloc_cluster_from! = |_, _, _| crash("`fat16-alloc-cluster-from` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_claim_cluster! : Mem.Mem, Fat16.Fat16Volume, I64 => (Mem.Mem, I64)
	fat16_claim_cluster! = |_, _, _| crash("`fat16-claim-cluster` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

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

	fat16_src_at! : Mem.Mem, Fat16.Fat16Source, I64 => (Mem.Mem, I64)
	fat16_src_at! = |mem, s, i| ({
		hn = U64.to_i64_wrap(List.len(s.fs_head))
		(if (i < hn) { (mem, (List.get(s.fs_head, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) } else { ({
			j = (i - hn)
			(if (j < s.fs_buf_len) { Mem.load!(mem, s.fs_buf, j, 1) } else { (mem, (List.get(s.fs_tail, I64.to_u64_wrap((j - s.fs_buf_len))) ?? crash("list-at out of range"))) })
		}) })
	})

	fat16_fill_sector! : Mem.Mem, I64, Fat16.Fat16Source, I64, I64, I64 => (Mem.Mem, I64)
	fat16_fill_sector! = |mem, buf, bytes, start, i, bps| (if (i >= bps) { (mem, 0) } else { ({
		src = (start + i)
		(mem1, b) = (if (src < bytes.fs_len) { fat16_src_at!(mem, bytes, src) } else { (mem, 0) })
		(mem2, _w) = Mem.store!(mem1, buf, i, b, 1)
		fat16_fill_sector!(mem2, buf, bytes, start, (i + 1), bps)
	}) })

	fat16_write_data_sector! : Mem.Mem, Fat16.Fat16Volume, I64, Fat16.Fat16Source, I64 => (Mem.Mem, I64)
	fat16_write_data_sector! = |_, _, _, _, _| crash("`fat16-write-data-sector` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_drop_to : I64, I64 -> I64
	fat16_drop_to = |_h, r| ({
		_z = 0
		r
	})

	fat16_put_data_sector! : Mem.Mem, Fat16.Fat16Volume, I64, Fat16.Fat16Source, I64, I64 => (Mem.Mem, I64)
	fat16_put_data_sector! = |_, _, _, _, _, _| crash("`fat16-put-data-sector` reaches `block-write-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_write_cluster! : Mem.Mem, Fat16.Fat16Volume, I64, Fat16.Fat16Source, I64, I64 => (Mem.Mem, I64)
	fat16_write_cluster! = |_, _, _, _, _, _| crash("`fat16-write-cluster` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_write_chain! : Mem.Mem, Fat16.Fat16Volume, I64, Fat16.Fat16Source, I64 => (Mem.Mem, I64)
	fat16_write_chain! = |_, _, _, _, _| crash("`fat16-write-chain` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_extend_chain! : Mem.Mem, Fat16.Fat16Volume, I64, Fat16.Fat16Source, I64 => (Mem.Mem, I64)
	fat16_extend_chain! = |_, _, _, _, _| crash("`fat16-extend-chain` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_link_and_continue! : Mem.Mem, Fat16.Fat16Volume, I64, I64, Fat16.Fat16Source, I64 => (Mem.Mem, I64)
	fat16_link_and_continue! = |_, _, _, _, _, _| crash("`fat16-link-and-continue` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_name_byte : Str, I64 -> I64
	fat16_name_byte = |s, i| (if (i >= Cce.length(s)) { 32 } else { CCE.to_unicode(Cce.at_or_crash(s, i)) })

	fat16_poke_83! : Mem.Mem, I64, I64, Str, Str => (Mem.Mem, I64)
	fat16_poke_83! = |mem, buf, off, base, ext| ({
		(mem1, _b) = fat16_poke_run!(mem, buf, off, base, 0, 8)
		fat16_poke_run!(mem1, buf, (off + 8), ext, 0, 3)
	})

	fat16_poke_run! : Mem.Mem, I64, I64, Str, I64, I64 => (Mem.Mem, I64)
	fat16_poke_run! = |mem, buf, off, s, i, n| (if (i >= n) { (mem, 0) } else { ({
		(mem1, _w) = Mem.store!(mem, buf, (off + i), fat16_name_byte(s, i), 1)
		fat16_poke_run!(mem1, buf, off, s, (i + 1), n)
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

	fat16_poke_dir_entry! : Mem.Mem, I64, I64, Str, I64, I64, I64 => (Mem.Mem, I64)
	fat16_poke_dir_entry! = |mem, buf, off, name, attr, cluster, size| ({
		(mem1, _n) = fat16_poke_83!(mem, buf, off, fat16_base_of(name), fat16_ext_of(name))
		(mem2, _a) = Mem.store!(mem1, buf, (off + 11), attr, 1)
		(mem3, _z) = fat16_zero_run!(mem2, buf, (off + 12), 0, 14)
		(mem4, _c) = fat16_write_u16!(mem3, buf, (off + 26), cluster)
		(mem5, _s1) = fat16_write_u16!(mem4, buf, (off + 28), I64.bitwise_and(size, 65535))
		fat16_write_u16!(mem5, buf, (off + 30), I64.bitwise_and(I64.shr_zf_wrap(size, I64.to_u8_wrap(16)), 65535))
	})

	fat16_zero_run! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_zero_run! = |mem, buf, off, i, n| (if (i >= n) { (mem, 0) } else { ({
		(mem1, _w) = Mem.store!(mem, buf, (off + i), 0, 1)
		fat16_zero_run!(mem1, buf, off, (i + 1), n)
	}) })

	fat16_root_sector_count : Fat16.Fat16Volume -> I64
	fat16_root_sector_count = |vol| I64.div_trunc_by((((vol.vol_root_entry_count * 32) + vol.vol_bytes_per_sector) - 1), vol.vol_bytes_per_sector)

	fat16_dir_chain_ends_at : I64 -> Bool
	fat16_dir_chain_ends_at = |c| (if (c < 2) { True } else { fat16_is_end(c) })

	fat16_last_cluster_of! : Mem.Mem, Fat16.Fat16Volume, I64 => (Mem.Mem, I64)
	fat16_last_cluster_of! = |_, _, _| crash("`fat16-last-cluster-of` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_grow_dir_at! : Mem.Mem, Fat16.Fat16Volume, I64 => (Mem.Mem, I64)
	fat16_grow_dir_at! = |_, _, _| crash("`fat16-grow-dir-at` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_grow_dir_with! : Mem.Mem, Fat16.Fat16Volume, I64, I64 => (Mem.Mem, I64)
	fat16_grow_dir_with! = |_, _, _, _| crash("`fat16-grow-dir-with` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_zero_dir_cluster! : Mem.Mem, Fat16.Fat16Volume, I64, I64 => (Mem.Mem, I64)
	fat16_zero_dir_cluster! = |_, _, _, _| crash("`fat16-zero-dir-cluster` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_link_grown_dir! : Mem.Mem, Fat16.Fat16Volume, I64, I64 => (Mem.Mem, I64)
	fat16_link_grown_dir! = |_, _, _, _| crash("`fat16-link-grown-dir` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_create_file! : Mem.Mem, Fat16.Fat16Volume, Str, Fat16.Fat16Source => (Mem.Mem, Bool)
	fat16_create_file! = |_, _, _, _| crash("`fat16-create-file` reaches `process-get-scope`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_create_or_replace! : Mem.Mem, Fat16.Fat16Volume, Str, Fat16.Fat16Source, Maybe.Maybe(Fat16.Fat16DirEntry) => (Mem.Mem, Bool)
	fat16_create_or_replace! = |_, _, _, _, _| crash("`fat16-create-or-replace` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_replace_in_root! : Mem.Mem, Fat16.Fat16Volume, Str, Fat16.Fat16Source, Fat16.Fat16DirEntry => (Mem.Mem, Bool)
	fat16_replace_in_root! = |_, _, _, _, _| crash("`fat16-replace-in-root` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_replace_at_slot! : Mem.Mem, Fat16.Fat16Volume, Str, Fat16.Fat16Source, I64, I64 => (Mem.Mem, Bool)
	fat16_replace_at_slot! = |_, _, _, _, _, _| crash("`fat16-replace-at-slot` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_erase_then_create_root! : Mem.Mem, Fat16.Fat16Volume, Str, Fat16.Fat16Source, I64 => (Mem.Mem, Bool)
	fat16_erase_then_create_root! = |_, _, _, _, _| crash("`fat16-erase-then-create-root` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_create_fresh_in_root! : Mem.Mem, Fat16.Fat16Volume, Str, Fat16.Fat16Source => (Mem.Mem, Bool)
	fat16_create_fresh_in_root! = |_, _, _, _| crash("`fat16-create-fresh-in-root` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_place_in_root! : Mem.Mem, Fat16.Fat16Volume, Str, Str, Fat16.Fat16Source => (Mem.Mem, Bool)
	fat16_place_in_root! = |_, _, _, _, _| crash("`fat16-place-in-root` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_pick_alias_root! : Mem.Mem, Fat16.Fat16Volume, Str, I64 => (Mem.Mem, Str)
	fat16_pick_alias_root! = |_, _, _, _| crash("`fat16-pick-alias-root` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_pick_alias_dir! : Mem.Mem, Fat16.Fat16Volume, I64, Str, I64 => (Mem.Mem, Str)
	fat16_pick_alias_dir! = |_, _, _, _, _| crash("`fat16-pick-alias-dir` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_free_chain! : Mem.Mem, Fat16.Fat16Volume, I64 => (Mem.Mem, I64)
	fat16_free_chain! = |_, _, _| crash("`fat16-free-chain` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_free_chain_walk! : Mem.Mem, Fat16.Fat16Volume, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_free_chain_walk! = |_, _, _, _, _, _| crash("`fat16-free-chain-walk` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_free_chain_from! : Mem.Mem, Fat16.Fat16Volume, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_free_chain_from! = |_, _, _, _, _, _, _| crash("`fat16-free-chain-from` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_find_name_slot! : Mem.Mem, Fat16.Fat16Volume, Str => (Mem.Mem, I64)
	fat16_find_name_slot! = |_, _, _| crash("`fat16-find-name-slot` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_name_slot_sectors! : Mem.Mem, Fat16.Fat16Volume, Str, I64, I64, I64 => (Mem.Mem, I64)
	fat16_name_slot_sectors! = |_, _, _, _, _, _| crash("`fat16-name-slot-sectors` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_name_slot_step! : Mem.Mem, Fat16.Fat16Volume, Str, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_name_slot_step! = |_, _, _, _, _, _, _| crash("`fat16-name-slot-step` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_name_slot_in_sector! : Mem.Mem, I64, Str, I64, I64 => (Mem.Mem, I64)
	fat16_name_slot_in_sector! = |mem, buf, name, i, count| (if (i >= count) { (mem, (0 - 1)) } else { ({
		off = (i * 32)
		({
			(mem1, mem__339) = fat16_is_free_entry!(mem, buf, off)
			(if mem__339 { fat16_name_slot_in_sector!(mem1, buf, name, (i + 1), count) } else { ({
			(mem2, mem__340) = fat16_is_lfn_entry!(mem1, buf, off)
			(if mem__340 { fat16_name_slot_in_sector!(mem2, buf, name, (i + 1), count) } else { ({
			(mem3, mem__341) = fat16_is_volume_label!(mem2, buf, off)
			(if mem__341 { fat16_name_slot_in_sector!(mem3, buf, name, (i + 1), count) } else { ({
			(mem4, mem__342) = fat16_entry_name_at!(mem3, buf, off)
			(if fat16_name_matches(mem__342, name) { (mem4, off) } else { fat16_name_slot_in_sector!(mem4, buf, name, (i + 1), count) })
		}) })
		}) })
		}) })
		})
	}) })

	fat16_entry_name_at! : Mem.Mem, I64, I64 => (Mem.Mem, Str)
	fat16_entry_name_at! = |mem, buf, off| ({
		(mem1, mem__343) = fat16_read_dir_entry!(mem, buf, off)
		(mem1, mem__343.de_name)
	})

	fat16_find_name_slot_in_dir! : Mem.Mem, Fat16.Fat16Volume, I64, Str => (Mem.Mem, I64)
	fat16_find_name_slot_in_dir! = |_, _, _, _| crash("`fat16-find-name-slot-in-dir` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_find_name_slot_walk! : Mem.Mem, Fat16.Fat16Volume, I64, Str, I64, I64, I64 => (Mem.Mem, I64)
	fat16_find_name_slot_walk! = |_, _, _, _, _, _, _| crash("`fat16-find-name-slot-walk` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_name_slot_or_next! : Mem.Mem, Fat16.Fat16Volume, I64, Str, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_name_slot_or_next! = |_, _, _, _, _, _, _, _| crash("`fat16-name-slot-or-next` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_name_slot_dir_sectors! : Mem.Mem, Fat16.Fat16Volume, Str, I64, I64 => (Mem.Mem, I64)
	fat16_name_slot_dir_sectors! = |_, _, _, _, _| crash("`fat16-name-slot-dir-sectors` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_name_slot_dir_step! : Mem.Mem, Fat16.Fat16Volume, Str, I64, I64, I64 => (Mem.Mem, I64)
	fat16_name_slot_dir_step! = |_, _, _, _, _, _| crash("`fat16-name-slot-dir-step` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_create_in_subdir! : Mem.Mem, Fat16.Fat16Volume, Str, Fat16.Fat16Source => (Mem.Mem, Bool)
	fat16_create_in_subdir! = |_, _, _, _| crash("`fat16-create-in-subdir` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_create_in_dir_entry! : Mem.Mem, Fat16.Fat16Volume, Fat16.Fat16DirEntry, Str, Fat16.Fat16Source => (Mem.Mem, Bool)
	fat16_create_in_dir_entry! = |_, _, _, _, _| crash("`fat16-create-in-dir-entry` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_create_in_cluster_dir! : Mem.Mem, Fat16.Fat16Volume, I64, Str, Fat16.Fat16Source => (Mem.Mem, Bool)
	fat16_create_in_cluster_dir! = |_, _, _, _, _| crash("`fat16-create-in-cluster-dir` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_create_or_replace_in_dir! : Mem.Mem, Fat16.Fat16Volume, I64, Str, Fat16.Fat16Source, Maybe.Maybe(Fat16.Fat16DirEntry) => (Mem.Mem, Bool)
	fat16_create_or_replace_in_dir! = |_, _, _, _, _, _| crash("`fat16-create-or-replace-in-dir` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_replace_in_dir! : Mem.Mem, Fat16.Fat16Volume, I64, Str, Fat16.Fat16Source, Fat16.Fat16DirEntry => (Mem.Mem, Bool)
	fat16_replace_in_dir! = |_, _, _, _, _, _| crash("`fat16-replace-in-dir` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_replace_at_slot_in_dir! : Mem.Mem, Fat16.Fat16Volume, I64, Str, Fat16.Fat16Source, I64, I64 => (Mem.Mem, Bool)
	fat16_replace_at_slot_in_dir! = |_, _, _, _, _, _, _| crash("`fat16-replace-at-slot-in-dir` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_erase_then_create_dir! : Mem.Mem, Fat16.Fat16Volume, I64, Str, Fat16.Fat16Source, I64 => (Mem.Mem, Bool)
	fat16_erase_then_create_dir! = |_, _, _, _, _, _| crash("`fat16-erase-then-create-dir` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_create_fresh_in_dir! : Mem.Mem, Fat16.Fat16Volume, I64, Str, Fat16.Fat16Source => (Mem.Mem, Bool)
	fat16_create_fresh_in_dir! = |_, _, _, _, _| crash("`fat16-create-fresh-in-dir` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_place_in_dir! : Mem.Mem, Fat16.Fat16Volume, I64, Str, Str, Fat16.Fat16Source => (Mem.Mem, Bool)
	fat16_place_in_dir! = |_, _, _, _, _, _| crash("`fat16-place-in-dir` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_create_at_run! : Mem.Mem, Fat16.Fat16Volume, Str, Str, Fat16.Fat16Source, I64 => (Mem.Mem, Bool)
	fat16_create_at_run! = |_, _, _, _, _, _| crash("`fat16-create-at-run` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_create_with_cluster! : Mem.Mem, Fat16.Fat16Volume, Str, Str, Fat16.Fat16Source, I64, I64 => (Mem.Mem, Bool)
	fat16_create_with_cluster! = |_, _, _, _, _, _, _| crash("`fat16-create-with-cluster` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_commit_entry! : Mem.Mem, Fat16.Fat16Volume, Str, Str, Fat16.Fat16Source, I64, I64, I64 => (Mem.Mem, Bool)
	fat16_commit_entry! = |_, _, _, _, _, _, _, _| crash("`fat16-commit-entry` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_commit_short_if! : Mem.Mem, Str, Fat16.Fat16Source, I64, I64, I64, I64 => (Mem.Mem, Bool)
	fat16_commit_short_if! = |_, _, _, _, _, _, _| crash("`fat16-commit-short-if` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_commit_short! : Mem.Mem, Str, Fat16.Fat16Source, I64, I64, I64 => (Mem.Mem, Bool)
	fat16_commit_short! = |_, _, _, _, _, _| crash("`fat16-commit-short` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_put_entry_and_write! : Mem.Mem, Str, Fat16.Fat16Source, I64, I64, I64, I64 => (Mem.Mem, Bool)
	fat16_put_entry_and_write! = |_, _, _, _, _, _, _| crash("`fat16-put-entry-and-write` reaches `block-write-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_create_directory! : Mem.Mem, Fat16.Fat16Volume, Str => (Mem.Mem, Bool)
	fat16_create_directory! = |_, _, _| crash("`fat16-create-directory` reaches `process-get-scope`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_mkdir_if_free! : Mem.Mem, Fat16.Fat16Volume, Str, Maybe.Maybe(Fat16.Fat16DirEntry) => (Mem.Mem, Bool)
	fat16_mkdir_if_free! = |_, _, _, _| crash("`fat16-mkdir-if-free` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_mkdir_in_root! : Mem.Mem, Fat16.Fat16Volume, Str => (Mem.Mem, Bool)
	fat16_mkdir_in_root! = |_, _, _| crash("`fat16-mkdir-in-root` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_mkdir_place_root! : Mem.Mem, Fat16.Fat16Volume, Str, Str => (Mem.Mem, Bool)
	fat16_mkdir_place_root! = |_, _, _, _| crash("`fat16-mkdir-place-root` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_mkdir_in_subdir! : Mem.Mem, Fat16.Fat16Volume, Str => (Mem.Mem, Bool)
	fat16_mkdir_in_subdir! = |_, _, _| crash("`fat16-mkdir-in-subdir` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_mkdir_under! : Mem.Mem, Fat16.Fat16Volume, Fat16.Fat16DirEntry, Str => (Mem.Mem, Bool)
	fat16_mkdir_under! = |_, _, _, _| crash("`fat16-mkdir-under` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_mkdir_in_cluster! : Mem.Mem, Fat16.Fat16Volume, I64, Str => (Mem.Mem, Bool)
	fat16_mkdir_in_cluster! = |_, _, _, _| crash("`fat16-mkdir-in-cluster` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_mkdir_place_dir! : Mem.Mem, Fat16.Fat16Volume, I64, Str, Str => (Mem.Mem, Bool)
	fat16_mkdir_place_dir! = |_, _, _, _, _| crash("`fat16-mkdir-place-dir` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_mkdir_at_slot! : Mem.Mem, Fat16.Fat16Volume, Str, Str, I64, I64 => (Mem.Mem, Bool)
	fat16_mkdir_at_slot! = |_, _, _, _, _, _| crash("`fat16-mkdir-at-slot` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_mkdir_with_cluster! : Mem.Mem, Fat16.Fat16Volume, Str, Str, I64, I64, I64 => (Mem.Mem, Bool)
	fat16_mkdir_with_cluster! = |_, _, _, _, _, _, _| crash("`fat16-mkdir-with-cluster` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_mkdir_init_cluster! : Mem.Mem, Fat16.Fat16Volume, I64, I64, I64 => (Mem.Mem, I64)
	fat16_mkdir_init_cluster! = |_, _, _, _, _| crash("`fat16-mkdir-init-cluster` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_mkdir_write_dots! : Mem.Mem, Fat16.Fat16Volume, I64, I64 => (Mem.Mem, I64)
	fat16_mkdir_write_dots! = |_, _, _, _| crash("`fat16-mkdir-write-dots` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_mkdir_poke_dots! : Mem.Mem, Fat16.Fat16Volume, I64, I64, I64 => (Mem.Mem, I64)
	fat16_mkdir_poke_dots! = |_, _, _, _, _| crash("`fat16-mkdir-poke-dots` reaches `block-write-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_poke_dot_entry! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_poke_dot_entry! = |mem, buf, off, dots, cluster| ({
		(mem1, _n) = fat16_poke_dot_name!(mem, buf, off, dots)
		(mem2, _a) = Mem.store!(mem1, buf, (off + 11), 16, 1)
		(mem3, _z) = fat16_zero_run!(mem2, buf, (off + 12), 0, 14)
		(mem4, _c) = fat16_write_u16!(mem3, buf, (off + 26), cluster)
		(mem5, _s1) = fat16_write_u16!(mem4, buf, (off + 28), 0)
		fat16_write_u16!(mem5, buf, (off + 30), 0)
	})

	fat16_poke_dot_name! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	fat16_poke_dot_name! = |mem, buf, off, dots| ({
		(mem1, _d1) = Mem.store!(mem, buf, off, 46, 1)
		(mem2, _d2) = (if (dots > 1) { Mem.store!(mem1, buf, (off + 1), 46, 1) } else { (mem1, 0) })
		fat16_fill_run!(mem2, buf, (off + dots), 0, (11 - dots), 32)
	})

	fat16_fill_run! : Mem.Mem, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_fill_run! = |mem, buf, off, i, n, v| (if (i >= n) { (mem, 0) } else { ({
		(mem1, _w) = Mem.store!(mem, buf, (off + i), v, 1)
		fat16_fill_run!(mem1, buf, off, (i + 1), n, v)
	}) })

	fat16_mkdir_commit! : Mem.Mem, Fat16.Fat16Volume, Str, Str, I64, I64 => (Mem.Mem, Bool)
	fat16_mkdir_commit! = |_, _, _, _, _, _| crash("`fat16-mkdir-commit` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_mkdir_place_if! : Mem.Mem, Str, I64, I64, I64, I64 => (Mem.Mem, Bool)
	fat16_mkdir_place_if! = |_, _, _, _, _, _| crash("`fat16-mkdir-place-if` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_mkdir_place_entry! : Mem.Mem, Str, I64, I64, I64 => (Mem.Mem, Bool)
	fat16_mkdir_place_entry! = |_, _, _, _, _| crash("`fat16-mkdir-place-entry` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_mkdir_put_entry! : Mem.Mem, Str, I64, I64, I64, I64 => (Mem.Mem, Bool)
	fat16_mkdir_put_entry! = |_, _, _, _, _, _| crash("`fat16-mkdir-put-entry` reaches `block-write-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_read_dir_entry! : Mem.Mem, I64, I64 => (Mem.Mem, Fat16.Fat16DirEntry)
	fat16_read_dir_entry! = |mem, buf, off| ({
		(mem5, mem__344) = ({
		(mem1, name) = fat16_extract_name!(mem, buf, off)
		(mem2, attr) = Mem.load!(mem1, buf, (off + 11), 1)
		(mem3, cluster) = fat16_read_u16!(mem2, buf, (off + 26))
		(mem4, size) = fat16_read_u32!(mem3, buf, (off + 28))
		(mem4, { de_name: name, de_attr: attr, de_cluster: cluster, de_size: size })
	})
		(mem5, mem__344)
	})

	fat16_extract_name! : Mem.Mem, I64, I64 => (Mem.Mem, Str)
	fat16_extract_name! = |mem, buf, off| ({
		(mem3, mem__345) = ({
		(mem1, base) = fat16_extract_chars!(mem, buf, off, 8, "")
		(mem2, ext) = fat16_extract_chars!(mem1, buf, (off + 8), 3, "")
		trimmed_base = fat16_trim_spaces(base)
		trimmed_ext = fat16_trim_spaces(ext)
		(mem2, (if (Cce.length(trimmed_ext) == 0) { trimmed_base } else { Str.concat(Str.concat(trimmed_base, "."), trimmed_ext) }))
	})
		(mem3, mem__345)
	})

	fat16_extract_chars! : Mem.Mem, I64, I64, I64, Str => (Mem.Mem, Str)
	fat16_extract_chars! = |mem, buf, off, n, acc| (if (n == 0) { (mem, acc) } else { ({
		(mem1, c) = Mem.load!(mem, buf, off, 1)
		fat16_extract_chars!(mem1, buf, (off + 1), (n - 1), Str.concat(acc, Cce.text(CCE.from_unicode(c))))
	}) })

	fat16_trim_spaces : Str -> Str
	fat16_trim_spaces = |s| fat16_trim_loop(s, Cce.length(s))

	fat16_trim_loop : Str, I64 -> Str
	fat16_trim_loop = |s, len| (if (len == 0) { "" } else { (if (Cce.at_or_crash(s, (len - 1)) == CCE.from_unicode(32)) { fat16_trim_loop(s, (len - 1)) } else { Cce.substring(s, 0, len) }) })

	fat16_is_free_entry! : Mem.Mem, I64, I64 => (Mem.Mem, Bool)
	fat16_is_free_entry! = |mem, buf, off| ({
		(mem2, mem__346) = ({
		(mem1, first) = Mem.load!(mem, buf, off, 1)
		(mem1, ((first == 0) or (first == 229)))
	})
		(mem2, mem__346)
	})

	fat16_is_lfn_entry! : Mem.Mem, I64, I64 => (Mem.Mem, Bool)
	fat16_is_lfn_entry! = |mem, buf, off| ({
		(mem1, mem__347) = Mem.load!(mem, buf, (off + 11), 1)
		(mem1, (mem__347 == 15))
	})

	fat16_is_volume_label! : Mem.Mem, I64, I64 => (Mem.Mem, Bool)
	fat16_is_volume_label! = |mem, buf, off| ({
		(mem1, mem__348) = Mem.load!(mem, buf, (off + 11), 1)
		(mem1, (I64.bitwise_and(mem__348, 8) == 8))
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

	fat16_lfn_ord! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	fat16_lfn_ord! = |mem, buf, off| ({
		(mem1, mem__349) = Mem.load!(mem, buf, off, 1)
		(mem1, I64.bitwise_and(mem__349, 63))
	})

	fat16_lfn_is_last! : Mem.Mem, I64, I64 => (Mem.Mem, Bool)
	fat16_lfn_is_last! = |mem, buf, off| ({
		(mem1, mem__350) = Mem.load!(mem, buf, off, 1)
		(mem1, (I64.bitwise_and(mem__350, fat16_lfn_last) == fat16_lfn_last))
	})

	fat16_lfn_stored_sum! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	fat16_lfn_stored_sum! = |mem, buf, off| Mem.load!(mem, buf, (off + 13), 1)

	fat16_lfn_records_needed : I64 -> I64
	fat16_lfn_records_needed = |n| I64.div_trunc_by(((n + fat16_lfn_per_record) - 1), fat16_lfn_per_record)

	fat16_short_checksum! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	fat16_short_checksum! = |mem, buf, off| fat16_checksum_step!(mem, buf, off, 0, 0)

	fat16_checksum_step! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_checksum_step! = |mem, buf, off, i, sum| (if (i >= 11) { (mem, sum) } else { ({
		(mem1, mem__351) = Mem.load!(mem, buf, (off + i), 1)
		next = fat16_checksum_mix(sum, mem__351)
		fat16_checksum_step!(mem1, buf, off, (i + 1), next)
	}) })

	fat16_checksum_mix : I64, I64 -> I64
	fat16_checksum_mix = |sum, b| I64.bitwise_and(((I64.shl_wrap(I64.bitwise_and(sum, 1), I64.to_u8_wrap(7)) + I64.shr_zf_wrap(sum, I64.to_u8_wrap(1))) + b), 255)

	fat16_lfn_slot_offset : I64 -> I64
	fat16_lfn_slot_offset = |k| (if (k < 5) { (1 + (k * 2)) } else { (if (k < 11) { (14 + ((k - 5) * 2)) } else { (28 + ((k - 11) * 2)) }) })

	fat16_lfn_unit_at! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	fat16_lfn_unit_at! = |mem, buf, off, k| fat16_read_u16!(mem, buf, (off + fat16_lfn_slot_offset(k)))

	fat16_lfn_units_used! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	fat16_lfn_units_used! = |mem, buf, off, k| (if (k >= fat16_lfn_per_record) { (mem, k) } else { ({
		(mem1, u) = fat16_lfn_unit_at!(mem, buf, off, k)
		(if (u == 0) { (mem1, k) } else { (if (u == 65535) { (mem1, k) } else { fat16_lfn_units_used!(mem1, buf, off, (k + 1)) }) })
	}) })

	fat16_lfn_units_decodable! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, Bool)
	fat16_lfn_units_decodable! = |mem, buf, off, k, n| (if (k >= n) { (mem, True) } else { ({
		(mem1, mem__352) = fat16_lfn_unit_at!(mem, buf, off, k)
		(if (CCE.from_unicode(mem__352) < 0) { (mem1, False) } else { fat16_lfn_units_decodable!(mem1, buf, off, (k + 1), n) })
	}) })

	fat16_lfn_decode_units! : Mem.Mem, I64, I64, I64, I64, Str => (Mem.Mem, Str)
	fat16_lfn_decode_units! = |mem, buf, off, k, n, acc| (if (k >= n) { (mem, acc) } else { ({
		(mem1, mem__353) = fat16_lfn_unit_at!(mem, buf, off, k)
		piece = Cce.text(CCE.from_unicode(mem__353))
		fat16_lfn_decode_units!(mem1, buf, off, (k + 1), n, Str.concat(acc, piece))
	}) })

	fat16_lfn_unit_of : Str, I64 -> I64
	fat16_lfn_unit_of = |name, i| ({
		c = Cce.at_or_crash(name, i)
		u = CCE.to_unicode(c)
		(if (CCE.from_unicode(u) == c) { u } else { (-1) })
	})

	fat16_lfn_name_spellable : Str, I64, I64 -> Bool
	fat16_lfn_name_spellable = |name, i, n| (if (i >= n) { True } else { (if (fat16_lfn_unit_of(name, i) < 0) { False } else { fat16_lfn_name_spellable(name, (i + 1), n) }) })

	fat16_poke_lfn_record! : Mem.Mem, I64, I64, Str, I64, I64, Bool => (Mem.Mem, I64)
	fat16_poke_lfn_record! = |mem, buf, off, name, seq, sum, last| ({
		(mem1, _o) = Mem.store!(mem, buf, off, (if last { I64.bitwise_or(seq, fat16_lfn_last) } else { seq }), 1)
		(mem2, _a) = Mem.store!(mem1, buf, (off + 11), fat16_lfn_attr, 1)
		(mem3, _t) = Mem.store!(mem2, buf, (off + 12), 0, 1)
		(mem4, _s) = Mem.store!(mem3, buf, (off + 13), sum, 1)
		(mem5, _c) = fat16_write_u16!(mem4, buf, (off + 26), 0)
		fat16_poke_lfn_units!(mem5, buf, off, name, ((seq - 1) * fat16_lfn_per_record), 0)
	})

	fat16_poke_lfn_units! : Mem.Mem, I64, I64, Str, I64, I64 => (Mem.Mem, I64)
	fat16_poke_lfn_units! = |mem, buf, off, name, base, k| (if (k >= fat16_lfn_per_record) { (mem, 0) } else { ({
		i = (base + k)
		n = Cce.length(name)
		u = (if (i < n) { fat16_lfn_unit_of(name, i) } else { (if (i == n) { 0 } else { 65535 }) })
		(mem1, _w) = fat16_write_u16!(mem, buf, (off + fat16_lfn_slot_offset(k)), u)
		fat16_poke_lfn_units!(mem1, buf, off, name, base, (k + 1))
	}) })

	fat16_lfn_none : Fat16.Fat16Lfn
	fat16_lfn_none = { lf_name: "", lf_ord: 0, lf_sum: 0, lf_live: False }

	fat16_lfn_reset : Fat16.Fat16Lfn -> Fat16.Fat16Lfn
	fat16_lfn_reset = |st| (if st.lf_live { fat16_lfn_none } else { st })

	fat16_lfn_absorb! : Mem.Mem, I64, I64, Fat16.Fat16Lfn => (Mem.Mem, Fat16.Fat16Lfn)
	fat16_lfn_absorb! = |mem, buf, off, st| ({
		(mem1, ord) = fat16_lfn_ord!(mem, buf, off)
		({
			(mem2, mem__354) = fat16_lfn_is_last!(mem1, buf, off)
			(if mem__354 { fat16_lfn_open!(mem2, buf, off, ord) } else { fat16_lfn_extend!(mem2, buf, off, ord, st) })
		})
	})

	fat16_lfn_open! : Mem.Mem, I64, I64, I64 => (Mem.Mem, Fat16.Fat16Lfn)
	fat16_lfn_open! = |mem, buf, off, ord| (if (ord < 1) { (mem, fat16_lfn_none) } else { (if (ord > fat16_lfn_max_records) { (mem, fat16_lfn_none) } else { ({
		(mem1, mem__355) = fat16_lfn_stored_sum!(mem, buf, off)
		fat16_lfn_take!(mem1, buf, off, ord, mem__355, "")
	}) }) })

	fat16_lfn_extend! : Mem.Mem, I64, I64, I64, Fat16.Fat16Lfn => (Mem.Mem, Fat16.Fat16Lfn)
	fat16_lfn_extend! = |mem, buf, off, ord, st| (if (st.lf_live == False) { (mem, fat16_lfn_none) } else { (if (ord != st.lf_ord) { (mem, fat16_lfn_none) } else { ({
		(mem1, mem__356) = fat16_lfn_stored_sum!(mem, buf, off)
		(if (mem__356 != st.lf_sum) { (mem1, fat16_lfn_none) } else { fat16_lfn_take!(mem1, buf, off, ord, st.lf_sum, st.lf_name) })
	}) }) })

	fat16_lfn_take! : Mem.Mem, I64, I64, I64, I64, Str => (Mem.Mem, Fat16.Fat16Lfn)
	fat16_lfn_take! = |mem, buf, off, ord, sum, rest| ({
		(mem6, mem__360) = ({
		(mem1, used) = fat16_lfn_units_used!(mem, buf, off, 0)
		({
			(mem2, mem__357) = fat16_lfn_units_decodable!(mem1, buf, off, 0, used)
			(mem5, mem__359) = (if (mem__357 == False) { (mem2, fat16_lfn_none) } else { ({
			(mem4, mem__358) = ({
			(mem3, part) = fat16_lfn_decode_units!(mem2, buf, off, 0, used, "")
			(mem3, { lf_name: Str.concat(part, rest), lf_ord: (ord - 1), lf_sum: sum, lf_live: True })
		})
			(mem4, mem__358)
		}) })
			(mem5, mem__359)
		})
	})
		(mem6, mem__360)
	})

	fat16_lfn_final! : Mem.Mem, I64, I64, Fat16.Fat16Lfn => (Mem.Mem, Maybe.Maybe(Str))
	fat16_lfn_final! = |mem, buf, off, st| ({
		(mem3, mem__363) = (if (st.lf_live == False) { (mem, None) } else { ({
		(mem2, mem__362) = (if (st.lf_ord != 0) { (mem, None) } else { ({
		(mem1, mem__361) = fat16_short_checksum!(mem, buf, off)
		(mem1, (if (mem__361 != st.lf_sum) { None } else { (if (Cce.length(st.lf_name) == 0) { None } else { (if (Cce.length(st.lf_name) > fat16_lfn_max_name) { None } else { Just(st.lf_name) }) }) }))
	}) })
		(mem2, mem__362)
	}) })
		(mem3, mem__363)
	})

	fat16_entry_matches! : Mem.Mem, Fat16.Fat16DirEntry, I64, I64, Fat16.Fat16Lfn, Str => (Mem.Mem, Bool)
	fat16_entry_matches! = |mem, entry, buf, off, st, name| ({
		(mem3, mem__366) = (if fat16_name_matches(entry.de_name, name) { (mem, True) } else { ({
		(mem2, mem__365) = (if (st.lf_live == False) { (mem, False) } else { ({
		(mem1, mem__364) = fat16_lfn_final!(mem, buf, off, st)
		(mem1, (match mem__364 {
		Just(n) => fat16_name_matches(n, name)
		None => False
	}))
	}) })
		(mem2, mem__365)
	}) })
		(mem3, mem__366)
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

	fat16_run_in_sector! : Mem.Mem, I64, I64, I64, I64, I64 => (Mem.Mem, Fat16.Fat16Run)
	fat16_run_in_sector! = |mem, buf, i, n, need, streak| (if (i >= n) { (mem, { rn_found: False, rn_at: 0, rn_streak: streak }) } else { ({
		(mem1, mem__367) = fat16_is_free_entry!(mem, buf, (i * 32))
		(if (mem__367 == False) { fat16_run_in_sector!(mem1, buf, (i + 1), n, need, 0) } else { (if ((streak + 1) >= need) { (mem1, { rn_found: True, rn_at: ((i + 1) - need), rn_streak: need }) } else { fat16_run_in_sector!(mem1, buf, (i + 1), n, need, (streak + 1)) }) })
	}) })

	fat16_find_run_in_root! : Mem.Mem, Fat16.Fat16Volume, I64 => (Mem.Mem, I64)
	fat16_find_run_in_root! = |_, _, _| crash("`fat16-find-run-in-root` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_run_root_sectors! : Mem.Mem, Fat16.Fat16Volume, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_run_root_sectors! = |_, _, _, _, _, _| crash("`fat16-run-root-sectors` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_run_root_step! : Mem.Mem, Fat16.Fat16Volume, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_run_root_step! = |_, _, _, _, _, _, _| crash("`fat16-run-root-step` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_find_run_in_dir! : Mem.Mem, Fat16.Fat16Volume, I64, I64 => (Mem.Mem, I64)
	fat16_find_run_in_dir! = |_, _, _, _| crash("`fat16-find-run-in-dir` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_run_dir_walk! : Mem.Mem, Fat16.Fat16Volume, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_run_dir_walk! = |_, _, _, _, _, _, _| crash("`fat16-run-dir-walk` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_run_dir_or_next! : Mem.Mem, Fat16.Fat16Volume, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_run_dir_or_next! = |_, _, _, _, _, _, _, _| crash("`fat16-run-dir-or-next` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_run_dir_sectors! : Mem.Mem, Fat16.Fat16Volume, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_run_dir_sectors! = |_, _, _, _, _, _| crash("`fat16-run-dir-sectors` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_run_dir_step! : Mem.Mem, Fat16.Fat16Volume, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_run_dir_step! = |_, _, _, _, _, _, _| crash("`fat16-run-dir-step` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_find_or_grow_run_in_dir! : Mem.Mem, Fat16.Fat16Volume, I64, I64 => (Mem.Mem, I64)
	fat16_find_or_grow_run_in_dir! = |_, _, _, _| crash("`fat16-find-or-grow-run-in-dir` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_run_or_grow! : Mem.Mem, Fat16.Fat16Volume, I64, I64, I64 => (Mem.Mem, I64)
	fat16_run_or_grow! = |_, _, _, _, _| crash("`fat16-run-or-grow` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_records_for : Str -> I64
	fat16_records_for = |name| (if (fat16_needs_long(name) == False) { 0 } else { fat16_lfn_records_needed(Cce.length(name)) })

	fat16_slots_for : Str -> I64
	fat16_slots_for = |name| (fat16_records_for(name) + 1)

	fat16_write_run! : Mem.Mem, Fat16.Fat16Volume, Str, Str, I64, I64 => (Mem.Mem, I64)
	fat16_write_run! = |_, _, _, _, _, _| crash("`fat16-write-run` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_write_run_step! : Mem.Mem, Fat16.Fat16Volume, Str, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_write_run_step! = |_, _, _, _, _, _, _| crash("`fat16-write-run-step` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_write_run_next! : Mem.Mem, Fat16.Fat16Volume, Str, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_write_run_next! = |_, _, _, _, _, _, _, _| crash("`fat16-write-run-next` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_write_lfn_slot! : Mem.Mem, Str, I64, I64, I64, Bool => (Mem.Mem, I64)
	fat16_write_lfn_slot! = |_, _, _, _, _, _| crash("`fat16-write-lfn-slot` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_put_lfn_slot! : Mem.Mem, Str, I64, I64, I64, Bool, I64 => (Mem.Mem, I64)
	fat16_put_lfn_slot! = |_, _, _, _, _, _, _| crash("`fat16-put-lfn-slot` reaches `block-write-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_erase_entry! : Mem.Mem, Fat16.Fat16Volume, I64 => (Mem.Mem, I64)
	fat16_erase_entry! = |_, _, _| crash("`fat16-erase-entry` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_sum_at! : Mem.Mem, I64 => (Mem.Mem, I64)
	fat16_sum_at! = |_, _| crash("`fat16-sum-at` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_mark_free! : Mem.Mem, I64 => (Mem.Mem, I64)
	fat16_mark_free! = |_, _| crash("`fat16-mark-free` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_put_mark_free! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	fat16_put_mark_free! = |_, _, _| crash("`fat16-put-mark-free` reaches `block-write-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_erase_run! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_erase_run! = |_, _, _, _, _| crash("`fat16-erase-run` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_erase_run_step! : Mem.Mem, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	fat16_erase_run_step! = |_, _, _, _, _, _| crash("`fat16-erase-run-step` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_find_in_root! : Mem.Mem, Fat16.Fat16Volume, Str => (Mem.Mem, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_find_in_root! = |_, _, _| crash("`fat16-find-in-root` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_scan_root_sectors! : Mem.Mem, Fat16.Fat16Volume, Str, I64, I64, I64, Fat16.Fat16Lfn => (Mem.Mem, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_scan_root_sectors! = |_, _, _, _, _, _, _| crash("`fat16-scan-root-sectors` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_scan_root_step! : Mem.Mem, Fat16.Fat16Volume, Str, I64, I64, I64, I64, Fat16.Fat16Lfn => (Mem.Mem, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_scan_root_step! = |_, _, _, _, _, _, _, _| crash("`fat16-scan-root-step` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_scan_sector_lfn! : Mem.Mem, I64, Str, I64, I64, Fat16.Fat16Lfn => (Mem.Mem, Fat16.Fat16Scan)
	fat16_scan_sector_lfn! = |mem, buf, name, i, count, st| (if (i >= count) { (mem, { sc_found: None, sc_lfn: st }) } else { ({
		off = (i * 32)
		({
			(mem1, mem__368) = fat16_is_free_entry!(mem, buf, off)
			(if mem__368 { ({
			(mem2, mem__369) = Mem.load!(mem1, buf, off, 1)
			(if (mem__369 == 0) { (mem2, { sc_found: None, sc_lfn: fat16_lfn_reset(st) }) } else { fat16_scan_sector_lfn!(mem2, buf, name, (i + 1), count, fat16_lfn_reset(st)) })
		}) } else { ({
			(mem3, mem__370) = fat16_is_lfn_entry!(mem1, buf, off)
			(if mem__370 { ({
			(mem4, mem__371) = fat16_lfn_absorb!(mem3, buf, off, st)
			fat16_scan_sector_lfn!(mem4, buf, name, (i + 1), count, mem__371)
		}) } else { ({
			(mem5, mem__372) = fat16_is_volume_label!(mem3, buf, off)
			(if mem__372 { fat16_scan_sector_lfn!(mem5, buf, name, (i + 1), count, fat16_lfn_reset(st)) } else { ({
			(mem6, entry) = fat16_read_dir_entry!(mem5, buf, off)
			({
				(mem7, mem__373) = fat16_entry_matches!(mem6, entry, buf, off, st, name)
				(if mem__373 { (mem7, { sc_found: Just(entry), sc_lfn: st }) } else { fat16_scan_sector_lfn!(mem7, buf, name, (i + 1), count, fat16_lfn_reset(st)) })
			})
		}) })
		}) })
		}) })
		})
	}) })

	fat16_scan_sector_entries! : Mem.Mem, I64, Str, I64, I64 => (Mem.Mem, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_scan_sector_entries! = |mem, buf, name, i, count| (if (i >= count) { (mem, None) } else { ({
		off = (i * 32)
		({
			(mem1, mem__374) = fat16_is_free_entry!(mem, buf, off)
			(if mem__374 { ({
			(mem2, mem__375) = Mem.load!(mem1, buf, off, 1)
			(if (mem__375 == 0) { (mem2, None) } else { fat16_scan_sector_entries!(mem2, buf, name, (i + 1), count) })
		}) } else { ({
			(mem3, mem__376) = fat16_is_lfn_entry!(mem1, buf, off)
			(if mem__376 { fat16_scan_sector_entries!(mem3, buf, name, (i + 1), count) } else { ({
			(mem4, mem__377) = fat16_is_volume_label!(mem3, buf, off)
			(if mem__377 { fat16_scan_sector_entries!(mem4, buf, name, (i + 1), count) } else { ({
			(mem5, entry) = fat16_read_dir_entry!(mem4, buf, off)
			(if fat16_name_matches(entry.de_name, name) { (mem5, Just(entry)) } else { fat16_scan_sector_entries!(mem5, buf, name, (i + 1), count) })
		}) })
		}) })
		}) })
		})
	}) })

	fat16_find_in_cluster_dir! : Mem.Mem, Fat16.Fat16Volume, I64, Str => (Mem.Mem, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_find_in_cluster_dir! = |_, _, _, _| crash("`fat16-find-in-cluster-dir` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_find_in_cluster_walk! : Mem.Mem, Fat16.Fat16Volume, I64, Str, I64, I64, I64, Fat16.Fat16Lfn => (Mem.Mem, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_find_in_cluster_walk! = |_, _, _, _, _, _, _, _| crash("`fat16-find-in-cluster-walk` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_cluster_found_or_next! : Mem.Mem, Fat16.Fat16Volume, I64, Str, I64, I64, I64, Fat16.Fat16Scan => (Mem.Mem, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_cluster_found_or_next! = |_, _, _, _, _, _, _, _| crash("`fat16-cluster-found-or-next` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_find_in_cluster_step! : Mem.Mem, Fat16.Fat16Volume, I64, Str, I64, I64, I64, Fat16.Fat16Lfn => (Mem.Mem, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_find_in_cluster_step! = |_, _, _, _, _, _, _, _| crash("`fat16-find-in-cluster-step` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_scan_cluster_sectors! : Mem.Mem, Fat16.Fat16Volume, Str, I64, I64, Fat16.Fat16Lfn => (Mem.Mem, Fat16.Fat16Scan)
	fat16_scan_cluster_sectors! = |_, _, _, _, _, _| crash("`fat16-scan-cluster-sectors` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_scan_cluster_step! : Mem.Mem, Fat16.Fat16Volume, Str, I64, I64, I64, Fat16.Fat16Lfn => (Mem.Mem, Fat16.Fat16Scan)
	fat16_scan_cluster_step! = |_, _, _, _, _, _, _| crash("`fat16-scan-cluster-step` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_name_matches : Str, Str -> Bool
	fat16_name_matches = |entry_name, search_name| (fat16_upper(entry_name) == fat16_upper(search_name))

	fat16_upper : Str -> Str
	fat16_upper = |s| fat16_upper_loop(s, 0, Cce.length(s), "")

	fat16_upper_loop : Str, I64, I64, Str -> Str
	fat16_upper_loop = |s, i, len, acc| (if (i >= len) { acc } else { ({
		c = Cce.at_or_crash(s, i)
		fat16_upper_loop(s, (i + 1), len, Str.concat(acc, Cce.text(CCE.to_upper(c))))
	}) })

	fat16_scope_admits! : Mem.Mem, Str => (Mem.Mem, Bool)
	fat16_scope_admits! = |_, _| crash("`fat16-scope-admits` reaches `process-get-scope`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_resolve_path! : Mem.Mem, Fat16.Fat16Volume, Str => (Mem.Mem, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_resolve_path! = |_, _, _| crash("`fat16-resolve-path` reaches `process-get-scope`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_walk_path! : Mem.Mem, Fat16.Fat16Volume, List(Str), I64, I64 => (Mem.Mem, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_walk_path! = |_, _, _, _, _| crash("`fat16-walk-path` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_walk_path_sub! : Mem.Mem, Fat16.Fat16Volume, List(Str), I64, I64, I64 => (Mem.Mem, Maybe.Maybe(Fat16.Fat16DirEntry))
	fat16_walk_path_sub! = |_, _, _, _, _, _| crash("`fat16-walk-path-sub` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_split_path : Str -> List(Str)
	fat16_split_path = |path| fat16_split_loop(path, 0, Cce.length(path), 0, [])

	fat16_split_loop : Str, I64, I64, I64, List(Str) -> List(Str)
	fat16_split_loop = |s, i, len, start, acc| (if (i >= len) { (if (i > start) { List.append(acc, Cce.substring(s, start, (i - start))) } else { acc }) } else { (if (Cce.at_or_crash(s, i) == CCE.from_unicode(47)) { (if (i > start) { fat16_split_loop(s, (i + 1), len, (i + 1), List.append(acc, Cce.substring(s, start, (i - start)))) } else { fat16_split_loop(s, (i + 1), len, (i + 1), acc) }) } else { fat16_split_loop(s, (i + 1), len, start, acc) }) })

	fat16_read_cluster_bytes! : Mem.Mem, Fat16.Fat16Volume, I64, I64, I64, List(I64) => (Mem.Mem, List(I64))
	fat16_read_cluster_bytes! = |_, _, _, _, _, _| crash("`fat16-read-cluster-bytes` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_read_cluster_step! : Mem.Mem, Fat16.Fat16Volume, I64, I64, I64, List(I64), I64 => (Mem.Mem, List(I64))
	fat16_read_cluster_step! = |_, _, _, _, _, _, _| crash("`fat16-read-cluster-step` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_copy_bytes! : Mem.Mem, I64, I64, I64, List(I64) => (Mem.Mem, List(I64))
	fat16_copy_bytes! = |mem, buf, off, count, acc| (if (count <= 0) { (mem, acc) } else { ({
		(mem1, mem__378) = Mem.load!(mem, buf, off, 1)
		fat16_copy_bytes!(mem1, buf, (off + 1), (count - 1), List.append(acc, mem__378))
	}) })

	fat16_read_bytes! : Mem.Mem, Fat16.Fat16Volume, Str => (Mem.Mem, Maybe.Maybe(List(I64)))
	fat16_read_bytes! = |_, _, _| crash("`fat16-read-bytes` reaches `process-get-scope`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_byte_to_cce : List(I64), I64 -> I64
	fat16_byte_to_cce = |tbl, b| ({
		t0 = CCE.from_unicode_tier0(tbl, b, 0, 128)
		(if (t0 >= 0) { t0 } else { CCE.from_unicode(b) })
	})

	fat16_bytes_to_chars : List(I64), List(I64), I64, I64, List(Str) -> List(Str)
	fat16_bytes_to_chars = |tbl, bs, i, len, acc| (if (i >= len) { acc } else { fat16_bytes_to_chars(tbl, bs, (i + 1), len, List.append(acc, Cce.text(fat16_byte_to_cce(tbl, (List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))) })

	fat16_bytes_to_text : List(I64), I64, I64, Str -> Str
	fat16_bytes_to_text = |bs, i, len, acc| Str.concat(acc, Str.join_with(fat16_bytes_to_chars(CCE.cce_to_unicode_table, bs, i, len, []), ""))

	fat16_read_text! : Mem.Mem, Fat16.Fat16Volume, Str => (Mem.Mem, Maybe.Maybe(Str))
	fat16_read_text! = |_, _, _| crash("`fat16-read-text` reaches `process-get-scope`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_source_chars : List(I64), List(I64), I64, I64, List(Str) -> List(Str)
	fat16_source_chars = |tbl, bs, i, len, acc| (if (i >= len) { acc } else { (if ((List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) == 13) { fat16_source_chars(tbl, bs, (i + 1), len, acc) } else { fat16_source_chars(tbl, bs, (i + 1), len, List.append(acc, Cce.text(fat16_byte_to_cce(tbl, (List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))) }) })

	fat16_read_source! : Mem.Mem, Fat16.Fat16Volume, Str => (Mem.Mem, Maybe.Maybe(Str))
	fat16_read_source! = |_, _, _| crash("`fat16-read-source` reaches `process-get-scope`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_file_exists! : Mem.Mem, Fat16.Fat16Volume, Str => (Mem.Mem, Bool)
	fat16_file_exists! = |_, _, _| crash("`fat16-file-exists` reaches `process-get-scope`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_fallback_partition_start : I64
	fat16_fallback_partition_start = 2048

	fat16_vol_is_usable : Fat16.Fat16Volume -> Bool
	fat16_vol_is_usable = |vol| ((vol.vol_bytes_per_sector > 0) and (vol.vol_sectors_per_cluster > 0))

	fat16_boot_volume! : Mem.Mem => (Mem.Mem, Fat16.Fat16Volume)
	fat16_boot_volume! = |_| crash("`fat16-boot-volume` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_boot_volume_nogpt! : Mem.Mem => (Mem.Mem, Fat16.Fat16Volume)
	fat16_boot_volume_nogpt! = |_| crash("`fat16-boot-volume-nogpt` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_boot_volume_probe! : Mem.Mem, I64 => (Mem.Mem, Fat16.Fat16Volume)
	fat16_boot_volume_probe! = |_, _| crash("`fat16-boot-volume-probe` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_first_usable! : Mem.Mem, List(Gpt.GptPartition), I64, I64 => (Mem.Mem, Fat16.Fat16Volume)
	fat16_first_usable! = |_, _, _, _| crash("`fat16-first-usable` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	file_exists! : Mem.Mem, Str => (Mem.Mem, Bool)
	file_exists! = |_, _| crash("`file-exists` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_exists_on_disk! : Mem.Mem, Str => (Mem.Mem, Bool)
	fat16_exists_on_disk! = |_, _| crash("`fat16-exists-on-disk` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_text_bytes : Str, I64, I64, List(I64) -> List(I64)
	fat16_text_bytes = |s, i, n, acc| (if (i >= n) { acc } else { ({
		b = CCE.to_unicode(Cce.at_or_crash(s, i))
		fat16_text_bytes(s, (i + 1), n, List.append(acc, b))
	}) })

	fat16_write_file! : Mem.Mem, Str, Str => (Mem.Mem, Bool)
	fat16_write_file! = |_, _, _| crash("`fat16-write-file` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_write_binary_file! : Mem.Mem, Str, List(I64) => (Mem.Mem, Bool)
	fat16_write_binary_file! = |_, _, _| crash("`fat16-write-binary-file` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_write_segments! : Mem.Mem, Str, List(I64), I64, I64, List(I64) => (Mem.Mem, Bool)
	fat16_write_segments! = |_, _, _, _, _, _| crash("`fat16-write-segments` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_write_source! : Mem.Mem, Str, Fat16.Fat16Source => (Mem.Mem, Bool)
	fat16_write_source! = |_, _, _| crash("`fat16-write-source` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_list_root! : Mem.Mem, Fat16.Fat16Volume => (Mem.Mem, List(Str))
	fat16_list_root! = |_, _| crash("`fat16-list-root` reaches `process-get-scope`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_entry_names : List(Fat16.Fat16DirEntry), I64, I64, List(Str) -> List(Str)
	fat16_entry_names = |es, i, n, acc| (if (i >= n) { acc } else { fat16_entry_names(es, (i + 1), n, List.append(acc, (List.get(es, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).de_name)) })

	fat16_list_sector_entries! : Mem.Mem, I64, I64, I64, List(Str) => (Mem.Mem, List(Str))
	fat16_list_sector_entries! = |mem, buf, i, count, acc| (if (i >= count) { (mem, acc) } else { ({
		off = (i * 32)
		({
			(mem1, mem__379) = fat16_is_free_entry!(mem, buf, off)
			(if mem__379 { ({
			(mem2, mem__380) = Mem.load!(mem1, buf, off, 1)
			(if (mem__380 == 0) { (mem2, acc) } else { fat16_list_sector_entries!(mem2, buf, (i + 1), count, acc) })
		}) } else { ({
			(mem3, mem__381) = fat16_is_lfn_entry!(mem1, buf, off)
			(if mem__381 { fat16_list_sector_entries!(mem3, buf, (i + 1), count, acc) } else { ({
			(mem4, mem__382) = fat16_is_volume_label!(mem3, buf, off)
			(if mem__382 { fat16_list_sector_entries!(mem4, buf, (i + 1), count, acc) } else { ({
			(mem5, entry) = fat16_read_dir_entry!(mem4, buf, off)
			fat16_list_sector_entries!(mem5, buf, (i + 1), count, List.append(acc, entry.de_name))
		}) })
		}) })
		}) })
		})
	}) })

	fat16_read_entry_named! : Mem.Mem, I64, I64, Fat16.Fat16Lfn => (Mem.Mem, Fat16.Fat16DirEntry)
	fat16_read_entry_named! = |mem, buf, off, st| ({
		(mem3, mem__384) = ({
		(mem1, e) = fat16_read_dir_entry!(mem, buf, off)
		({
			(mem2, mem__383) = fat16_lfn_final!(mem1, buf, off, st)
			(mem2, (match mem__383 {
			Just(n) => { de_name: n, de_attr: e.de_attr, de_cluster: e.de_cluster, de_size: e.de_size }
			None => e
		}))
		})
	})
		(mem3, mem__384)
	})

	fat16_entries_in_sector! : Mem.Mem, I64, I64, I64, List(Fat16.Fat16DirEntry), Fat16.Fat16Lfn => (Mem.Mem, Fat16.Fat16List)
	fat16_entries_in_sector! = |mem, buf, i, count, acc, st| (if (i >= count) { (mem, { li_entries: acc, li_lfn: st }) } else { ({
		off = (i * 32)
		({
			(mem1, mem__385) = fat16_is_free_entry!(mem, buf, off)
			(if mem__385 { ({
			(mem2, mem__386) = Mem.load!(mem1, buf, off, 1)
			(if (mem__386 == 0) { (mem2, { li_entries: acc, li_lfn: fat16_lfn_reset(st) }) } else { fat16_entries_in_sector!(mem2, buf, (i + 1), count, acc, fat16_lfn_reset(st)) })
		}) } else { ({
			(mem3, mem__387) = fat16_is_lfn_entry!(mem1, buf, off)
			(if mem__387 { ({
			(mem4, mem__388) = fat16_lfn_absorb!(mem3, buf, off, st)
			fat16_entries_in_sector!(mem4, buf, (i + 1), count, acc, mem__388)
		}) } else { ({
			(mem5, mem__389) = fat16_is_volume_label!(mem3, buf, off)
			(if mem__389 { fat16_entries_in_sector!(mem5, buf, (i + 1), count, acc, fat16_lfn_reset(st)) } else { ({
			(mem6, named) = fat16_read_entry_named!(mem5, buf, off, st)
			fat16_entries_in_sector!(mem6, buf, (i + 1), count, List.append(acc, named), fat16_lfn_reset(st))
		}) })
		}) })
		}) })
		})
	}) })

	fat16_root_entries! : Mem.Mem, Fat16.Fat16Volume => (Mem.Mem, List(Fat16.Fat16DirEntry))
	fat16_root_entries! = |_, _| crash("`fat16-root-entries` reaches `process-get-scope`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_root_entry_sectors! : Mem.Mem, Fat16.Fat16Volume, I64, I64, I64, List(Fat16.Fat16DirEntry), Fat16.Fat16Lfn => (Mem.Mem, List(Fat16.Fat16DirEntry))
	fat16_root_entry_sectors! = |_, _, _, _, _, _, _| crash("`fat16-root-entry-sectors` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_cluster_entries! : Mem.Mem, Fat16.Fat16Volume, I64, List(Fat16.Fat16DirEntry) => (Mem.Mem, List(Fat16.Fat16DirEntry))
	fat16_cluster_entries! = |_, _, _, _| crash("`fat16-cluster-entries` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_cluster_entries_walk! : Mem.Mem, Fat16.Fat16Volume, I64, List(Fat16.Fat16DirEntry), I64, I64, I64, Fat16.Fat16Lfn => (Mem.Mem, List(Fat16.Fat16DirEntry))
	fat16_cluster_entries_walk! = |_, _, _, _, _, _, _, _| crash("`fat16-cluster-entries-walk` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_cluster_entry_sectors! : Mem.Mem, Fat16.Fat16Volume, I64, I64, List(Fat16.Fat16DirEntry), Fat16.Fat16Lfn => (Mem.Mem, Fat16.Fat16List)
	fat16_cluster_entry_sectors! = |_, _, _, _, _, _| crash("`fat16-cluster-entry-sectors` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_is_root_path : Str -> Bool
	fat16_is_root_path = |p| (((Cce.length(p) == 0) or (p == "/")) or (p == "."))

	fat16_is_dir_entry : Fat16.Fat16DirEntry -> Bool
	fat16_is_dir_entry = |e| (I64.bitwise_and(e.de_attr, 16) == 16)

	fat16_list_dir! : Mem.Mem, Fat16.Fat16Volume, Str => (Mem.Mem, List(Fat16.Fat16DirEntry))
	fat16_list_dir! = |_, _, _| crash("`fat16-list-dir` reaches `process-get-scope`, a device builtin this program's opening never calls, and the program runs without the machine")

	list_files! : Mem.Mem, Str, Str => (Mem.Mem, List(Str))
	list_files! = |_, _, _| crash("`list-files` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_pick_files : List(Fat16.Fat16DirEntry), I64, I64, Str, List(Str) -> List(Str)
	fat16_pick_files = |es, i, n, ext, acc| (if (i >= n) { acc } else { ({
		e = (List.get(es, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if fat16_is_dir_entry(e) { fat16_pick_files(es, (i + 1), n, ext, acc) } else { (if fat16_name_has_ext(e.de_name, ext) { fat16_pick_files(es, (i + 1), n, ext, List.append(acc, e.de_name)) } else { fat16_pick_files(es, (i + 1), n, ext, acc) }) })
	}) })

	fat16_name_has_ext : Str, Str -> Bool
	fat16_name_has_ext = |name, ext| (if (Cce.length(ext) == 0) { True } else { StringUtils.text_ends_with(fat16_upper(name), fat16_upper(ext)) })

	list_directories! : Mem.Mem, Str => (Mem.Mem, List(Str))
	list_directories! = |_, _| crash("`list-directories` reaches `block-read-sector`, a device builtin this program's opening never calls, and the program runs without the machine")

	fat16_pick_dirs : List(Fat16.Fat16DirEntry), I64, I64, List(Str) -> List(Str)
	fat16_pick_dirs = |es, i, n, acc| (if (i >= n) { acc } else { ({
		e = (List.get(es, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (fat16_is_dir_entry(e) == False) { fat16_pick_dirs(es, (i + 1), n, acc) } else { (if (e.de_name == ".") { fat16_pick_dirs(es, (i + 1), n, acc) } else { (if (e.de_name == "..") { fat16_pick_dirs(es, (i + 1), n, acc) } else { fat16_pick_dirs(es, (i + 1), n, List.append(acc, e.de_name)) }) }) })
	}) })
}
