## Scatter strays each animal of a herd a little from its place, so the herd
## doesn't stand in a perfect grid. It stands in for randomness: the stray comes
## from the sine and cosine of the animal's number, so it looks random but is
## the same on every run, and the frames stay exact.
import Distance

Scatter :: [].{

	## How far the animal numbered `index`, counting from 0, strays from its
	## place: along the road, `jitter_along` times the sine of `index` times
	## `along_phase`, and across it, `jitter_across` times the cosine of `index`
	## times `across_phase`. Each herd chooses its own phases by eye.
	stray_of : U64,
	{
		along_phase : F64,
		across_phase : F64,
		jitter_along : Distance,
		jitter_across : Distance,
	} -> { along : Distance, across : Distance }
	stray_of = |index, { along_phase, across_phase, jitter_along, jitter_across }| {
		i = index.to_f64()
		{
			along: jitter_along.times((i * along_phase).sin()),
			across: jitter_across.times((i * across_phase).cos()),
		}
	}
}

sample_stray : U64 -> { along : Distance, across : Distance }
sample_stray = |index|
	Scatter.stray_of(
		index,
		{
			along_phase: 2.0,
			across_phase: 3.0,
			jitter_along: Distance.metres(0.4),
			jitter_across: Distance.metres(0.6),
		},
	)

is_near : Distance, F64 -> Bool
is_near = |got, want| (got.to_metres() - want).abs() <= 0.000000001

# The first animal strays only across the road, its whole reach: the sine of 0
# is 0 and the cosine is 1.
expect sample_stray(0) == { along: Distance.metres(0.0), across: Distance.metres(0.6) }

# Later animals stray by the sine and cosine of their number times the phases,
# each phase on its own side.
expect
	[
		(1, 0.4 * 0.9092974268256817, 0.6 * -0.9899924966004454),
		(2, 0.4 * -0.7568024953079282, 0.6 * 0.960170286650366),
		(5, 0.4 * -0.5440211108893698, 0.6 * -0.7596879128588213),
	].all(
		|(index, along, across)| {
			stray = sample_stray(index)
			is_near(stray.along, along) and is_near(stray.across, across)
		},
	)
