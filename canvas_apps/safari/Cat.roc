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
import Distance
import Easing
import Fraction
import Speed
import Steps

Cat :: [].{

	## Where a cat crosses: how far along its segment, and its place across
	## the road at the start, in the middle of the road, and at the end.
	Crossing : {
		along : Along,
		start_across : Across,
		mid_across : Across,
		end_across : Across,
	}

	## How the cat holds itself: walking, it is at rest or mid-stride; then
	## frozen; then its leap, from the coil through flight and landing to the
	## collapse after.
	CatPose : [Rest, Stride, Frozen, Coil, Flight, Land, Collapse]

	cat_height : Distance
	cat_height = Distance.metres(1.7)

	## Where a segment's cat starts looking for its tree: it waits by the first
	## tree on the right from here on.
	cat_along : Along
	cat_along = Along.metres(105.0)

	## How far behind its tree, away from the road, the cat starts.
	cat_behind_tree : Distance
	cat_behind_tree = Distance.metres(1.5)

	## How far past its tree, along the road, the cat crosses.
	cat_beyond_tree : Distance
	cat_beyond_tree = Distance.metres(2.0)

	## How far ahead of its feet the frozen cat's head is. Its still's head runs
	## from 0.02 to 0.49 of its height ahead of them, so this is the head's
	## centre, and the cat freezes with its head over the middle of the road.
	frozen_head_reach : Distance
	frozen_head_reach = cat_height.times(0.25)

	## How far behind its feet the collapsed cat's hips lie: about 0.7 of its
	## height in its still, with the hind feet themselves nearer 0.6.
	collapsed_hip_reach : Distance
	collapsed_hip_reach = cat_height.times(0.7)

	## How far onto the far verge's grass the collapsed cat's hips lie.
	grass_toehold : Distance
	grass_toehold = Distance.metres(0.3)

	## The crossing of a cat by `tree`, on the right of the road: wherever that
	## tree stands, the cat starts behind it and just past it.
	crossing : {
		road_half_width : Distance,
		tree : { along : Along, across : Across, .. },
	} -> Cat.Crossing
	crossing = |{ road_half_width, tree }| {
		far_verge = Across.left_of_middle(road_half_width.plus(grass_toehold))
		{
			along: tree.along.plus(cat_beyond_tree),
			start_across: tree.across.plus(cat_behind_tree),
			mid_across: Across.right_of_middle(frozen_head_reach),
			end_across: far_verge.minus(collapsed_hip_reach),
		}
	}

	## How the cat looks walking out: two strides, a frame each step.
	walking_poses : List(Cat.CatPose)
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
	leap_frames : List({ pose : Cat.CatPose, place : { share : Fraction, lift : Distance } })
	leap_frames = [
		{ pose: Coil, place: { share: Fraction.zero, lift: Distance.zero } },
		{ pose: Flight, place: { share: Fraction.of(0.4), lift: Distance.metres(0.27) } },
		{ pose: Flight, place: { share: Fraction.of(0.85), lift: Distance.metres(0.17) } },
		{ pose: Land, place: { share: Fraction.whole, lift: Distance.zero } },
	]

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

	## How hard the cat holds the rider's eye at its strongest.
	peak_attention : Attention
	peak_attention = Attention.of(1.8)

	## Over how many steps its hold fades. The fade starts when the crossing ends,
	## with the rider `clear_gap` short of the cat, so at a metre a step the cat
	## lets go 80 metres past itself.
	attention_fade : Steps
	attention_fade = Steps.of(83)

	## How hard the cat holds the rider's eye: rising as it crosses, then
	## fading once it is across.
	attention : Animation.Approach -> Attention
	attention = |approach|
		if approach.speed == Speed.at_rest {
			Attention.none
		} else {
			match crossing_stage(approach) {
				Waiting => Attention.none
				Playing(progress) => peak_attention.portion(Easing.smoothstep(progress))
				Past(beyond) => {
					faded = beyond.ratio_to(approach.speed.distance_in(attention_fade))
					peak_attention.portion(Easing.smoothstep(Fraction.clamp(faded)).complement())
				}
			}
		}

	## The whole of a crossing, a frame a step: the cat walks out to the middle
	## of the road, freezes there, and leaps clear to the far verge.
	crossing_timeline : Cat.Crossing -> Animation.Timeline(Cat.CatPose)
	crossing_timeline = |cat| {
		on_road = |across| { along: cat.along, across, lift: Distance.zero }
		start = on_road(cat.start_across)
		middle = on_road(cat.mid_across)
		end = on_road(cat.end_across)
		walking = walking_poses.map_with_index(
			|pose, frame| {
				fraction = Fraction.of(frame.to_f64() / walking_poses.len().to_f64())
				{ pose, spot: Animation.spot_between({ from: start, to: middle, fraction }) }
			},
		)
		frozen = List.repeat({ pose: Frozen, spot: middle }, frozen_frames)
		leaping = leap_frames.map(
			|{ pose, place }| {
				on_the_way = Animation.spot_between({
					from: middle,
					to: end,
					fraction: place.share,
				})
				{ pose, spot: { ..on_the_way, lift: place.lift } }
			},
		)
		Animation.Timeline.(
			{
				before: { pose: Rest, spot: start },
				frames: [walking, frozen, leaping].join(),
				after: { pose: Collapse, spot: end },
			},
		)
	}

	## The cat as the rider comes on it.
	instant_at : Cat.Crossing, Animation.Approach -> Animation.Instant(Cat.CatPose)
	instant_at = |cat, approach| crossing_timeline(cat).instant(crossing_stage(approach))
}

