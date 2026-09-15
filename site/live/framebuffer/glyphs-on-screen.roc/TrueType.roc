# TrueType -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

TrueType :: [].{
	TtfTableEntry : { tte_tag : I64, tte_offset : I64, tte_length : I64 }
	TtfDir : { td_num_tables : I64, td_tables : List(TrueType.TtfTableEntry) }
	TtfHead : { th_units_per_em : I64, th_index_to_loc : I64, th_x_min : I64, th_y_min : I64, th_x_max : I64, th_y_max : I64 }
	TtfHMetric : { hm_advance : I64, hm_lsb : I64 }
	TtfCmap : { cm_seg_count : I64, cm_end_codes : List(I64), cm_start_codes : List(I64), cm_id_deltas : List(I64), cm_id_range_offsets : List(I64), cm_glyph_ids : List(I64), cm_range_off_base : I64 }
	TtfPoint : { tp_x : I64, tp_y : I64, tp_on_curve : I64 }
	TtfContour : { tc_points : List(TrueType.TtfPoint) }
	TtfGlyph : { tg_contours : List(TrueType.TtfContour), tg_x_min : I64, tg_y_min : I64, tg_x_max : I64, tg_y_max : I64, tg_advance : I64, tg_lsb : I64 }
	TtfFlagsResult : { tfr_flags : List(I64), tfr_offset : I64 }
	TtfCoordsResult : { tcr_coords : List(I64), tcr_offset : I64 }
	TtfFont : { tf_buf : List(I64), tf_dir : TrueType.TtfDir, tf_head : TrueType.TtfHead, tf_num_glyphs : I64, tf_num_hmetrics : I64, tf_hmetrics : List(TrueType.TtfHMetric), tf_cmap : TrueType.TtfCmap, tf_loca : List(I64), tf_glyf_off : I64 }

	ttf_byte_at : List(I64), I64 -> I64
	ttf_byte_at = |buf, off| (if (off < 0) { 0 } else { (if (off >= U64.to_i64_wrap(List.len(buf))) { 0 } else { (List.get(buf, I64.to_u64_wrap(off)) ?? crash("list-at out of range")) }) })

	ttf_u8 : List(I64), I64 -> I64
	ttf_u8 = |buf, off| ttf_byte_at(buf, off)

	ttf_u16 : List(I64), I64 -> I64
	ttf_u16 = |buf, off| ({
		hi = ttf_byte_at(buf, off)
		lo = ttf_byte_at(buf, (off + 1))
		((hi * 256) + lo)
	})

	ttf_i16 : List(I64), I64 -> I64
	ttf_i16 = |buf, off| ({
		v = ttf_u16(buf, off)
		(if (v >= 32768) { (v - 65536) } else { v })
	})

	ttf_u32 : List(I64), I64 -> I64
	ttf_u32 = |buf, off| ({
		a = ttf_byte_at(buf, off)
		b = ttf_byte_at(buf, (off + 1))
		c = ttf_byte_at(buf, (off + 2))
		d = ttf_byte_at(buf, (off + 3))
		((((a * 16777216) + (b * 65536)) + (c * 256)) + d)
	})

	ttf_read_tag : List(I64), I64 -> I64
	ttf_read_tag = |buf, off| ({
		a = ttf_byte_at(buf, off)
		b = ttf_byte_at(buf, (off + 1))
		c = ttf_byte_at(buf, (off + 2))
		d = ttf_byte_at(buf, (off + 3))
		((((a * 16777216) + (b * 65536)) + (c * 256)) + d)
	})

	ttf_read_dir : List(I64) -> TrueType.TtfDir
	ttf_read_dir = |buf| ({
		num = ttf_u16(buf, 4)
		tables = ttf_read_dir_loop(buf, 12, num, 0, [])
		{ td_num_tables: num, td_tables: tables }
	})

	ttf_read_dir_loop : List(I64), I64, I64, I64, List(TrueType.TtfTableEntry) -> List(TrueType.TtfTableEntry)
	ttf_read_dir_loop = |buf, off, num, i, acc| (if (i >= num) { acc } else { ({
		entry = { tte_tag: ttf_read_tag(buf, off), tte_offset: ttf_u32(buf, (off + 8)), tte_length: ttf_u32(buf, (off + 12)) }
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
	ttf_read_head = |buf, off| { th_units_per_em: ttf_u16(buf, (off + 18)), th_index_to_loc: ttf_i16(buf, (off + 50)), th_x_min: ttf_i16(buf, (off + 36)), th_y_min: ttf_i16(buf, (off + 38)), th_x_max: ttf_i16(buf, (off + 40)), th_y_max: ttf_i16(buf, (off + 42)) }

	ttf_read_num_glyphs : List(I64), I64 -> I64
	ttf_read_num_glyphs = |buf, off| ttf_u16(buf, (off + 4))

	ttf_read_num_hmetrics : List(I64), I64 -> I64
	ttf_read_num_hmetrics = |buf, off| ttf_u16(buf, (off + 34))

	ttf_read_hmetrics : List(I64), I64, I64 -> List(TrueType.TtfHMetric)
	ttf_read_hmetrics = |buf, off, count| ttf_read_hmetrics_loop(buf, off, count, 0, [])

	ttf_read_hmetrics_loop : List(I64), I64, I64, I64, List(TrueType.TtfHMetric) -> List(TrueType.TtfHMetric)
	ttf_read_hmetrics_loop = |buf, off, count, i, acc| (if (i >= count) { acc } else { ({
		m = { hm_advance: ttf_u16(buf, (off + (i * 4))), hm_lsb: ttf_i16(buf, ((off + (i * 4)) + 2)) }
		ttf_read_hmetrics_loop(buf, off, count, (i + 1), List.append(acc, m))
	}) })

	ttf_read_loca_short : List(I64), I64, I64 -> List(I64)
	ttf_read_loca_short = |buf, off, num_glyphs| ttf_read_loca_short_loop(buf, off, (num_glyphs + 1), 0, [])

	ttf_read_loca_short_loop : List(I64), I64, I64, I64, List(I64) -> List(I64)
	ttf_read_loca_short_loop = |buf, off, count, i, acc| (if (i >= count) { acc } else { ({
		v = (ttf_u16(buf, (off + (i * 2))) * 2)
		ttf_read_loca_short_loop(buf, off, count, (i + 1), List.append(acc, v))
	}) })

	ttf_read_loca_long : List(I64), I64, I64 -> List(I64)
	ttf_read_loca_long = |buf, off, num_glyphs| ttf_read_loca_long_loop(buf, off, (num_glyphs + 1), 0, [])

	ttf_read_loca_long_loop : List(I64), I64, I64, I64, List(I64) -> List(I64)
	ttf_read_loca_long_loop = |buf, off, count, i, acc| (if (i >= count) { acc } else { ({
		v = ttf_u32(buf, (off + (i * 4)))
		ttf_read_loca_long_loop(buf, off, count, (i + 1), List.append(acc, v))
	}) })

	ttf_find_cmap4 : List(I64), I64 -> I64
	ttf_find_cmap4 = |buf, cmap_off| ({
		num_sub = ttf_u16(buf, (cmap_off + 2))
		ttf_find_cmap4_loop(buf, (cmap_off + 4), num_sub, 0, cmap_off)
	})

	ttf_find_cmap4_loop : List(I64), I64, I64, I64, I64 -> I64
	ttf_find_cmap4_loop = |buf, off, num, i, cmap_off| (if (i >= num) { (-1) } else { ({
		_plat = ttf_u16(buf, off)
		_enc = ttf_u16(buf, (off + 2))
		sub_off = ttf_u32(buf, (off + 4))
		fmt = ttf_u16(buf, (cmap_off + sub_off))
		(if (fmt == 4) { (cmap_off + sub_off) } else { ttf_find_cmap4_loop(buf, (off + 8), num, (i + 1), cmap_off) })
	}) })

	ttf_read_cmap4 : List(I64), I64 -> TrueType.TtfCmap
	ttf_read_cmap4 = |buf, off| ({
		seg_count = I64.div_trunc_by(ttf_u16(buf, (off + 6)), 2)
		end_off = (off + 14)
		start_off = ((end_off + (seg_count * 2)) + 2)
		delta_off = (start_off + (seg_count * 2))
		range_off = (delta_off + (seg_count * 2))
		glyph_off = (range_off + (seg_count * 2))
		table_len = ttf_u16(buf, (off + 2))
		glyph_count = I64.div_trunc_by((table_len - (glyph_off - off)), 2)
		{ cm_seg_count: seg_count, cm_end_codes: ttf_read_u16_array(buf, end_off, seg_count), cm_start_codes: ttf_read_u16_array(buf, start_off, seg_count), cm_id_deltas: ttf_read_i16_array(buf, delta_off, seg_count), cm_id_range_offsets: ttf_read_u16_array(buf, range_off, seg_count), cm_glyph_ids: ttf_read_u16_array(buf, glyph_off, ttf_cmap_max(glyph_count, 0)), cm_range_off_base: range_off }
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
		end_code = (List.get(cm.cm_end_codes, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (cp > end_code) { ttf_cmap_lookup_loop(cm, cp, (i + 1)) } else { ({
			start_code = (List.get(cm.cm_start_codes, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
			(if (cp < start_code) { 0 } else { ({
				range_off = (List.get(cm.cm_id_range_offsets, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
				(if (range_off == 0) { ({
					delta = (List.get(cm.cm_id_deltas, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
					ttf_mod65536((cp + delta))
				}) } else { ({
					idx = ((I64.div_trunc_by(range_off, 2) + (cp - start_code)) - (cm.cm_seg_count - i))
					(if (idx < 0) { 0 } else { (if (idx >= U64.to_i64_wrap(List.len(cm.cm_glyph_ids))) { 0 } else { ({
						gid = (List.get(cm.cm_glyph_ids, I64.to_u64_wrap(idx)) ?? crash("list-at out of range"))
						(if (gid == 0) { 0 } else { ({
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
		m = (v - (I64.div_trunc_by(v, 65536) * 65536))
		(if (m < 0) { (m + 65536) } else { m })
	})

	ttf_empty_glyph : TrueType.TtfGlyph
	ttf_empty_glyph = { tg_contours: [], tg_x_min: 0, tg_y_min: 0, tg_x_max: 0, tg_y_max: 0, tg_advance: 0, tg_lsb: 0 }

	ttf_read_glyph : List(I64), I64, I64, List(TrueType.TtfHMetric), I64 -> TrueType.TtfGlyph
	ttf_read_glyph = |buf, glyf_off, glyph_off, hmetrics, glyph_idx| ({
		off = (glyf_off + glyph_off)
		num_contours = ttf_i16(buf, off)
		hm = ttf_get_hmetric(hmetrics, glyph_idx)
		(if (num_contours < 0) { ttf_read_compound_glyph(buf, off, hm) } else { (if (num_contours == 0) { { ..{ ..ttf_empty_glyph, tg_advance: hm.hm_advance }, tg_lsb: hm.hm_lsb } } else { ttf_read_simple_glyph(buf, off, num_contours, hm) }) })
	})

	ttf_get_hmetric : List(TrueType.TtfHMetric), I64 -> TrueType.TtfHMetric
	ttf_get_hmetric = |hmetrics, idx| (if (U64.to_i64_wrap(List.len(hmetrics)) == 0) { { hm_advance: 0, hm_lsb: 0 } } else { (if (idx < 0) { (List.get(hmetrics, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) } else { (if (idx >= U64.to_i64_wrap(List.len(hmetrics))) { (List.get(hmetrics, I64.to_u64_wrap((U64.to_i64_wrap(List.len(hmetrics)) - 1))) ?? crash("list-at out of range")) } else { (List.get(hmetrics, I64.to_u64_wrap(idx)) ?? crash("list-at out of range")) }) }) })

	ttf_read_simple_glyph : List(I64), I64, I64, TrueType.TtfHMetric -> TrueType.TtfGlyph
	ttf_read_simple_glyph = |buf, off, num_contours, hm| ({
		x_min = ttf_i16(buf, (off + 2))
		y_min = ttf_i16(buf, (off + 4))
		x_max = ttf_i16(buf, (off + 6))
		y_max = ttf_i16(buf, (off + 8))
		end_pts = ttf_read_u16_array(buf, (off + 10), num_contours)
		total_pts = ((List.get(end_pts, I64.to_u64_wrap((num_contours - 1))) ?? crash("list-at out of range")) + 1)
		instr_len = ttf_u16(buf, ((off + 10) + (num_contours * 2)))
		flags_off = ((((off + 10) + (num_contours * 2)) + 2) + instr_len)
		flags_result = ttf_read_flags(buf, flags_off, total_pts)
		flags = ttf_fr_flags(flags_result)
		after_flags = ttf_fr_offset(flags_result)
		xs_result = ttf_read_coords(buf, after_flags, flags, total_pts, 1, 2)
		xs = ttf_cr_coords(xs_result)
		ys_result = ttf_read_coords(buf, ttf_cr_offset(xs_result), flags, total_pts, 4, 32)
		ys = ttf_cr_coords(ys_result)
		points = ttf_build_points(flags, xs, ys, total_pts, 0, [])
		contours = ttf_split_contours(points, end_pts, num_contours, 0, 0, [])
		{ tg_contours: contours, tg_x_min: x_min, tg_y_min: y_min, tg_x_max: x_max, tg_y_max: y_max, tg_advance: hm.hm_advance, tg_lsb: hm.hm_lsb }
	})

	ttf_fr_flags : TrueType.TtfFlagsResult -> List(I64)
	ttf_fr_flags = |r| r.tfr_flags

	ttf_fr_offset : TrueType.TtfFlagsResult -> I64
	ttf_fr_offset = |r| r.tfr_offset

	ttf_read_flags : List(I64), I64, I64 -> TrueType.TtfFlagsResult
	ttf_read_flags = |buf, off, total| ttf_read_flags_loop(buf, off, total, [])

	ttf_read_flags_loop : List(I64), I64, I64, List(I64) -> TrueType.TtfFlagsResult
	ttf_read_flags_loop = |buf, off, remaining, acc| (if (remaining <= 0) { { tfr_flags: acc, tfr_offset: off } } else { ({
		flag = ttf_u8(buf, off)
		is_repeat = ttf_bit_test(flag, 3)
		(if (is_repeat == 0) { ttf_read_flags_loop(buf, (off + 1), (remaining - 1), List.append(acc, flag)) } else { ({
			count = ttf_u8(buf, (off + 1))
			expanded = ttf_repeat_flag(flag, count, acc)
			ttf_read_flags_loop(buf, (off + 2), ((remaining - 1) - count), expanded)
		}) })
	}) })

	ttf_repeat_flag : I64, I64, List(I64) -> List(I64)
	ttf_repeat_flag = |flag, count, acc| (if (count <= 0) { List.append(acc, flag) } else { ttf_repeat_flag(flag, (count - 1), List.append(acc, flag)) })

	ttf_bit_test : I64, I64 -> I64
	ttf_bit_test = |val, bit| ({
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
	ttf_read_coords_loop = |buf, off, flags, total, short_bit, same_bit, i, prev, acc| (if (i >= total) { { tcr_coords: acc, tcr_offset: off } } else { ({
		flag = (List.get(flags, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		is_short = ttf_bit_test(flag, short_bit)
		is_same = ttf_bit_test(flag, same_bit)
		(if (is_short > 0) { ({
			raw = ttf_u8(buf, off)
			delta = (if (is_same > 0) { raw } else { (-raw) })
			val = (prev + delta)
			ttf_read_coords_loop(buf, (off + 1), flags, total, short_bit, same_bit, (i + 1), val, List.append(acc, val))
		}) } else { (if (is_same > 0) { ttf_read_coords_loop(buf, off, flags, total, short_bit, same_bit, (i + 1), prev, List.append(acc, prev)) } else { ({
			delta = ttf_i16(buf, off)
			val = (prev + delta)
			ttf_read_coords_loop(buf, (off + 2), flags, total, short_bit, same_bit, (i + 1), val, List.append(acc, val))
		}) }) })
	}) })

	ttf_build_points : List(I64), List(I64), List(I64), I64, I64, List(TrueType.TtfPoint) -> List(TrueType.TtfPoint)
	ttf_build_points = |flags, xs, ys, total, i, acc| (if (i >= total) { acc } else { ({
		flag = (List.get(flags, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		on_curve = ttf_bit_test(flag, 0)
		pt = { tp_x: (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), tp_y: (List.get(ys, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), tp_on_curve: on_curve }
		ttf_build_points(flags, xs, ys, total, (i + 1), List.append(acc, pt))
	}) })

	ttf_split_contours : List(TrueType.TtfPoint), List(I64), I64, I64, I64, List(TrueType.TtfContour) -> List(TrueType.TtfContour)
	ttf_split_contours = |points, end_pts, num, ci, start, acc| (if (ci >= num) { acc } else { ({
		end_pt = (List.get(end_pts, I64.to_u64_wrap(ci)) ?? crash("list-at out of range"))
		contour_pts = ttf_slice_points(points, start, (end_pt + 1), [])
		contour = { tc_points: contour_pts }
		ttf_split_contours(points, end_pts, num, (ci + 1), (end_pt + 1), List.append(acc, contour))
	}) })

	ttf_slice_points : List(TrueType.TtfPoint), I64, I64, List(TrueType.TtfPoint) -> List(TrueType.TtfPoint)
	ttf_slice_points = |points, from, to, acc| (if (from >= to) { acc } else { ttf_slice_points(points, (from + 1), to, List.append(acc, (List.get(points, I64.to_u64_wrap(from)) ?? crash("list-at out of range")))) })

	ttf_read_compound_glyph : List(I64), I64, TrueType.TtfHMetric -> TrueType.TtfGlyph
	ttf_read_compound_glyph = |buf, off, hm| { tg_contours: [], tg_x_min: ttf_i16(buf, (off + 2)), tg_y_min: ttf_i16(buf, (off + 4)), tg_x_max: ttf_i16(buf, (off + 6)), tg_y_max: ttf_i16(buf, (off + 8)), tg_advance: hm.hm_advance, tg_lsb: hm.hm_lsb }

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
		head_off = ttf_find_table(dir, ttf_tag_head)
		maxp_off = ttf_find_table(dir, ttf_tag_maxp)
		hhea_off = ttf_find_table(dir, ttf_tag_hhea)
		hmtx_off = ttf_find_table(dir, ttf_tag_hmtx)
		cmap_off = ttf_find_table(dir, ttf_tag_cmap)
		loca_off = ttf_find_table(dir, ttf_tag_loca)
		glyf_off = ttf_find_table(dir, ttf_tag_glyf)
		head = ttf_read_head(buf, head_off)
		num_glyphs = ttf_read_num_glyphs(buf, maxp_off)
		num_hmetrics = ttf_read_num_hmetrics(buf, hhea_off)
		hmetrics = ttf_read_hmetrics(buf, hmtx_off, num_hmetrics)
		cmap4_off = ttf_find_cmap4(buf, cmap_off)
		cmap = ttf_read_cmap4(buf, cmap4_off)
		loca = (if (head.th_index_to_loc == 0) { ttf_read_loca_short(buf, loca_off, num_glyphs) } else { ttf_read_loca_long(buf, loca_off, num_glyphs) })
		{ tf_buf: buf, tf_dir: dir, tf_head: head, tf_num_glyphs: num_glyphs, tf_num_hmetrics: num_hmetrics, tf_hmetrics: hmetrics, tf_cmap: cmap, tf_loca: loca, tf_glyf_off: glyf_off }
	})

	ttf_glyph_for_char : TrueType.TtfFont, I64 -> TrueType.TtfGlyph
	ttf_glyph_for_char = |font, codepoint| ({
		glyph_idx = ttf_cmap_lookup(font.tf_cmap, codepoint)
		glyph_off = (List.get(font.tf_loca, I64.to_u64_wrap(glyph_idx)) ?? crash("list-at out of range"))
		next_off = (List.get(font.tf_loca, I64.to_u64_wrap((glyph_idx + 1))) ?? crash("list-at out of range"))
		(if (glyph_off == next_off) { { ..{ ..ttf_empty_glyph, tg_advance: ttf_get_hmetric(font.tf_hmetrics, glyph_idx).hm_advance }, tg_lsb: ttf_get_hmetric(font.tf_hmetrics, glyph_idx).hm_lsb } } else { ttf_read_glyph(font.tf_buf, font.tf_glyf_off, glyph_off, font.tf_hmetrics, glyph_idx) })
	})

	format_ttf_font : TrueType.TtfFont -> Str
	format_ttf_font = |font| Str.concat(Str.concat(Str.concat(Str.concat("TrueType: ", I64.to_str(font.tf_num_glyphs)), " glyphs, "), I64.to_str(font.tf_head.th_units_per_em)), " UPM")

	format_ttf_glyph : TrueType.TtfGlyph -> Str
	format_ttf_glyph = |g| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("Glyph: ", I64.to_str(U64.to_i64_wrap(List.len(g.tg_contours)))), " contours, advance="), I64.to_str(g.tg_advance)), " ["), I64.to_str(g.tg_x_min)), ","), I64.to_str(g.tg_y_min)), "]-["), I64.to_str(g.tg_x_max)), ","), I64.to_str(g.tg_y_max)), "]")
}
