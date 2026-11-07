## Gawking is what a pig by the road does to the rider's speed. A rider who
## notices a pig that catches the eye slows for it, and stays slow to the end
## of the segment. The eyes' part, the look, is Gaze's.
import Acceleration
import Billboard
import Distance
import Geom
import Motorcycle
import Route
import Segment
import Speed
import VehicleLimits
import World

Gawking :: [].{

	## How far short of a pig the rider notices it, measured along the road.
	## The look and the gawking both start here.
	notice_distance : Distance
	notice_distance = Distance.metres(150.0)

	## The speed a gawking rider brakes down to.
	gawk_speed : Speed
	gawk_speed = Speed.metres_a_step(0.2)

	## How far short of the pig a gawking rider aims to reach `gawk_speed`.
	gawk_settle_distance : Distance
	gawk_settle_distance = Distance.metres(25.0)

	## The shortest distance the brake for a pig is worked out over. Past the
	## settle distance the rider is still coming down to `gawk_speed`, so the
	## brake keeps working at this distance's strength. Throttle's bend limit
	## has a different guard, which lets go at its commit point: a rider who
	## reaches a bend has no more road to brake on, and a rider who reaches
	## the pig has the rest of the segment.
	gawk_least_distance : Distance
	gawk_least_distance = Distance.metres(1.0)

	## The pig on `seg` that catches the rider's eye: the standout pig of a herd
	## the rider finds distracting. A herd the rider passes by catches no eye.
	eye_catching_pig : Segment -> [CatchesEye(Geom.Placed(Billboard)), NoPigCatchesEye]
	eye_catching_pig = |seg|
		match seg.standout_pig() {
			Standout({ pig, interest: Distracting }) => CatchesEye(pig)
			Standout({ interest: Unnoticed, .. }) | NoPigs => NoPigCatchesEye
		}

	## Whether the rider is gawking at this segment's pig. It starts where the
	## pig is noticed and asks only where the motorcycle is, so it stays true
	## past the pig to the end of the segment: the rider brakes for the pig and
	## doesn't open the throttle until the next segment. Two things depend on
	## that. `gawk_brake` holds the rider down for as long as this is true, and
	## Throttle's `allowed_speed` leaves a gawking rider below the segment's exit
	## speed, where it lifts any other rider near the end up to it.
	is_gawking : Motorcycle, Segment -> Bool
	is_gawking = |motorcycle, seg|
		match eye_catching_pig(seg) {
			CatchesEye(pig) => motorcycle.along >= pig.along.minus(notice_distance)
			NoPigCatchesEye => False
		}

	## The brake for a gawking rider, who aims to be down to `gawk_speed` by
	## the settle distance before the pig.
	gawk_brake : Motorcycle, Segment -> VehicleLimits.Limit
	gawk_brake = |motorcycle, seg|
		match eye_catching_pig(seg) {
			CatchesEye(pig) if is_gawking(motorcycle, seg) => {
				room = pig.along.distance_from(motorcycle.along).minus(gawk_settle_distance)
				AtMost(
					motorcycle.speed.acceleration_to({
						target: gawk_speed,
						within: room.max(gawk_least_distance),
					}),
				)
			}
			CatchesEye(_) | NoPigCatchesEye => NoLimit
		}
}

# Each is within 1e-12 of its want.
expect
	[
		(Gawking.notice_distance.to_metres(), 150.0),
		(Gawking.gawk_speed.to_metres_a_step(), 0.2),
		(Gawking.gawk_settle_distance.to_metres(), 25.0),
		(Gawking.gawk_least_distance.to_metres(), 1.0),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

plain : Segment
plain = World.route.segment_at(Route.SegmentIndex.number(0))

distracting : Segment
distracting = World.route.segment_at(Route.SegmentIndex.number(2))

expect plain.pigs == NoPigs
expect Gawking.eye_catching_pig(plain) == NoPigCatchesEye

## A segment whose herd the rider passes by.
passed_by : Segment
passed_by = World.route.segment_at(Route.SegmentIndex.number(11))

expect Gawking.eye_catching_pig(passed_by) == NoPigCatchesEye

## The pig that catches the eye on the distracting segment.
watched_pig : Geom.Placed(Billboard)
watched_pig =
	match Gawking.eye_catching_pig(distracting) {
		CatchesEye(pig) => pig
		NoPigCatchesEye => crash "Gawking's expects: this segment's pigs catch the eye"
	}

# The rider watches a pig of the herd.
expect distracting.segment_pigs().count_if(|pig| pig == watched_pig) == 1

## A motorcycle `along` metres into its segment, at rest in every other way.
## Gawking doesn't import Along, so `along` is a distance from the segment's
## start.
motorcycle_at : F64 -> Motorcycle
motorcycle_at = |along| {
	..Motorcycle.initial,
	along: Motorcycle.initial.along.plus(Distance.metres(along)),
}

## A motorcycle on the distracting segment, `metres` short of the pig.
short_of_pig : F64 -> Motorcycle
short_of_pig = |metres| {
	..Motorcycle.initial,
	along: watched_pig.along.minus(Distance.metres(metres)),
}

expect !Gawking.is_gawking(motorcycle_at(200.0), plain)
expect !Gawking.is_gawking(motorcycle_at(100.0), distracting)
expect Gawking.is_gawking(motorcycle_at(200.0), distracting)
expect Gawking.is_gawking(motorcycle_at(341.0), distracting)

# The gawking starts where the pig is noticed, and not a centimetre sooner.
expect Gawking.is_gawking(short_of_pig(Gawking.notice_distance.to_metres()), distracting)
expect !Gawking.is_gawking(short_of_pig(150.01), distracting)

expect Gawking.gawk_brake(motorcycle_at(200.0), plain) == NoLimit
expect Gawking.gawk_brake(motorcycle_at(100.0), distracting) == NoLimit

## The brake for a motorcycle `metres` short of the pig, going `speed` metres a
## step.
brake_short_of_pig : F64, F64 -> F64
brake_short_of_pig = |metres, speed| {
	motorcycle = { ..short_of_pig(metres), speed: Speed.metres_a_step(speed) }
	match Gawking.gawk_brake(motorcycle, distracting) {
		AtMost(brake) => brake.to_metres_a_step_each_step()
		NoLimit => crash "Gawking's expects: this rider is gawking"
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
