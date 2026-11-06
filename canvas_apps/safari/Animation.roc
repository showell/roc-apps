## How a critter plays out as the rider comes. A rule turns an `Approach` into a
## `Stage`, and a timeline turns a `Stage` into an `Instant`. The two know nothing
## of each other: `stage_over_gap` or `stage_over_step_span` says how far along an animation is,
## and a timeline looks up the frame that far through its list.
##
## A timeline is a list of frames, each a pose and a spot, so a critter's whole
## animation reads in one place. Nothing here plays a timeline but that lookup.
## The instants before and after are the timeline's own, because a critter can
## rest somewhere no frame ever reaches.
import Across
import Along
import Distance
import Easing
import Fraction
import Speed
import Steps

Animation :: [].{

	## How the rider comes on a thing: the gap from the rider ahead to it, and
	## the rider's speed.
	Approach : { gap : Distance, speed : Speed }

	## Where an animation has got to: not begun, playing and this far through,
	## or over, with the rider this far beyond its end.
	Stage : [Waiting, Playing(Fraction), Past(Distance)]

	## The gaps an animation plays between.
	GapSpan : { starts_at : Distance, ends_at : Distance }

	## How many steps an animation plays for, and the gap it ends at.
	StepSpan : { length : Steps, ends_at : Distance }

	## An animation that plays while the rider closes from a gap of `starts_at`
	## to `ends_at`, however fast. It is playing only strictly between the two,
	## so a critter is at rest at both ends.
	stage_over_gap : Animation.GapSpan, { gap : Distance, .. } -> Animation.Stage
	stage_over_gap = |{ starts_at, ends_at }, { gap, .. }|
		if gap <= ends_at {
			Past(ends_at.minus(gap))
		} else if gap >= starts_at {
			Waiting
		} else {
			Playing(Fraction.of(starts_at.minus(gap).ratio_to(starts_at.minus(ends_at))))
		}

	## An animation that plays one frame a step, and ends with the rider
	## `ends_at` short: `stage_over_gap`, starting however far off the rider's speed
	## covers `length` from there. A faster rider starts it sooner, so it
	## finishes in time however fast the rider comes.
	##
	## It takes the speed to be steady. A rider who slows mid-animation shortens
	## what is left to cover, so the animation falls back a little, and one who
	## stands still has set nothing going: they are `Waiting`.
	stage_over_step_span : Animation.StepSpan, Animation.Approach -> Animation.Stage
	stage_over_step_span = |{ length, ends_at }, approach| {
		starts_at = ends_at.plus(approach.speed.distance_in(length))
		stage_over_gap({ starts_at, ends_at }, approach)
	}

	## A place on a critter's segment, and how high it is off the ground.
	Spot : {
		along : Along,
		across : Across,
		lift : Distance,
	}

	## The spot `fraction` of the way from `from` to `to`, in a straight line.
	spot_between : {
		from : Animation.Spot,
		to : Animation.Spot,
		fraction : Fraction,
	} -> Animation.Spot
	spot_between = |{ from, to, fraction }| {
		between = |start, end| Easing.lerp({ from: start, to: end, fraction })
		{
			along: Along.metres(between(from.along.to_metres(), to.along.to_metres())),
			across: Across.metres(between(from.across.to_metres(), to.across.to_metres())),
			lift: Distance.metres(between(from.lift.to_metres(), to.lift.to_metres())),
		}
	}

	## A critter at one instant: how it looks, and where it is.
	Instant(pose) : { pose : pose, spot : Animation.Spot }

	## A whole animation: the critter at rest before, the frames it plays through,
	## each an equal share of the animation, and the critter at rest after.
	Timeline(pose) := {
		before : Animation.Instant(pose),
		frames : List(Animation.Instant(pose)),
		after : Animation.Instant(pose),
	}.{

		## The critter at `stage`. Only a progress of the whole way falls past
		## the last frame, and that is the rest after it.
		instant : Animation.Timeline(pose), Animation.Stage -> Animation.Instant(pose)
		instant = |Animation.Timeline.(timeline), stage|
			match stage {
				Waiting => timeline.before
				Playing(progress) =>
					match timeline.frames.get(frame_number(progress, timeline.frames.len())) {
						Ok(frame) => frame
						Err(OutOfBounds) => timeline.after
					}
				Past(_) => timeline.after
			}
	}
}

