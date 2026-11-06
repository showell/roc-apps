## A cat that crosses the road ahead of the rider. It waits by a roadside
## tree, then, as the rider comes, walks out into the lane, freezes there,
## and leaps clear to the far verge. How far through its crossing it is
## depends only on how far ahead it is and how fast the rider comes: it
## starts when the rider is `crossing_beats` away, at a beat a step, and is
## across when the rider is `road_buffer` from it. The rider's eye is drawn to it while
## it crosses, and lets it go after. A cat's spots are relative to where it
## crosses along its segment, so cats the same distance from the road play
## one timeline.
import Across
import Along
import Animation
import Attention
import Beat
import Beats
import CatHeights
import Distance
import Easing
import Fraction
import Float

Cat :: [].{

	## Where a cat crosses: how far along its segment, and its place across
	## the road at the start, in the middle of the lane, and at the end.
	Crossing : {
		along : Along,
		start_across : Across,
		mid_across : Across,
		end_across : Across,
		height : Distance,
	}

	## How the cat holds itself: walking, it is at rest or mid-stride; then
	## frozen; then its leap, from the coil through flight and landing to the
	## collapse after.
	Pose : [Rest, Stride, Frozen, Coil, Flight, Land, Collapse]

	cat_height : Distance
	cat_height = Distance.metres(1.7)

	## How far along its segment the cat waits, before it is moved to just
	## past the nearest tree.
	cat_along : Along
	cat_along = Along.metres(105.0)

	## How far out from its tree, towards the road, the cat starts.
	cat_road_gap : Distance
	cat_road_gap = Distance.metres(1.5)

	## How far past its tree, along the road, the cat crosses.
	cat_beyond_tree : Distance
	cat_beyond_tree = Distance.metres(2.0)

	## Where the cat's head is across its body, in cat heights; it freezes
	## with its head in the middle of the lane.
	cat_head_x : CatHeights
	cat_head_x = CatHeights.of(-0.48)

	## How far the cat's hind feet land past the grass's edge.
	land_hind_reach : Distance
	land_hind_reach = cat_height.times(0.7)

	## How far onto the far verge's grass the cat's landing reaches.
	grass_toehold : Distance
	grass_toehold = Distance.metres(0.3)

	## The crossing of a cat by the tree `tree_offset` out from the lane's
	## edge and at `tree_along` on the segment.
	crossing : {
		road_half_width : Distance,
		tree_offset : Distance,
		tree_along : Along,
	} -> Cat.Crossing
	crossing = |{ road_half_width, tree_offset, tree_along }| {
		tree_across = road_half_width.plus(tree_offset)
		far_verge = Across.left_of_middle(road_half_width.plus(grass_toehold))
		{
			along: tree_along.plus(cat_beyond_tree),
			start_across: Across.right_of_middle(tree_across.plus(cat_road_gap)),
			mid_across: Across.right_of_middle(cat_height.times(-cat_head_x.to_f64())),
			end_across: far_verge.minus(land_hind_reach),
			height: cat_height,
		}
	}

	## The crossing's three parts, in beats.
	enters_road_beats : Beats
	enters_road_beats = Beats.of(10.0)

	frozen_beats : Beats
	frozen_beats = Beats.of(24.0)

	escapes_beats : Beats
	escapes_beats = Beats.of(4.0)

	crossing_beats : Beats
	crossing_beats = enters_road_beats.plus(frozen_beats).plus(escapes_beats)

	## The beat the cat's escape starts after.
	escape_at : Beat
	escape_at = Beat.at(enters_road_beats.plus(frozen_beats))

	## How many beats into its escape the cat leaves the ground, and lands.
	leaves_ground_beats : Beats
	leaves_ground_beats = Beats.of(1.0)

	touches_down_beats : Beats
	touches_down_beats = Beats.of(3.0)

	## How many beats into its escape the cat stops coiling, flying and
	## landing. Its body moves ahead of its path, so each falls a little before
	## the leap itself gets there.
	coil_ends_beats : Beats
	coil_ends_beats = Beats.of(0.8)

	flight_ends_beats : Beats
	flight_ends_beats = Beats.of(2.8)

	land_ends_beats : Beats
	land_ends_beats = Beats.of(3.8)

	## How far short of the cat the rider is when it is across.
	road_buffer : Distance
	road_buffer = Distance.metres(3.0)

	## Where the crossing has got to. A cat has to finish before the rider
	## reaches it however fast the rider comes, so it plays over beats.
	crossing_stage : Animation.Approach -> Animation.Stage
	crossing_stage = |approach|
		Animation.over_beats({ length: crossing_beats, buffer: road_buffer }, approach)

	## Whether the cat is crossing in front of the rider now.
	is_in_danger : Animation.Approach -> Bool
	is_in_danger = |approach|
		match crossing_stage(approach) {
			Playing(_) => True
			Waiting | Past(_) => False
		}

	## How hard the cat holds the rider's eye at its strongest.
	peak_attention : Attention
	peak_attention = Attention.of(1.8)

	## Over how many beats, after the rider reaches the cat, its hold fades.
	attention_fade : Beats
	attention_fade = Beats.of(83.0)

	## How hard the cat holds the rider's eye: rising as it crosses, then
	## fading once the rider is past.
	attention : Animation.Approach -> Attention
	attention = |approach|
		if approach.speed <= Animation.standstill {
			Attention.none
		} else {
			match crossing_stage(approach) {
				Waiting => Attention.none
				Playing(progress) => peak_attention.portion(Easing.smoothstep(progress))
				Past(beyond) => {
					faded = approach.speed.beats_to_cover(beyond).ratio_to(attention_fade)
					peak_attention.portion(Easing.smoothstep(Fraction.clamp(faded)).complement())
				}
			}
		}

	## A stride is about this many beats.
	stride_beats : Beats
	stride_beats = Beats.of(5.0)

	## How many strides a cat walking for `length` takes: a whole number, at
	## least one.
	strides_in : Beats -> U32
	strides_in = |length| {
		strides = Float.round(length.ratio_to(stride_beats))
		if strides < 1.0 {
			1
		} else {
			strides.to_u32_wrap()
		}
	}

	## The number CatStills draws a pose by.
	pose_index : Cat.Pose -> I64
	pose_index = |pose|
		match pose {
			Rest => 0
			Stride => 1
			Frozen => 2
			Coil => 3
			Flight => 4
			Land => 5
			Collapse => 6
		}

	## The top of the leap, in cat heights.
	leap_height : CatHeights
	leap_height = CatHeights.of(0.18)

	## The whole of a crossing: the cat walks out to the middle of the lane,
	## freezes there, and leaps clear to the far verge. Each leap pose's cut
	## sums to a float just under the beat it stands for, so that float goes
	## with the pose before it, which is why those cuts are `Through`.
	crossing_timeline : Cat.Crossing -> Animation.Timeline(Cat.Pose, CatHeights)
	crossing_timeline = |cat| {
		start = spot_across(cat.start_across)
		middle = spot_across(cat.mid_across)
		end = spot_across(cat.end_across)
		Animation.Timeline.(
			{
				length: crossing_beats,
				before: { pose: Rest, spot: start },
				after: { pose: Collapse, spot: end },
				looks: {
					stretches: [
						{
							until: Through(Beat.at(enters_road_beats)),
							plays: Alternates({
								up: Stride,
								down: Rest,
								count: strides_in(enters_road_beats),
								over: enters_road_beats,
							}),
						},
						{ until: Through(escape_at), plays: Holds(Frozen) },
						{ until: Through(escape_at.plus(coil_ends_beats)), plays: Holds(Coil) },
						{ until: Through(escape_at.plus(flight_ends_beats)), plays: Holds(Flight) },
						{ until: Through(escape_at.plus(land_ends_beats)), plays: Holds(Land) },
					],
					finally: Holds(Collapse),
				},
				path: {
					stretches: [
						{
							until: Through(Beat.at(enters_road_beats)),
							plays: Line({
								from: start,
								to: middle,
								ease: Steady,
							}),
						},
						{
							until: Before(escape_at.plus(leaves_ground_beats)),
							plays: StaysAt(middle),
						},
						{
							until: Before(escape_at.plus(touches_down_beats)),
							plays: Arc({
								line: {
									from: middle,
									to: end,
									ease: ThreeQuarterPower,
								},
								rise: leap_height,
							}),
						},
					],
					finally: StaysAt(end),
				},
			},
		)
	}

	## The cat as the rider comes on it.
	instant_at : Cat.Crossing, Animation.Approach -> Animation.Instant(Cat.Pose, CatHeights)
	instant_at = |cat, approach| crossing_timeline(cat).instant(crossing_stage(approach))
}

