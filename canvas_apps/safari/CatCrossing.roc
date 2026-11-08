## A cat that crosses the road ahead of the rider, by a roadside tree on the
## right of the road. Wherever that tree stands, the cat waits behind it and
## just past it, then walks out into the road, freezes with its head over the
## middle, and leaps clear to the far verge, a frame a step at its own pace. The
## ride plans its start so that it is across as the rider comes within
## `clear_gap` of it.
import Across
import Along
import Animation
import Attention
import Distance
import EncounterPlan
import Fraction
import Geom
import Steps

CatCrossing :: { tree : Geom.RoadPoint }.{

	## How the cat holds itself: walking, it is at rest or mid-stride; then
	## frozen; then its leap, from the coil through flight and landing to the
	## collapse after.
	CatPose : [Rest, Stride, Frozen, Coil, Flight, Land, Collapse]

	## A cat at one instant: how it looks, and where it is.
	CatInstant : Animation.Instant(CatCrossing.CatPose)

	## How tall a cat stands.
	cat_height : Distance
	cat_height = Distance.metres(1.7)

	## Where the tree the cat crosses by stands.
	tree : CatCrossing -> Geom.RoadPoint
	tree = |CatCrossing.(crossing)| crossing.tree

	## How far along its segment the cat crosses: just past its tree.
	along : CatCrossing -> Along
	along = |crossing| crossing.tree().along.plus(cat_beyond_tree)

	## Where across the road the cat starts, behind its tree.
	start_across : CatCrossing -> Across
	start_across = |crossing| crossing.tree().across.plus(cat_behind_tree)

	## Where across the road every cat ends: on the far verge, its hips on the
	## grass.
	end_across : Across
	end_across =
		Across.left_of_middle(Geom.road_half_width.plus(grass_toehold))
			.minus(collapsed_hip_reach)

	## Where every cat freezes across the road: with its head over the middle.
	mid_across : Across
	mid_across = Across.right_of_middle(frozen_head_reach)

	## The crossing of a cat by `tree`, on the right of the road.
	by_tree : { tree : Geom.RoadPoint } -> CatCrossing
	by_tree = |{ tree: tree_point }| CatCrossing.({ tree: tree_point })

	## What the ride plans a crossing by: its length, and the gap it ends at.
	crossing_span : EncounterPlan.StepSpan
	crossing_span = { length: Steps.of(crossing_frames.len().to_u32_wrap()), ends_at: clear_gap }

	## Where along its segment the ride plans `crossing` by: where the cat
	## crosses.
	planned_along : CatCrossing -> Along
	planned_along = |crossing| crossing.along()

	## Where the crossing has got to at `timing`.
	crossing_stage : EncounterPlan.Timing -> Animation.Stage
	crossing_stage = |timing| EncounterPlan.stage_at(timing, crossing_span.length)

	## How eye-catching a crossing cat is: how hard it holds the rider's eye at
	## its strongest.
	peak_attention : Attention
	peak_attention = Attention.of(1.8)

	## The cat at `stage` of its crossing.
	cat_instant_at : CatCrossing, Animation.Stage -> CatCrossing.CatInstant
	cat_instant_at = |crossing, stage| crossing_timeline(crossing).instant(stage)
}

## How far ahead of its feet the frozen cat's head is. Its still's head runs
## from 0.02 to 0.49 of its height ahead of them, so this is the head's centre.
frozen_head_reach : Distance
frozen_head_reach = CatCrossing.cat_height.times(0.25)

## How far behind its feet the collapsed cat's hips lie: about 0.7 of its
## height in its still, with the hind feet themselves nearer 0.6.
collapsed_hip_reach : Distance
collapsed_hip_reach = CatCrossing.cat_height.times(0.7)

## How far behind its tree, away from the road, the cat starts.
cat_behind_tree : Distance
cat_behind_tree = Distance.metres(1.5)

## How far past its tree, along the road, the cat crosses.
cat_beyond_tree : Distance
cat_beyond_tree = Distance.metres(2.0)

## How far onto the far verge's grass the collapsed cat's hips lie.
grass_toehold : Distance
grass_toehold = Distance.metres(0.3)

