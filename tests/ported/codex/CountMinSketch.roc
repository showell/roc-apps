# CountMinSketch -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Cce
import ListUtils
import Random

CountMinSketch :: [].{
	CmSketch : { cms_table : List(I64), cms_width : I64, cms_depth : I64, cms_total : I64 }

	cms_new : I64, I64 -> CountMinSketch.CmSketch
	cms_new = |width, depth| { cms_table: ListUtils.list_zeros((width * depth)), cms_width: width, cms_depth: depth, cms_total: 0 }

	cms_add : CountMinSketch.CmSketch, Str, I64 -> CountMinSketch.CmSketch
	cms_add = |sketch, key, count| ({
		h = cms_hash_key(key)
		updated = cms_add_rows(sketch.cms_table, h, sketch.cms_width, sketch.cms_depth, count, 0)
		{ cms_table: updated, cms_width: sketch.cms_width, cms_depth: sketch.cms_depth, cms_total: (sketch.cms_total + count) }
	})

	cms_add_rows : List(I64), I64, I64, I64, I64, I64 -> List(I64)
	cms_add_rows = |table, hash, width, depth, count, row| (if (row >= depth) { table } else { ({
		col = cms_row_hash(hash, row, width)
		idx = ((row * width) + col)
		old = (List.get(table, I64.to_u64_wrap(idx)) ?? crash("list-at out of range"))
		cms_add_rows((List.set(table, I64.to_u64_wrap(idx), (old + count)) ?? crash("list-set-at past the end")), hash, width, depth, count, (row + 1))
	}) })

	cms_count : CountMinSketch.CmSketch, Str -> I64
	cms_count = |sketch, key| ({
		h = cms_hash_key(key)
		cms_min_rows(sketch.cms_table, h, sketch.cms_width, sketch.cms_depth, 0, 999999999)
	})

	cms_min_rows : List(I64), I64, I64, I64, I64, I64 -> I64
	cms_min_rows = |table, hash, width, depth, row, best| (if (row >= depth) { best } else { ({
		col = cms_row_hash(hash, row, width)
		idx = ((row * width) + col)
		val = (List.get(table, I64.to_u64_wrap(idx)) ?? crash("list-at out of range"))
		new_best = (if (val < best) { val } else { best })
		cms_min_rows(table, hash, width, depth, (row + 1), new_best)
	}) })

	cms_hash_key : Str -> I64
	cms_hash_key = |key| cms_text_hash(key, 0, Cce.length(key), 5381)

	cms_text_hash : Str, I64, I64, I64 -> I64
	cms_text_hash = |key, i, len, hash| (if (i >= len) { ({
		positive = (if (hash < 0) { (-hash) } else { hash })
		positive
	}) } else { ({
		c = Cce.at_or_crash(key, i)
		cms_text_hash(key, (i + 1), len, I64.plus_wrap(I64.times_wrap(hash, 33), c))
	}) })

	cms_row_hash : I64, I64, I64 -> I64
	cms_row_hash = |hash, row, width| Random.rand_in_range(hash, row, 0, (width - 1))

	cms_total : CountMinSketch.CmSketch -> I64
	cms_total = |sketch| sketch.cms_total

	format_cms : CountMinSketch.CmSketch -> Str
	format_cms = |s| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("cms ", I64.to_str(s.cms_width)), "x"), I64.to_str(s.cms_depth)), " total="), I64.to_str(s.cms_total))
}
