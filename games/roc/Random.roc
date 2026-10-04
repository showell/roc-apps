# Random -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Wrap64

Random :: [].{

	mix_bits : I64, I64 -> I64
	mix_bits = |seed, idx| ({
		z : I64
		z = I64.plus_wrap(I64.times_wrap(seed, 2654435769), I64.times_wrap(idx, 1442695040888963407))
		a : I64
		a = I64.bitwise_xor(z, I64.shr_zf_wrap(z, I64.to_u8_wrap(30)))
		b : I64
		b = Wrap64.w64_mul(a, 6364136223846793005)
		c : I64
		c = I64.bitwise_xor(b, I64.shr_zf_wrap(b, I64.to_u8_wrap(27)))
		d : I64
		d = Wrap64.w64_mul(c, 1442695040888963407)
		I64.bitwise_xor(d, I64.shr_zf_wrap(d, I64.to_u8_wrap(31)))
	})

	rand_in_range : I64, I64, I64, I64 -> I64
	rand_in_range = |seed, idx, lo, hi| ({
		h : I64
		h = mix_bits(seed, idx)
		positive : I64
		positive = (if (h < 0) { (-h) } else { h })
		range : I64
		range = ((hi - lo) + 1)
		(if (range <= 0) { lo } else { (lo + (positive - (I64.div_trunc_by(positive, range) * range))) })
	})
}
