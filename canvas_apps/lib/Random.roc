## Random is a reproducible number, with roc-ray's own shape. roc-ray's
## `Random` re-exports the roc-random package, and the canvas apps' wasm build
## is a flat pile of Roc with no package manifest, so this offers the same
## names: `seed`, `step`, `next`, `bounded_i32`, and a `Generation` carrying
## `value` and `state`. A game that starts from an example changes its import line
## and nothing else.
##
## The sequence is not roc-random's, so the same seed draws different numbers
## here than upstream. It is reproducible from its seed, which is all the rules
## ask of it.
##
## It is a linear congruential generator with Numerical Recipes' constants,
## kept in a U64 and masked back to 32 bits. The mask keeps the multiply from
## ever overflowing, since `*` on a fixed-width integer crashes rather than
## wraps, and the state is opaque so that only `seed` and a draw can make one.

Random :: [].{
	State :: U64.{
		is_eq : _
	}

	## A draw's value, the number drawn, and the state to draw the next from,
	## under roc-ray's names, so a ported game reads them unchanged.
	Generation(value) : { value : value, state : Random.State }

	Generator(value) : Random.State -> Random.Generation(value)

	seed : U32 -> Random.State
	seed = |n| State.(n.to_u64())

	## Draw from a generator, starting a sequence.
	step : Random.State, Random.Generator(value) -> Random.Generation(value)
	step = |state, generator| generator(state)

	## Draw again, continuing one.
	next : Random.Generation(_), Random.Generator(value) -> Random.Generation(value)
	next = |generation, generator| generator(generation.state)

	## An integer from `lo` to `hi`, both ends included. A range whose `hi` is
	## below its `lo` holds no integer, and crashes.
	bounded_i32 : I32, I32 -> Random.Generator(I32)
	bounded_i32 = |lo, hi|
		if hi < lo {
			crash "Random.bounded_i32: hi is below lo"
		} else {
			|state| {
				turned = turn(state)
				span = (hi - lo).to_i64() + 1
				# The high bits are the well-mixed ones in an LCG, so the draw
				# comes from the top of the word rather than the bottom.
				drawn = bits(turned).shr_wrap(8).to_i64_wrap()
				{ value: lo + drawn.rem_by(span).to_i32_wrap(), state: turned }
			}
		}
}

mask : U64
mask = 4294967295

bits : Random.State -> U64
bits = |Random.State.(n)| n

# The next state, and the 32 bits it carries.
turn : Random.State -> Random.State
turn = |state| Random.State.((bits(state) * 1664525 + 1013904223).bitwise_and(mask))

# A range whose ends meet draws the one integer in it, rather than crashing.
expect Random.step(Random.seed(5), Random.bounded_i32(3, 3)).value == 3
