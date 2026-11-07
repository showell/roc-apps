## Beacon holds the clock rules of a tower's beacon: how long a blink lasts, how
## far apart the towers' blinks start, and how bright a beacon is at a step of
## the ride. A beacon is known by its key, and it knows nothing of towers or of
## where they stand.
import Clock
import Fraction
import Route
import Steps

## A tower's beacon, by its key. Beacons with neighbouring keys blink apart.
Beacon :: U32.{

	## The beacon of the tower past the end of the segment at `index`, keyed by
	## that segment's number, so neighbouring segments' beacons blink apart.
	of_segment : Route.SegmentIndex -> Beacon
	of_segment = |index| Beacon.(index.to_u32())

	## A beacon blinks once in this many steps of the ride.
	beacon_period : Steps
	beacon_period = Steps.of(120)

	## How bright `beacon` is at `clock`.
	brightness_at : Beacon, Clock -> Fraction
	brightness_at = |Beacon.(key), clock|
		beacon_brightness(clock.steps_since(Clock.start).plus(beacon_offset_for(key)))

	## The beacon that blinks exactly opposite `beacon`. Its key is
	## `opposite_key_offset` past this one's.
	opposite : Beacon -> Beacon
	opposite = |Beacon.(key)| Beacon.(key + opposite_key_offset)
}

## Each beacon's blink starts this many steps past the last one's, a number
## that shares no factor with the period, so neighbours blink apart.
beacon_stagger : Steps
beacon_stagger = Steps.of(37)

## How far past a beacon's key the key of the beacon opposite it is. That many
## staggers come to half a period past a whole number of periods.
opposite_key_offset : U32
opposite_key_offset = 60

## How far into its blink the beacon with key `n` is when the ride's clock is
## 0.
beacon_offset_for : U32 -> Steps
beacon_offset_for = |n| beacon_stagger.times(n).wrapped_to(Beacon.beacon_period)

## How bright a beacon is `phase` steps into its blink.
beacon_brightness : Steps -> Fraction
beacon_brightness = |phase| {
	wrapped = phase.wrapped_to(Beacon.beacon_period).to_f64()
	angle = 2.0 * F64.pi * wrapped / Beacon.beacon_period.to_f64()
	Fraction.of((1.0 - angle.cos()) / 2.0)
}

expect beacon_offset_for(0).to_f64() == 0.0
expect beacon_offset_for(1).to_f64() == 37.0
expect beacon_offset_for(2).to_f64() == 74.0
expect beacon_offset_for(3).to_f64() == 111.0
expect beacon_offset_for(4).to_f64() == 28.0
expect beacon_offset_for(5).to_f64() == 65.0
expect beacon_offset_for(10).to_f64() == 10.0
expect beacon_offset_for(60).to_f64() == 60.0
expect beacon_offset_for(120).to_f64() == 0.0
expect
	[
		(beacon_brightness(Steps.of(0)).to_f64(), 0.0),
		(beacon_brightness(Steps.of(60)).to_f64(), 1.0),
		(beacon_brightness(Steps.of(30)).to_f64(), 0.5),
		(beacon_brightness(Steps.of(90)).to_f64(), 0.5),
		(beacon_brightness(Steps.of(120)).to_f64(), 0.0),
		(beacon_brightness(Steps.of(180)).to_f64(), 1.0),
		(beacon_brightness(Steps.of(300)).to_f64(), 1.0),
		(beacon_brightness(Steps.of(240)).to_f64(), 0.0),
	].all(|(got, want)| (got - want).abs() <= 0.0000001)
