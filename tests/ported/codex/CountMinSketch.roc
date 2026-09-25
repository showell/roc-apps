# CountMinSketch -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceChar
import CceText
import ListUtils
import Random

CountMinSketch :: [].{
	CmSketch := { cms_table : List(I64), cms_width : I64, cms_depth : I64, cms_total : I64 }.{
		is_eq : CountMinSketch.CmSketch, CountMinSketch.CmSketch -> Bool
		is_eq = |a, b| a.cms_table == b.cms_table and a.cms_width == b.cms_width and a.cms_depth == b.cms_depth and a.cms_total == b.cms_total
	}

	cms_new : I64, I64 -> CountMinSketch.CmSketch
	cms_new = |width, depth| CountMinSketch.CmSketch.{ cms_table: ListUtils.list_zeros((width * depth)), cms_width: width, cms_depth: depth, cms_total: 0 }

	cms_add : CountMinSketch.CmSketch, CceText, I64 -> CountMinSketch.CmSketch
	cms_add = |sketch, key, count| ({
		h : I64
		h = cms_hash_key(key)
		cms_add_rows_v1 : List(I64)
		cms_add_rows_v1 = cms_add_rows(sketch.cms_table, h, sketch.cms_width, sketch.cms_depth, count, 0)
		updated : List(I64)
		updated = cms_add_rows_v1
		CountMinSketch.CmSketch.{ cms_table: updated, cms_width: sketch.cms_width, cms_depth: sketch.cms_depth, cms_total: (sketch.cms_total + count) }
	})

	cms_add_rows : List(I64), I64, I64, I64, I64, I64 -> List(I64)
	cms_add_rows = |table, hash, width, depth, count, row| (if (row >= depth) { table } else { ({
		col : I64
		col = cms_row_hash(hash, row, width)
		idx : I64
		idx = ((row * width) + col)
		old : I64
		old = (List.get(table, I64.to_u64_wrap(idx)) ?? crash("list-at out of range"))
		table_v1 : List(I64)
		table_v1 = (List.set(table, I64.to_u64_wrap(idx), (old + count)) ?? crash("list-set-at past the end"))
		cms_add_rows(table_v1, hash, width, depth, count, (row + 1))
	}) })

	cms_count : CountMinSketch.CmSketch, CceText -> I64
	cms_count = |sketch, key| ({
		h : I64
		h = cms_hash_key(key)
		cms_min_rows(sketch.cms_table, h, sketch.cms_width, sketch.cms_depth, 0, 999999999)
	})

	cms_min_rows : List(I64), I64, I64, I64, I64, I64 -> I64
	cms_min_rows = |table, hash, width, depth, row, best| (if (row >= depth) { best } else { ({
		col : I64
		col = cms_row_hash(hash, row, width)
		idx : I64
		idx = ((row * width) + col)
		val : I64
		val = (List.get(table, I64.to_u64_wrap(idx)) ?? crash("list-at out of range"))
		new_best : I64
		new_best = (if (val < best) { val } else { best })
		cms_min_rows(table, hash, width, depth, (row + 1), new_best)
	}) })

	cms_hash_key : CceText -> I64
	cms_hash_key = |key| cms_text_hash(key, 0, CceText.len(key), 5381)

	cms_text_hash : CceText, I64, I64, I64 -> I64
	cms_text_hash = |key, i, len, hash| (if (i >= len) { (if (hash < 0) { I64.minus_wrap(0, hash) } else { hash }) } else { ({
		c : I64
		c = CceChar.code(CceText.char_at(key, i))
		cms_text_hash(key, (i + 1), len, I64.plus_wrap(I64.times_wrap(hash, 33), c))
	}) })

	cms_row_hash : I64, I64, I64 -> I64
	cms_row_hash = |hash, row, width| Random.rand_in_range(hash, row, 0, (width - 1))

	cms_total : CountMinSketch.CmSketch -> I64
	cms_total = |sketch| sketch.cms_total

	format_cms : CountMinSketch.CmSketch -> CceText
	format_cms = |s| CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("cms ", CceText.show_int(s.cms_width)), "x"), CceText.show_int(s.cms_depth)), " total="), CceText.show_int(s.cms_total))
}