## Which of `count` frames `progress` has reached, counting from 0. A progress
## meant to land on the start of a frame can come out a rounding error short of
## it, so a billionth of a frame counts as having arrived.
frame_number : Fraction, U64 -> U64
frame_number = |progress, count| (progress.to_f64() * count.to_f64() + 0.000000001).to_u64_wrap()

## Whether each of `got` is within a billionth of its `want`.
is_near : List(F64), List(F64) -> Bool
is_near = |got, want| {
	closeness = got.map2(want, |one, wanted| (one - wanted).abs() <= 0.000000001)
	got.len() == want.len() and closeness.all(|is_close| is_close)
}

## A stage as numbers, so a table can hold each tag beside its payload: 0 for
## waiting, 1 and its progress for playing, 2 and its metres for past.
stage_numbers : Animation.Stage -> List(F64)
stage_numbers = |stage|
	match stage {
		Waiting => [0.0, 0.0]
		Playing(progress) => [1.0, progress.to_f64()]
		Past(beyond) => [2.0, beyond.to_metres()]
	}

gap_stage : F64 -> Animation.Stage
gap_stage = |gap|
	Animation.stage_over_gap(
		{ starts_at: Distance.metres(60.0), ends_at: Distance.metres(20.0) },
		{ gap: Distance.metres(gap) },
	)

expect
	[
		(61.0, [0.0, 0.0]),
		(60.0, [0.0, 0.0]),
		(59.0, [1.0, 0.025]),
		(40.0, [1.0, 0.5]),
		(21.0, [1.0, 0.975]),
		(20.0, [2.0, 0.0]),
		(19.0, [2.0, 1.0]),
	].all(|(gap, want)| is_near(stage_numbers(gap_stage(gap)), want))

beat_stage : F64, F64 -> Animation.Stage
beat_stage = |gap, speed|
	Animation.stage_over_step_span(
		{ length: Steps.of(10), ends_at: Distance.metres(3.0) },
		{ gap: Distance.metres(gap), speed: Speed.metres_a_step(speed) },
	)

expect
	[
		(beat_stage(14.0, 1.0), [0.0, 0.0]),
		(beat_stage(13.0, 1.0), [0.0, 0.0]),
		(beat_stage(12.0, 1.0), [1.0, 0.1]),
		(beat_stage(8.0, 1.0), [1.0, 0.5]),
		(beat_stage(4.0, 1.0), [1.0, 0.9]),
		(beat_stage(3.0, 1.0), [2.0, 0.0]),
		(beat_stage(1.0, 1.0), [2.0, 2.0]),
		(beat_stage(23.0, 2.0), [0.0, 0.0]),
		(beat_stage(21.0, 2.0), [1.0, 0.1]),
		(beat_stage(13.0, 2.0), [1.0, 0.5]),
	].all(|(stage, want)| is_near(stage_numbers(stage), want))

# A rider at rest is waiting short of the end and past it from there on, and
# one creeping is on the same rule as any other.
expect
	[
		(beat_stage(3.5, 0.0), [0.0, 0.0]),
		(beat_stage(3.0, 0.0), [2.0, 0.0]),
		(beat_stage(2.0, 0.0), [2.0, 1.0]),
		(beat_stage(3.000011, 0.000001), [0.0, 0.0]),
		(beat_stage(3.000001, 0.000002), [1.0, 0.95]),
		(beat_stage(2.0, 0.000001), [2.0, 1.0]),
	].all(|(stage, want)| is_near(stage_numbers(stage), want))

