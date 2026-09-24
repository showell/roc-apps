# Sha256 -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceChar
import CceText
import Mem

Sha256 :: [].{
	Sha256State : { a : I64, b : I64, c : I64, d : I64, e : I64, f : I64, g : I64, h : I64 }

	mask32 : I64
	mask32 = 4294967295

	w32 : I64 -> I64
	w32 = |x| I64.bitwise_and(x, mask32)

	sha256_k : List(I64)
	sha256_k = [1116352408, 1899447441, 3049323471, 3921009573, 961987163, 1508970993, 2453635748, 2870763221, 3624381080, 310598401, 607225278, 1426881987, 1925078388, 2162078206, 2614888103, 3248222580, 3835390401, 4022224774, 264347078, 604807628, 770255983, 1249150122, 1555081692, 1996064986, 2554220882, 2821834349, 2952996808, 3210313671, 3336571891, 3584528711, 113926993, 338241895, 666307205, 773529912, 1294757372, 1396182291, 1695183700, 1986661051, 2177026350, 2456956037, 2730485921, 2820302411, 3259730800, 3345764771, 3516065817, 3600352804, 4094571909, 275423344, 430227734, 506948616, 659060556, 883997877, 958139571, 1322822218, 1537002063, 1747873779, 1955562222, 2024104815, 2227730452, 2361852424, 2428436474, 2756734187, 3204031479, 3329325298]

	sha256_h0 : List(I64)
	sha256_h0 = [1779033703, 3144134277, 1013904242, 2773480762, 1359893119, 2600822924, 528734635, 1541459225]

	rotr32 : I64, I64 -> I64
	rotr32 = |x, n| w32(I64.bitwise_or(I64.shr_zf_wrap(I64.bitwise_and(x, mask32), I64.to_u8_wrap(n)), I64.shl_wrap(x, I64.to_u8_wrap((32 - n)))))

	sigma0 : I64 -> I64
	sigma0 = |x| I64.bitwise_xor(rotr32(x, 7), I64.bitwise_xor(rotr32(x, 18), I64.shr_zf_wrap(I64.bitwise_and(x, mask32), I64.to_u8_wrap(3))))

	sigma1 : I64 -> I64
	sigma1 = |x| I64.bitwise_xor(rotr32(x, 17), I64.bitwise_xor(rotr32(x, 19), I64.shr_zf_wrap(I64.bitwise_and(x, mask32), I64.to_u8_wrap(10))))

	big_sigma0 : I64 -> I64
	big_sigma0 = |x| I64.bitwise_xor(rotr32(x, 2), I64.bitwise_xor(rotr32(x, 13), rotr32(x, 22)))

	big_sigma1 : I64 -> I64
	big_sigma1 = |x| I64.bitwise_xor(rotr32(x, 6), I64.bitwise_xor(rotr32(x, 11), rotr32(x, 25)))

	ch : I64, I64, I64 -> I64
	ch = |x, y, z| I64.bitwise_xor(I64.bitwise_and(x, y), I64.bitwise_and(I64.bitwise_xor(x, mask32), z))

	maj : I64, I64, I64 -> I64
	maj = |x, y, z| I64.bitwise_xor(I64.bitwise_and(x, y), I64.bitwise_xor(I64.bitwise_and(x, z), I64.bitwise_and(y, z)))

	sha256_schedule : List(I64) -> List(I64)
	sha256_schedule = |block| sha256_schedule_loop(block, 16)

	sha256_schedule_loop : List(I64), I64 -> List(I64)
	sha256_schedule_loop = |w, t| (if (t == 64) { w } else { ({
		s0 = sigma0((List.get(w, I64.to_u64_wrap((t - 15))) ?? crash("list-at out of range")))
		s1 = sigma1((List.get(w, I64.to_u64_wrap((t - 2))) ?? crash("list-at out of range")))
		val = w32(((((List.get(w, I64.to_u64_wrap((t - 16))) ?? crash("list-at out of range")) + s0) + (List.get(w, I64.to_u64_wrap((t - 7))) ?? crash("list-at out of range"))) + s1))
		sha256_schedule_loop(List.append(w, val), (t + 1))
	}) })

	state_from_hash : List(I64) -> Sha256.Sha256State
	state_from_hash = |hs| { a: (List.get(hs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")), b: (List.get(hs, I64.to_u64_wrap(1)) ?? crash("list-at out of range")), c: (List.get(hs, I64.to_u64_wrap(2)) ?? crash("list-at out of range")), d: (List.get(hs, I64.to_u64_wrap(3)) ?? crash("list-at out of range")), e: (List.get(hs, I64.to_u64_wrap(4)) ?? crash("list-at out of range")), f: (List.get(hs, I64.to_u64_wrap(5)) ?? crash("list-at out of range")), g: (List.get(hs, I64.to_u64_wrap(6)) ?? crash("list-at out of range")), h: (List.get(hs, I64.to_u64_wrap(7)) ?? crash("list-at out of range")) }

	sha256_round : Sha256.Sha256State, I64, I64 -> Sha256.Sha256State
	sha256_round = |s, ki, wi| ({
		t1 = w32(((((s.h + big_sigma1(s.e)) + ch(s.e, s.f, s.g)) + ki) + wi))
		t2 = w32((big_sigma0(s.a) + maj(s.a, s.b, s.c)))
		{ a: w32((t1 + t2)), b: s.a, c: s.b, d: s.c, e: w32((s.d + t1)), f: s.e, g: s.f, h: s.g }
	})

	sha256_rounds : Sha256.Sha256State, List(I64), List(I64), I64 -> Sha256.Sha256State
	sha256_rounds = |s, k, w, t| (if (t == 64) { s } else { sha256_rounds(sha256_round(s, (List.get(k, I64.to_u64_wrap(t)) ?? crash("list-at out of range")), (List.get(w, I64.to_u64_wrap(t)) ?? crash("list-at out of range"))), k, w, (t + 1)) })

	sha256_compress : List(I64), List(I64) -> List(I64)
	sha256_compress = |hash, block_words| ({
		w = sha256_schedule(block_words)
		s0 = state_from_hash(hash)
		sf = sha256_rounds(s0, sha256_k, w, 0)
		h0 = (List.set(hash, I64.to_u64_wrap(0), w32(((List.get(hash, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) + sf.a))) ?? crash("list-set-at past the end"))
		h1 = (List.set(h0, I64.to_u64_wrap(1), w32(((List.get(h0, I64.to_u64_wrap(1)) ?? crash("list-at out of range")) + sf.b))) ?? crash("list-set-at past the end"))
		h2 = (List.set(h1, I64.to_u64_wrap(2), w32(((List.get(h1, I64.to_u64_wrap(2)) ?? crash("list-at out of range")) + sf.c))) ?? crash("list-set-at past the end"))
		h3 = (List.set(h2, I64.to_u64_wrap(3), w32(((List.get(h2, I64.to_u64_wrap(3)) ?? crash("list-at out of range")) + sf.d))) ?? crash("list-set-at past the end"))
		h4 = (List.set(h3, I64.to_u64_wrap(4), w32(((List.get(h3, I64.to_u64_wrap(4)) ?? crash("list-at out of range")) + sf.e))) ?? crash("list-set-at past the end"))
		h5 = (List.set(h4, I64.to_u64_wrap(5), w32(((List.get(h4, I64.to_u64_wrap(5)) ?? crash("list-at out of range")) + sf.f))) ?? crash("list-set-at past the end"))
		h6 = (List.set(h5, I64.to_u64_wrap(6), w32(((List.get(h5, I64.to_u64_wrap(6)) ?? crash("list-at out of range")) + sf.g))) ?? crash("list-set-at past the end"))
		(List.set(h6, I64.to_u64_wrap(7), w32(((List.get(h6, I64.to_u64_wrap(7)) ?? crash("list-at out of range")) + sf.h))) ?? crash("list-set-at past the end"))
	})

	sha256_copy_list : List(I64), I64, I64, List(I64) -> List(I64)
	sha256_copy_list = |xs, i, len, acc| (if (i == len) { acc } else { sha256_copy_list(xs, (i + 1), len, List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	sha256_pad : List(I64) -> List(I64)
	sha256_pad = |msg| ({
		len = U64.to_i64_wrap(List.len(msg))
		bit_len = (len * 8)
		padded = List.append(sha256_copy_list(msg, 0, len, []), 128)
		padding_zeros = (55 - (len - (I64.div_trunc_by(len, 64) * 64)))
		zeros_needed = (if (padding_zeros < 0) { (padding_zeros + 64) } else { padding_zeros })
		with_zeros = append_zeros(padded, zeros_needed)
		append_length_be(with_zeros, bit_len)
	})

	append_zeros : List(I64), I64 -> List(I64)
	append_zeros = |xs, n| (if (n <= 0) { xs } else { append_zeros(List.append(xs, 0), (n - 1)) })

	append_length_be : List(I64), I64 -> List(I64)
	append_length_be = |xs, bit_len| ({
		xs1 = List.append(xs, w32(I64.shr_wrap(bit_len, I64.to_u8_wrap(56))))
		xs2 = List.append(xs1, I64.bitwise_and(I64.shr_wrap(bit_len, I64.to_u8_wrap(48)), 255))
		xs3 = List.append(xs2, I64.bitwise_and(I64.shr_wrap(bit_len, I64.to_u8_wrap(40)), 255))
		xs4 = List.append(xs3, I64.bitwise_and(I64.shr_wrap(bit_len, I64.to_u8_wrap(32)), 255))
		xs5 = List.append(xs4, I64.bitwise_and(I64.shr_wrap(bit_len, I64.to_u8_wrap(24)), 255))
		xs6 = List.append(xs5, I64.bitwise_and(I64.shr_wrap(bit_len, I64.to_u8_wrap(16)), 255))
		xs7 = List.append(xs6, I64.bitwise_and(I64.shr_wrap(bit_len, I64.to_u8_wrap(8)), 255))
		List.append(xs7, I64.bitwise_and(bit_len, 255))
	})

	bytes_to_words : List(I64), I64, I64, I64, List(I64) -> List(I64)
	bytes_to_words = |bytes, i, len, wi, out| (if (i >= len) { out } else { ({
		w = w32(I64.bitwise_or(I64.shl_wrap((List.get(bytes, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), I64.to_u8_wrap(24)), I64.bitwise_or(I64.shl_wrap((List.get(bytes, I64.to_u64_wrap((i + 1))) ?? crash("list-at out of range")), I64.to_u8_wrap(16)), I64.bitwise_or(I64.shl_wrap((List.get(bytes, I64.to_u64_wrap((i + 2))) ?? crash("list-at out of range")), I64.to_u8_wrap(8)), (List.get(bytes, I64.to_u64_wrap((i + 3))) ?? crash("list-at out of range"))))))
		bytes_to_words(bytes, (i + 4), len, (wi + 1), (List.set(out, I64.to_u64_wrap(wi), w) ?? crash("list-set-at past the end")))
	}) })

	sha256_process_blocks : List(I64), List(I64), I64, I64 -> List(I64)
	sha256_process_blocks = |padded, hash, offset, total_len| (if (offset >= total_len) { hash } else { ({
		block_words = bytes_to_words(padded, offset, (offset + 64), 0, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
		sha256_process_blocks(padded, sha256_compress(hash, block_words), (offset + 64), total_len)
	}) })

	sha256 : List(I64) -> List(I64)
	sha256 = |msg| ({
		padded = sha256_pad(msg)
		sha256_process_blocks(padded, sha256_h0, 0, U64.to_i64_wrap(List.len(padded)))
	})

	sha256_bytes : List(I64) -> List(I64)
	sha256_bytes = |msg| sha256_digest_bytes(sha256(msg), 0, List.with_capacity(I64.to_u64_wrap(32)))

	sha256_digest_bytes : List(I64), I64, List(I64) -> List(I64)
	sha256_digest_bytes = |words, i, out| (if (i >= U64.to_i64_wrap(List.len(words))) { out } else { ({
		w = (List.get(words, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		sha256_digest_bytes(words, (i + 1), List.append(List.append(List.append(List.append(out, I64.bitwise_and(I64.shr_zf_wrap(w, I64.to_u8_wrap(24)), 255)), I64.bitwise_and(I64.shr_zf_wrap(w, I64.to_u8_wrap(16)), 255)), I64.bitwise_and(I64.shr_zf_wrap(w, I64.to_u8_wrap(8)), 255)), I64.bitwise_and(w, 255)))
	}) })

	sha256_to_hex : List(I64) -> CceText
	sha256_to_hex = |hash| words_to_hex(hash, 0, U64.to_i64_wrap(List.len(hash)), "")

	words_to_hex : List(I64), I64, I64, CceText -> CceText
	words_to_hex = |ws, i, len, acc| (if (i == len) { acc } else { ({
		w = (List.get(ws, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		words_to_hex(ws, (i + 1), len, CceText.concat(acc, word_to_hex(w)))
	}) })

	word_to_hex : I64 -> CceText
	word_to_hex = |w| ({
		b0 = I64.bitwise_and(I64.shr_wrap(w, I64.to_u8_wrap(24)), 255)
		b1 = I64.bitwise_and(I64.shr_wrap(w, I64.to_u8_wrap(16)), 255)
		b2 = I64.bitwise_and(I64.shr_wrap(w, I64.to_u8_wrap(8)), 255)
		b3 = I64.bitwise_and(w, 255)
		CceText.concat(CceText.concat(CceText.concat(byte_to_hex(b0), byte_to_hex(b1)), byte_to_hex(b2)), byte_to_hex(b3))
	})

	byte_to_hex : I64 -> CceText
	byte_to_hex = |b| ({
		hi = I64.shr_wrap(b, I64.to_u8_wrap(4))
		lo = I64.bitwise_and(b, 15)
		CceText.concat(sha256_hex_nibble(hi), sha256_hex_nibble(lo))
	})

	sha256_hex_nibble : I64 -> CceText
	sha256_hex_nibble = |n| (if (n == 0) { "0" } else { (if (n == 1) { "1" } else { (if (n == 2) { "2" } else { (if (n == 3) { "3" } else { (if (n == 4) { "4" } else { (if (n == 5) { "5" } else { (if (n == 6) { "6" } else { (if (n == 7) { "7" } else { (if (n == 8) { "8" } else { (if (n == 9) { "9" } else { (if (n == 10) { "a" } else { (if (n == 11) { "b" } else { (if (n == 12) { "c" } else { (if (n == 13) { "d" } else { (if (n == 14) { "e" } else { "f" }) }) }) }) }) }) }) }) }) }) }) }) }) }) })

	text_to_bytes : CceText -> List(I64)
	text_to_bytes = |s| text_to_bytes_loop(s, 0, CceText.len(s), [])

	text_to_bytes_loop : CceText, I64, I64, List(I64) -> List(I64)
	text_to_bytes_loop = |s, i, len, acc| (if (i == len) { acc } else { text_to_bytes_loop(s, (i + 1), len, List.append(acc, CceChar.code(CceText.char_at(s, i)))) })

	sha256_buf! : Mem.Mem, I64, I64, I64 => (Mem.Mem, List(I64))
	sha256_buf! = |mem, buf, off, len| sha256_buf_blocks!(mem, buf, off, len, 0, 1779033703, 3144134277, 1013904242, 2773480762, 1359893119, 2600822924, 528734635, 1541459225)

	sha256_buf_blocks! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, List(I64))
	sha256_buf_blocks! = |mem, buf, off, len, pos, a, b, c, d, e, f, g, h| (if ((pos + 64) > len) { sha256_buf_final!(mem, buf, off, len, pos, a, b, c, d, e, f, g, h) } else { ({
		(mem1, hp) = Mem.mark(mem)
		(mem2, words) = sha256_buf_block_words!(mem1, buf, (off + pos))
		nh = sha256_compress([a, b, c, d, e, f, g, h], words)
		n0 = (List.get(nh, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
		n1 = (List.get(nh, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))
		n2 = (List.get(nh, I64.to_u64_wrap(2)) ?? crash("list-at out of range"))
		n3 = (List.get(nh, I64.to_u64_wrap(3)) ?? crash("list-at out of range"))
		n4 = (List.get(nh, I64.to_u64_wrap(4)) ?? crash("list-at out of range"))
		n5 = (List.get(nh, I64.to_u64_wrap(5)) ?? crash("list-at out of range"))
		n6 = (List.get(nh, I64.to_u64_wrap(6)) ?? crash("list-at out of range"))
		n7 = (List.get(nh, I64.to_u64_wrap(7)) ?? crash("list-at out of range"))
		(mem3, _restored) = Mem.release(mem2, hp)
		sha256_buf_blocks!(mem3, buf, off, len, (pos + 64), n0, n1, n2, n3, n4, n5, n6, n7)
	}) })

	sha256_buf_word! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	sha256_buf_word! = |mem, buf, p| ({
		(mem1, mem__1) = Mem.load!(mem, buf, p, 1)
		(mem2, mem__2) = Mem.load!(mem1, buf, (p + 1), 1)
		(mem3, mem__3) = Mem.load!(mem2, buf, (p + 2), 1)
		(mem4, mem__4) = Mem.load!(mem3, buf, (p + 3), 1)
		(mem4, w32(I64.bitwise_or(I64.shl_wrap(mem__1, I64.to_u8_wrap(24)), I64.bitwise_or(I64.shl_wrap(mem__2, I64.to_u8_wrap(16)), I64.bitwise_or(I64.shl_wrap(mem__3, I64.to_u8_wrap(8)), mem__4)))))
	})

	sha256_buf_block_words! : Mem.Mem, I64, I64 => (Mem.Mem, List(I64))
	sha256_buf_block_words! = |mem, buf, p| ({
		(mem1, mem__1) = sha256_buf_word!(mem, buf, p)
		(mem2, mem__2) = sha256_buf_word!(mem1, buf, (p + 4))
		(mem3, mem__3) = sha256_buf_word!(mem2, buf, (p + 8))
		(mem4, mem__4) = sha256_buf_word!(mem3, buf, (p + 12))
		(mem5, mem__5) = sha256_buf_word!(mem4, buf, (p + 16))
		(mem6, mem__6) = sha256_buf_word!(mem5, buf, (p + 20))
		(mem7, mem__7) = sha256_buf_word!(mem6, buf, (p + 24))
		(mem8, mem__8) = sha256_buf_word!(mem7, buf, (p + 28))
		(mem9, mem__9) = sha256_buf_word!(mem8, buf, (p + 32))
		(mem10, mem__10) = sha256_buf_word!(mem9, buf, (p + 36))
		(mem11, mem__11) = sha256_buf_word!(mem10, buf, (p + 40))
		(mem12, mem__12) = sha256_buf_word!(mem11, buf, (p + 44))
		(mem13, mem__13) = sha256_buf_word!(mem12, buf, (p + 48))
		(mem14, mem__14) = sha256_buf_word!(mem13, buf, (p + 52))
		(mem15, mem__15) = sha256_buf_word!(mem14, buf, (p + 56))
		(mem16, mem__16) = sha256_buf_word!(mem15, buf, (p + 60))
		(mem16, [mem__1, mem__2, mem__3, mem__4, mem__5, mem__6, mem__7, mem__8, mem__9, mem__10, mem__11, mem__12, mem__13, mem__14, mem__15, mem__16])
	})

	sha256_buf_tail_bytes! : Mem.Mem, I64, I64, I64, List(I64) => (Mem.Mem, List(I64))
	sha256_buf_tail_bytes! = |mem, buf, p, n, acc| (if (n == 0) { (mem, acc) } else { ({
		(mem1, mem__1) = Mem.load!(mem, buf, p, 1)
		sha256_buf_tail_bytes!(mem1, buf, (p + 1), (n - 1), List.append(acc, mem__1))
	}) })

	sha256_buf_final! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, List(I64))
	sha256_buf_final! = |mem, buf, off, len, pos, a, b, c, d, e, f, g, h| ({
		(mem2, mem__1) = ({
		(mem1, tail) = sha256_buf_tail_bytes!(mem, buf, (off + pos), (len - pos), [])
		padded1 = List.append(tail, 128)
		padding_zeros = (55 - (len - (I64.div_trunc_by(len, 64) * 64)))
		zeros_needed = (if (padding_zeros < 0) { (padding_zeros + 64) } else { padding_zeros })
		with_zeros = append_zeros(padded1, zeros_needed)
		padded = append_length_be(with_zeros, (len * 8))
		(mem1, sha256_buf_final_blocks(padded, [a, b, c, d, e, f, g, h], 0, U64.to_i64_wrap(List.len(padded))))
	})
		(mem2, mem__1)
	})

	sha256_buf_final_blocks : List(I64), List(I64), I64, I64 -> List(I64)
	sha256_buf_final_blocks = |padded, hash, offset, total| (if (offset >= total) { hash } else { ({
		words = bytes_to_words(padded, offset, (offset + 64), 0, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
		sha256_buf_final_blocks(padded, sha256_compress(hash, words), (offset + 64), total)
	}) })
}
