# CCE -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceChar
import CceText
import Prelude

CCE :: [].{
	CharClass : [Whitespace, Digit, Lower, Upper, Punct, Accented, Cyrillic, Other]

	to_upper : CceChar -> CceChar
	to_upper = |c| (if (CceChar.code(c) >= 13) { (if (CceChar.code(c) <= 38) { CceChar.of_code((CceChar.code(c) + 26)) } else { c }) } else { c })

	cce_to_unicode_table : List(I64)
	cce_to_unicode_table = [0, 10, 32, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 101, 116, 97, 111, 105, 110, 115, 104, 114, 100, 108, 99, 117, 109, 119, 102, 103, 121, 112, 98, 118, 107, 106, 120, 113, 122, 69, 84, 65, 79, 73, 78, 83, 72, 82, 68, 76, 67, 85, 77, 87, 70, 71, 89, 80, 66, 86, 75, 74, 88, 81, 90, 46, 44, 33, 63, 58, 59, 39, 34, 45, 40, 41, 43, 61, 42, 60, 62, 47, 64, 35, 38, 95, 92, 124, 91, 93, 123, 125, 126, 96, 94, 36, 37, 233, 232, 234, 235, 225, 224, 226, 228, 243, 244, 246, 250, 252, 241, 231, 237, 1072, 1086, 1077, 1080, 1085, 1090, 1089, 1088, 1074, 1083, 1082, 1084, 1076, 1087, 1091]

	cce_tier1_block_count : I64
	cce_tier1_block_count = 11

	cce_tier1_block_bases : List(I64)
	cce_tier1_block_bases = [128, 256, 1024, 128, 880, 128, 1536, 128, 1424, 128, 2304, 128, 3584, 128, 4352, 128, 19968, 512, 12352, 256, 8704, 128]

	cce_tier1_block_unicode_base : I64 -> I64
	cce_tier1_block_unicode_base = |block| (List.get(cce_tier1_block_bases, I64.to_u64_wrap((block * 2))) ?? crash("list-at out of range"))

	cce_tier1_block_size : I64 -> I64
	cce_tier1_block_size = |block| (List.get(cce_tier1_block_bases, I64.to_u64_wrap(((block * 2) + 1))) ?? crash("list-at out of range"))

	cce_tier1_block : I64 -> I64
	cce_tier1_block = |cp| ({
		v : I64
		v = (cp - 128)
		(if (v < 256) { 0 } else { (if (v < 384) { 1 } else { (if (v < 512) { 2 } else { (if (v < 640) { 3 } else { (if (v < 768) { 4 } else { (if (v < 896) { 5 } else { (if (v < 1024) { 6 } else { (if (v < 1152) { 7 } else { (if (v < 1664) { 8 } else { (if (v < 1920) { 9 } else { (if (v < 2048) { 10 } else { (-1) }) }) }) }) }) }) }) }) }) }) })
	})

	cce_tier1_offset_in_block : I64 -> I64
	cce_tier1_offset_in_block = |cp| ({
		v : I64
		v = (cp - 128)
		(if (v < 256) { v } else { (if (v < 1152) { Prelude.int_mod((v - 256), 128) } else { (if (v < 1664) { (v - 1152) } else { (if (v < 1920) { (v - 1664) } else { (v - 1920) }) }) }) })
	})

	cce_tier2_base : I64
	cce_tier2_base = 2176

	cce_tier2_block_count : I64
	cce_tier2_block_count = 10

	cce_tier2_block_table : List(I64)
	cce_tier2_block_table = [12288, 64, 12352, 96, 12448, 96, 19968, 20992, 13312, 6592, 44032, 11172, 3584, 256, 8192, 512, 127744, 1024, 9728, 256]

	cce_tier2_block_unicode_base : I64 -> I64
	cce_tier2_block_unicode_base = |block| (List.get(cce_tier2_block_table, I64.to_u64_wrap((block * 2))) ?? crash("list-at out of range"))

	cce_tier2_block_size : I64 -> I64
	cce_tier2_block_size = |block| (List.get(cce_tier2_block_table, I64.to_u64_wrap(((block * 2) + 1))) ?? crash("list-at out of range"))

	cce_tier2_cce_base : I64 -> I64
	cce_tier2_cce_base = |block| cce_tier2_cce_base_loop(block, 0, cce_tier2_base)

	cce_tier2_cce_base_loop : I64, I64, I64 -> I64
	cce_tier2_cce_base_loop = |target, i, acc| (if (i >= target) { acc } else { cce_tier2_cce_base_loop(target, (i + 1), (acc + cce_tier2_block_size(i))) })

	to_unicode : I64 -> I64
	to_unicode = |cp| to_unicode_with(cce_to_unicode_table, cp)

	to_unicode_with : List(I64), I64 -> I64
	to_unicode_with = |tbl, cp| (if (cp < 0) { 65533 } else { (if (cp < 128) { (List.get(tbl, I64.to_u64_wrap(cp)) ?? crash("list-at out of range")) } else { (if (cp < 2176) { ({
		block : I64
		block = cce_tier1_block(cp)
		(if (block < 0) { 65533 } else { (cce_tier1_block_unicode_base(block) + cce_tier1_offset_in_block(cp)) })
	}) } else { (if (cp < 67712) { to_unicode_tier2(cp, 0) } else { 65533 }) }) }) })

	to_unicode_tier2 : I64, I64 -> I64
	to_unicode_tier2 = |cp, block| (if (block >= cce_tier2_block_count) { 65533 } else { ({
		block_base : I64
		block_base = cce_tier2_cce_base(block)
		block_size : I64
		block_size = cce_tier2_block_size(block)
		(if (cp >= block_base) { (if (cp < (block_base + block_size)) { (cce_tier2_block_unicode_base(block) + (cp - block_base)) } else { to_unicode_tier2(cp, (block + 1)) }) } else { to_unicode_tier2(cp, (block + 1)) })
	}) })

	from_unicode : I64 -> I64
	from_unicode = |u| from_unicode_with(cce_to_unicode_table, u)

	cce_foreign_byte_text : I64 -> CceText
	cce_foreign_byte_text = |b| ({
		cp : I64
		cp = from_unicode(b)
		(if (cp >= 0) { CceText.char_encode(CceChar.of_code(cp)) } else { (if (b == 9) { " " } else { "" }) })
	})

	from_unicode_with : List(I64), I64 -> I64
	from_unicode_with = |tbl, u| ({
		t0 : I64
		t0 = from_unicode_tier0(tbl, u, 0, 128)
		(if (t0 >= 0) { t0 } else { ({
			t1 : I64
			t1 = from_unicode_tier1(u, 0)
			(if (t1 >= 0) { t1 } else { from_unicode_tier2(u, 0) })
		}) })
	})

	from_unicode_tier0 : List(I64), I64, I64, I64 -> I64
	from_unicode_tier0 = |tbl, u, i, len| (if (i >= len) { (-1) } else { (if ((List.get(tbl, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) == u) { i } else { from_unicode_tier0(tbl, u, (i + 1), len) }) })

	from_unicode_tier1 : I64, I64 -> I64
	from_unicode_tier1 = |u, block| (if (block >= cce_tier1_block_count) { (-1) } else { ({
		base : I64
		base = cce_tier1_block_unicode_base(block)
		size : I64
		size = cce_tier1_block_size(block)
		(if (u >= base) { (if (u < (base + size)) { ({
			block_start : I64
			block_start = (if (block == 0) { 128 } else { (if (block < 8) { (256 + (block * 128)) } else { (if (block == 8) { 1280 } else { (if (block == 9) { 1792 } else { (if (block == 10) { 2048 } else { (-1) }) }) }) }) })
			(if (block_start < 0) { (-1) } else { (block_start + (u - base)) })
		}) } else { from_unicode_tier1(u, (block + 1)) }) } else { from_unicode_tier1(u, (block + 1)) })
	}) })

	from_unicode_tier2 : I64, I64 -> I64
	from_unicode_tier2 = |u, block| (if (block >= cce_tier2_block_count) { (-1) } else { ({
		base : I64
		base = cce_tier2_block_unicode_base(block)
		size : I64
		size = cce_tier2_block_size(block)
		(if (u >= base) { (if (u < (base + size)) { (cce_tier2_cce_base(block) + (u - base)) } else { from_unicode_tier2(u, (block + 1)) }) } else { from_unicode_tier2(u, (block + 1)) })
	}) })

	eq_CharClass : CCE.CharClass, CCE.CharClass -> Bool
	eq_CharClass = |ex, ey| (match ex {
		Whitespace => (match ey {
			Whitespace => True
			_ => False
		})
		Digit => (match ey {
			Digit => True
			_ => False
		})
		Lower => (match ey {
			Lower => True
			_ => False
		})
		Upper => (match ey {
			Upper => True
			_ => False
		})
		Punct => (match ey {
			Punct => True
			_ => False
		})
		Accented => (match ey {
			Accented => True
			_ => False
		})
		Cyrillic => (match ey {
			Cyrillic => True
			_ => False
		})
		Other => (match ey {
			Other => True
			_ => False
		})
	})
}