# The two rules answer alike at their ends: the same stage, whichever rule the
# same start and end come from.
expect
	[8.0, 7.0, 6.5, 5.0, 3.5, 3.0, 1.0].all(
		|gap| {
			start_and_end = { starts_at: Distance.metres(7.0), ends_at: Distance.metres(3.0) }
			approach = { gap: Distance.metres(gap), speed: Speed.metres_a_step(0.4) }
			rule_by_gap = Animation.stage_over_gap(start_and_end, approach)
			rule_by_steps = Animation.stage_over_step_span(
				{ length: Steps.of(10), ends_at: Distance.metres(3.0) },
				approach,
			)
			is_near(stage_numbers(rule_by_gap), stage_numbers(rule_by_steps))
		},
	)

Note : [First, Second, Third, Fourth, BeforeIt, AfterIt]

spot_at : F64 -> Animation.Spot
spot_at = |across| {
	along: Along.metres(0.0),
	across: Across.metres(across),
	lift: Distance.zero,
}

## A timeline of four frames.
four_frames : Animation.Timeline(Note)
four_frames = Animation.Timeline.(
	{
		before: { pose: BeforeIt, spot: spot_at(-1.0) },
		frames: [
			{ pose: First, spot: spot_at(1.0) },
			{ pose: Second, spot: spot_at(2.0) },
			{ pose: Third, spot: spot_at(3.0) },
			{ pose: Fourth, spot: spot_at(4.0) },
		],
		after: { pose: AfterIt, spot: spot_at(99.0) },
	},
)

# Each frame holds a quarter of the animation, from its own start, and a
# progress of the whole way is the rest after the last.
expect
	[
		(0.0, First),
		(0.2499, First),
		(0.25, Second),
		(0.4999, Second),
		(0.5, Third),
		(0.75, Fourth),
		(0.9999, Fourth),
		(1.0, AfterIt),
	].all(|(progress, note)| four_frames.instant(Playing(Fraction.of(progress))).pose == note)

# A progress a rounding error short of a frame's start has reached it.
expect four_frames.instant(Playing(Fraction.of(0.25 - 0.0000000000001))).pose == Second

expect four_frames.instant(Waiting).pose == BeforeIt
expect four_frames.instant(Past(Distance.metres(5.0))).pose == AfterIt
expect four_frames.instant(Waiting).spot.across.to_metres() == -1.0
expect four_frames.instant(Playing(Fraction.of(0.5))).spot.across.to_metres() == 3.0
expect four_frames.instant(Past(Distance.metres(5.0))).spot.across.to_metres() == 99.0

## A timeline with no frames at all.
empty_timeline : Animation.Timeline(Note)
empty_timeline = Animation.Timeline.(
	{
		before: { pose: BeforeIt, spot: spot_at(0.0) },
		frames: [],
		after: { pose: AfterIt, spot: spot_at(0.0) },
	},
)

expect empty_timeline.instant(Playing(Fraction.zero)).pose == AfterIt

start_spot : Animation.Spot
start_spot = {
	along: Along.metres(10.0),
	across: Across.metres(20.0),
	lift: Distance.metres(30.0),
}

end_spot : Animation.Spot
end_spot = {
	along: Along.metres(18.0),
	across: Across.metres(4.0),
	lift: Distance.metres(46.0),
}

## The spot's three parts, `fraction` of the way from `start_spot` to `end_spot`.
spot_numbers : F64 -> List(F64)
spot_numbers = |fraction| {
	spot = Animation.spot_between({
		from: start_spot,
		to: end_spot,
		fraction: Fraction.of(fraction),
	})
	[spot.along.to_metres(), spot.across.to_metres(), spot.lift.to_metres()]
}

expect
	[
		(0.0, [10.0, 20.0, 30.0]),
		(0.25, [12.0, 16.0, 34.0]),
		(1.0, [18.0, 4.0, 46.0]),
	].all(|(fraction, want)| is_near(spot_numbers(fraction), want))
