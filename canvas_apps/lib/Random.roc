# Random -- a reproducible number, with roc-ray's own shape.
#
# Hand-written. roc-ray's `Random` re-exports the roc-random PACKAGE, and the
# canvas_apps's wasm build is a flat pile of Roc with no package manifest, so this
# offers the same names -- `seed`, `step`, `next`, `bounded_i32`, and a
# `Generation` carrying `value` and `state`. A game ported from an example
# changes its import line and nothing else.
#
# The sequence is NOT roc-random's, so a game's food lands somewhere else than
# it does upstream. It is reproducible from its seed, which is all the rules
# ask of it.
#
# A linear congruential generator, Numerical Recipes' constants, kept in a U64
# and masked back to 32 bits. The mask is what keeps the multiply from ever
# overflowing, since `*` on a fixed-width integer crashes rather than wraps.

Random :: [].{
	State : { bits : U64 }

	Generation(value) : { value : value, state : Random.State }

	Generator(value) : Random.State -> Random.Generation(value)

	mask : U64
	mask = 4294967295

	seed : U32 -> Random.State
	seed = |n| { bits: n.to_u64() }

	## The next state, and the 32 bits it carries.
	turn : Random.State -> Random.State
	turn = |state| { bits: (state.bits * 1664525 + 1013904223).bitwise_and(mask) }

	## Draw from a generator, starting a sequence.
	step : Random.State, Random.Generator(value) -> Random.Generation(value)
	step = |state, generator| generator(state)

	## Draw again, continuing one.
	next : Random.Generation(_), Random.Generator(value) -> Random.Generation(value)
	next = |generation, generator| generator(generation.state)

	## An integer from `lo` to `hi`, both ends included.
	bounded_i32 : I32, I32 -> Random.Generator(I32)
	bounded_i32 = |lo, hi| |state| {
		turned = turn(state)
		span = if hi >= lo {
			(hi - lo).to_i64() + 1
		} else {
			1
		}
		# The high bits are the well-mixed ones in an LCG, so the draw comes
		# from the top of the word rather than the bottom.
		drawn = turned.bits.shr_wrap(8).to_i64_wrap()
		{ value: lo + drawn.rem_by(span).to_i32_wrap(), state: turned }
	}
}
