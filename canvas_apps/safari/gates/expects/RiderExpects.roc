## RiderExpects holds the expects of the rider: the heading, the lens and
## attention, the throttle, coasting, gawking and the gaze.

import Fixtures
import game.Across
import game.Along
import game.Angle
import game.Billboard
import game.Clock
import game.Coast
import game.Distance
import game.EncounterPlan
import game.EncounterReaction
import game.Fraction
import game.Gawking
import game.Gaze
import game.Geom
import game.LeanSearch
import game.Lens
import game.Motorcycle
import game.Pixels
import game.RideInstant
import game.RiderCamera
import game.Rider
import game.Route
import game.Segment
import game.Speed
import game.Steps
import game.Throttle
import game.Tour
import game.VehicleLimits
import game.World

RiderExpects :: [].{}

## A rider on the segment at `segment`, turned `yaw` from its axis, leaning
## `lean` and looking `gaze_yaw` from the way the motorcycle points.
rider_facing : {
	segment : U32,
	yaw : Angle.Turn,
	lean : Angle.Lean,
	gaze_yaw : Angle.Turn,
} -> Rider
rider_facing = |{ segment, yaw, lean, gaze_yaw }| {
	..Rider.initial,
	motorcycle: {
		..Rider.initial.motorcycle,
		route_place: {
			..Rider.initial.motorcycle.route_place,
			segment_index: Route.SegmentIndex.number(segment),
		},
		yaw,
		lean,
	},
	eyes: { ..Rider.initial.eyes, gaze_yaw },
}

# The camera's heading is the bearing the rider's segment sets off on, turned by
# the motorcycle's yaw, the gaze and the lean (0.15 of it). The first two are on
# the first segment, which sets off north: a rider looking straight ahead faces
# north, and one turned 0.375 by the yaw, 0.375 by the gaze and 0.01875 by the
# lean faces 0.76875. The third is the second segment's bearing alone, the first
# bend's 50 degrees. The fourth is the long westward segment's bearing, minus
# 120 degrees, turned 0.05 left. The fifth is the last segment's bearing, turned
# 0.0125 right by a gaze to the right against a lean to the left.
expect
	[
		(
			{
				segment: 0,
				yaw: Angle.Turn.radians(0.0),
				lean: Angle.Lean.radians(0.0),
				gaze_yaw: Angle.Turn.radians(0.0),
			},
			0.0,
		),
		(
			{
				segment: 0,
				yaw: Angle.Turn.radians(0.375),
				lean: Angle.Lean.radians(0.125),
				gaze_yaw: Angle.Turn.radians(0.375),
			},
			0.76875,
		),
		(
			{
				segment: 1,
				yaw: Angle.Turn.radians(0.0),
				lean: Angle.Lean.radians(0.0),
				gaze_yaw: Angle.Turn.radians(0.0),
			},
			0.8726646259971648,
		),
		(
			{
				segment: Fixtures.longest_segment_index.to_u32(),
				yaw: Angle.Turn.radians(-0.25),
				lean: Angle.Lean.radians(0.5),
				gaze_yaw: Angle.Turn.radians(0.125),
			},
			-2.144395102393195,
		),
		(
			{
				segment: 18,
				yaw: Angle.Turn.radians(0.0),
				lean: Angle.Lean.radians(-0.75),
				gaze_yaw: Angle.Turn.radians(0.125),
			},
			-1.4710298641951802,
		),
	].all(
		|(facing, heading)| {
			camera = RiderCamera.of(
				rider_facing(facing),
				{ route: World.route, encounter_stage: Waiting },
			)
			camera.heading.to_radians() == heading
		},
	)

# Each segment's bearing is the one before it turned by the bend between them.
expect {
	first_turn = World.route.segment_at(Route.SegmentIndex.first).bend_out_of().turn
	World.route.bearing_of(Route.SegmentIndex.number(1)) == Angle.north.plus(first_turn)
		and first_turn != Angle.straight_ahead
}

