# TrueType -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

TrueType :: [].{
	TtfTableEntry := { tte_tag : I64, tte_offset : I64, tte_length : I64 }.{
		is_eq : TrueType.TtfTableEntry, TrueType.TtfTableEntry -> Bool
		is_eq = |a, b| eq_TtfTableEntry(a, b)
	}
	TtfDir := { td_num_tables : I64, td_tables : List(TrueType.TtfTableEntry) }.{
		is_eq : TrueType.TtfDir, TrueType.TtfDir -> Bool
		is_eq = |a, b| eq_TtfDir(a, b)
	}
	TtfHead := { th_units_per_em : I64, th_index_to_loc : I64, th_x_min : I64, th_y_min : I64, th_x_max : I64, th_y_max : I64 }.{
		is_eq : TrueType.TtfHead, TrueType.TtfHead -> Bool
		is_eq = |a, b| eq_TtfHead(a, b)
	}
	TtfHMetric := { hm_advance : I64, hm_lsb : I64 }.{
		is_eq : TrueType.TtfHMetric, TrueType.TtfHMetric -> Bool
		is_eq = |a, b| eq_TtfHMetric(a, b)
	}
	TtfCmap := { cm_seg_count : I64, cm_end_codes : List(I64), cm_start_codes : List(I64), cm_id_deltas : List(I64), cm_id_range_offsets : List(I64), cm_glyph_ids : List(I64), cm_range_off_base : I64 }.{
		is_eq : TrueType.TtfCmap, TrueType.TtfCmap -> Bool
		is_eq = |a, b| eq_TtfCmap(a, b)
	}
	TtfPoint := { tp_x : I64, tp_y : I64, tp_on_curve : I64 }.{
		is_eq : TrueType.TtfPoint, TrueType.TtfPoint -> Bool
		is_eq = |a, b| eq_TtfPoint(a, b)
	}
	TtfContour := { tc_points : List(TrueType.TtfPoint) }.{
		is_eq : TrueType.TtfContour, TrueType.TtfContour -> Bool
		is_eq = |a, b| eq_TtfContour(a, b)
	}
	TtfGlyph := { tg_contours : List(TrueType.TtfContour), tg_x_min : I64, tg_y_min : I64, tg_x_max : I64, tg_y_max : I64, tg_advance : I64, tg_lsb : I64 }.{
		is_eq : TrueType.TtfGlyph, TrueType.TtfGlyph -> Bool
		is_eq = |a, b| eq_TtfGlyph(a, b)
	}
	TtfFlagsResult := { tfr_flags : List(I64), tfr_offset : I64 }.{
		is_eq : TrueType.TtfFlagsResult, TrueType.TtfFlagsResult -> Bool
		is_eq = |a, b| eq_TtfFlagsResult(a, b)
	}
	TtfCoordsResult := { tcr_coords : List(I64), tcr_offset : I64 }.{
		is_eq : TrueType.TtfCoordsResult, TrueType.TtfCoordsResult -> Bool
		is_eq = |a, b| eq_TtfCoordsResult(a, b)
	}
	TtfResolved := { tr_glyph : TrueType.TtfGlyph, tr_left : I64, tr_ok : Bool }.{
		is_eq : TrueType.TtfResolved, TrueType.TtfResolved -> Bool
		is_eq = |a, b| eq_TtfResolved(a, b)
	}
	TtfTransform := { tx_xx : I64, tx_xy : I64, tx_yx : I64, tx_yy : I64, tx_next : I64 }.{
		is_eq : TrueType.TtfTransform, TrueType.TtfTransform -> Bool
		is_eq = |a, b| eq_TtfTransform(a, b)
	}
	TtfPointRef := { tpr_point : TrueType.TtfPoint, tpr_ok : Bool }.{
		is_eq : TrueType.TtfPointRef, TrueType.TtfPointRef -> Bool
		is_eq = |a, b| eq_TtfPointRef(a, b)
	}
	TtfFont := { tf_buf : List(I64), tf_dir : TrueType.TtfDir, tf_head : TrueType.TtfHead, tf_num_glyphs : I64, tf_num_hmetrics : I64, tf_hmetrics : List(TrueType.TtfHMetric), tf_cmap : TrueType.TtfCmap, tf_loca : List(I64), tf_glyf_off : I64 }.{
		is_eq : TrueType.TtfFont, TrueType.TtfFont -> Bool
		is_eq = |a, b| eq_TtfFont(a, b)
	}

	ttf_byte_at : List(I64), I64 -> I64
	ttf_byte_at = |buf, off| (if (off < 0) { 0 } else { (if (off >= U64.to_i64_wrap(List.len(buf))) { 0 } else { (List.get(buf, I64.to_u64_wrap(off)) ?? crash("list-at out of range")) }) })

	ttf_u8 : List(I64), I64 -> I64
	ttf_u8 = |buf, off| ttf_byte_at(buf, off)

	ttf_u16 : List(I64), I64 -> I64
	ttf_u16 = |buf, off| ({
		hi : I64
		hi = ttf_byte_at(buf, off)
		lo : I64
		lo = ttf_byte_at(buf, (off + 1))
		((hi * 256) + lo)
	})

	ttf_i16 : List(I64), I64 -> I64
	ttf_i16 = |buf, off| ({
		v : I64
		v = ttf_u16(buf, off)
		(if (v >= 32768) { (v - 65536) } else { v })
	})

	ttf_u32 : List(I64), I64 -> I64
	ttf_u32 = |buf, off| ({
		a : I64
		a = ttf_byte_at(buf, off)
		b : I64
		b = ttf_byte_at(buf, (off + 1))
		c : I64
		c = ttf_byte_at(buf, (off + 2))
		d : I64
		d = ttf_byte_at(buf, (off + 3))
		((((a * 16777216) + (b * 65536)) + (c * 256)) + d)
	})

	ttf_read_tag : List(I64), I64 -> I64
	ttf_read_tag = |buf, off| ({
		a : I64
		a = ttf_byte_at(buf, off)
		b : I64
		b = ttf_byte_at(buf, (off + 1))
		c : I64
		c = ttf_byte_at(buf, (off + 2))
		d : I64
		d = ttf_byte_at(buf, (off + 3))
		((((a * 16777216) + (b * 65536)) + (c * 256)) + d)
	})

	ttf_read_dir : List(I64) -> TrueType.TtfDir
	ttf_read_dir = |buf| ({
		num : I64
		num = ttf_u16(buf, 4)
		tables = ttf_read_dir_loop(buf, 12, num, 0, [])
		TrueType.TtfDir.{ td_num_tables: num, td_tables: tables }
	})

	ttf_read_dir_loop : List(I64), I64, I64, I64, List(TrueType.TtfTableEntry) -> List(TrueType.TtfTableEntry)
	ttf_read_dir_loop = |buf, off, num, i, acc| (if (i >= num) { acc } else { ({
		entry = TrueType.TtfTableEntry.{ tte_tag: ttf_read_tag(buf, off), tte_offset: ttf_u32(buf, (off + 8)), tte_length: ttf_u32(buf, (off + 12)) }
		ttf_read_dir_loop(buf, (off + 16), num, (i + 1), List.append(acc, entry))
	}) })

	ttf_find_table : TrueType.TtfDir, I64 -> I64
	ttf_find_table = |dir, tag| ttf_find_table_loop(dir.td_tables, tag, 0)

	ttf_find_table_loop : List(TrueType.TtfTableEntry), I64, I64 -> I64
	ttf_find_table_loop = |tables, tag, i| (if (i >= U64.to_i64_wrap(List.len(tables))) { (-1) } else { ({
		entry = (List.get(tables, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (entry.tte_tag == tag) { entry.tte_offset } else { ttf_find_table_loop(tables, tag, (i + 1)) })
	}) })

	ttf_read_head : List(I64), I64 -> TrueType.TtfHead
	ttf_read_head = |buf, off| TrueType.TtfHead.{ th_units_per_em: ttf_u16(buf, (off + 18)), th_index_to_loc: ttf_i16(buf, (off + 50)), th_x_min: ttf_i16(buf, (off + 36)), th_y_min: ttf_i16(buf, (off + 38)), th_x_max: ttf_i16(buf, (off + 40)), th_y_max: ttf_i16(buf, (off + 42)) }

	ttf_read_num_glyphs : List(I64), I64 -> I64
	ttf_read_num_glyphs = |buf, off| ttf_u16(buf, (off + 4))

	ttf_read_num_hmetrics : List(I64), I64 -> I64
	ttf_read_num_hmetrics = |buf, off| ttf_u16(buf, (off + 34))

	ttf_read_hmetrics : List(I64), I64, I64 -> List(TrueType.TtfHMetric)
	ttf_read_hmetrics = |buf, off, count| ttf_read_hmetrics_loop(buf, off, count, 0, [])

	ttf_read_hmetrics_loop : List(I64), I64, I64, I64, List(TrueType.TtfHMetric) -> List(TrueType.TtfHMetric)
	ttf_read_hmetrics_loop = |buf, off, count, i, acc| (if (i >= count) { acc } else { ({
		m = TrueType.TtfHMetric.{ hm_advance: ttf_u16(buf, (off + (i * 4))), hm_lsb: ttf_i16(buf, ((off + (i * 4)) + 2)) }
		ttf_read_hmetrics_loop(buf, off, count, (i + 1), List.append(acc, m))
	}) })

	ttf_read_loca_short : List(I64), I64, I64 -> List(I64)
	ttf_read_loca_short = |buf, off, num_glyphs| ttf_read_loca_short_loop(buf, off, (num_glyphs + 1), 0, [])

	ttf_read_loca_short_loop : List(I64), I64, I64, I64, List(I64) -> List(I64)
	ttf_read_loca_short_loop = |buf, off, count, i, acc| (if (i >= count) { acc } else { ({
		v : I64
		v = (ttf_u16(buf, (off + (i * 2))) * 2)
		ttf_read_loca_short_loop(buf, off, count, (i + 1), List.append(acc, v))
	}) })

	ttf_read_loca_long : List(I64), I64, I64 -> List(I64)
	ttf_read_loca_long = |buf, off, num_glyphs| ttf_read_loca_long_loop(buf, off, (num_glyphs + 1), 0, [])

	ttf_read_loca_long_loop : List(I64), I64, I64, I64, List(I64) -> List(I64)
	ttf_read_loca_long_loop = |buf, off, count, i, acc| (if (i >= count) { acc } else { ({
		v : I64
		v = ttf_u32(buf, (off + (i * 4)))
		ttf_read_loca_long_loop(buf, off, count, (i + 1), List.append(acc, v))
	}) })

	ttf_find_cmap4 : List(I64), I64 -> I64
	ttf_find_cmap4 = |buf, cmap_off| ({
		num_sub : I64
		num_sub = ttf_u16(buf, (cmap_off + 2))
		ttf_find_cmap4_loop(buf, (cmap_off + 4), num_sub, 0, cmap_off)
	})

	ttf_find_cmap4_loop : List(I64), I64, I64, I64, I64 -> I64
	ttf_find_cmap4_loop = |buf, off, num, i, cmap_off| (if (i >= num) { (-1) } else { ({
		_plat = ttf_u16(buf, off)
		_enc = ttf_u16(buf, (off + 2))
		sub_off : I64
		sub_off = ttf_u32(buf, (off + 4))
		fmt : I64
		fmt = ttf_u16(buf, (cmap_off + sub_off))
		(if (fmt == 4) { (cmap_off + sub_off) } else { ttf_find_cmap4_loop(buf, (off + 8), num, (i + 1), cmap_off) })
	}) })

	ttf_read_cmap4 : List(I64), I64 -> TrueType.TtfCmap
	ttf_read_cmap4 = |buf, off| ({
		seg_count : I64
		seg_count = I64.div_trunc_by(ttf_u16(buf, (off + 6)), 2)
		end_off : I64
		end_off = (off + 14)
		start_off : I64
		start_off = ((end_off + (seg_count * 2)) + 2)
		delta_off : I64
		delta_off = (start_off + (seg_count * 2))
		range_off : I64
		range_off = (delta_off + (seg_count * 2))
		glyph_off : I64
		glyph_off = (range_off + (seg_count * 2))
		table_len : I64
		table_len = ttf_u16(buf, (off + 2))
		glyph_count : I64
		glyph_count = I64.div_trunc_by((table_len - (glyph_off - off)), 2)
		TrueType.TtfCmap.{ cm_seg_count: seg_count, cm_end_codes: ttf_read_u16_array(buf, end_off, seg_count), cm_start_codes: ttf_read_u16_array(buf, start_off, seg_count), cm_id_deltas: ttf_read_i16_array(buf, delta_off, seg_count), cm_id_range_offsets: ttf_read_u16_array(buf, range_off, seg_count), cm_glyph_ids: ttf_read_u16_array(buf, glyph_off, ttf_cmap_max(glyph_count, 0)), cm_range_off_base: range_off }
	})

	ttf_cmap_max : I64, I64 -> I64
	ttf_cmap_max = |a, b| (if (a > b) { a } else { b })

	ttf_read_u16_array : List(I64), I64, I64 -> List(I64)
	ttf_read_u16_array = |buf, off, count| ttf_read_u16_array_loop(buf, off, count, 0, [])

	ttf_read_u16_array_loop : List(I64), I64, I64, I64, List(I64) -> List(I64)
	ttf_read_u16_array_loop = |buf, off, count, i, acc| (if (i >= count) { acc } else { ttf_read_u16_array_loop(buf, off, count, (i + 1), List.append(acc, ttf_u16(buf, (off + (i * 2))))) })

	ttf_read_i16_array : List(I64), I64, I64 -> List(I64)
	ttf_read_i16_array = |buf, off, count| ttf_read_i16_array_loop(buf, off, count, 0, [])

	ttf_read_i16_array_loop : List(I64), I64, I64, I64, List(I64) -> List(I64)
	ttf_read_i16_array_loop = |buf, off, count, i, acc| (if (i >= count) { acc } else { ttf_read_i16_array_loop(buf, off, count, (i + 1), List.append(acc, ttf_i16(buf, (off + (i * 2))))) })

	ttf_cmap_lookup : TrueType.TtfCmap, I64 -> I64
	ttf_cmap_lookup = |cm, codepoint| ttf_cmap_lookup_loop(cm, codepoint, 0)

	ttf_cmap_lookup_loop : TrueType.TtfCmap, I64, I64 -> I64
	ttf_cmap_lookup_loop = |cm, cp, i| (if (i >= cm.cm_seg_count) { 0 } else { ({
		end_code : I64
		end_code = (List.get(cm.cm_end_codes, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (cp > end_code) { ttf_cmap_lookup_loop(cm, cp, (i + 1)) } else { ({
			start_code : I64
			start_code = (List.get(cm.cm_start_codes, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
			(if (cp < start_code) { 0 } else { ({
				range_off : I64
				range_off = (List.get(cm.cm_id_range_offsets, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
				(if (range_off == 0) { ({
					delta : I64
					delta = (List.get(cm.cm_id_deltas, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
					ttf_mod65536((cp + delta))
				}) } else { ({
					idx : I64
					idx = ((I64.div_trunc_by(range_off, 2) + (cp - start_code)) - (cm.cm_seg_count - i))
					(if (idx < 0) { 0 } else { (if (idx >= U64.to_i64_wrap(List.len(cm.cm_glyph_ids))) { 0 } else { ({
						gid : I64
						gid = (List.get(cm.cm_glyph_ids, I64.to_u64_wrap(idx)) ?? crash("list-at out of range"))
						(if (gid == 0) { 0 } else { ({
							delta : I64
							delta = (List.get(cm.cm_id_deltas, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
							ttf_mod65536((gid + delta))
						}) })
					}) }) })
				}) })
			}) })
		}) })
	}) })

	ttf_mod65536 : I64 -> I64
	ttf_mod65536 = |v| ({
		m : I64
		m = (v - (I64.div_trunc_by(v, 65536) * 65536))
		(if (m < 0) { (m + 65536) } else { m })
	})

	ttf_empty_glyph : TrueType.TtfGlyph
	ttf_empty_glyph = TrueType.TtfGlyph.{ tg_contours: [], tg_x_min: 0, tg_y_min: 0, tg_x_max: 0, tg_y_max: 0, tg_advance: 0, tg_lsb: 0 }

	ttf_read_glyph : TrueType.TtfFont, I64 -> TrueType.TtfGlyph
	ttf_read_glyph = |font, glyph_idx| ttf_resolve_glyph(font, glyph_idx, 0, 64).tr_glyph

	ttf_get_hmetric : List(TrueType.TtfHMetric), I64 -> TrueType.TtfHMetric
	ttf_get_hmetric = |hmetrics, idx| (if (U64.to_i64_wrap(List.len(hmetrics)) == 0) { TrueType.TtfHMetric.{ hm_advance: 0, hm_lsb: 0 } } else { (if (idx < 0) { (List.get(hmetrics, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) } else { (if (idx >= U64.to_i64_wrap(List.len(hmetrics))) { (List.get(hmetrics, I64.to_u64_wrap((U64.to_i64_wrap(List.len(hmetrics)) - 1))) ?? crash("list-at out of range")) } else { (List.get(hmetrics, I64.to_u64_wrap(idx)) ?? crash("list-at out of range")) }) }) })

	ttf_read_simple_glyph : List(I64), I64, I64, TrueType.TtfHMetric -> TrueType.TtfGlyph
	ttf_read_simple_glyph = |buf, off, num_contours, hm| ({
		x_min : I64
		x_min = ttf_i16(buf, (off + 2))
		y_min : I64
		y_min = ttf_i16(buf, (off + 4))
		x_max : I64
		x_max = ttf_i16(buf, (off + 6))
		y_max : I64
		y_max = ttf_i16(buf, (off + 8))
		end_pts : List(I64)
		end_pts = ttf_read_u16_array(buf, (off + 10), num_contours)
		total_pts : I64
		total_pts = ((List.get(end_pts, I64.to_u64_wrap((num_contours - 1))) ?? crash("list-at out of range")) + 1)
		instr_len : I64
		instr_len = ttf_u16(buf, ((off + 10) + (num_contours * 2)))
		flags_off : I64
		flags_off = ((((off + 10) + (num_contours * 2)) + 2) + instr_len)
		flags_result = ttf_read_flags(buf, flags_off, total_pts)
		flags : List(I64)
		flags = ttf_fr_flags(flags_result)
		after_flags : I64
		after_flags = ttf_fr_offset(flags_result)
		xs_result = ttf_read_coords(buf, after_flags, flags, total_pts, 1, 4)
		xs : List(I64)
		xs = ttf_cr_coords(xs_result)
		ys_result = ttf_read_coords(buf, ttf_cr_offset(xs_result), flags, total_pts, 2, 5)
		ys : List(I64)
		ys = ttf_cr_coords(ys_result)
		points = ttf_build_points(flags, xs, ys, total_pts, 0, [])
		contours = ttf_split_contours(points, end_pts, num_contours, 0, 0, [])
		TrueType.TtfGlyph.{ tg_contours: contours, tg_x_min: x_min, tg_y_min: y_min, tg_x_max: x_max, tg_y_max: y_max, tg_advance: hm.hm_advance, tg_lsb: hm.hm_lsb }
	})

	ttf_fr_flags : TrueType.TtfFlagsResult -> List(I64)
	ttf_fr_flags = |r| r.tfr_flags

	ttf_fr_offset : TrueType.TtfFlagsResult -> I64
	ttf_fr_offset = |r| r.tfr_offset

	ttf_read_flags : List(I64), I64, I64 -> TrueType.TtfFlagsResult
	ttf_read_flags = |buf, off, total| ttf_read_flags_loop(buf, off, total, [])

	ttf_read_flags_loop : List(I64), I64, I64, List(I64) -> TrueType.TtfFlagsResult
	ttf_read_flags_loop = |buf, off, remaining, acc| (if (remaining <= 0) { TrueType.TtfFlagsResult.{ tfr_flags: acc, tfr_offset: off } } else { ({
		flag : I64
		flag = ttf_u8(buf, off)
		is_repeat : I64
		is_repeat = ttf_bit_test(flag, 3)
		(if (is_repeat == 0) { ttf_read_flags_loop(buf, (off + 1), (remaining - 1), List.append(acc, flag)) } else { ({
			count : I64
			count = ttf_u8(buf, (off + 1))
			expanded : List(I64)
			expanded = ttf_repeat_flag(flag, count, acc)
			ttf_read_flags_loop(buf, (off + 2), ((remaining - 1) - count), expanded)
		}) })
	}) })

	ttf_repeat_flag : I64, I64, List(I64) -> List(I64)
	ttf_repeat_flag = |flag, count, acc| (if (count <= 0) { List.append(acc, flag) } else { ttf_repeat_flag(flag, (count - 1), List.append(acc, flag)) })

	ttf_bit_test : I64, I64 -> I64
	ttf_bit_test = |val, bit| ({
		shifted : I64
		shifted = ttf_shift_right(val, bit)
		(shifted - (I64.div_trunc_by(shifted, 2) * 2))
	})

	ttf_shift_right : I64, I64 -> I64
	ttf_shift_right = |val, n| (if (n <= 0) { val } else { ttf_shift_right(I64.div_trunc_by(val, 2), (n - 1)) })

	ttf_cr_coords : TrueType.TtfCoordsResult -> List(I64)
	ttf_cr_coords = |r| r.tcr_coords

	ttf_cr_offset : TrueType.TtfCoordsResult -> I64
	ttf_cr_offset = |r| r.tcr_offset

	ttf_read_coords : List(I64), I64, List(I64), I64, I64, I64 -> TrueType.TtfCoordsResult
	ttf_read_coords = |buf, off, flags, total, short_bit, same_bit| ttf_read_coords_loop(buf, off, flags, total, short_bit, same_bit, 0, 0, [])

	ttf_read_coords_loop : List(I64), I64, List(I64), I64, I64, I64, I64, I64, List(I64) -> TrueType.TtfCoordsResult
	ttf_read_coords_loop = |buf, off, flags, total, short_bit, same_bit, i, prev, acc| (if (i >= total) { TrueType.TtfCoordsResult.{ tcr_coords: acc, tcr_offset: off } } else { ({
		flag : I64
		flag = (List.get(flags, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		is_short : I64
		is_short = ttf_bit_test(flag, short_bit)
		is_same : I64
		is_same = ttf_bit_test(flag, same_bit)
		(if (is_short > 0) { ({
			raw : I64
			raw = ttf_u8(buf, off)
			delta : I64
			delta = (if (is_same > 0) { raw } else { (-raw) })
			val : I64
			val = (prev + delta)
			ttf_read_coords_loop(buf, (off + 1), flags, total, short_bit, same_bit, (i + 1), val, List.append(acc, val))
		}) } else { (if (is_same > 0) { ttf_read_coords_loop(buf, off, flags, total, short_bit, same_bit, (i + 1), prev, List.append(acc, prev)) } else { ({
			delta : I64
			delta = ttf_i16(buf, off)
			val : I64
			val = (prev + delta)
			ttf_read_coords_loop(buf, (off + 2), flags, total, short_bit, same_bit, (i + 1), val, List.append(acc, val))
		}) }) })
	}) })

	ttf_build_points : List(I64), List(I64), List(I64), I64, I64, List(TrueType.TtfPoint) -> List(TrueType.TtfPoint)
	ttf_build_points = |flags, xs, ys, total, i, acc| (if (i >= total) { acc } else { ({
		flag : I64
		flag = (List.get(flags, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		on_curve : I64
		on_curve = ttf_bit_test(flag, 0)
		pt = TrueType.TtfPoint.{ tp_x: (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), tp_y: (List.get(ys, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), tp_on_curve: on_curve }
		ttf_build_points(flags, xs, ys, total, (i + 1), List.append(acc, pt))
	}) })

	ttf_split_contours : List(TrueType.TtfPoint), List(I64), I64, I64, I64, List(TrueType.TtfContour) -> List(TrueType.TtfContour)
	ttf_split_contours = |points, end_pts, num, ci, start, acc| (if (ci >= num) { acc } else { ({
		end_pt : I64
		end_pt = (List.get(end_pts, I64.to_u64_wrap(ci)) ?? crash("list-at out of range"))
		contour_pts = ttf_slice_points(points, start, (end_pt + 1), [])
		contour = TrueType.TtfContour.{ tc_points: contour_pts }
		ttf_split_contours(points, end_pts, num, (ci + 1), (end_pt + 1), List.append(acc, contour))
	}) })

	ttf_slice_points : List(TrueType.TtfPoint), I64, I64, List(TrueType.TtfPoint) -> List(TrueType.TtfPoint)
	ttf_slice_points = |points, from, to, acc| (if (from >= to) { acc } else { ttf_slice_points(points, (from + 1), to, List.append(acc, (List.get(points, I64.to_u64_wrap(from)) ?? crash("list-at out of range")))) })

	ttf_refused : I64 -> TrueType.TtfResolved
	ttf_refused = |left| TrueType.TtfResolved.{ tr_glyph: ttf_empty_glyph, tr_left: left, tr_ok: False }

	ttf_header_glyph : List(I64), I64, TrueType.TtfHMetric -> TrueType.TtfGlyph
	ttf_header_glyph = |buf, off, hm| TrueType.TtfGlyph.{ tg_contours: [], tg_x_min: ttf_i16(buf, (off + 2)), tg_y_min: ttf_i16(buf, (off + 4)), tg_x_max: ttf_i16(buf, (off + 6)), tg_y_max: ttf_i16(buf, (off + 8)), tg_advance: hm.hm_advance, tg_lsb: hm.hm_lsb }

	ttf_resolve_glyph : TrueType.TtfFont, I64, I64, I64 -> TrueType.TtfResolved
	ttf_resolve_glyph = |font, idx, depth, fuel| (if (((((depth > 16) or (fuel <= 0)) or (idx < 0)) or (idx >= font.tf_num_glyphs)) or ((idx + 1) >= U64.to_i64_wrap(List.len(font.tf_loca)))) { ttf_refused(fuel) } else { ({
		first : I64
		first = (List.get(font.tf_loca, I64.to_u64_wrap(idx)) ?? crash("list-at out of range"))
		last : I64
		last = (List.get(font.tf_loca, I64.to_u64_wrap((idx + 1))) ?? crash("list-at out of range"))
		off : I64
		off = (font.tf_glyf_off + first)
		stop : I64
		stop = (font.tf_glyf_off + last)
		hm = ttf_get_hmetric(font.tf_hmetrics, idx)
		(if ((((first < 0) or (last < first)) or (font.tf_glyf_off < 0)) or (stop > U64.to_i64_wrap(List.len(font.tf_buf)))) { ttf_refused(fuel) } else { (if (first == last) { TrueType.TtfResolved.{ tr_glyph: TrueType.TtfGlyph.{ tg_contours: [], tg_x_min: 0, tg_y_min: 0, tg_x_max: 0, tg_y_max: 0, tg_advance: hm.hm_advance, tg_lsb: hm.hm_lsb }, tr_left: (fuel - 1), tr_ok: True } } else { (if ((stop - off) < 10) { ttf_refused(fuel) } else { ({
			count : I64
			count = ttf_i16(font.tf_buf, off)
			header = ttf_header_glyph(font.tf_buf, off, hm)
			(if (count < 0) { ttf_components(font, (off + 10), stop, depth, (fuel - 1), header, 0) } else { (if (count == 0) { TrueType.TtfResolved.{ tr_glyph: header, tr_left: (fuel - 1), tr_ok: True } } else { (if ((count > 256) or (((off + 12) + (count * 2)) > stop)) { ttf_refused(fuel) } else { ({
				points : I64
				points = (ttf_u16(font.tf_buf, ((off + 10) + ((count - 1) * 2))) + 1)
				instructions : I64
				instructions = ttf_u16(font.tf_buf, ((off + 10) + (count * 2)))
				(if ((points > 4096) or ((((off + 12) + (count * 2)) + instructions) > stop)) { ttf_refused(fuel) } else { (if (ttf_end_pts_ordered(font.tf_buf, (off + 10), count, 0, 0) == False) { ttf_refused(fuel) } else { TrueType.TtfResolved.{ tr_glyph: ttf_read_simple_glyph(font.tf_buf, off, count, hm), tr_left: (fuel - 1), tr_ok: True } }) })
			}) }) }) })
		}) }) }) })
	}) })

	ttf_end_pts_ordered : List(I64), I64, I64, I64, I64 -> Bool
	ttf_end_pts_ordered = |buf, off, count, i, prev| (if (i >= count) { True } else { ({
		e : I64
		e = ttf_u16(buf, (off + (i * 2)))
		(if (e < prev) { False } else { ttf_end_pts_ordered(buf, off, count, (i + 1), e) })
	}) })

	ttf_component_arg : List(I64), I64, Bool, Bool -> I64
	ttf_component_arg = |buf, off, word, signed| (if word { (if signed { ttf_i16(buf, off) } else { ttf_u16(buf, off) }) } else { ({
		v : I64
		v = ttf_u8(buf, off)
		(if (signed and (v >= 128)) { (v - 256) } else { v })
	}) })

	ttf_component_transform : List(I64), I64, I64 -> TrueType.TtfTransform
	ttf_component_transform = |buf, off, flags| (if (I64.bitwise_and(flags, 8) != 0) { ({
		v : I64
		v = ttf_i16(buf, off)
		TrueType.TtfTransform.{ tx_xx: v, tx_xy: 0, tx_yx: 0, tx_yy: v, tx_next: (off + 2) }
	}) } else { (if (I64.bitwise_and(flags, 64) != 0) { TrueType.TtfTransform.{ tx_xx: ttf_i16(buf, off), tx_xy: 0, tx_yx: 0, tx_yy: ttf_i16(buf, (off + 2)), tx_next: (off + 4) } } else { (if (I64.bitwise_and(flags, 128) != 0) { TrueType.TtfTransform.{ tx_xx: ttf_i16(buf, off), tx_xy: ttf_i16(buf, (off + 4)), tx_yx: ttf_i16(buf, (off + 2)), tx_yy: ttf_i16(buf, (off + 6)), tx_next: (off + 8) } } else { TrueType.TtfTransform.{ tx_xx: 16384, tx_xy: 0, tx_yx: 0, tx_yy: 16384, tx_next: off } }) }) })

	ttf_transform_point : TrueType.TtfPoint, TrueType.TtfTransform, I64, I64 -> TrueType.TtfPoint
	ttf_transform_point = |p, tx, dx, dy| TrueType.TtfPoint.{ tp_x: (I64.div_trunc_by(((tx.tx_xx * p.tp_x) + (tx.tx_xy * p.tp_y)), 16384) + dx), tp_y: (I64.div_trunc_by(((tx.tx_yx * p.tp_x) + (tx.tx_yy * p.tp_y)), 16384) + dy), tp_on_curve: p.tp_on_curve }

	ttf_transform_points : List(TrueType.TtfPoint), TrueType.TtfTransform, I64, I64, I64, List(TrueType.TtfPoint) -> List(TrueType.TtfPoint)
	ttf_transform_points = |ps, tx, dx, dy, i, acc| (if (i >= U64.to_i64_wrap(List.len(ps))) { acc } else { ttf_transform_points(ps, tx, dx, dy, (i + 1), List.append(acc, ttf_transform_point((List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), tx, dx, dy))) })

	ttf_transform_contours : List(TrueType.TtfContour), TrueType.TtfTransform, I64, I64, I64, List(TrueType.TtfContour) -> List(TrueType.TtfContour)
	ttf_transform_contours = |cs, tx, dx, dy, i, acc| (if (i >= U64.to_i64_wrap(List.len(cs))) { acc } else { ({
		c = TrueType.TtfContour.{ tc_points: ttf_transform_points((List.get(cs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).tc_points, tx, dx, dy, 0, []) }
		ttf_transform_contours(cs, tx, dx, dy, (i + 1), List.append(acc, c))
	}) })

	ttf_outline_point : List(TrueType.TtfContour), I64, I64 -> TrueType.TtfPointRef
	ttf_outline_point = |cs, index, i| (if ((i >= U64.to_i64_wrap(List.len(cs))) or (index < 0)) { TrueType.TtfPointRef.{ tpr_point: TrueType.TtfPoint.{ tp_x: 0, tp_y: 0, tp_on_curve: 1 }, tpr_ok: False } } else { ({
		ps = (List.get(cs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).tc_points
		(if (index < U64.to_i64_wrap(List.len(ps))) { TrueType.TtfPointRef.{ tpr_point: (List.get(ps, I64.to_u64_wrap(index)) ?? crash("list-at out of range")), tpr_ok: True } } else { ttf_outline_point(cs, (index - U64.to_i64_wrap(List.len(ps))), (i + 1)) })
	}) })

	ttf_components : TrueType.TtfFont, I64, I64, I64, I64, TrueType.TtfGlyph, I64 -> TrueType.TtfResolved
	ttf_components = |font, off, stop, depth, fuel, parent, components| (if ((((off + 6) > stop) or (components >= 64)) or (fuel <= 0)) { ttf_refused(fuel) } else { ({
		flags : I64
		flags = ttf_u16(font.tf_buf, off)
		index : I64
		index = ttf_u16(font.tf_buf, (off + 2))
		word : Bool
		word = (I64.bitwise_and(flags, 1) != 0)
		xy : Bool
		xy = (I64.bitwise_and(flags, 2) != 0)
		width : I64
		width = (if word { 2 } else { 1 })
		a : I64
		a = ttf_component_arg(font.tf_buf, (off + 4), word, xy)
		b : I64
		b = ttf_component_arg(font.tf_buf, ((off + 4) + width), word, xy)
		tx = ttf_component_transform(font.tf_buf, ((off + 4) + (width * 2)), flags)
		transforms : I64
		transforms = (((if (I64.bitwise_and(flags, 8) != 0) { 1 } else { 0 }) + (if (I64.bitwise_and(flags, 64) != 0) { 1 } else { 0 })) + (if (I64.bitwise_and(flags, 128) != 0) { 1 } else { 0 }))
		(if ((tx.tx_next > stop) or (transforms > 1)) { ttf_refused(fuel) } else { ({
			child = ttf_resolve_glyph(font, index, (depth + 1), fuel)
			(if (child.tr_ok == False) { child } else { ({
				pp = ttf_outline_point(parent.tg_contours, a, 0)
				cp = ttf_outline_point(child.tr_glyph.tg_contours, b, 0)
				origin = ttf_transform_point(cp.tpr_point, tx, 0, 0)
				scaled : Bool
				scaled = ((I64.bitwise_and(flags, 2048) != 0) and (I64.bitwise_and(flags, 4096) == 0))
				offset = ttf_transform_point(TrueType.TtfPoint.{ tp_x: a, tp_y: b, tp_on_curve: 1 }, tx, 0, 0)
				dx : I64
				dx = (if xy { (if scaled { offset.tp_x } else { a }) } else { (pp.tpr_point.tp_x - origin.tp_x) })
				dy : I64
				dy = (if xy { (if scaled { offset.tp_y } else { b }) } else { (pp.tpr_point.tp_y - origin.tp_y) })
				(if ((xy == False) and ((pp.tpr_ok == False) or (cp.tpr_ok == False))) { ttf_refused(child.tr_left) } else { ({
					contours = ttf_transform_contours(child.tr_glyph.tg_contours, tx, dx, dy, 0, parent.tg_contours)
					metric : Bool
					metric = (I64.bitwise_and(flags, 512) != 0)
					combined = TrueType.TtfGlyph.{ tg_contours: contours, tg_x_min: parent.tg_x_min, tg_y_min: parent.tg_y_min, tg_x_max: parent.tg_x_max, tg_y_max: parent.tg_y_max, tg_advance: (if metric { child.tr_glyph.tg_advance } else { parent.tg_advance }), tg_lsb: (if metric { child.tr_glyph.tg_lsb } else { parent.tg_lsb }) }
					(if (I64.bitwise_and(flags, 32) != 0) { ttf_components(font, tx.tx_next, stop, depth, child.tr_left, combined, (components + 1)) } else { (if ((I64.bitwise_and(flags, 256) != 0) and (((tx.tx_next + 2) > stop) or (((tx.tx_next + 2) + ttf_u16(font.tf_buf, tx.tx_next)) > stop))) { ttf_refused(child.tr_left) } else { TrueType.TtfResolved.{ tr_glyph: combined, tr_left: child.tr_left, tr_ok: True } }) })
				}) })
			}) })
		}) })
	}) })

	ttf_tag_head : I64
	ttf_tag_head = 1751474532

	ttf_tag_maxp : I64
	ttf_tag_maxp = 1835104368

	ttf_tag_hhea : I64
	ttf_tag_hhea = 1751672161

	ttf_tag_hmtx : I64
	ttf_tag_hmtx = 1752003704

	ttf_tag_cmap : I64
	ttf_tag_cmap = 1668112752

	ttf_tag_loca : I64
	ttf_tag_loca = 1819239265

	ttf_tag_glyf : I64
	ttf_tag_glyf = 1735162214

	ttf_parse : List(I64) -> TrueType.TtfFont
	ttf_parse = |buf| ({
		dir = ttf_read_dir(buf)
		head_off : I64
		head_off = ttf_find_table(dir, ttf_tag_head)
		maxp_off : I64
		maxp_off = ttf_find_table(dir, ttf_tag_maxp)
		hhea_off : I64
		hhea_off = ttf_find_table(dir, ttf_tag_hhea)
		hmtx_off : I64
		hmtx_off = ttf_find_table(dir, ttf_tag_hmtx)
		cmap_off : I64
		cmap_off = ttf_find_table(dir, ttf_tag_cmap)
		loca_off : I64
		loca_off = ttf_find_table(dir, ttf_tag_loca)
		glyf_off : I64
		glyf_off = ttf_find_table(dir, ttf_tag_glyf)
		head = ttf_read_head(buf, head_off)
		num_glyphs : I64
		num_glyphs = ttf_read_num_glyphs(buf, maxp_off)
		num_hmetrics : I64
		num_hmetrics = ttf_read_num_hmetrics(buf, hhea_off)
		hmetrics = ttf_read_hmetrics(buf, hmtx_off, num_hmetrics)
		cmap4_off : I64
		cmap4_off = ttf_find_cmap4(buf, cmap_off)
		cmap = ttf_read_cmap4(buf, cmap4_off)
		loca : List(I64)
		loca = (if (head.th_index_to_loc == 0) { ttf_read_loca_short(buf, loca_off, num_glyphs) } else { ttf_read_loca_long(buf, loca_off, num_glyphs) })
		TrueType.TtfFont.{ tf_buf: buf, tf_dir: dir, tf_head: head, tf_num_glyphs: num_glyphs, tf_num_hmetrics: num_hmetrics, tf_hmetrics: hmetrics, tf_cmap: cmap, tf_loca: loca, tf_glyf_off: glyf_off }
	})

	ttf_glyph_for_char : TrueType.TtfFont, I64 -> TrueType.TtfGlyph
	ttf_glyph_for_char = |font, codepoint| ({
		glyph_idx : I64
		glyph_idx = ttf_cmap_lookup(font.tf_cmap, codepoint)
		ttf_read_glyph(font, glyph_idx)
	})

	eq_TtfTableEntry : TrueType.TtfTableEntry, TrueType.TtfTableEntry -> Bool
	eq_TtfTableEntry = |ex, ey| (((ex.tte_tag == ey.tte_tag) and (ex.tte_offset == ey.tte_offset)) and (ex.tte_length == ey.tte_length))

	eq_TtfDir : TrueType.TtfDir, TrueType.TtfDir -> Bool
	eq_TtfDir = |ex, ey| ((ex.td_num_tables == ey.td_num_tables) and (ex.td_tables == ey.td_tables))

	eq_TtfHead : TrueType.TtfHead, TrueType.TtfHead -> Bool
	eq_TtfHead = |ex, ey| ((((((ex.th_units_per_em == ey.th_units_per_em) and (ex.th_index_to_loc == ey.th_index_to_loc)) and (ex.th_x_min == ey.th_x_min)) and (ex.th_y_min == ey.th_y_min)) and (ex.th_x_max == ey.th_x_max)) and (ex.th_y_max == ey.th_y_max))

	eq_TtfHMetric : TrueType.TtfHMetric, TrueType.TtfHMetric -> Bool
	eq_TtfHMetric = |ex, ey| ((ex.hm_advance == ey.hm_advance) and (ex.hm_lsb == ey.hm_lsb))

	eq_TtfCmap : TrueType.TtfCmap, TrueType.TtfCmap -> Bool
	eq_TtfCmap = |ex, ey| (((((((ex.cm_seg_count == ey.cm_seg_count) and (ex.cm_end_codes == ey.cm_end_codes)) and (ex.cm_start_codes == ey.cm_start_codes)) and (ex.cm_id_deltas == ey.cm_id_deltas)) and (ex.cm_id_range_offsets == ey.cm_id_range_offsets)) and (ex.cm_glyph_ids == ey.cm_glyph_ids)) and (ex.cm_range_off_base == ey.cm_range_off_base))

	eq_TtfPoint : TrueType.TtfPoint, TrueType.TtfPoint -> Bool
	eq_TtfPoint = |ex, ey| (((ex.tp_x == ey.tp_x) and (ex.tp_y == ey.tp_y)) and (ex.tp_on_curve == ey.tp_on_curve))

	eq_TtfContour : TrueType.TtfContour, TrueType.TtfContour -> Bool
	eq_TtfContour = |ex, ey| (ex.tc_points == ey.tc_points)

	eq_TtfGlyph : TrueType.TtfGlyph, TrueType.TtfGlyph -> Bool
	eq_TtfGlyph = |ex, ey| (((((((ex.tg_contours == ey.tg_contours) and (ex.tg_x_min == ey.tg_x_min)) and (ex.tg_y_min == ey.tg_y_min)) and (ex.tg_x_max == ey.tg_x_max)) and (ex.tg_y_max == ey.tg_y_max)) and (ex.tg_advance == ey.tg_advance)) and (ex.tg_lsb == ey.tg_lsb))

	eq_TtfFlagsResult : TrueType.TtfFlagsResult, TrueType.TtfFlagsResult -> Bool
	eq_TtfFlagsResult = |ex, ey| ((ex.tfr_flags == ey.tfr_flags) and (ex.tfr_offset == ey.tfr_offset))

	eq_TtfCoordsResult : TrueType.TtfCoordsResult, TrueType.TtfCoordsResult -> Bool
	eq_TtfCoordsResult = |ex, ey| ((ex.tcr_coords == ey.tcr_coords) and (ex.tcr_offset == ey.tcr_offset))

	eq_TtfResolved : TrueType.TtfResolved, TrueType.TtfResolved -> Bool
	eq_TtfResolved = |ex, ey| ((eq_TtfGlyph(ex.tr_glyph, ey.tr_glyph) and (ex.tr_left == ey.tr_left)) and (ex.tr_ok == ey.tr_ok))

	eq_TtfTransform : TrueType.TtfTransform, TrueType.TtfTransform -> Bool
	eq_TtfTransform = |ex, ey| (((((ex.tx_xx == ey.tx_xx) and (ex.tx_xy == ey.tx_xy)) and (ex.tx_yx == ey.tx_yx)) and (ex.tx_yy == ey.tx_yy)) and (ex.tx_next == ey.tx_next))

	eq_TtfPointRef : TrueType.TtfPointRef, TrueType.TtfPointRef -> Bool
	eq_TtfPointRef = |ex, ey| (eq_TtfPoint(ex.tpr_point, ey.tpr_point) and (ex.tpr_ok == ey.tpr_ok))

	eq_TtfFont : TrueType.TtfFont, TrueType.TtfFont -> Bool
	eq_TtfFont = |ex, ey| (((((((((ex.tf_buf == ey.tf_buf) and eq_TtfDir(ex.tf_dir, ey.tf_dir)) and eq_TtfHead(ex.tf_head, ey.tf_head)) and (ex.tf_num_glyphs == ey.tf_num_glyphs)) and (ex.tf_num_hmetrics == ey.tf_num_hmetrics)) and (ex.tf_hmetrics == ey.tf_hmetrics)) and eq_TtfCmap(ex.tf_cmap, ey.tf_cmap)) and (ex.tf_loca == ey.tf_loca)) and (ex.tf_glyf_off == ey.tf_glyf_off))
}
