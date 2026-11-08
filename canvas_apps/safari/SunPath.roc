## The sun's path across the sky through the ride: the sky turns about its
## pole as the earth does, carrying the sun down an arc into the southwest.
## The clock says where the sun stands, and its height is what the rest of the
## sunset follows: the sky, the mountains and the truck's headlights.
import Angle
import Clock
import FarHeight
import FarRise
import Lens
import Steps

SunPath :: [].{

	## The direction the sun stands in: its bearing, and its height above the
	## horizon, a far height, which is how the resting lens holds an elevation.
	Direction : { bearing : Angle.Bearing, height : FarHeight }

	## The sun's direction at `clock`, from where the turning sky has carried
	## it. In the frame of the sky's pole the sun stands `declination` from the
	## sky's equator and `hour_angle_at(clock)` west of the meridian; the pole
	## stands `latitude` above the north horizon. Turning that into the
	## rider's frame is the one piece of spherical trig: the sun's direction
	## as a unit vector, up, north and east.
	sun_direction_at : Clock -> SunPath.Direction
	sun_direction_at = |clock| {
		pole = latitude.to_radians()
		from_equator = declination.to_radians()
		hour = hour_angle_at(clock).to_radians()
		up = pole.sin() * from_equator.sin() + pole.cos() * from_equator.cos() * hour.cos()
		north = pole.cos() * from_equator.sin() - pole.sin() * from_equator.cos() * hour.cos()
		east = 0.0 - from_equator.cos() * hour.sin()
		level = (north * north + east * east).sqrt()
		elevation = Angle.Turn.radians(F64.atan2({ x: level, y: up }))
		{
			bearing: Angle.Bearing.radians(F64.atan2({ x: north, y: east })),
			height: Lens.height_at_elevation(elevation),
		}
	}

	## The sun's bearing at `clock`. It starts a little west of south and
	## swings west as it sinks.
	bearing_at : Clock -> Angle.Bearing
	bearing_at = |clock| sun_direction_at(clock).bearing

	## How high the sun stands above the horizon at `clock`; below it once
	## negative.
	height_at : Clock -> FarHeight
	height_at = |clock| sun_direction_at(clock).height

	## The sun's radius: how far its top stands above its middle, and its
	## bottom below.
	radius : FarRise
	radius = FarRise.of(46.0)

	## How high the sun stands above the horizon as the ride starts.
	height_at_start : FarHeight
	height_at_start = height_at(Clock.start)

	## How high the sun stands once it has fully set: its top on the horizon.
	height_when_set : FarHeight
	height_when_set = FarHeight.zero.lowered_by(radius)

	## The first step at which the sun has fully set, its whole disc below the
	## horizon. The sky's turning places it; `sunset_climax` in
	## gates/expects/RideExpects.roc holds where the sunset falls in the ride.
	fully_set_at : Clock
	fully_set_at = {
		var $clock = Clock.start
		while height_at($clock) > height_when_set {
			$clock = $clock.next()
		}
		$clock
	}
}

## How far the sky's pole stands above the north horizon, which is the
## latitude the ride is at: 45°, halfway from the equator to the pole. The
## further from the equator, the more slantwise the sun goes down.
latitude : Angle.Turn
latitude = Angle.Turn.degrees(45.0)

## How far the sun stands south of the sky's equator: as far as it goes, at
## the winter solstice. It makes the year's shortest day, with the sun low at
## noon and setting in the southwest.
declination : Angle.Turn
declination = Angle.Turn.degrees(-23.44)

## How many steps the sky takes to turn an hour, a 24th of a whole turn. The
## ride of about 7,000 steps lasts most of an afternoon and evening.
steps_an_hour : Steps
steps_an_hour = Steps.of(1000)

## How far past noon the ride starts: 10°, forty minutes at the sky's 15° an
## hour.
hour_angle_at_start : Angle.Turn
hour_angle_at_start = Angle.Turn.degrees(10.0)

## How far west of the meridian the sky has turned the sun at `clock`. It
## turns at one steady rate, so the sun climbs and sinks fastest near the
## horizon and lingers near noon.
hour_angle_at : Clock -> Angle.Turn
hour_angle_at = |clock| {
	hours_in = clock.steps_since(Clock.start).ratio_to(steps_an_hour)
	hour_angle_at_start.plus(Angle.Turn.degrees(15.0).times(hours_in))
}

# Part of the disc is still above the horizon a step before `fully_set_at`,
# which gates/expects/RideExpects.roc holds, and none of it from then on.
expect SunPath.height_at(SunPath.fully_set_at) <= SunPath.height_when_set

# At noon the sun stands due south, as high as it climbs: 90° less the
# latitude, less the declination south of the equator, so 21.56°. The ride
# starts forty minutes later, a little lower and west of south.
expect {
	noon = Lens.height_at_elevation(Angle.Turn.degrees(21.56))
	a_little_lower = Lens.height_at_elevation(Angle.Turn.degrees(20.5))
	start = SunPath.sun_direction_at(Clock.start)
	west_of_south = start.bearing.turn_from(Angle.Bearing.radians(F64.pi))
	start.height < noon and start.height > a_little_lower and west_of_south > Angle.straight_ahead
}

# The sun swings west as it sinks, and sinks faster the lower it is: the
# second hour of the ride takes it further down than the first.
expect {
	at_hour = |hour| SunPath.sun_direction_at(Clock.at_step(hour * 1000))
	first_drop = at_hour(0).height.minus(at_hour(1).height)
	second_drop = at_hour(1).height.minus(at_hour(2).height)
	at_hour(2).bearing.turn_from(at_hour(1).bearing) > Angle.straight_ahead
		and second_drop > first_drop
}
