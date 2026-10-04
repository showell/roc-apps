# Rng -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Random

Rng :: [].{
	Rng := { state : I64 }.{
		is_eq : Rng.Rng, Rng.Rng -> Bool
		is_eq = |a, b| eq_Rng(a, b)
	}

	rng_new : I64 -> Rng.Rng
	rng_new = |seed| Rng.Rng.{ state: seed }

	rng_next : Rng.Rng -> Rng.Rng
	rng_next = |r| ({
		h : I64
		h = I64.plus_wrap(I64.times_wrap(r.state, 1103515245), 12345)
		positive : I64
		positive = (if (h < 0) { I64.minus_wrap(0, h) } else { h })
		Rng.Rng.{ state: positive }
	})

	rng_value : Rng.Rng -> I64
	rng_value = |r| r.state

	rng_range : Rng.Rng, I64, I64 -> I64
	rng_range = |r, lo, hi| ({
		span : I64
		span = ((hi - lo) + 1)
		(lo + rng_mod(rng_value(r), span))
	})

	rng_mod : I64, I64 -> I64
	rng_mod = |val, modulus| (if (modulus <= 0) { 0 } else { (val - (I64.div_trunc_by(val, modulus) * modulus)) })

	rng_bit : Rng.Rng -> I64
	rng_bit = |r| ({
		h : I64
		h = Random.mix_bits(rng_value(r), 1)
		positive : I64
		positive = (if (h < 0) { (-h) } else { h })
		(positive - (I64.div_trunc_by(positive, 2) * 2))
	})

	eq_Rng : Rng.Rng, Rng.Rng -> Bool
	eq_Rng = |ex, ey| (ex.state == ey.state)
}