## The spot `across` the road, on the ground where the cat crosses.
spot_across : Across -> Animation.Spot(CatHeights)
spot_across = |across| { along: Along.start, across, lift: CatHeights.zero }

the_cat : Cat.Crossing
the_cat = Cat.crossing({
	road_half_width: Distance.metres(2.0),
	tree_offset: Distance.metres(1.0),
	tree_along: Along.metres(100.0),
})

## A rider `gap` metres short of the cat, at `speed` metres a step. Cat doesn't
## import Speed, so a speed comes from `standstill`, a millionth of a metre a step.
coming : F64, F64 -> Animation.Approach
coming = |gap, speed| {
	gap: Distance.metres(gap),
	speed: Animation.standstill.times(speed * 1000000.0),
}

expect coming(0.0, 1.0).speed.to_metres_a_step() == 1.0

expect the_cat.along.to_metres() == 102.0
expect the_cat.start_across.to_metres() == 4.5
expect the_cat.mid_across.to_metres() == 0.816
expect the_cat.height.to_metres() == 1.7
expect
	[
		(the_cat.end_across.to_metres(), -3.49),
		(the_cat.mid_across.distance_from(the_cat.end_across).to_metres(), 4.306),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

expect Cat.cat_height.to_metres() == 1.7
expect Cat.cat_along.to_metres() == 105.0
expect Cat.cat_road_gap.to_metres() == 1.5
expect Cat.cat_beyond_tree.to_metres() == 2.0
expect Cat.cat_head_x.to_f64() == -0.48
expect Cat.land_hind_reach.to_metres() == 1.19
expect Cat.grass_toehold.to_metres() == 0.3
expect Cat.enters_road_beats.to_f64() == 10.0
expect Cat.frozen_beats.to_f64() == 24.0
expect Cat.escapes_beats.to_f64() == 4.0
expect Cat.crossing_beats.to_f64() == 38.0
expect Cat.road_buffer.to_metres() == 3.0
expect
	[
		(coming(41.0, 1.0), True),
		(coming(42.0, 1.0), False),
		(coming(3.0, 1.0), False),
		(coming(2.0, 1.0), False),
		(coming(41.0, 0.0), False),
		(coming(22.0, 1.0), True),
	].all(|(input, want)| Cat.is_in_danger(input) == want)

## How far through its crossing a cat is.
progress_of : Animation.Approach -> F64
progress_of = |approach|
	match Cat.crossing_stage(approach) {
		Waiting => 0.0
		Playing(progress) => progress.to_f64()
		Past(_) => 1.0
	}

expect
	[
		(coming(41.0, 1.0), 0.0),
		(coming(22.0, 1.0), 0.5),
		(coming(3.0, 1.0), 1.0),
		(coming(2.0, 1.0), 1.0),
		(coming(100.0, 1.0), 0.0),
		(coming(41.0, 0.0), 0.0),
	].all(|(input, want)| progress_of(input) == want)

expect Cat.attention(coming(41.0, 1.0)).to_f64() == 0.0
expect Cat.attention(coming(22.0, 1.0)).to_f64() == 0.9
expect Cat.attention(coming(3.0, 1.0)).to_f64() == 1.8
expect Cat.attention(coming(-38.5, 1.0)).to_f64() == 0.9
expect Cat.attention(coming(-80.0, 1.0)).to_f64() == 0.0
expect Cat.attention(coming(22.0, 0.0)).to_f64() == 0.0
expect Cat.peak_attention.to_f64() == 1.8
expect Cat.attention_fade.to_f64() == 83.0

## How many strides of a walk `length` beats long are done `progress` through it.
turns : F64, F64 -> F64
turns = |progress, length| progress * Cat.strides_in(Beats.of(length)).to_f64()

expect turns(0.0, 10.0) == 0.0
expect turns(1.0, 10.0) == 2.0
expect turns(0.5, 10.0) == 1.0
expect turns(1.0, 20.0) == 4.0
expect turns(1.0, 3.0) == 1.0
expect turns(1.0, 0.0) == 1.0
expect Cat.stride_beats.to_f64() == 5.0

## The cat at `beat` of its crossing.
crossing_at : F64 -> Animation.Instant(Cat.Pose, CatHeights)
crossing_at = |beat| Cat.crossing_timeline(the_cat).at_beat(Beat.of(beat))

expect
	[Rest, Stride, Frozen, Coil, Flight, Land, Collapse].map(Cat.pose_index)
		== [0, 1, 2, 3, 4, 5, 6]

expect
	[
		(34.01, 3),
		(34.79, 3),
		(34.81, 4),
		(36.79, 4),
		(36.81, 5),
		(37.79, 5),
		(37.81, 6),
		(38.0, 6),
	].all(|(beat, want)| Cat.pose_index(crossing_at(beat).pose) == want)

## The float after `beat`.
just_past : F64 -> F64
just_past = |beat| F64.from_bits(beat.to_bits() + 1)

## Where a cut `into_escape` beats into the escape falls.
cut_after_escape : Beats -> F64
cut_after_escape = |into_escape| Cat.escape_at.plus(into_escape).to_f64()

# Each leap pose lasts through its cut's own float, and no further.
expect
	[
		(cut_after_escape(Cat.coil_ends_beats), 3),
		(just_past(cut_after_escape(Cat.coil_ends_beats)), 4),
		(cut_after_escape(Cat.flight_ends_beats), 4),
		(just_past(cut_after_escape(Cat.flight_ends_beats)), 5),
		(cut_after_escape(Cat.land_ends_beats), 5),
		(just_past(cut_after_escape(Cat.land_ends_beats)), 6),
	].all(|(beat, want)| Cat.pose_index(crossing_at(beat).pose) == want)

phase_of : F64 -> Animation.Instant(Cat.Pose, CatHeights)
phase_of = |gap| Cat.instant_at(the_cat, coming(gap, 1.0))

expect
	[
		(41.0, 0),
		(31.5, 0),
		(30.0, 2),
		(7.0, 2),
		(6.5, 3),
		(6.0, 4),
		(4.0, 5),
		(3.0, 6),
	].all(|(gap, want)| Cat.pose_index(phase_of(gap).pose) == want)

expect crossing_at(0.0).spot.across.to_metres() == 4.5
expect crossing_at(1.25).spot.across.to_metres() == 4.0395
expect crossing_at(3.75).spot.across.to_metres() == 3.1185
expect crossing_at(6.25).spot.across.to_metres() == 2.1975
expect crossing_at(8.75).spot.across.to_metres() == 1.2765
expect crossing_at(0.0).spot.lift.to_f64() == 0.0
expect crossing_at(8.75).spot.lift.to_f64() == 0.0
expect
	[
		(0.0, 0),
		(1.25, 1),
		(3.75, 0),
		(6.25, 1),
		(8.75, 0),
	].all(|(beat, want)| Cat.pose_index(crossing_at(beat).pose) == want)

expect phase_of(30.0).spot.across.to_metres() == 0.816
expect phase_of(7.0).spot.across.to_metres() == 0.816
expect phase_of(30.0).spot.lift.to_f64() == 0.0
expect phase_of(6.5).spot.across.to_metres() == 0.816
expect phase_of(6.5).spot.lift.to_f64() == 0.0
expect phase_of(6.0).spot.across.to_metres() == 0.816
expect phase_of(6.0).spot.lift.to_f64() == 0.0
expect Easing.three_quarter_power(Fraction.zero).to_f64() == 0.0
expect Easing.three_quarter_power(Fraction.whole).to_f64() == 1.0
expect Easing.three_quarter_power(Fraction.of(0.0625)).to_f64() == 0.125
expect Cat.leap_height.to_f64() == 0.18
expect
	[
		(phase_of(5.875).spot.across.to_metres(), 0.27775),
		(phase_of(5.875).spot.lift.to_f64(), 0.0421875),
		(phase_of(4.0).spot.across.to_metres(), -3.49),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)
