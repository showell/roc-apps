## A cat that crosses the road ahead of the rider. It waits by a roadside
## tree, then walks out into the road, freezes there, and leaps clear to the
## far verge, a frame a step at its own pace. The ride plans its start so that
## it is across as the rider comes within `clear_gap` of it. The rider's eye is
## drawn to it while it crosses, and lets it go after.
import Across
import Along
import Animation
import Attention
import CatCrossing
import Distance
import Easing
import Fraction
import PosedCat
import Steps

Cat :: [].{

	## How long a crossing takes, at a frame a step.
	crossing_steps : Steps
	crossing_steps = {
		frames = walking_poses.len() + frozen_frames + leap_frames.len()
		Steps.of(frames.to_u32_wrap())
	}

	## How far short of the cat the rider is when its crossing ends.
	clear_gap : Distance
	clear_gap = Distance.metres(3.0)

	## What the ride plans a crossing by: its length, and the gap it ends at.
	crossing_span : Animation.StepSpan
	crossing_span = { length: crossing_steps, ends_at: clear_gap }

	## Where the crossing has got to at `timing`.
	crossing_stage : Animation.Timing -> Animation.Stage
	crossing_stage = |timing| Animation.stage_at(timing, crossing_steps)

	## Whether the cat is crossing in front of the rider at `stage`. The rider
	## eases off while it does, which is the rider reacting to the cat; the cat
	## never reacts to the rider.
	is_crossing : Animation.Stage -> Bool
	is_crossing = |stage|
		match stage {
			Playing(_) => True
			Waiting | Past(_) => False
		}

	## How hard the cat holds the rider's eye at `stage`: rising as it crosses,
	## then fading once it is across.
	attention : Animation.Stage -> Attention
	attention = |stage|
		match stage {
			Waiting => Attention.none
			Playing(steps_in) => {
				progress = Fraction.of(steps_in.to_f64() / crossing_steps.to_f64())
				peak_attention.scaled_by(Easing.smoothstep(progress))
			}
			Past(steps_past) => {
				faded = Fraction.clamp(steps_past.to_f64() / attention_fade.to_f64())
				peak_attention.scaled_by(Easing.smoothstep(faded).less())
			}
		}

	## The cat at `stage` of its crossing.
	instant_at : CatCrossing, Animation.Stage -> Animation.Instant(PosedCat.CatPose)
	instant_at = |cat, stage| crossing_timeline(cat).instant(stage)
}

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
leap_frames : List(
	{
		pose : PosedCat.CatPose,
		way_to_verge : Fraction,
		lift : Distance,
	},
)
leap_frames = [
	{
		pose: Coil,
		way_to_verge: Fraction.zero,
		lift: Distance.zero,
	},
	{
		pose: Flight,
		way_to_verge: Fraction.of(0.4),
		lift: Distance.metres(0.27),
	},
	{
		pose: Flight,
		way_to_verge: Fraction.of(0.85),
		lift: Distance.metres(0.17),
	},
	{
		pose: Land,
		way_to_verge: Fraction.whole,
		lift: Distance.zero,
	},
]

## How hard the cat holds the rider's eye at its strongest.
peak_attention : Attention
peak_attention = Attention.of(1.8)

## Over how many steps its hold fades. The fade starts when the crossing ends,
## with the rider `clear_gap` short of the cat, so at a metre a step the cat
## lets go 80 metres past itself.
attention_fade : Steps
attention_fade = Steps.of(83)

## The whole of a crossing, a frame a step: the cat walks out to the middle
## of the road, freezes there, and leaps clear to the far verge.
crossing_timeline : CatCrossing -> Animation.Timeline(PosedCat.CatPose)
crossing_timeline = |cat| {
	on_road = |across| { along: cat.along, across, lift: Distance.zero }
	start = on_road(cat.start_across)
	middle = on_road(CatCrossing.mid_across)
	end = on_road(cat.end_across)
	walking = walking_poses.map_with_index(
		|pose, frame| {
			fraction = Fraction.of(frame.to_f64() / walking_poses.len().to_f64())
			{ pose, location: Animation.location_between({ from: start, to: middle, fraction }) }
		},
	)
	frozen = List.repeat({ pose: Frozen, location: middle }, frozen_frames)
	leaping = leap_frames.map(
		|{ pose, way_to_verge, lift }| {
			on_the_way = Animation.location_between({
				from: middle,
				to: end,
				fraction: way_to_verge,
			})
			{ pose, location: { ..on_the_way, lift } }
		},
	)
	Animation.Timeline.(
		{
			before: { pose: Rest, location: start },
			frames: [walking, frozen, leaping].join(),
			after: { pose: Collapse, location: end },
		},
	)
}