## How far short of the cat the rider is when its crossing ends.
clear_gap : Distance
clear_gap = Distance.metres(3.0)

## How the cat looks walking out: two strides, a frame each step.
walking_poses : List(CatCrossing.CatPose)
walking_poses = [
	Stride,
	Stride,
	Stride,
	Rest,
	Rest,
	Stride,
	Stride,
	Stride,
	Rest,
	Rest,
]

## How many frames the cat stands frozen.
frozen_frames : U64
frozen_frames = 24

## The leap, frame by frame: how the cat looks, how much of the way from the
## middle of the road to the far verge it has come, and how high its feet are.
## These are keyframes set by eye, not measured off the stills, and each shows
## for one step.
leap_frames : List(CrossingFrame)
leap_frames = [
	{ pose: Coil, way: Leaping({ way_to_verge: Fraction.zero, lift: Distance.zero }) },
	{ pose: Flight, way: Leaping({ way_to_verge: Fraction.of(0.4), lift: Distance.metres(0.27) }) },
	{
		pose: Flight,
		way: Leaping({ way_to_verge: Fraction.of(0.85), lift: Distance.metres(0.17) }),
	},
	{ pose: Land, way: Leaping({ way_to_verge: Fraction.whole, lift: Distance.zero }) },
]

## Where a cat is on its way across in one frame: walking out, this much of
## the way to the middle of the road; standing frozen there; or leaping, this
## much of the way on to the far verge and this high.
CrossingWay : [
	WalkingOut(Fraction),
	StandingFrozen,
	Leaping({ way_to_verge : Fraction, lift : Distance }),
]

## One frame of any crossing before it is put on a road: how the cat looks, and
## where it is on its way across.
CrossingFrame : { pose : CatCrossing.CatPose, way : CrossingWay }

## The frames of any crossing, one a step. Both the crossing's length and its
## timeline come from this one list, so the two can't disagree.
crossing_frames : List(CrossingFrame)
crossing_frames = {
	walking = walking_poses.map_with_index(
		|pose, frame| {
			pose,
			way: WalkingOut(Fraction.of(frame.to_f64() / walking_poses.len().to_f64())),
		},
	)
	frozen = List.repeat({ pose: Frozen, way: StandingFrozen }, frozen_frames)
	[walking, frozen, leap_frames].join()
}

## The whole of a crossing, a frame a step: the cat walks out to the middle
## of the road, freezes there, and leaps clear to the far verge.
crossing_timeline : CatCrossing -> Animation.Timeline(CrossingFrame, CatCrossing.CatPose)
crossing_timeline = |crossing| {
	on_road = |across| { road_point: { along: crossing.along(), across }, lift: Distance.zero }
	start = on_road(crossing.start_across())
	middle = on_road(CatCrossing.mid_across)
	end = on_road(CatCrossing.end_across)
	location_of = |way|
		match way {
			WalkingOut(fraction) =>
				Animation.location_between({ from: start, to: middle, fraction })
			StandingFrozen => middle
			Leaping({ way_to_verge, lift }) => {
				on_the_way = Animation.location_between({
					from: middle,
					to: end,
					fraction: way_to_verge,
				})
				{ ..on_the_way, lift }
			}
		}
	Animation.Timeline.of({
		before: { pose: Rest, location: start },
		frames: crossing_frames,
		frame_instant: |{ pose, way }, _frame_number| { pose, location: location_of(way) },
		after: { pose: Collapse, location: end },
	})
}

the_cat : CatCrossing
the_cat = CatCrossing.by_tree({ tree: { along: Along.metres(100.0), across: Across.metres(3.0) } })

## The same cat by a tree farther from the road.
the_cat_by_a_far_tree : CatCrossing
the_cat_by_a_far_tree = CatCrossing.by_tree({
	tree: { along: Along.metres(100.0), across: Across.metres(8.0) },
})

expect the_cat.along().to_metres() == 102.0
expect the_cat.start_across().to_metres() == 4.5
expect the_cat_by_a_far_tree.start_across().to_metres() == 9.5
expect
	[
		(CatCrossing.end_across.to_metres(), -3.49),
		(CatCrossing.mid_across.distance_from(CatCrossing.end_across).to_metres(), 3.915),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)
