# ElmRandom -- elm/random 1.0.0's `initialSeed`, `int` and `step`, to the bit.
#
# A seed deals the same cards here as in the Elm build, so a game replays move
# for move against it. `web/elm_random_oracle.mjs` is the arithmetic as Elm
# compiles it, and the expects below pin its output.
#
# **ELM MULTIPLIES IN DOUBLES.** `peel`'s product reaches 2^59, past a double's
# 53 bits, and JavaScript rounds it before `>>>` and `^` take the low 32 bits.
# `peel` rounds through F64 at the same point; an exact integer multiply gives
# different cards.
ElmRandom :: [].{
	Seed : { state : U64, incr : U64 }

	## One draw, as elm/random's `step` answers it: the number drawn and the
	## seed after it.
	Draw : { number : I64, seed : ElmRandom.Seed }

	mask : U64
	mask = 4294967295

	next : ElmRandom.Seed -> ElmRandom.Seed
	next = |seed| { state: ((seed.state * 1664525) + seed.incr).bitwise_and(mask), incr: seed.incr }

	## What `Bitwise.xor` answers: the low 32 bits, read as a signed Int32.
	signed32 : U64 -> I64
	signed32 = |bits| {
		low = U64.bitwise_and(bits, mask)
		if low >= 2147483648 {
			low.to_i64_wrap() - 4294967296
		} else {
			low.to_i64_wrap()
		}
	}

	## ToUint32 of an integer: its value modulo 2^32.
	unsigned32 : I64 -> U64
	unsigned32 = |n| U64.bitwise_and(n.to_u64_wrap(), mask)

	peel : ElmRandom.Seed -> U64
	peel = |seed| {
		state = seed.state
		shift = (state.shr_zf_wrap(28) + 4).to_u8_wrap()
		mixed = signed32(U64.bitwise_xor(state, state.shr_zf_wrap(shift)))
		# The product as a double, then back: exact for every |x| < 2^63.
		word = unsigned32((mixed * 277803737).to_f64().to_i64_wrap())
		U64.bitwise_and(U64.bitwise_xor(word.shr_zf_wrap(22), word), mask)
	}

	initial_seed : U64 -> ElmRandom.Seed
	initial_seed = |x| {
		seed1 = next({ state: 0, incr: 1013904223 })
		state2 = (seed1.state + x).bitwise_and(mask)
		next({ state: state2, incr: seed1.incr })
	}

	## `Random.step (Random.int a b) seed`.
	int : I64, I64, ElmRandom.Seed -> ElmRandom.Draw
	int = |a, b, seed0| {
		lo = if a < b {
			a
		} else {
			b
		}
		hi = if a < b {
			b
		} else {
			a
		}
		range = (hi - lo + 1).to_u64_wrap()
		if (range - 1).bitwise_and(range) == 0 {
			{ number: (range - 1).bitwise_and(peel(seed0)).to_i64_wrap() + lo, seed: next(seed0) }
		} else {
			threshold = (4294967296 - range).rem_by(range)
			var $seed = seed0
			var $x = peel($seed)
			while $x < threshold {
				$seed = next($seed)
				$x = peel($seed)
			}
			{ number: $x.rem_by(range).to_i64_wrap() + lo, seed: next($seed) }
		}
	}
}

## Twelve draws from a shrinking deck, the way Player.replenish_hand draws.
draws : ElmRandom.Seed -> { values : List(I64), last : ElmRandom.Seed }
draws = |seed0| {
	var $seed = seed0
	var $values = []
	var $deck = 54
	while $deck > 42 {
		d = ElmRandom.int(0, $deck - 1, $seed)
		$values = $values.append(d.number)
		$seed = d.seed
		$deck = $deck - 1
	}
	{ values: $values, last: $seed }
}

# Pinned by web/elm_random_oracle.mjs.
expect ElmRandom.initial_seed(0) == { state: 1196435762, incr: 1013904223 }
expect draws(ElmRandom.initial_seed(0)) == { values: [7, 8, 14, 39, 19, 8, 41, 10, 0, 34, 0, 7], last: { state: 3801544430, incr: 1013904223 } }
expect draws(ElmRandom.initial_seed(42)) == { values: [17, 28, 12, 8, 0, 37, 16, 13, 5, 9, 42, 37], last: { state: 3922542192, incr: 1013904223 } }
expect draws(ElmRandom.initial_seed(1700000000000)) == { values: [3, 19, 19, 38, 8, 10, 16, 27, 38, 8, 31, 3], last: { state: 3406216942, incr: 1013904223 } }
expect draws(ElmRandom.initial_seed(1758570000123)) == { values: [45, 52, 42, 3, 36, 43, 16, 5, 6, 29, 7, 27], last: { state: 3381593597, incr: 1013904223 } }
