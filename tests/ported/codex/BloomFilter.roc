# BloomFilter -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Cce
import Random

BloomFilter :: [].{
	BloomFilter : { bits : List(I64), num_bits : I64, num_hashes : I64, count : I64 }

	bloom_new : I64, I64 -> BloomFilter.BloomFilter
	bloom_new = |num_bits, num_hashes| ({
		num_bytes = I64.div_trunc_by((num_bits + 7), 8)
		{ bits: bloom_zero_bytes(num_bytes, 0, []), num_bits: num_bits, num_hashes: num_hashes, count: 0 }
	})

	bloom_zero_bytes : I64, I64, List(I64) -> List(I64)
	bloom_zero_bytes = |n, i, acc| (if (i >= n) { acc } else { bloom_zero_bytes(n, (i + 1), List.append(acc, 0)) })

	bloom_hash : I64, I64, I64 -> I64
	bloom_hash = |value, seed, num_bits| ({
		h = Random.mix_bits(value, seed)
		positive = (if (h < 0) { (-h) } else { h })
		(positive - (I64.div_trunc_by(positive, num_bits) * num_bits))
	})

	bloom_hash_text : Str, I64, I64 -> I64
	bloom_hash_text = |s, seed, num_bits| ({
		h = bloom_hash_text_loop(s, 0, Cce.length(s), seed)
		positive = (if (h < 0) { (-h) } else { h })
		(positive - (I64.div_trunc_by(positive, num_bits) * num_bits))
	})

	bloom_hash_text_loop : Str, I64, I64, I64 -> I64
	bloom_hash_text_loop = |s, i, len, hash| (if (i >= len) { hash } else { ({
		c = Cce.at_or_crash(s, i)
		bloom_hash_text_loop(s, (i + 1), len, I64.bitwise_xor(I64.plus_wrap(I64.times_wrap(hash, 31), c), U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(hash), U64.pow(2, I64.to_u64_wrap(3))))))
	}) })

	bloom_set_bit : List(I64), I64 -> List(I64)
	bloom_set_bit = |bits, pos| ({
		byte_idx = I64.div_trunc_by(pos, 8)
		bit_idx = (pos - (byte_idx * 8))
		(List.set(bits, I64.to_u64_wrap(byte_idx), I64.bitwise_or((List.get(bits, I64.to_u64_wrap(byte_idx)) ?? crash("list-at out of range")), U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(1), U64.pow(2, I64.to_u64_wrap(bit_idx)))))) ?? crash("list-set-at past the end"))
	})

	bloom_test_bit : List(I64), I64 -> Bool
	bloom_test_bit = |bits, pos| ({
		byte_idx = I64.div_trunc_by(pos, 8)
		bit_idx = (pos - (byte_idx * 8))
		(I64.bitwise_and((List.get(bits, I64.to_u64_wrap(byte_idx)) ?? crash("list-at out of range")), U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(1), U64.pow(2, I64.to_u64_wrap(bit_idx))))) > 0)
	})

	bloom_add : BloomFilter.BloomFilter, I64 -> BloomFilter.BloomFilter
	bloom_add = |bf, value| ({
		new_bits = bloom_add_hashes(bf.bits, value, bf.num_bits, bf.num_hashes, 0)
		{ bits: new_bits, num_bits: bf.num_bits, num_hashes: bf.num_hashes, count: (bf.count + 1) }
	})

	bloom_add_hashes : List(I64), I64, I64, I64, I64 -> List(I64)
	bloom_add_hashes = |bits, value, num_bits, k, i| (if (i >= k) { bits } else { ({
		pos = bloom_hash(value, i, num_bits)
		bloom_add_hashes(bloom_set_bit(bits, pos), value, num_bits, k, (i + 1))
	}) })

	bloom_contains : BloomFilter.BloomFilter, I64 -> Bool
	bloom_contains = |bf, value| bloom_check_hashes(bf.bits, value, bf.num_bits, bf.num_hashes, 0)

	bloom_check_hashes : List(I64), I64, I64, I64, I64 -> Bool
	bloom_check_hashes = |bits, value, num_bits, k, i| (if (i >= k) { True } else { ({
		pos = bloom_hash(value, i, num_bits)
		(if bloom_test_bit(bits, pos) { bloom_check_hashes(bits, value, num_bits, k, (i + 1)) } else { False })
	}) })

	bloom_add_text : BloomFilter.BloomFilter, Str -> BloomFilter.BloomFilter
	bloom_add_text = |bf, s| ({
		new_bits = bloom_add_text_hashes(bf.bits, s, bf.num_bits, bf.num_hashes, 0)
		{ bits: new_bits, num_bits: bf.num_bits, num_hashes: bf.num_hashes, count: (bf.count + 1) }
	})

	bloom_add_text_hashes : List(I64), Str, I64, I64, I64 -> List(I64)
	bloom_add_text_hashes = |bits, s, num_bits, k, i| (if (i >= k) { bits } else { ({
		pos = bloom_hash_text(s, i, num_bits)
		bloom_add_text_hashes(bloom_set_bit(bits, pos), s, num_bits, k, (i + 1))
	}) })

	bloom_contains_text : BloomFilter.BloomFilter, Str -> Bool
	bloom_contains_text = |bf, s| bloom_check_text_hashes(bf.bits, s, bf.num_bits, bf.num_hashes, 0)

	bloom_check_text_hashes : List(I64), Str, I64, I64, I64 -> Bool
	bloom_check_text_hashes = |bits, s, num_bits, k, i| (if (i >= k) { True } else { ({
		pos = bloom_hash_text(s, i, num_bits)
		(if bloom_test_bit(bits, pos) { bloom_check_text_hashes(bits, s, num_bits, k, (i + 1)) } else { False })
	}) })

	bloom_count : BloomFilter.BloomFilter -> I64
	bloom_count = |bf| bf.count

	bloom_false_positive_rate : BloomFilter.BloomFilter -> I64
	bloom_false_positive_rate = |bf| ({
		filled = bloom_count_set_bits(bf.bits, 0, bf.num_bits, 0)
		I64.div_trunc_by((filled * 100), bf.num_bits)
	})

	bloom_count_set_bits : List(I64), I64, I64, I64 -> I64
	bloom_count_set_bits = |bits, i, num_bits, acc| (if (i >= num_bits) { acc } else { bloom_count_set_bits(bits, (i + 1), num_bits, (acc + (if bloom_test_bit(bits, i) { 1 } else { 0 }))) })
}
