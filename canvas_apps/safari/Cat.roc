## A cat that crosses the road ahead of the rider. It waits by a roadside
## tree, then, as the rider comes, walks out into the road, freezes there,
## and leaps clear to the far verge. How far through its crossing it is
## depends only on how far ahead it is and how fast the rider comes: it
## starts `crossing_steps` before the rider gets within `clear_gap` of it, and is
## across at that gap. The rider's eye is drawn to it while it crosses, and lets
## it go after.
import Across
import Along
import Animation
import Attention
import CatCrossing
import Distance
import Easing
import Fraction
import PosedCat
import Speed
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

	## Where the crossing has got to. A cat has to finish before the rider
	## reaches it however fast the rider comes, so it plays over steps. The rider
	## may not speed up while it plays, so a step moves it on by one frame at
	## most, and every pose in `leap_frames` has a frame of its own: none can be skipped.
	crossing_stage : Animation.Approach -> Animation.Stage
	crossing_stage = |approach|
		Animation.stage_over_step_span({ length: crossing_steps, ends_at: clear_gap }, approach)

	## Whether the cat is crossing in front of the rider now.
	is_crossing : Animation.Approach -> Bool
	is_crossing = |approach|
		match crossing_stage(approach) {
			Playing(_) => True
			Waiting | Past(_) => False
		}

	## How hard the cat holds the rider's eye: rising as it crosses, then
	## fading once it is across.
	attention : Animation.Approach -> Attention
	attention = |approach|
		if approach.speed == Speed.at_rest {
			Attention.none
		} else {
			match crossing_stage(approach) {
				Waiting => Attention.none
				Playing(progress) => peak_attention.scaled_by(Easing.smoothstep(progress))
				Past(beyond) => {
					faded = beyond.portion(approach.speed.distance_in(attention_fade))
					peak_attention.scaled_by(Easing.smoothstep(Fraction.clamp(faded)).less())
				}
			}
		}

	## The cat as the rider comes on it.
	instant_at : CatCrossing, Animation.Approach -> Animation.Instant(PosedCat.CatPose)
	instant_at = |cat, approach| crossing_timeline(cat).instant(crossing_stage(approach))
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
## These are set by eye, not measured off the stills. A rider at a steady
## speed sees every one of these frames.
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

## A rider `gap` metres short of the cat, at `speed` metres a step.
coming : F64, F64 -> Animation.Approach
coming = |gap, speed| { gap: Distance.metres(gap), speed: Speed.metres_a_step(speed) }

expect Cat.crossing_steps == Steps.of(38)
expect
	[
		(coming(40.5, 1.0), True),
		(coming(41.0, 1.0), False),
		(coming(42.0, 1.0), False),
		(coming(3.0, 1.0), False),
		(coming(2.0, 1.0), False),
		(coming(41.0, 0.0), False),
		(coming(22.0, 1.0), True),
	].all(|(input, want)| Cat.is_crossing(input) == want)

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

## The cat `steps_left` steps short of the end of its crossing, for a rider
## going a metre a step.
phase_of : F64 -> Animation.Instant(PosedCat.CatPose)
phase_of = |steps_left| Cat.instant_at(the_cat, coming(3.0 + steps_left, 1.0))

## The frames of a crossing, as a rider who sees each sees them.
the_frames : List(Animation.Instant(PosedCat.CatPose))
the_frames = List.from_iter(U64.until(0, 38)).map(|frame| phase_of(37.5 - frame.to_f64()))

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
expect phase_of(38.5).pose == Rest
expect phase_of(0.0).pose == Collapse

## How far across the road the cat is `steps_left` steps from the end.
across_at : F64 -> F64
across_at = |steps_left| phase_of(steps_left).location.across.to_metres()

## How high the cat is `steps_left` steps from the end.
lift_at : F64 -> F64
lift_at = |steps_left| phase_of(steps_left).location.lift.to_metres()

# It walks the first ten frames in even steps, and then stands in the middle of
# the road, and every frame is on the ground until it leaves it.
expect
	[
		(37.5, 4.5),
		(36.5, 4.0925),
		(28.5, 0.8325),
		(27.5, 0.425),
		(4.5, 0.425),
		(3.5, 0.425),
	].all(|(steps_left, want)| (across_at(steps_left) - want).abs() <= 0.000000000001)
expect [37.5, 28.5, 27.5, 4.5, 3.5, 0.5].all(|steps_left| lift_at(steps_left) == 0.0)

# In the air, it is on its way and off the ground.
expect
	[(2.5, -1.141, 0.27), (1.5, -2.90275, 0.17)].all(
		|(steps_left, across, lift)|
			(across_at(steps_left) - across).abs() <= 0.000000000001
				and (lift_at(steps_left) - lift).abs() <= 0.000000000001,
	)

expect (across_at(0.5) - -3.49).abs() <= 0.000000000001
expect (across_at(0.0) - -3.49).abs() <= 0.000000000001

# Every crossing is on its own road.
expect the_frames.all(|frame| frame.location.along == the_cat.along)

## The poses a rider at `speed`, a metre a step apart from one step to the next,
## sees through the crossing, `phase` of a step past the start of each frame.
poses_seen : F64, F64 -> List(PosedCat.CatPose)
poses_seen = |speed, phase|
	List.from_iter(U64.until(0, 38)).map(
		|frame| {
			steps_left = 38.0 - frame.to_f64() - phase
			gap = 3.0 + steps_left * speed
			Cat.instant_at(the_cat, coming(gap, speed)).pose
		},
	)

# A rider at a steady speed sees every frame once, whatever speed they come at
# and however a step falls in a frame: no pose is skipped.
expect
	[0.117, 0.3, 1.0, 1.2199, 1.2334, 2.5].all(
		|speed| [0.01, 0.139, 0.5, 0.653, 0.88, 0.99].all(
			|phase| poses_seen(speed, phase) == poses_of(0, 37),
		),
	)
