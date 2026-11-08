## The ride's plan for the encounter on the rider's segment: when its animation
## starts, and so where it has got to. An encounter's animation runs on its own
## clock, a frame a step from the step it starts at, and never looks at the
## rider. The ride picks that step once, when the rider first comes within
## reach, from how the rider is coming then, so that the animation ends as the
## rider arrives. A `Timing` says where the animation has got to as an
## `Animation.Stage`, which the animal's timeline turns into what it shows.
import Animation
import Clock
import Distance
import Speed
import Steps

## When the encounter on the rider's segment starts: not planned yet, or at a
## step of the ride's clock. The ride keeps one, and forgets it at each new
## segment, since only the encounter on the rider's own segment is ever live.
EncounterPlan := [Unplanned, StartsAt(Clock)].{

	is_eq : _

	## Where an encounter's clock stands: not planned yet, or planned to start
	## at `first_step`, with the ride's clock at `now`.
	Timing : [Unplanned, Planned({ first_step : Clock, now : Clock })]

	## The timing of the encounter `plan` starts, with the ride's clock at `now`.
	timing_at : EncounterPlan, Clock -> EncounterPlan.Timing
	timing_at = |plan, now|
		match plan {
			Unplanned => Unplanned
			StartsAt(first_step) => Planned({ first_step, now })
		}

	## How many steps an animation plays for, a frame a step, and the gap from
	## the rider to the animal it ends at.
	StepSpan : { length : Steps, ends_at : Distance }

	## How far from the animal an animation is planned for a rider at `speed`:
	## the gap it ends at, and the road the rider covers while it plays. A
	## faster rider has it planned farther off.
	planning_gap : EncounterPlan.StepSpan, Speed -> Distance
	planning_gap = |span, speed| span.ends_at.plus(speed.distance_in(span.length))

	## How the rider comes at the encounter on their segment: `gap` short of
	## its animal at `speed`, for an animation `span` long, or none on a quiet
	## road.
	Approach : [
		Approaching(
			{
				span : EncounterPlan.StepSpan,
				gap : Distance,
				speed : Speed,
			},
		),
		QuietRoad,
	]

	## The plan a step after `plan`, for a rider who has just come onto a new
	## segment or stayed on the same one, coming at its encounter by
	## `approach` with the ride's clock at `now`. A new segment forgets the
	## plan. A plan once made is kept, and an unplanned encounter is planned by
	## `plan_for`.
	plan_at_next_step : EncounterPlan,
	{
		segment_change : [SameSegment, NewSegment],
		approach : EncounterPlan.Approach,
		now : Clock,
	} -> EncounterPlan
	plan_at_next_step = |plan, { segment_change, approach, now }| {
		kept_plan =
			match segment_change {
				SameSegment => plan
				NewSegment => Unplanned
			}
		match kept_plan {
			StartsAt(_) => kept_plan
			Unplanned =>
				match approach {
					Approaching({ span, gap, speed }) =>
						plan_for(span, { gap, speed, now })
					QuietRoad => Unplanned
				}
		}
	}

	## The timing of an animation `span` long, for a rider `gap` short of its
	## animal, coming at a steady `speed` from `gap_at_start` at step 0 of the
	## ride's clock. It is planned by `plan_for`, on the first step that such a
	## rider comes within reach. The ride's rider is not steady, so on the ride
	## the same animation may start on another step.
	steady_approach_timing : EncounterPlan.StepSpan,
	{
		gap_at_start : Distance,
		speed : Speed,
		gap : Distance,
	} -> EncounterPlan.Timing
	steady_approach_timing = |span, { gap_at_start, speed, gap }| {
		now = Clock.start.plus(speed.steps_to_cover(gap_at_start.minus(gap)))
		var $step = Clock.start
		var $plan = Unplanned
		while $plan == Unplanned and !(now < $step) {
			$plan = plan_for(
				span,
				{
					gap: gap_at_start.minus(speed.distance_in($step.steps_since(Clock.start))),
					speed,
					now: $step,
				},
			)
			$step = $step.next()
		}
		EncounterPlan.timing_at($plan, now)
	}

	## Where an animation `length` steps long has got to at `timing`.
	stage_at : EncounterPlan.Timing, Steps -> Animation.Stage
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
}

