# Random -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Wrap64

Random :: [].{

	mix_bits : I64, I64 -> I64
	mix_bits = |seed, idx| ({
		z = I64.plus_wrap(I64.times_wrap(seed, 2654435769), I64.times_wrap(idx, 1442695040888963407))
		a = I64.bitwise_xor(z, U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(z), U64.pow(2, I64.to_u64_wrap(30)))))
		b = Wrap64.w64_mul(a, 6364136223846793005)
		c = I64.bitwise_xor(b, U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(b), U64.pow(2, I64.to_u64_wrap(27)))))
		d = Wrap64.w64_mul(c, 1442695040888963407)
		I64.bitwise_xor(d, U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(d), U64.pow(2, I64.to_u64_wrap(31)))))
	})

	rand_in_range : I64, I64, I64, I64 -> I64
	rand_in_range = |seed, idx, lo, hi| ({
		h = mix_bits(seed, idx)
		positive = (if (h < 0) { (-h) } else { h })
		range = ((hi - lo) + 1)
		(if (range <= 0) { lo } else { (lo + (positive - (I64.div_trunc_by(positive, range) * range))) })
	})
}
