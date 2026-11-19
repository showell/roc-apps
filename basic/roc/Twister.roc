# The Mersenne Twister (MT19937) and Ruby's 53-bit draw from it, for a
# microcomputer's RND: the games' captures are basic101's output, and
# basic101 draws from Ruby's `Random.new(0)`.
#
# A shift is a multiplication or a division by a power of two.
Twister :: [].{
	# The state after init_genrand(seed).
	by_seed : U32 -> List(U32)
	by_seed = |seed| {
		var $mt = List.with_capacity(624)
		var $prev = seed
		$mt = $mt.append(seed)
		var $i = 1
		while $i < 624 {
			x = U32.times_wrap(
				1812433253,
				U32.bitwise_xor($prev, $prev.div_trunc_by(1073741824)),
			).plus_wrap(U64.to_u32_wrap($i))
			$mt = $mt.append(x)
			$prev = x
			$i = $i + 1
		}
		$mt
	}

	# The state after init_by_array([seed]).
	by_array : U32 -> List(U32)
	by_array = |seed| {
		var $mt = Twister.by_seed(19650218)
		var $i = 1
		var $k = 624
		while $k > 0 {
			prev = $mt.get($i - 1) ?? crash "Twister: an index inside the 624-word state"
			cur = $mt.get($i) ?? crash "Twister: an index inside the 624-word state"
			x = U32.bitwise_xor(
				cur,
				U32.bitwise_xor(prev, prev.div_trunc_by(1073741824)).times_wrap(1664525),
			).plus_wrap(seed)
			$mt = $mt.set($i, x) ?? crash "by_array: inside the state"
			$i = $i + 1
			if $i >= 624 {
				$mt = $mt.set(
					0,
					$mt.get(623) ?? crash "Twister: an index inside the 624-word state",
				) ?? crash "by_array: inside the state"
				$i = 1
			} else {
				{}
			}
			$k = $k - 1
		}
		$k = 623
		while $k > 0 {
			prev = $mt.get($i - 1) ?? crash "Twister: an index inside the 624-word state"
			cur = $mt.get($i) ?? crash "Twister: an index inside the 624-word state"
			x = U32.bitwise_xor(
				cur,
				U32.bitwise_xor(prev, prev.div_trunc_by(1073741824)).times_wrap(1566083941),
			).minus_wrap(U64.to_u32_wrap($i))
			$mt = $mt.set($i, x) ?? crash "by_array: inside the state"
			$i = $i + 1
			if $i >= 624 {
				$mt = $mt.set(
					0,
					$mt.get(623) ?? crash "Twister: an index inside the 624-word state",
				) ?? crash "by_array: inside the state"
				$i = 1
			} else {
				{}
			}
			$k = $k - 1
		}
		$mt.set(0, 2147483648) ?? crash "by_array: inside the state"
	}

	twist : List(U32) -> List(U32)
	twist = |state| {
		var $mt = state
		var $kk = 0
		while $kk < 624 {
			y = U32.bitwise_or(
				($mt.get($kk) ?? crash "Twister: an index inside the 624-word state").bitwise_and(2147483648),
				($mt.get(($kk + 1).rem_by(624)) ?? crash "Twister: an index inside the 624-word state").bitwise_and(2147483647),
			)
			mag = if U32.bitwise_and(y, 1) == 1 {
				2567483615
			} else {
				0
			}
			x = U32.bitwise_xor(
				($mt.get(($kk + 397).rem_by(624)) ?? crash "Twister: an index inside the 624-word state").bitwise_xor(y.div_trunc_by(2)),
				mag,
			)
			$mt = $mt.set($kk, x) ?? crash "twist: inside the state"
			$kk = $kk + 1
		}
		$mt
	}

	temper : U32 -> U32
	temper = |y0| {
		y1 = U32.bitwise_xor(y0, y0.div_trunc_by(2048))
		y2 = U32.bitwise_xor(y1, U32.bitwise_and(y1.times_wrap(128), 2636928640))
		y3 = U32.bitwise_xor(y2, U32.bitwise_and(y2.times_wrap(32768), 4022730752))
		U32.bitwise_xor(y3, y3.div_trunc_by(262144))
	}

	# The next 32-bit output; `at` 624 twists first.
	next : List(U32),
	U64 -> {
		y : U32,
		mt : List(U32),
		at : U64,
	}
	next = |mt, at|
		if at >= 624 {
			fresh = Twister.twist(mt)
			{
				y: Twister.temper(fresh.get(0) ?? crash "Twister: an index inside the 624-word state"),
				mt: fresh,
				at: 1,
			}
		} else {
			{
				y: Twister.temper(mt.get(at) ?? crash "Twister: an index inside the 624-word state"),
				mt: mt,
				at: at + 1,
			}
		}

	# A float in [0, 1) from two outputs, as Ruby's Random#rand makes it.
	res53 : List(U32),
	U64 -> {
		v : F64,
		mt : List(U32),
		at : U64,
	}
	res53 = |mt, at| {
		a = Twister.next(mt, at)
		b = Twister.next(a.mt, a.at)
		hi = a.y.div_trunc_by(32).to_f64()
		lo = b.y.div_trunc_by(64).to_f64()
		{
			v: (hi * 67108864.0 + lo) / 9007199254740992.0,
			mt: b.mt,
			at: b.at,
		}
	}
}