the_cat : Cat.Crossing
the_cat = Cat.crossing({
	road_half_width: Distance.metres(2.0),
	tree: { along: Along.metres(100.0), across: Across.metres(3.0) },
})

## The same cat by a tree farther from the road.
the_cat_by_a_far_tree : Cat.Crossing
the_cat_by_a_far_tree = Cat.crossing({
	road_half_width: Distance.metres(2.0),
	tree: { along: Along.metres(100.0), across: Across.metres(8.0) },
})

## A rider `gap` metres short of the cat, at `speed` metres a step.
coming : F64, F64 -> Animation.Approach
coming = |gap, speed| { gap: Distance.metres(gap), speed: Speed.metres_a_step(speed) }

expect the_cat.along.to_metres() == 102.0
expect the_cat.start_across.to_metres() == 4.5
expect the_cat_by_a_far_tree.start_across.to_metres() == 9.5
expect the_cat_by_a_far_tree.mid_across == the_cat.mid_across
expect the_cat_by_a_far_tree.end_across == the_cat.end_across
expect the_cat.mid_across.to_metres() == 0.425
expect
	[
		(the_cat.end_across.to_metres(), -3.49),
		(the_cat.mid_across.distance_from(the_cat.end_across).to_metres(), 3.915),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

expect Cat.cat_height.to_metres() == 1.7
expect Cat.cat_along.to_metres() == 105.0
expect Cat.cat_behind_tree.to_metres() == 1.5
expect Cat.cat_beyond_tree.to_metres() == 2.0
expect Cat.frozen_head_reach.to_metres() == 0.425
expect Cat.collapsed_hip_reach.to_metres() == 1.19
expect Cat.grass_toehold.to_metres() == 0.3
expect Cat.crossing_steps == Steps.of(38)
expect Cat.clear_gap.to_metres() == 3.0
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
expect Cat.peak_attention.to_f64() == 1.8
expect Cat.attention_fade == Steps.of(83)

## The cat `steps_left` steps short of the end of its crossing, for a rider
## going a metre a step.
phase_of : F64 -> Animation.Instant(Cat.CatPose)
phase_of = |steps_left| Cat.instant_at(the_cat, coming(3.0 + steps_left, 1.0))

## The frames of a crossing, as a rider who sees each sees them.
the_frames : List(Animation.Instant(Cat.CatPose))
the_frames = List.from_iter(U64.until(0, 38)).map(|frame| phase_of(37.5 - frame.to_f64()))

## The poses frames `from` to `to` of the crossing show.
poses_of : U64, U64 -> List(Cat.CatPose)
poses_of = |from, to| the_frames.sublist({
	start: from,
	len: to - from + 1,
}).map(|frame| frame.pose)

expect the_frames.len() == 38
expect poses_of(0, 9) == Cat.walking_poses
expect poses_of(10, 33).all(|pose| pose == Frozen)
expect poses_of(34, 37) == [Coil, Flight, Flight, Land]
expect phase_of(38.5).pose == Rest
expect phase_of(0.0).pose == Collapse

## How far across the road the cat is `steps_left` steps from the end.
across_at : F64 -> F64
across_at = |steps_left| phase_of(steps_left).spot.across.to_metres()

## How high the cat is `steps_left` steps from the end.
lift_at : F64 -> F64
lift_at = |steps_left| phase_of(steps_left).spot.lift.to_metres()

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
expect the_frames.all(|frame| frame.spot.along == the_cat.along)

## The poses a rider at `speed`, a metre a step apart from one step to the next,
## sees through the crossing, `phase` of a step past the start of each frame.
poses_seen : F64, F64 -> List(Cat.CatPose)
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
