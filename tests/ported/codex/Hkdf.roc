# Hkdf -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Hmac

Hkdf :: [].{

	hkdf_extract : List(I64), List(I64) -> List(I64)
	hkdf_extract = |salt, ikm| ({
		effective_salt = (if (U64.to_i64_wrap(List.len(salt)) == 0) { hkdf_zero_salt } else { salt })
		hkdf_words_to_bytes(Hmac.hmac_sha256(effective_salt, ikm))
	})

	hkdf_zero_salt : List(I64)
	hkdf_zero_salt = hkdf_zeros(32, 0, [])

	hkdf_zeros : I64, I64, List(I64) -> List(I64)
	hkdf_zeros = |n, i, acc| (if (i >= n) { acc } else { hkdf_zeros(n, (i + 1), List.append(acc, 0)) })

	hkdf_expand : List(I64), List(I64), I64 -> List(I64)
	hkdf_expand = |prk, info, length| (if (length < 0) { [] } else { (if (length > 8160) { [] } else { (if (U64.to_i64_wrap(List.len(prk)) < 32) { [] } else { ({
		n = I64.div_trunc_by((length + 31), 32)
		hkdf_expand_loop(prk, info, length, n, 1, [], List.with_capacity(I64.to_u64_wrap(length)))
	}) }) }) })

	hkdf_expand_loop : List(I64), List(I64), I64, I64, I64, List(I64), List(I64) -> List(I64)
	hkdf_expand_loop = |prk, info, length, n, i, prev, acc| (if (i > n) { acc } else { ({
		input = List.concat(List.concat(prev, info), [i])
		block = hkdf_words_to_bytes(Hmac.hmac_sha256(prk, input))
		remaining = (length - U64.to_i64_wrap(List.len(acc)))
		take = (if (remaining < 32) { remaining } else { 32 })
		hkdf_expand_loop(prk, info, length, n, (i + 1), block, hkdf_append_block(acc, block, 0, take))
	}) })

	hkdf_append_block : List(I64), List(I64), I64, I64 -> List(I64)
	hkdf_append_block = |acc, block, i, n| (if (i >= n) { acc } else { hkdf_append_block(List.append(acc, (List.get(block, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), block, (i + 1), n) })

	hkdf_take : List(I64), I64 -> List(I64)
	hkdf_take = |xs, n| hkdf_take_loop(xs, n, 0, [])

	hkdf_take_loop : List(I64), I64, I64, List(I64) -> List(I64)
	hkdf_take_loop = |xs, n, i, acc| (if (i >= n) { acc } else { (if (i >= U64.to_i64_wrap(List.len(xs))) { acc } else { hkdf_take_loop(xs, n, (i + 1), List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) }) })

	hkdf : List(I64), List(I64), List(I64), I64 -> List(I64)
	hkdf = |salt, ikm, info, length| ({
		prk = hkdf_extract(salt, ikm)
		hkdf_expand(prk, info, length)
	})

	hkdf_words_to_bytes : List(I64) -> List(I64)
	hkdf_words_to_bytes = |words| hkdf_w2b(words, 0, U64.to_i64_wrap(List.len(words)), [])

	hkdf_w2b : List(I64), I64, I64, List(I64) -> List(I64)
	hkdf_w2b = |words, i, len, acc| (if (i >= len) { acc } else { ({
		w = (List.get(words, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		b0 = I64.bitwise_and(I64.shr_zf_wrap(w, I64.to_u8_wrap(24)), 255)
		b1 = I64.bitwise_and(I64.shr_zf_wrap(w, I64.to_u8_wrap(16)), 255)
		b2 = I64.bitwise_and(I64.shr_zf_wrap(w, I64.to_u8_wrap(8)), 255)
		b3 = I64.bitwise_and(w, 255)
		hkdf_w2b(words, (i + 1), len, List.append(List.append(List.append(List.append(acc, b0), b1), b2), b3))
	}) })
}
