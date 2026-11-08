## RideExpects holds the expects of the ride as a whole: its instants, its
## crossings, its finish, the sunset and the night, and its frames.

import Fixtures
import game.Across
import game.Along
import game.Angle
import game.Attention
import game.BirdFlight
import game.CatCrossing
import game.Clock
import game.Distance
import game.EncounterReaction
import game.FarHeight
import game.Fraction
import game.FrameView
import game.LitTruck
import game.Motorcycle
import game.RideInstant
import game.Rider
import game.Route
import game.Sky
import game.Skyline
import game.Speed
import game.Steps
import game.SunPath
import game.Tour
import game.World

RideExpects :: [].{}

## A ride on the last segment, past its end.
finished_ride : RideInstant
finished_ride = {
	rider: {
		motorcycle: {
			route_place: {
				segment_index: Route.SegmentIndex.number(last_segment_index),
				along: Along.metres(400.0),
				across: Across.metres(0.0),
			},
			yaw: Angle.Turn.radians(0.0),
			speed: Speed.at_rest,
			lean: Angle.Lean.radians(0.0),
		},
		eyes: { gaze_yaw: Angle.Turn.radians(0.0), look_depth: Fraction.of(0.9) },
	},
	truck: {
		route_position: Distance.metres(9000.0),
		speed: Speed.metres_a_step(2.0),
		pace: Slowing,
	},
	clock: Clock.at_step(12345),
	encounter_start: StartsAt(Clock.at_step(12300)),
}

## The world's ride a step on from `instant`, whether it went on or restarted.
instant_after : RideInstant -> RideInstant
instant_after = |instant|
	match RideInstant.next_or_restart(World.route, instant) {
		Continued(next) | Restarted(next) => next
	}

## The segment the rider of `instant` is on.
rider_segment_index : RideInstant -> Route.SegmentIndex
rider_segment_index = |instant| instant.rider.motorcycle.route_place.segment_index

## How far along their segment the rider of `instant` is.
rider_along : RideInstant -> Along
rider_along = |instant| instant.rider.motorcycle.route_place.along

# A ride that has finished starts again.
expect
	match RideInstant.next_or_restart(World.route, finished_ride) {
		Restarted(instant) => {
			initial = RideInstant.initial
			instant.clock == initial.clock
				and instant.rider.motorcycle.route_place == initial.rider.motorcycle.route_place
				and instant.rider.motorcycle.speed == initial.rider.motorcycle.speed
				and instant.rider.eyes.look_depth == initial.rider.eyes.look_depth
				and instant.truck.route_position == initial.truck.route_position
				and instant.truck.pace == initial.truck.pace
				and instant.encounter_start == initial.encounter_start
		}
		Continued(_) => False
	}

expect
	match RideInstant.next_or_restart(World.route, RideInstant.initial) {
		Continued(_) => True
		Restarted(_) => False
	}

# The gaze is home at each of the ride's crossings, and it did leave home. The
# bike doesn't turn at a seam, and `gaze_yaw` is measured from the bike, so a
# crossing carries the gaze over and it has no need to be reset.
expect {
	var $instant = RideInstant.initial
	var $crossings = 0
	var $is_home_at_each = True
	var $has_looked = False
	while !$instant.rider.is_finished(World.route) {
		next = instant_after($instant)
		if rider_segment_index(next) != rider_segment_index($instant) {
			$crossings = $crossings + 1
			is_home = $instant.rider.eyes.gaze_yaw == Angle.straight_ahead
			$is_home_at_each = $is_home_at_each and is_home
		}
		$has_looked = $has_looked or next.rider.eyes.gaze_yaw != Angle.straight_ahead
		$instant = next
	}
	$crossings == 18 and $is_home_at_each and $has_looked
}

# A ride that hasn't finished steps on: the clock by a step, the rider and the
# truck forward.
ride_at_step_one : RideInstant
ride_at_step_one = instant_after(RideInstant.initial)

expect ride_at_step_one.clock == Clock.at_step(1)
expect rider_along(ride_at_step_one) > rider_along(RideInstant.initial)
expect ride_at_step_one.truck.route_position > RideInstant.initial.truck.route_position

## A rider on the middle of the road at the starting speed, `along` metres down
## segment `index` of the route.
placed_rider : U32, F64 -> Rider
placed_rider = |index, along| {
	..Rider.initial,
	motorcycle: {
		..Motorcycle.initial,
		route_place: {
			..Motorcycle.initial.route_place,
			segment_index: Route.SegmentIndex.number(index),
			along: Along.metres(along),
		},
	},
}

## The route's last segment, which ends the route.
last_segment_index : U32
last_segment_index = 18

# The ride is finished once the rider reaches the end of the last segment, and
# not before, nor anywhere on a segment that bends into another.
expect placed_rider(last_segment_index, 300.0).is_finished(World.route)
expect !placed_rider(last_segment_index, 299.0).is_finished(World.route)
expect !placed_rider(0, 499.0).is_finished(World.route)

## That rider a step on.
rider_a_step_after : U32, F64 -> Rider
rider_a_step_after = |index, along|
	placed_rider(index, along).next({ route: World.route, encounter_timing: Unplanned })

