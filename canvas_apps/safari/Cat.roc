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
import Beats
import Distance
import Easing
import Fraction
import Num_

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
	cat_head_x : F64
	cat_head_x = (0.0 - 0.48)

	## How far the cat's hind feet land past the grass's edge.
	land_hind_reach : Distance
	land_hind_reach = cat_height.times(0.7)

	## How far onto the far verge's grass the cat's landing reaches.
	grass_toehold : Distance
	grass_toehold = Distance.metres(0.3)

	## The crossing of a cat by the tree `tree_offset` out from the lane's
	## edge and at `tree_along` on the segment.
	crossing : {
		lane_half_width : Distance,
		tree_offset : Distance,
		tree_along : Along,
	} -> Cat.Crossing
	crossing = |
		{
			lane_half_width,
			tree_offset,
			tree_along,
		},
	| {
		tree_across = lane_half_width.plus(tree_offset)
		far_verge = Across.left_of_middle(lane_half_width.plus(grass_toehold))
		{
			along: tree_along.plus(cat_beyond_tree),
			start_across: Across.right_of_middle(tree_across.plus(cat_road_gap)),
			mid_across: Across.right_of_middle(cat_height.times(0.0 - cat_head_x)),
			end_across: far_verge.minus(land_hind_reach),
			height: cat_height,
		}
	}

	## The crossing's three stages, in beats.
	enters_road_beats : Beats
	enters_road_beats = Beats.of(10.0)

	frozen_beats : Beats
	frozen_beats = Beats.of(24.0)

	escapes_beats : Beats
	escapes_beats = Beats.of(4.0)

	crossing_beats : Beats
	crossing_beats = enters_road_beats.plus(frozen_beats).plus(escapes_beats)

	## The beat the cat's escape starts after.
	escape_at : Beats
	escape_at = enters_road_beats.plus(frozen_beats)

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
	focus_peak : Attention
	focus_peak = Attention.of(1.8)

	## Over how many beats, after the rider reaches the cat, its hold fades.
	focus_ramp_down : Beats
	focus_ramp_down = Beats.of(83.0)

	## How hard the cat holds the rider's eye: rising as it crosses, then
	## fading once the rider is past.
	focus : Animation.Approach -> Attention
	focus = |approach|
		if approach.speed <= Animation.standstill {
			Attention.none
		} else {
			match crossing_stage(approach) {
				Waiting => Attention.none
				Playing(progress) => focus_peak.portion(Easing.smoothstep(progress))
				Past(beyond) => {
					faded = approach.speed.beats_to_cover(beyond).ratio_to(focus_ramp_down)
					focus_peak.portion(Easing.smoothstep(Fraction.clamp(faded)).complement())
				}
			}
		}

	## A stride is about this many beats.
	stride_beats : Beats
	stride_beats = Beats.of(5.0)

	## How many strides a cat walking for `length` takes: a whole number, at
	## least one.
	strides_in : Beats -> F64
	strides_in = |length| {
		strides = Num_.round_real(length.ratio_to(stride_beats))
		if (strides < 1.0) 1.0 else strides
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
	leap_height : F64
	leap_height = 0.18

	## The whole of a crossing: the cat walks out to the middle of the lane,
	## freezes there, and leaps clear to the far verge. Each leap pose's cut
	## sums to a float just under the beat it stands for, so that float goes
	## with the pose before it, which is why those cuts are `Through`.
	crossing_timeline : Cat.Crossing -> Animation.Timeline(Cat.Pose)
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
							until: Through(enters_road_beats),
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
							until: Through(enters_road_beats),
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
	instant_at : Cat.Crossing, Animation.Approach -> Animation.Instant(Cat.Pose)
	instant_at = |cat, approach| crossing_timeline(cat).instant(crossing_stage(approach))
}

## The spot `across` the road, on the ground where the cat crosses.
spot_across : Across -> Animation.Spot
spot_across = |across| {
	along: Along.start,
	across,
	lift: 0.0,
}