the_cat : CatCrossing
the_cat = CatCrossing.by_tree({
	road_half_width: Distance.metres(2.0),
	tree: { along: Along.metres(100.0), across: Across.metres(3.0) },
})

expect Cat.crossing_steps == Steps.of(38)
expect
	[
		(Waiting, False),
		(Playing(Steps.zero), True),
		(Playing(Steps.of(37)), True),
		(Past(Steps.zero), False),
	].all(|(stage, want)| Cat.is_crossing(stage) == want)

## How hard the cat holds the eye at `stage`.
attention_at : Animation.Stage -> F64
attention_at = |stage| Cat.attention(stage).to_f64()

expect attention_at(Waiting) == 0.0
expect attention_at(Playing(Steps.zero)) == 0.0
expect attention_at(Playing(Steps.of(19))) == 0.9
expect attention_at(Past(Steps.zero)) == 1.8
expect attention_at(Past(Steps.of(42))) > 0.0
expect attention_at(Past(Steps.of(42))) < 1.8
expect attention_at(Past(Steps.of(83))) == 0.0
expect attention_at(Past(Steps.of(200))) == 0.0

## The cat `steps_in` steps into its crossing.
frame_of : U32 -> Animation.Instant(PosedCat.CatPose)
frame_of = |steps_in| Cat.instant_at(the_cat, Playing(Steps.of(steps_in)))

## The frames of a crossing, one a step.
the_frames : List(Animation.Instant(PosedCat.CatPose))
the_frames = List.from_iter(U32.until(0, 38)).map(frame_of)

## The poses frames `from` to `to` of the crossing show.
poses_of : U64, U64 -> List(PosedCat.CatPose)
poses_of = |from, to| the_frames.sublist({
	start: from,
	len: to - from + 1,
}).map(|frame| frame.pose)

expect the_frames.len() == 38
expect poses_of(0, 9) == walking_poses
expect poses_of(10, 33).all(|pose| pose == Frozen)
expect poses_of(34, 37) == [Coil, Flight, Flight, Land]
expect Cat.instant_at(the_cat, Waiting).pose == Rest
expect Cat.instant_at(the_cat, Past(Steps.zero)).pose == Collapse

## How far across the road the cat is `steps_in` steps into its crossing.
across_at : U32 -> F64
across_at = |steps_in| frame_of(steps_in).location.across.to_metres()

## How high the cat is `steps_in` steps into its crossing.
lift_at : U32 -> F64
lift_at = |steps_in| frame_of(steps_in).location.lift.to_metres()

# It walks the first ten frames in even steps, and then stands in the middle of
# the road, and every frame is on the ground until it leaves it.
expect
	[
		(0, 4.5),
		(1, 4.0925),
		(9, 0.8325),
		(10, 0.425),
		(33, 0.425),
		(34, 0.425),
	].all(|(steps_in, want)| (across_at(steps_in) - want).abs() <= 0.000000000001)
expect [0, 9, 10, 33, 34, 37].all(|steps_in| lift_at(steps_in) == 0.0)

# In the air, it is on its way and off the ground.
expect
	[(35, -1.141, 0.27), (36, -2.90275, 0.17)].all(
		|(steps_in, across, lift)|
			(across_at(steps_in) - across).abs() <= 0.000000000001
				and (lift_at(steps_in) - lift).abs() <= 0.000000000001,
	)

expect (across_at(37) - -3.49).abs() <= 0.000000000001
expect (
	Cat.instant_at(
		the_cat,
		Past(Steps.zero),
	).location.across.to_metres() - -3.49
).abs() <= 0.000000000001

# Every crossing is on its own road.
expect the_frames.all(|frame| frame.location.along == the_cat.along)
