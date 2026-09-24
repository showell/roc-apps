# EditDistance -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText

EditDistance :: [].{
	EditMatch : { em_text : CceText, em_distance : I64, em_index : I64 }

	edit_distance : CceText, CceText -> I64
	edit_distance = |a, b| ({
		m = CceText.len(a)
		n = CceText.len(b)
		(if (m == 0) { n } else { (if (n == 0) { m } else { (if (m > n) { edit_distance(b, a) } else { ({
			row = ed_init_row(0, (n + 1), [])
			ed_outer(a, b, row, 1, m, n)
		}) }) }) })
	})

	ed_init_row : I64, I64, List(I64) -> List(I64)
	ed_init_row = |i, len, acc| (if (i >= len) { acc } else { ed_init_row((i + 1), len, List.append(acc, i)) })

	ed_outer : CceText, CceText, List(I64), I64, I64, I64 -> I64
	ed_outer = |a, b, row, i, m, n| (if (i > m) { (List.get(row, I64.to_u64_wrap(n)) ?? crash("list-at out of range")) } else { ({
		new_row = ed_inner(a, b, row, i, 1, n, [i])
		ed_outer(a, b, new_row, (i + 1), m, n)
	}) })

	ed_inner : CceText, CceText, List(I64), I64, I64, I64, List(I64) -> List(I64)
	ed_inner = |a, b, prev, i, j, n, curr| (if (j > n) { curr } else { ({
		cost = (if (CceText.char_at(a, (i - 1)) == CceText.char_at(b, (j - 1))) { 0 } else { 1 })
		del = ((List.get(prev, I64.to_u64_wrap(j)) ?? crash("list-at out of range")) + 1)
		ins = ((List.get(curr, I64.to_u64_wrap((j - 1))) ?? crash("list-at out of range")) + 1)
		sub = ((List.get(prev, I64.to_u64_wrap((j - 1))) ?? crash("list-at out of range")) + cost)
		best = ed_min3(del, ins, sub)
		ed_inner(a, b, prev, i, (j + 1), n, List.append(curr, best))
	}) })

	edit_similarity : CceText, CceText -> I64
	edit_similarity = |a, b| ({
		m = CceText.len(a)
		n = CceText.len(b)
		max_len = (if (m > n) { m } else { n })
		(if (max_len == 0) { 1000 } else { ({
			dist = edit_distance(a, b)
			I64.div_trunc_by(((max_len - dist) * 1000), max_len)
		}) })
	})

	edit_best_match : CceText, List(CceText) -> EditDistance.EditMatch
	edit_best_match = |query, candidates| ed_best_loop(query, candidates, 0, U64.to_i64_wrap(List.len(candidates)), { em_text: "", em_distance: 999999, em_index: (0 - 1) })

	ed_best_loop : CceText, List(CceText), I64, I64, EditDistance.EditMatch -> EditDistance.EditMatch
	ed_best_loop = |query, candidates, i, n, best| (if (i >= n) { best } else { ({
		c = (List.get(candidates, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		d = edit_distance(query, c)
		new_best = (if (d < best.em_distance) { { em_text: c, em_distance: d, em_index: i } } else { best })
		ed_best_loop(query, candidates, (i + 1), n, new_best)
	}) })

	edit_within : CceText, List(CceText), I64 -> List(CceText)
	edit_within = |query, candidates, max_dist| ed_within_loop(query, candidates, max_dist, 0, U64.to_i64_wrap(List.len(candidates)), [])

	ed_within_loop : CceText, List(CceText), I64, I64, I64, List(CceText) -> List(CceText)
	ed_within_loop = |query, candidates, max_dist, i, n, acc| (if (i >= n) { acc } else { ({
		c = (List.get(candidates, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		d = edit_distance(query, c)
		new_acc = (if (d <= max_dist) { List.append(acc, c) } else { acc })
		ed_within_loop(query, candidates, max_dist, (i + 1), n, new_acc)
	}) })

	ed_min3 : I64, I64, I64 -> I64
	ed_min3 = |a, b, c| ({
		ab = (if (a < b) { a } else { b })
		(if (ab < c) { ab } else { c })
	})

	format_edit_match : EditDistance.EditMatch -> CceText
	format_edit_match = |m| CceText.concat(CceText.concat(CceText.concat(m.em_text, " (d="), CceText.show_int(m.em_distance)), ")")
}
