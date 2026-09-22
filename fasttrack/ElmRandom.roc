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

	Draw : { value : I64, seed : ElmRandom.Seed }

	mask : U64
	mask = 4294967295

	next : ElmRandom.Seed -> ElmRandom.Seed
	next = |seed| { state: U64.bitwise_and((seed.state * 1664525) + seed.incr, mask), incr: seed.incr }

	## What `Bitwise.xor` answers: the low 32 bits, read as a signed Int32.
	signed32 : U64 -> I64
	signed32 = |bits| {
		low = U64.bitwise_and(bits, mask)
		if low >= 2147483648 { U64.to_i64_wrap(low) - 4294967296 } else { U64.to_i64_wrap(low) }
	}

	## ToUint32 of an integer: its value modulo 2^32.
	unsigned32 : I64 -> U64
	unsigned32 = |n| U64.bitwise_and(I64.to_u64_wrap(n), mask)

	peel : ElmRandom.Seed -> U64
	peel = |seed| {
		state = seed.state
		shift = U64.to_u8_wrap(U64.shr_zf_wrap(state, 28) + 4)
		mixed = signed32(U64.bitwise_xor(state, U64.shr_zf_wrap(state, shift)))
		# The product as a double, then back: exact for every |x| < 2^63.
		word = unsigned32(F64.to_i64_wrap(I64.to_f64(mixed * 277803737)))
		U64.bitwise_and(U64.bitwise_xor(U64.shr_zf_wrap(word, 22), word), mask)
	}

	initial_seed : U64 -> ElmRandom.Seed
	initial_seed = |x| {
		seed1 = next({ state: 0, incr: 1013904223 })
		state2 = U64.bitwise_and(seed1.state + x, mask)
		next({ state: state2, incr: seed1.incr })
	}

	## `Random.step (Random.int a b) seed`.
	int : I64, I64, ElmRandom.Seed -> ElmRandom.Draw
	int = |a, b, seed0| {
		lo = if a < b { a } else { b }
		hi = if a < b { b } else { a }
		range = I64.to_u64_wrap(hi - lo + 1)
		if U64.bitwise_and(range - 1, range) == 0 {
			{ value: U64.to_i64_wrap(U64.bitwise_and(range - 1, peel(seed0))) + lo, seed: next(seed0) }
		} else {
			threshold = U64.rem_by(4294967296 - range, range)
			var $seed = seed0
			var $x = peel($seed)
			while $x < threshold {
				$seed = next($seed)
				$x = peel($seed)
			}
			{ value: U64.to_i64_wrap(U64.rem_by($x, range)) + lo, seed: next($seed) }
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
		$values = List.append($values, d.value)
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
