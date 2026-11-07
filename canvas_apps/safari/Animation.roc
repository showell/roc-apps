## How a critter plays out on the ride. An encounter's animation runs on its own
## clock, a frame a step from the step it starts at, and never looks at the
## rider. The ride picks that step once, when the rider first comes within
## reach, from how the rider is coming then, so that the animation ends as the
## rider arrives. A `Timing` says where the animation has got to as a `Stage`,
## and a timeline turns a `Stage` into an `Instant`.
##
## A timeline is a list of frames, each a pose and a location, so a critter's
## whole animation reads in one place. Nothing here plays a timeline but that lookup.
## The instants before and after are the timeline's own, because a critter can
## rest somewhere no frame ever reaches.
import Across
import Along
import Clock
import Distance
import Easing
import Fraction
import Geom
import Speed
import Steps
import VehicleLimits

Animation :: [].{

	## How the rider comes on a thing: the gap from the rider ahead to it, and
	## the rider's speed.
	Approach : { gap : Distance, speed : Speed }

	## When the encounter on the rider's segment starts: not planned yet, or at
	## a step of the ride's clock. The ride keeps one, and forgets it at each new
	## segment, since only the encounter on the rider's own segment is ever live.
	Start : [Unplanned, StartsAt(Clock)]

	## Where an encounter's clock stands: not planned yet, or planned to start
	## at `first_step`, with the ride's clock at `now`.
	Timing : [Unplanned, Planned({ first_step : Clock, now : Clock })]

	## The timing of an encounter that starts at `start`, with the ride's clock
	## at `now`.
	timing_of : Animation.Start, Clock -> Animation.Timing
	timing_of = |start, now|
		match start {
			Unplanned => Unplanned
			StartsAt(first_step) => Planned({ first_step, now })
		}

	## Where an animation has got to: not begun, playing and this many steps in,
	## which is the frame it shows, or over this many steps ago.
	Stage : [Waiting, Playing(Steps), Past(Steps)]

	## How many steps an animation plays for, a frame a step, and the gap from
	## the rider to the critter it ends at.
	StepSpan : { length : Steps, ends_at : Distance }

	## How far from the critter an animation is planned for the fastest rider,
	## who covers the most road while it plays. No plan is made farther off.
	farthest_planning_gap : Animation.StepSpan -> Distance
	farthest_planning_gap = |span|
		span.ends_at.plus(VehicleLimits.top_speed.distance_in(span.length))

	## The start of an animation that is to end as the rider comes within
	## `ends_at`, planned at `now` from how the rider comes then. It starts now
	## on the first step that a rider keeping their speed would arrive within
	## its length, so a faster rider has it start farther off. Till then, and
	## while the rider is at rest, it isn't planned. The plan looks at the
	## rider's speed that once: after it, the critter doesn't care what the
	## rider does.
	##
	## Planning on the step itself keeps the guess short, an animation's length
	## ahead. A plan from farther off would take the speed to be steady for
	## longer, and a rider speeding up meanwhile would arrive before the end.
	planned_start : Animation.StepSpan,
	{
		approach : Animation.Approach,
		now : Clock,
	} -> Animation.Start
	planned_start = |{ length, ends_at }, { approach, now }|
		if approach.speed == Speed.at_rest {
			Unplanned
		} else if approach.gap <= ends_at.plus(approach.speed.distance_in(length)) {
			StartsAt(now)
		} else {
			Unplanned
		}

	## Where an animation `length` steps long has got to at `timing`.
	stage_at : Animation.Timing, Steps -> Animation.Stage
	stage_at = |timing, length|
		match timing {
			Unplanned => Waiting
			Planned({ first_step, now }) => {
				end = first_step.plus(length)
				if now < first_step {
					Waiting
				} else if now < end {
					Playing(now.steps_since(first_step))
				} else {
					Past(now.steps_since(end))
				}
			}
		}

	## Where a critter is: a place on its segment, and how high it is off the
	## ground.
	Location : {
		along : Along,
		across : Across,
		lift : Distance,
	}

	## The location `fraction` of the way from `from` to `to`, in a straight line.
	location_between : {
		from : Animation.Location,
		to : Animation.Location,
		fraction : Fraction,
	} -> Animation.Location
	location_between = |{ from, to, fraction }| {
		between = |start, end| Easing.lerp({ from: start, to: end, fraction })
		{
			along: Along.metres(between(from.along.to_metres(), to.along.to_metres())),
			across: Across.metres(between(from.across.to_metres(), to.across.to_metres())),
			lift: Distance.metres(between(from.lift.to_metres(), to.lift.to_metres())),
		}
	}

	## A critter at one instant: how it looks, and where it is.
	Instant(pose) : { pose : pose, location : Animation.Location }

	## `instant` as an object on the road: it stands at the instant's location,
	## and its kind is the instant's pose.
	placed_instant : Animation.Instant(pose) -> Geom.Placed({ pose : pose })
	placed_instant = |{ pose, location }| {
		road_point: { along: location.along, across: location.across },
		lift: location.lift,
		kind: { pose: pose },
	}

	## A whole animation: the critter at rest before, the frames it plays through,
	## one a step, and the critter at rest after.
	Timeline(pose) := {
		before : Animation.Instant(pose),
		frames : List(Animation.Instant(pose)),
		after : Animation.Instant(pose),
	}.{

		## The critter at `stage`. A stage past the last frame is the rest after it.
		instant : Animation.Timeline(pose), Animation.Stage -> Animation.Instant(pose)
		instant = |Animation.Timeline.(timeline), stage|
			match stage {
				Waiting => timeline.before
				Playing(steps_in) =>
					match timeline.frames.get(steps_in.to_u32().to_u64()) {
						Ok(frame) => frame
						Err(OutOfBounds) => timeline.after
					}
				Past(_) => timeline.after
			}
	}
}