# The camera's focal length: the view widens as the rider leans, and as the
# rider's attention is caught, by the cat on the road or by a look to the side.
## The focal length of the camera for `rider` on the cat route, before any
## encounter is planned.
focal_length_of : Rider -> Pixels
focal_length_of = |rider|
	RiderCamera.of(rider, { route: Fixtures.cat_route, encounter_stage: Waiting }).focal_length

## An encounter ten steps in.
ten_steps_in : EncounterPlan.Timing
ten_steps_in = EncounterPlan.timing_at(StartsAt(Clock.at_step(100)), Clock.at_step(110))

## The focal length of the camera for `rider` on the cat route, with the
## encounter on their segment ten steps in.
focal_length_ten_steps_in : Rider -> Pixels
focal_length_ten_steps_in = |rider| {
	segment = rider.motorcycle.route_place.segment_on(Fixtures.cat_route)
	RiderCamera.of(
		rider,
		{ route: Fixtures.cat_route, encounter_stage: segment.encounter_stage(ten_steps_in) },
	).focal_length
}

## A rider at the start of the first segment, upright and looking ahead.
upright : Rider
upright = Rider.initial

## An upright rider on the segment at `number`.
rider_on : U32 -> Rider
rider_on = |number| {
	..upright,
	motorcycle: {
		..upright.motorcycle,
		route_place: {
			..upright.motorcycle.route_place,
			segment_index: Route.SegmentIndex.number(number),
		},
	},
}

## The same rider leaning `lean`.
leaning = |rider, lean| { ..rider, motorcycle: { ..rider.motorcycle, lean } }

## The same rider as deep into a look as a rider goes.
looking_hard : Rider -> Rider
looking_hard = |rider| { ..rider, eyes: { ..rider.eyes, look_depth: Fraction.whole } }

## How strongly the encounter on this rider's segment, at `encounter_timing`, holds
## their attention.
encounter_attention_of : Rider, EncounterPlan.Timing -> F64
encounter_attention_of = |rider, encounter_timing| {
	segment = Fixtures.cat_route.segment_at(rider.motorcycle.route_place.segment_index)
	stage = segment.encounter_stage(encounter_timing)
	EncounterReaction.encounter_attention(segment, stage).to_f64()
}

expect focal_length_of(upright).minus(Lens.resting_focal_length) == Pixels.zero

focal_length_at_lean = |lean| focal_length_of(leaning(upright, lean))

no_lean = upright.motorcycle.lean

## The change from upright to the full lean.
full_change = Angle.LeanChange.degrees(20.0)

## The full lean, to the left.
full_left = no_lean.minus(full_change)

expect {
	half = no_lean.halfway_to(RiderCamera.full_lean)
	focal_length_at_lean(half) < focal_length_at_lean(no_lean)
		and focal_length_at_lean(RiderCamera.full_lean) < focal_length_at_lean(half)
		and focal_length_at_lean(full_left) < focal_length_at_lean(no_lean)
		and focal_length_at_lean(no_lean) <= Lens.resting_focal_length
}

# A lean past the greatest one widens the view no further.
expect focal_length_at_lean(RiderCamera.full_lean) == focal_length_at_lean(full_left)

expect {
	twice = RiderCamera.full_lean.plus(full_change)
	twice_change = Angle.LeanChange.degrees(40.0)
	ten_times = twice.plus(twice_change).plus(twice_change).plus(twice_change).plus(twice_change)
	at_full_lean = focal_length_at_lean(RiderCamera.full_lean)
	focal_length_at_lean(twice).minus(at_full_lean) == Pixels.zero
		and focal_length_at_lean(ten_times).minus(at_full_lean) == Pixels.zero
}

expect encounter_attention_of(rider_on(1), ten_steps_in) > 0.0
expect !(encounter_attention_of(rider_on(1), Unplanned) > 0.0)
expect !(encounter_attention_of(rider_on(0), ten_steps_in) > 0.0)
expect focal_length_ten_steps_in(rider_on(1)) < focal_length_ten_steps_in(rider_on(0))

