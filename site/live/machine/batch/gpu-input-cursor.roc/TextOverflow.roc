# TextOverflow -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

TextOverflow :: [].{
	TextOverflow : [OverflowClip, OverflowEllipsis, OverflowScroll]

	text_overflow_default : TextOverflow.TextOverflow
	text_overflow_default = OverflowClip

	text_fit_count : I64, I64, I64 -> I64
	text_fit_count = |avail, advance, glyph| (if (advance <= 0) { 0 } else { (if (avail < glyph) { 0 } else { (I64.div_trunc_by((avail - glyph), advance) + 1) }) })

	text_ellipsis_glyphs : I64
	text_ellipsis_glyphs = 3

	text_overflow_start : TextOverflow.TextOverflow, I64, I64, I64, I64 -> I64
	text_overflow_start = |mode, len, avail, advance, glyph| ({
		fits = text_fit_count(avail, advance, glyph)
		(if (len <= fits) { 0 } else { (match mode {
			OverflowClip => 0
			OverflowEllipsis => 0
			OverflowScroll => (len - fits)
		}) })
	})

	text_overflow_count : TextOverflow.TextOverflow, I64, I64, I64, I64 -> I64
	text_overflow_count = |mode, len, avail, advance, glyph| ({
		fits = text_fit_count(avail, advance, glyph)
		(if (len <= fits) { len } else { (match mode {
			OverflowClip => fits
			OverflowEllipsis => (if (fits < (text_ellipsis_glyphs + 1)) { fits } else { (fits - text_ellipsis_glyphs) })
			OverflowScroll => fits
		}) })
	})

	text_overflow_dots : TextOverflow.TextOverflow, I64, I64, I64, I64 -> I64
	text_overflow_dots = |mode, len, avail, advance, glyph| ({
		fits = text_fit_count(avail, advance, glyph)
		(if (len <= fits) { 0 } else { (match mode {
			OverflowClip => 0
			OverflowEllipsis => (if (fits < (text_ellipsis_glyphs + 1)) { 0 } else { text_ellipsis_glyphs })
			OverflowScroll => 0
		}) })
	})

	text_overflow_name : TextOverflow.TextOverflow -> Str
	text_overflow_name = |mode| (match mode {
		OverflowClip => "clip"
		OverflowEllipsis => "ellipsis"
		OverflowScroll => "scroll"
	})

	eq_TextOverflow : TextOverflow.TextOverflow, TextOverflow.TextOverflow -> Bool
	eq_TextOverflow = |ex, ey| (match ex {
		OverflowClip => (match ey {
			OverflowClip => True
			_ => False
		})
		OverflowEllipsis => (match ey {
			OverflowEllipsis => True
			_ => False
		})
		OverflowScroll => (match ey {
			OverflowScroll => True
			_ => False
		})
	})
}