## A span of 10 steps that ends 3 m short of the critter.
ten_step_span : Animation.StepSpan
ten_step_span = { length: Steps.of(10), ends_at: Distance.metres(3.0) }

## The start a rider `gap` metres off at `speed` metres a step plans at step 100.
planned_at : F64, F64 -> Animation.Start
planned_at = |gap, speed|
	Animation.planned_start(
		ten_step_span,
		{
			approach: { gap: Distance.metres(gap), speed: Speed.metres_a_step(speed) },
			now: Clock.at_step(100),
		},
	)

# At 1 m a step the rider is 10 steps from the end 13 m off: the animation
# starts there and nearer, and not farther off. At 2 m a step that is 23 m off.
expect planned_at(13.0, 1.0) == StartsAt(Clock.at_step(100))
expect planned_at(13.1, 1.0) == Unplanned
expect planned_at(8.0, 1.0) == StartsAt(Clock.at_step(100))
expect planned_at(23.0, 2.0) == StartsAt(Clock.at_step(100))
expect planned_at(23.1, 2.0) == Unplanned

# A rider at rest plans nothing, however near.
expect planned_at(2.0, 0.0) == Unplanned

# The fastest rider plans farthest off: 3 + 2.5 × 10 = 28 m.
expect Animation.farthest_planning_gap(ten_step_span) == Distance.metres(28.0)
expect planned_at(28.0, 2.5) == StartsAt(Clock.at_step(100))

## The stage at step `now` of a 10-step animation starting at step 50.
stage_now : U32 -> Animation.Stage
stage_now = |now|
	Animation.stage_at(
		Animation.timing_of(StartsAt(Clock.at_step(50)), Clock.at_step(now)),
		Steps.of(10),
	)

expect stage_now(49) == Waiting
expect stage_now(50) == Playing(Steps.zero)
expect stage_now(59) == Playing(Steps.of(9))
expect stage_now(60) == Past(Steps.zero)
expect stage_now(65) == Past(Steps.of(5))
expect Animation.stage_at(
	Animation.timing_of(Unplanned, Clock.at_step(60)),
	Steps.of(10),
) == Waiting

## Whether each of `got` is within a billionth of its `expected`.
is_near : List(F64), List(F64) -> Bool
is_near = |got, expected| {
	closeness = got.map2(expected, |one, wanted| (one - wanted).abs() <= 0.000000001)
	got.len() == expected.len() and closeness.all(|is_close| is_close)
}

Note : [First, Second, Third, Fourth, BeforeIt, AfterIt]

sideways_location : F64 -> Animation.Location
sideways_location = |across| {
	along: Along.metres(0.0),
	across: Across.metres(across),
	lift: Distance.zero,
}

## A timeline of four frames.
four_frames : Animation.Timeline(Note)
four_frames = Animation.Timeline.(
	{
		before: { pose: BeforeIt, location: sideways_location(-1.0) },
		frames: [
			{ pose: First, location: sideways_location(1.0) },
			{ pose: Second, location: sideways_location(2.0) },
			{ pose: Third, location: sideways_location(3.0) },
			{ pose: Fourth, location: sideways_location(4.0) },
		],
		after: { pose: AfterIt, location: sideways_location(99.0) },
	},
)

# Each step in shows its own frame, and a step past the last is the rest after.
expect
	[
		(0, First),
		(1, Second),
		(2, Third),
		(3, Fourth),
		(4, AfterIt),
	].all(|(steps_in, note)| four_frames.instant(Playing(Steps.of(steps_in))).pose == note)

expect four_frames.instant(Waiting).pose == BeforeIt
expect four_frames.instant(Past(Steps.of(5))).pose == AfterIt
expect four_frames.instant(Waiting).location.across.to_metres() == -1.0
expect four_frames.instant(Playing(Steps.of(2))).location.across.to_metres() == 3.0
expect four_frames.instant(Past(Steps.of(5))).location.across.to_metres() == 99.0

## A timeline with no frames at all.
empty_timeline : Animation.Timeline(Note)
empty_timeline = Animation.Timeline.(
	{
		before: { pose: BeforeIt, location: sideways_location(0.0) },
		frames: [],
		after: { pose: AfterIt, location: sideways_location(0.0) },
	},
)

expect empty_timeline.instant(Playing(Steps.zero)).pose == AfterIt

# A placed instant stands at the instant's location, and its kind is the pose.
expect {
	location = {
		along: Along.metres(3.0),
		across: Across.metres(-1.0),
		lift: Distance.metres(2.0),
	}
	Animation.placed_instant({ pose: First, location })
		== {
			road_point: { along: location.along, across: location.across },
			lift: location.lift,
			kind: { pose: First },
		}
}

start_location : Animation.Location
start_location = {
	along: Along.metres(10.0),
	across: Across.metres(20.0),
	lift: Distance.metres(30.0),
}

end_location : Animation.Location
end_location = {
	along: Along.metres(18.0),
	across: Across.metres(4.0),
	lift: Distance.metres(46.0),
}

## The location's three parts, `fraction` of the way from `start_location` to `end_location`.
location_numbers : F64 -> List(F64)
location_numbers = |fraction| {
	location = Animation.location_between({
		from: start_location,
		to: end_location,
		fraction: Fraction.of(fraction),
	})
	[location.along.to_metres(), location.across.to_metres(), location.lift.to_metres()]
}

expect
	[
		(0.0, [10.0, 20.0, 30.0]),
		(0.25, [12.0, 16.0, 34.0]),
		(1.0, [18.0, 4.0, 46.0]),
	].all(|(fraction, want)| is_near(location_numbers(fraction), want))