# While a cat crosses, the rider eases off: the throttle holds the acceleration
# at none. Before the crossing it opens.
## The change of speed Throttle makes for a rider at the start of the world's
## cat segment, going 0.3 m a step, with its crossing at `encounter_timing`.
cat_throttle_change : EncounterPlan.Timing -> F64
cat_throttle_change = |encounter_timing| {
	motorcycle = {
		..Motorcycle.initial,
		route_place: {
			..Motorcycle.initial.route_place,
			segment_index: Route.SegmentIndex.number(3),
		},
		speed: Speed.metres_a_step(0.3),
	}
	throttle_change_at(motorcycle, encounter_timing)
}

## The change of speed Throttle makes for this motorcycle in a step on the real
## route, with its encounter at `encounter_timing`, held to the top speed, in
## metres a step each step.
throttle_change_at : Motorcycle, EncounterPlan.Timing -> F64
throttle_change_at = |motorcycle, encounter_timing| {
	segment = motorcycle.route_place.segment_on(World.route)
	acceleration = Throttle.next_acceleration(
		motorcycle,
		{ segment, encounter_stage: segment.encounter_stage(encounter_timing) },
	)
	next = motorcycle.motorcycle_at_next_step({ lean: motorcycle.lean, acceleration })
	next.speed.to_metres_a_step() - motorcycle.speed.to_metres_a_step()
}

expect cat_throttle_change(ten_steps_in) == 0.0
expect cat_throttle_change(Unplanned) > 0.0
expect {
	before_it = EncounterPlan.timing_at(StartsAt(Clock.at_step(100)), Clock.at_step(99))
	cat_throttle_change(before_it) > 0.0
}
expect focal_length_of(looking_hard(upright)) < focal_length_of(upright)
expect {
	half_look = { ..upright, eyes: { ..upright.eyes, look_depth: Fraction.of(0.5) } }
	focal_length_of(looking_hard(upright)) < focal_length_of(half_look)
}

focal_length_leaning_and_looking : Pixels
focal_length_leaning_and_looking = {
	leaning_hard = leaning(upright, RiderCamera.full_lean)
	focal_length_of(looking_hard(leaning_hard))
}

focal_length_leaning : Pixels
focal_length_leaning = focal_length_of(leaning(upright, RiderCamera.full_lean))

focal_length_looking : Pixels
focal_length_looking = focal_length_of(looking_hard(upright))

# A full lean and a hard look together widen the view as far as the wider of the
# two alone, and no further.
expect
	focal_length_leaning_and_looking.to_f64().to_bits()
		== focal_length_leaning.to_f64().min(focal_length_looking.to_f64()).to_bits()

# Coast's outcomes. Coast imports neither Angle nor Speed, which these need.

## The coast of a motorcycle at the start of the segment, going the base speed.
coast_of : F64, F64 -> Coast.Outcome
coast_of = |across, lean_radians|
	Coast.coast_outcome({
		..Motorcycle.initial,
		route_place: { ..Motorcycle.initial.route_place, across: Across.metres(across) },
		lean: Angle.Lean.radians(lean_radians),
	})

expect coast_of(3.0, 0.0) == EndsAt(Across.metres(3.0))
expect {
	resting = { ..Motorcycle.initial, speed: Speed.at_rest }
	Coast.coast_outcome(resting) == EndsAt(Across.metres(0.0))
}

# A rider this slow and this far over circles on the road, and the coast still ends.
expect {
	circling = Coast.coast_outcome({
		..Motorcycle.initial,
		speed: Speed.metres_a_step(0.01),
		lean: Angle.Lean.radians(0.5),
	})
	match circling {
		EndsAt(_) => True
		Leaves(_) => False
	}
}

