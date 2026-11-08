## A cat that crosses the road ahead of the rider. It waits by a roadside
## tree, then walks out into the road, freezes there, and leaps clear to the
## far verge, a frame a step at its own pace. The ride plans its start so that
## it is across as the rider comes within `clear_gap` of it.
import Animation
import EncounterPlan
import Attention
import CatCrossing
import Distance
import Fraction
import PosedCat
import Steps

Cat :: [].{

	## What the ride plans a crossing by: its length, and the gap it ends at.
	crossing_span : EncounterPlan.StepSpan
	crossing_span = { length: crossing_steps, ends_at: clear_gap }

	## Where the crossing has got to at `timing`.
	crossing_stage : EncounterPlan.Timing -> Animation.Stage
	crossing_stage = |timing| EncounterPlan.stage_at(timing, crossing_steps)

	## How eye-catching a crossing cat is: how hard it holds the rider's eye at
	## its strongest.
	peak_attention : Attention
	peak_attention = Attention.of(1.8)

	## The cat at `stage` of its crossing.
	instant_at : CatCrossing, Animation.Stage -> Animation.Instant(PosedCat.CatPose)
	instant_at = |cat, stage| crossing_timeline(cat).instant(stage)
}

## How long a crossing takes, at a frame a step.
crossing_steps : Steps
crossing_steps = Steps.of(crossing_frames.len().to_u32_wrap())

## How far short of the cat the rider is when its crossing ends.
clear_gap : Distance
clear_gap = Distance.metres(3.0)

## How the cat looks walking out: two strides, a frame each step.
walking_poses : List(PosedCat.CatPose)
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
CrossingFrame : { pose : PosedCat.CatPose, way : CrossingWay }

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
crossing_timeline : CatCrossing -> Animation.Timeline(CrossingFrame, PosedCat.CatPose)
crossing_timeline = |cat| {
	on_road = |across| { along: cat.along(), across, lift: Distance.zero }
	start = on_road(cat.start_across())
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