# A rider near the first bend crosses onto the next segment's road, and one well
# short of it, which the bend would carry far off that road, stays.
expect {
	crossed = rider_a_step_after(0, 499.0).motorcycle.route_place
	crossed.segment_index == Route.SegmentIndex.number(1)
}
expect {
	stayed = rider_a_step_after(0, 100.0).motorcycle.route_place
	stayed.segment_index == Route.SegmentIndex.number(0)
}

# The ride ends stopped dead at the route's end, and a step short of the end
# leaves the rider moving.
expect {
	stopped = ride_at_finish.rider.motorcycle
	stopped.route_place.along.to_metres() == 300.0 and stopped.speed == Speed.at_rest
}
expect {
	short = rider_a_step_after(last_segment_index, 290.0).motorcycle
	short.route_place.along.to_metres() < 300.0 and short.speed > Speed.at_rest
}

## A motorcycle just short of the first bend, a little off the middle and
## turned a little from the segment's axis.
motorcycle_at_first_seam : Motorcycle
motorcycle_at_first_seam = {
	route_place: {
		..Motorcycle.initial.route_place,
		along: Along.metres(499.0),
		across: Across.metres(0.5),
	},
	yaw: Angle.Turn.radians(0.1),
	speed: Speed.metres_a_step(1.25),
	lean: Angle.Lean.radians(0.05),
}

# The crossing keeps the motorcycle's bearing in the world: the yaw turns back
# by the bend that turns the next segment's bearing. The two sums round apart,
# by no more than a float's last bits.
expect {
	first = Route.SegmentIndex.first
	at_seam = motorcycle_at_first_seam
	on_next = at_seam.cross_bend_if_on_road(World.route.segment_at(first).bend_out_of())
	before = World.route.bearing_of(first).plus(at_seam.yaw)
	after = World.route.bearing_of(first.next()).plus(on_next.yaw)
	after.turn_from(before).abs() < Angle.Turn.radians(0.000000000001)
}

# A tour can be ridden right up to the step the ride finishes at. A step past it
# crashes, since the ride starts again before reaching it.
expect {
	var $tour = Tour.initial
	while !$tour.instant().rider.is_finished($tour.route()) {
		$tour = Tour.step_forward($tour)
	}
	finish = $tour.instant().clock
	Tour.at_step(finish.steps_since(Clock.start).to_u32()).instant().clock == finish
}

# The sun's disc is not yet wholly set a step before `fully_set_at`, and the sky
# is lighter than when it is.
expect {
	step_before_set = SunPath.fully_set_at.minus(Steps.one_step)
	SunPath.height_at(step_before_set) > SunPath.height_when_set
		and Sky.darkness_at(step_before_set) < Sky.darkness_at(SunPath.fully_set_at)
}

## The first step of the ride at which `holds` holds.
first_step_where : (Clock -> Bool) -> Clock
first_step_where = |holds| {
	var $clock = Clock.start
	while !holds($clock) {
		$clock = $clock.next()
	}
	$clock
}

## Whether the truck's headlights are on at `clock`.
headlights_on : Clock -> Bool
headlights_on = |clock| {
	lit_truck = LitTruck.at(NotSlowing, Sky.darkness_at(clock))
	lit_truck == { headlights: On, brake_lights: Off }
}

# The headlights come on at step 3,555, the first step the sun is behind the
# mountains, and are off the step before. Their threshold was measured to keep
# that step, so this holds the threshold and the step together.
expect {
	onset = Clock.at_step(3555)
	headlights_on(onset)
		and !headlights_on(onset.minus(Steps.one_step))
		and first_step_where(is_sun_behind_mountains) == onset
}

## The skyline's height at `bearing`: the highest of the land and the two
## ranges. Only the ride's timing asks for it: the ride draws each range on
## its own.
skyline_height : Angle.Bearing -> FarHeight
skyline_height = |bearing| {
	north_or_land = Skyline.north_range_height(bearing).max(Skyline.land_height(bearing))
	Skyline.west_range_height(bearing).max(north_or_land)
}

## Whether the sun, at `clock`, has sunk behind the skyline.
is_sun_behind_mountains : Clock -> Bool
is_sun_behind_mountains = |clock| {
	sun = SunPath.direction_at(clock)
	sun.height.plus(SunPath.radius) < skyline_height(sun.bearing)
}

expect !is_sun_behind_mountains(Clock.at_step(0))
expect is_sun_behind_mountains(Clock.at_step(6000))

## The climax of the sunset: the step the sun's lower edge meets the west range,
## where the sun starts to set on screen. The range stands above the horizon at
## the sun's bearing, so the sun's touching the horizon is never seen. The sun's
## top sinks behind the range at the first step the sun is behind it, which says
## how high the range stands there, and the lower edge meets it a diameter
## higher.
sunset_climax : Clock
sunset_climax = {
	hidden_at = first_step_where(is_sun_behind_mountains)
	range_top = SunPath.height_at(hidden_at).plus(SunPath.radius)
	first_step_where(|clock| SunPath.height_at(clock).minus(SunPath.radius) < range_top)
}