# A coast's path has a motorcycle for each step it ran and ends where its
# outcome says, clear of the start when it stays on the road, and `coast_outcome`
# gives the same outcome without the path.
expect {
	state = {
		..Motorcycle.initial,
		yaw: Angle.Turn.radians(-1.5),
		speed: Speed.metres_a_step(0.7),
	}
	coast = Coast.coast_path(state)
	match coast.outcome {
		Leaves({ side: Left, after }) =>
			coast.path_motorcycles.len() == after.to_u32().to_u64()
				and coast.outcome == Coast.coast_outcome(state)
		Leaves({ side: Right, .. }) | EndsAt(_) => False
	}
}
expect {
	state = {
		..Motorcycle.initial,
		route_place: { ..Motorcycle.initial.route_place, across: Across.metres(1.0) },
	}
	coast = Coast.coast_path(state)
	match (coast.outcome, coast.path_motorcycles.last()) {
		(EndsAt(end_across), Ok(last)) => {
			travelled = last.route_place.along.distance_from(state.route_place.along)
			last.route_place.across == end_across
				and travelled >= Coast.clear_distance
				and coast.outcome == Coast.coast_outcome(state)
		}
		(Leaves(_), _) | (EndsAt(_), Err(_)) => False
	}
}

## How many steps a coast runs before it leaves the road.
steps_off_road : Coast.Outcome -> Steps
steps_off_road = |coast|
	match coast {
		Leaves({ after, .. }) => after
		EndsAt(_) => crash "RiderExpects: this coast stays on the road"
	}

# A lean to the right coasts off the right shoulder, and the same lean to the
# left coasts off the left one in as many steps.
expect {
	right_lean = coast_of(0.0, 0.2)
	left_lean = coast_of(0.0, -0.2)
	right_lean == Leaves({ side: Right, after: steps_off_road(right_lean) })
		and left_lean == Leaves({ side: Left, after: steps_off_road(left_lean) })
		and steps_off_road(right_lean) == steps_off_road(left_lean)
}

## The change of speed Throttle makes for a motorcycle on the first segment far
## off to the right, leaning `lean`.
wide_of_road : F64 -> F64
wide_of_road = |lean| {
	motorcycle = {
		..Motorcycle.initial,
		route_place: { ..Motorcycle.initial.route_place, across: Across.metres(100.0) },
		lean: Angle.Lean.radians(lean),
	}
	throttle_change(motorcycle)
}

# A rider far off to the right, whose coast crosses no shoulder, opens the
# throttle however far they lean. Each is within 1e-12 of its want.
expect [-0.001, -0.035, -0.535].all(|lean| (wide_of_road(lean) - 0.01).abs() <= 0.000000000001)

# Throttle's decisions on the real route, through Throttle.next_acceleration. Throttle
# imports neither World nor Angle, which these need.

## A motorcycle on the middle of the road, upright, `along` metres down the
## real route's first segment, going `speed` metres a step.
centered_motorcycle : F64, F64 -> Motorcycle
centered_motorcycle = |along, speed| {
	..Motorcycle.initial,
	route_place: { ..Motorcycle.initial.route_place, along: Along.metres(along) },
	speed: Speed.metres_a_step(speed),
}

## The same motorcycle on the real route's segment `index`.
with_segment : Motorcycle, U32 -> Motorcycle
with_segment = |motorcycle, index| {
	..motorcycle,
	route_place: { ..motorcycle.route_place, segment_index: Route.SegmentIndex.number(index) },
}

## The change of speed Throttle makes for this motorcycle on the real route,
## before its encounter is planned, in metres a step each step.
throttle_change : Motorcycle -> F64
throttle_change = |motorcycle| {
	throttle_change_at(motorcycle, Unplanned)
}

# The rider brakes for the bend from 60 m short of the segment's end, and not a
# centimetre sooner.
expect throttle_change(centered_motorcycle(439.9, 0.3)) > 0.0
expect throttle_change(centered_motorcycle(440.0, 0.3)) < 0.0

# Past the commit point there is no road left to brake on, and the throttle holds
# the acceleration at none.
expect [498.4, 600.0].all(|along| throttle_change(centered_motorcycle(along, 0.3)) == 0.0)

# Short of the commit point a faster rider brakes harder.
expect {
	fast_brake = throttle_change(centered_motorcycle(460.0, 2.0))
	fast_brake < throttle_change(centered_motorcycle(460.0, 0.3))
}