## The start of an animation that is to end as the rider comes within
## `ends_at`, planned at `now` from how the rider comes then: `gap` from the
## animal, at `speed`. It starts now on the first step that a rider keeping
## their speed would arrive within its length, so a faster rider has it
## start farther off. Till then, and while the rider is at rest, it isn't
## planned. The plan looks at the rider's speed that once: after it, the
## animal doesn't care what the rider does.
##
## Planning on the step itself keeps the guess short, an animation's length
## ahead. A plan from farther off would take the speed to be steady for
## longer, and a rider speeding up meanwhile would arrive before the end.
plan_for : EncounterPlan.StepSpan,
{
	gap : Distance,
	speed : Speed,
	now : Clock,
} -> EncounterPlan
plan_for = |span, { gap, speed, now }|
	if speed == Speed.at_rest {
		Unplanned
	} else if gap <= EncounterPlan.planning_gap(span, speed) {
		StartsAt(now)
	} else {
		Unplanned
	}

## A span of 10 steps that ends 3 m short of the animal.
ten_step_span : EncounterPlan.StepSpan
ten_step_span = { length: Steps.of(10), ends_at: Distance.metres(3.0) }

## The start a rider `gap` metres off at `speed` metres a step plans at step 100.
planned_at : F64, F64 -> EncounterPlan
planned_at = |gap, speed|
	plan_for(
		ten_step_span,
		{
			gap: Distance.metres(gap),
			speed: Speed.metres_a_step(speed),
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

# At 2.5 m a step the plan is made 3 + 2.5 × 10 = 28 m off.
expect EncounterPlan.planning_gap(ten_step_span, Speed.metres_a_step(2.5)) == Distance.metres(28.0)
expect planned_at(28.0, 2.5) == StartsAt(Clock.at_step(100))

## A rider 8 m off the animal at 1 m a step, whom `plan_for` plans for at
## step 100.
near_approach : EncounterPlan.Approach
near_approach = Approaching({
	span: ten_step_span,
	gap: Distance.metres(8.0),
	speed: Speed.metres_a_step(1.0),
})

## The plan a step after `plan`, at step 100, for a rider on the same segment
## with `approach`.
plan_on_same_segment : EncounterPlan, EncounterPlan.Approach -> EncounterPlan
plan_on_same_segment = |plan, approach|
	EncounterPlan.plan_at_next_step(
		plan,
		{
			segment_change: SameSegment,
			approach,
			now: Clock.at_step(100),
		},
	)

## The plan a step after `plan`, at step 100, for a rider just come onto a new
## segment with `approach`.
plan_on_new_segment : EncounterPlan, EncounterPlan.Approach -> EncounterPlan
plan_on_new_segment = |plan, approach|
	EncounterPlan.plan_at_next_step(
		plan,
		{
			segment_change: NewSegment,
			approach,
			now: Clock.at_step(100),
		},
	)

## A plan made at step 40.
made_plan : EncounterPlan
made_plan = StartsAt(Clock.at_step(40))

# A plan once made is kept on its segment, and forgotten at a new one, where
# the new encounter is planned afresh.
expect plan_on_same_segment(made_plan, near_approach) == made_plan
expect plan_on_same_segment(made_plan, QuietRoad) == made_plan
expect plan_on_new_segment(made_plan, near_approach) == StartsAt(Clock.at_step(100))
expect plan_on_new_segment(made_plan, QuietRoad) == Unplanned
expect plan_on_same_segment(Unplanned, near_approach) == StartsAt(Clock.at_step(100))
expect plan_on_same_segment(Unplanned, QuietRoad) == Unplanned

## The stage at step `now` of a 10-step animation starting at step 50.
stage_now : U32 -> Animation.Stage
stage_now = |now|
	EncounterPlan.stage_at(
		EncounterPlan.timing_at(StartsAt(Clock.at_step(50)), Clock.at_step(now)),
		Steps.of(10),
	)

expect stage_now(49) == Waiting
expect stage_now(50) == Playing(Steps.zero)
expect stage_now(59) == Playing(Steps.of(9))
expect stage_now(60) == Past(Steps.zero)
expect stage_now(65) == Past(Steps.of(5))
expect EncounterPlan.stage_at(
	EncounterPlan.timing_at(Unplanned, Clock.at_step(60)),
	Steps.of(10),
) == Waiting