## How many steps before and after the sunset's climax the rider must be on the
## long westward segment: 150, a few hundred metres of road, so the rider sees
## the sun come down onto the range from the straight and watches it start to
## sink.
sunset_margin : Steps
sunset_margin = Steps.of(150)

# The route's longest segment, as the rider enters it, heads within 20° of the
# sun at the sunset's climax.
expect {
	bearing = World.route.bearing_of(Fixtures.longest_segment_index)
	SunPath.bearing_at(sunset_climax).turn_from(bearing).abs() < Angle.Turn.degrees(20.0)
}

# Steve's rule: the climax of the sunset happens on the really long road segment
# that heads west. The ride is ridden to `sunset_margin` steps past the climax,
# and the rider is on that segment from `sunset_margin` steps before it.
expect {
	from = sunset_climax.minus(sunset_margin)
	until = sunset_climax.plus(sunset_margin)
	var $instant = RideInstant.initial
	while $instant.clock != from {
		$instant = instant_after($instant)
	}
	var $is_on_long_segment = True
	while $instant.clock != until {
		is_on_it = rider_segment_index($instant) == Fixtures.longest_segment_index
		$is_on_long_segment = $is_on_long_segment and is_on_it
		$instant = instant_after($instant)
	}
	$is_on_long_segment and rider_segment_index($instant) == Fixtures.longest_segment_index
}

# Steve's rule: the ride reaches full night, past dusk, before it finishes. The
# rule is strict that night comes and loose about when, so it holds no step.
# The sky only darkens as the clock runs, so full darkness at the finish means it
# came at or before it.
expect Sky.darkness_at(ride_at_finish.clock) == Fraction.whole

## The ride at the step it finishes.
ride_at_finish : RideInstant
ride_at_finish = {
	var $instant = RideInstant.initial
	while !$instant.rider.is_finished(World.route) {
		$instant = instant_after($instant)
	}
	$instant
}

## What the encounters do over the whole ride: how many steps a bird is in
## flight and a cat crosses, whether every flying bird is ahead of the rider,
## how many cat segments the rider leaves, at a bend or the route's end, and
## whether each cat's hold on the eye has faded by then.
ride_encounters : {
	flying_step_count : U64,
	crossing_step_count : U64,
	is_bird_ahead_throughout : Bool,
	cat_exits : U64,
	is_faded_at_each_exit : Bool,
}
ride_encounters = {
	var $instant = RideInstant.initial
	var $flying_step_count = 0
	var $crossing_step_count = 0
	var $is_bird_ahead_throughout = True
	var $cat_exits = 0
	var $is_faded_at_each_exit = True
	while !$instant.rider.is_finished(World.route) {
		segment = World.route.segment_at(rider_segment_index($instant))
		timing = RideInstant.encounter_timing($instant)
		next = instant_after($instant)
		is_leaving =
			rider_segment_index(next) != rider_segment_index($instant)
				or next.rider.is_finished(World.route)
		match segment.encounter {
			BirdHere(flight) => {
				stage = BirdFlight.flight_stage(timing)
				match stage {
					Playing(_) => {
						bird = flight.instant_at(stage)
						$flying_step_count = $flying_step_count + 1
						$is_bird_ahead_throughout = $is_bird_ahead_throughout
							and bird.location.road_point.along > rider_along($instant)
					}
					Waiting | Past(_) => {}
				}
			}
			CatCrosses(_) => {
				match CatCrossing.crossing_stage(timing) {
					Playing(_) => {
						$crossing_step_count = $crossing_step_count + 1
					}
					Waiting | Past(_) => {}
				}
				if is_leaving {
					$cat_exits = $cat_exits + 1
					$is_faded_at_each_exit = $is_faded_at_each_exit
						and EncounterReaction.encounter_attention(segment, timing) == Attention.none
				}
			}
			QuietRoad => {}
		}
		$instant = next
	}
	{
		flying_step_count: $flying_step_count,
		crossing_step_count: $crossing_step_count,
		is_bird_ahead_throughout: $is_bird_ahead_throughout,
		cat_exits: $cat_exits,
		is_faded_at_each_exit: $is_faded_at_each_exit,
	}
}

# Steve's rule: the rider can't overtake a bird. Each of the route's birds flies
# its whole flight on the ride, and at every step of it the bird is ahead of the
# rider.
expect
	ride_encounters.flying_step_count
		== Fixtures.route_flights.len() * BirdFlight.flight_span.length.to_u32().to_u64()
expect ride_encounters.is_bird_ahead_throughout

# Each of the three cats crosses on the ride. The reaction ends with its
# segment, so the cat's hold has to have faded by then or it would snap to
# nothing there.
expect ride_encounters.crossing_step_count == 3 * CatCrossing.crossing_span.length.to_u32().to_u64()
expect ride_encounters.cat_exits == 3
expect ride_encounters.is_faded_at_each_exit

# The ride starts facing away from the sun.
expect FrameView.frame_view_at(World.route, RideInstant.initial).backdrop.sun_sighting == OutOfView