# A rider already at the first bend's speed of 0.222 holds it into the bend. On
# the last segment, which ends the route, the same rider brakes to rest, but not
# before the approach.
expect throttle_change(centered_motorcycle(460.0, 0.222)) == 0.0
expect throttle_change(with_segment(centered_motorcycle(260.0, 0.222), 18)) < 0.0
expect throttle_change(with_segment(centered_motorcycle(200.0, 0.222), 18)) > 0.0

## The change at the start of the first segment, going `speed` and leaning
## `lean` radians.
change_leaning : Speed, F64 -> F64
change_leaning = |speed, lean|
	throttle_change({ ..Motorcycle.initial, speed, lean: Angle.Lean.radians(lean) })

# Each is within 1e-12 of its want.
expect
	[
		(change_leaning(Speed.metres_a_step(0.3), 0.0), 0.01),
		(change_leaning(VehicleLimits.top_speed, 0.0), 0.0),
		(change_leaning(Speed.at_rest, 0.0), 0.01),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

# On the middle of the road, a lean that coasts off it brakes, either way, and a
# slight one speeds up.
expect change_leaning(Speed.metres_a_step(0.3), 0.034) < 0.0
expect change_leaning(Speed.metres_a_step(0.3), 0.001) > 0.0
expect change_leaning(Speed.metres_a_step(0.3), -0.034) < 0.0

## A motorcycle at the start of the first segment, steering hard left at
## `speed`.
off_left : F64 -> Motorcycle
off_left = |speed| { ..centered_motorcycle(0.0, speed), yaw: Angle.Turn.radians(-1.5) }

# Its coast leaves the road on the third step, and the throttle gives it the
# shoulder brake for three steps at 0.7 m a step, within 1e-12.
expect Coast.coast_outcome(off_left(0.7)) == Leaves({ side: Left, after: Steps.of(3) })
expect (throttle_change(off_left(0.7)) - -0.10041593058292341).abs() <= 0.000000000001

# A gawking rider brakes. On segment 2 the rider opens the throttle short of
# where its pig is noticed, and brakes past it; at the start of segment 3 nothing
# holds the rider back.
expect throttle_change(with_segment(centered_motorcycle(0.0, 0.3), 3)) > 0.0
expect throttle_change(with_segment(centered_motorcycle(100.0, 0.3), 2)) > 0.0
expect throttle_change(with_segment(centered_motorcycle(300.0, 0.3), 2)) < 0.0

## A segment with no pigs.
pigless_segment : Segment
pigless_segment = Fixtures.segment_of([])

## The route's first segment with a herd the rider finds distracting.
distracting_segment : Segment
distracting_segment = World.first_distracting_segment

expect Gaze.eye_catching_pig(pigless_segment) == NoPigCatchesEye

## A segment of the route whose herd the rider passes by.
passed_by_segment : Segment
passed_by_segment = World.route.segment_at(Route.SegmentIndex.number(11))

expect Gaze.eye_catching_pig(passed_by_segment) == NoPigCatchesEye

## The pig that catches the eye on the distracting segment.
watched_pig : Geom.Placed(Billboard)
watched_pig =
	match Gaze.eye_catching_pig(distracting_segment) {
		CatchesEye(pig) => pig
		NoPigCatchesEye => crash "RiderExpects: this segment's pigs catch the eye"
	}

# The rider watches a pig of the herd.
expect distracting_segment.segment_pigs().count_if(|pig| pig == watched_pig) == 1

## A motorcycle `along` metres into its segment, at rest in every other way.
motorcycle_at : F64 -> Motorcycle
motorcycle_at = |along| {
	..Motorcycle.initial,
	route_place: {
		..Motorcycle.initial.route_place,
		along: Motorcycle.initial.route_place.along.plus(Distance.metres(along)),
	},
}

## A motorcycle on the distracting segment, `metres` short of the pig.
short_of_pig : F64 -> Motorcycle
short_of_pig = |metres| {
	..Motorcycle.initial,
	route_place: {
		..Motorcycle.initial.route_place,
		along: watched_pig.road_point.along.minus(Distance.metres(metres)),
	},
}

expect !Gawking.is_gawking(motorcycle_at(200.0), pigless_segment)
expect !Gawking.is_gawking(motorcycle_at(100.0), distracting_segment)
expect Gawking.is_gawking(motorcycle_at(200.0), distracting_segment)
expect Gawking.is_gawking(motorcycle_at(341.0), distracting_segment)

# The gawking starts where the pig is noticed, and not a centimetre sooner.
expect Gawking.is_gawking(short_of_pig(Gaze.notice_distance.to_metres()), distracting_segment)
expect !Gawking.is_gawking(short_of_pig(150.01), distracting_segment)

expect Gawking.gawk_brake(motorcycle_at(200.0), pigless_segment) == NoLimit
expect Gawking.gawk_brake(motorcycle_at(100.0), distracting_segment) == NoLimit

## The brake for a motorcycle `metres` short of the pig, going `speed` metres a
## step.
brake_short_of_pig : F64, F64 -> F64
brake_short_of_pig = |metres, speed| {
	motorcycle = { ..short_of_pig(metres), speed: Speed.metres_a_step(speed) }
	match Gawking.gawk_brake(motorcycle, distracting_segment) {
		AtMost(brake) => brake.to_metres_a_step_each_step()
		NoLimit => crash "RiderExpects: this rider is gawking"
	}
}

# Each is within 1e-12 of its want. The brake works out the road left to the
# settle distance, until there's less than the least distance left.
expect
	[
		((125.0, 0.3), -0.00025),
		((75.0, 0.3), -0.0005),
		((27.0, 0.3), -0.0125),
		((26.0, 0.3), -0.025),
		((25.5, 0.3), -0.025),
		((0.0, 0.3), -0.025),
		((-10.0, 0.3), -0.025),
		((125.0, 0.2), 0.0),
		((125.0, 0.1), 0.00015),
	].all(
		|
			((metres, speed), want),
		| (brake_short_of_pig(metres, speed) - want).abs() <= 0.000000000001,
	)

## How far this motorcycle on the distracting segment wants to turn to the pig.
turn_to_pig : Motorcycle -> F64
turn_to_pig = |motorcycle|
	match Gaze.desired_gaze(motorcycle, distracting_segment) {
		OnPig(turn) => turn.to_radians()
		OnRoad => crash "RiderExpects: no pig in sight"
	}

expect {
	far = turn_to_pig(motorcycle_at(200.0))
	near = turn_to_pig(motorcycle_at(320.0))
	far > 0.0 and near > far
}

expect Gaze.desired_gaze(motorcycle_at(200.0), pigless_segment) == OnRoad
expect Gaze.desired_gaze(motorcycle_at(100.0), distracting_segment) == OnRoad

# The gawking outlasts the look: at 341 m the rider still gawks, but no longer
# looks.
expect Gaze.desired_gaze(motorcycle_at(341.0), distracting_segment) == OnRoad

## A motorcycle 100 m short of the pig, turned so the pig is `degrees` off.
motorcycle_with_pig_off : F64 -> Motorcycle
motorcycle_with_pig_off = |degrees| {
	straight = short_of_pig(100.0)
	turn_to_watched_pig = Angle.Turn.radians(
		F64.atan2({
			x: watched_pig.road_point.along.distance_from(straight.route_place.along).to_metres(),
			y: watched_pig.road_point.across.distance_from(straight.route_place.across).to_metres(),
		}),
	).minus(straight.yaw)
	{ ..straight, yaw: turn_to_watched_pig.minus(Angle.Turn.degrees(degrees)) }
}

## Whether this motorcycle's rider on the distracting segment wants to look at
## the pig.
is_looking : Motorcycle -> Bool
is_looking = |motorcycle|
	match Gaze.desired_gaze(motorcycle, distracting_segment) {
		OnPig(_) => True
		OnRoad => False
	}

# The pig stays in sight up to the release angle, on either side of the
# motorcycle.
expect
	[
		(34.99, True),
		(-34.99, True),
		(35.01, False),
		(-35.01, False),
	].all(|(degrees, is_in_sight)| is_looking(motorcycle_with_pig_off(degrees)) == is_in_sight)

# The first pig that catches the rider's eye, on the real ride. The gaze widget
# plays steps 860 to 1320, and the parked book's table quotes these steps.

## The real ride's instants up to step 1320, a little after the gaze is back on
## the road. As a constant it is ridden once, at compile time.
first_pig_instants : List(RideInstant)
first_pig_instants = {
	var $tour = Tour.initial
	var $instants = [$tour.instant()]
	for _ in 0..<1320 {
		$tour = Tour.step_forward($tour)
		$instants = $instants.append($tour.instant())
	}
	$instants
}

## The rider at `step` of the real ride.
rider_at_step : U32 -> Rider
rider_at_step = |step| {
	instant =
		first_pig_instants.get(step.to_u64())
			?? crash "RiderExpects.rider_at_step: the first pig's ride reaches step 1320"
	instant.rider
}

## How far `rider` looks from the way the motorcycle points, in degrees.
gaze_degrees_of : Rider -> F64
gaze_degrees_of = |rider| rider.eyes.gaze_yaw.to_degrees()

# The steps the table quotes, each with its speed in metres a step, its gaze_yaw
# in degrees and its look depth, to the table's precision.
expect
	[
		{
			step: 885,
			speed: 1.9357,
			gaze: 4.0,
			look_depth: 0.1143,
		},
		{
			step: 1049,
			speed: 0.2000,
			gaze: 34.9525,
			look_depth: 0.9986,
		},
		{
			step: 1050,
			speed: 0.2000,
			gaze: 34.7525,
			look_depth: 0.9986,
		},
		{
			step: 1224,
			speed: 0.2000,
			gaze: 0.0,
			look_depth: 0.9974,
		},
	].all(
		|{ step, speed, gaze, look_depth }| {
			rider = rider_at_step(step)
			(rider.motorcycle.speed.to_metres_a_step() - speed).abs() <= 0.00005
				and (gaze_degrees_of(rider) - gaze).abs() <= 0.00005
				and (rider.eyes.look_depth.to_f64() - look_depth).abs() <= 0.00005
		},
	)

## Whether the rider at `step` is gawking at the first pig.
is_gawking_at : U32 -> Bool
is_gawking_at = |step| Gawking.is_gawking(rider_at_step(step).motorcycle, distracting_segment)

## Whether the rider at `step` wants to look at the first pig.
is_looking_at : U32 -> Bool
is_looking_at = |step| is_looking(rider_at_step(step).motorcycle)

# Each phase starts at its step, and not one step before it. The gawking and the
# look start together at 885; the look lets go at 1050, while the gawking lasts to
# the segment's end; the gaze is home at 1224.
expect [860, 884].all(|step| !is_gawking_at(step) and !is_looking_at(step))
expect [885, 1049].all(|step| is_gawking_at(step) and is_looking_at(step))
expect [1050, 1223, 1224, 1320].all(|step| is_gawking_at(step) and !is_looking_at(step))
expect [1050, 1223].all(|step| rider_at_step(step).eyes.gaze_yaw != Angle.straight_ahead)
expect [1224, 1320].all(|step| rider_at_step(step).eyes.gaze_yaw == Angle.straight_ahead)

# The brake bites a step after the gawking starts.
expect {
	before = rider_at_step(884).motorcycle.speed
	first = rider_at_step(885).motorcycle.speed
	first > before and rider_at_step(886).motorcycle.speed < first
}

# The gaze is at its widest on the look's last step, and the look ends short of
# the release angle, because the next step would pass it.
expect {
	widest = gaze_degrees_of(rider_at_step(1049))
	first_pig_instants.drop_first(860).all(|instant| gaze_degrees_of(instant.rider) <= widest)
		and gaze_degrees_of(rider_at_step(1050)) < widest
		and gaze_degrees_of(rider_at_step(1048)) < widest
		and widest < Gaze.look_release_angle.to_degrees()
}

# A coast off the left shoulder means lean more right, and off the right more
# left.
expect LeanSearch.lean_correction(Leaves({ side: Left, after: Steps.one_step })) == MoreRight
expect LeanSearch.lean_correction(Leaves({ side: Right, after: Steps.one_step })) == MoreLeft
