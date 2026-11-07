## Beacon holds the clock rules of a tower's beacon: how long a blink lasts, how
## far apart the towers' blinks start, and how bright a beacon is partway through
## one. It knows steps of the ride, and nothing of towers or of where they stand.
import Fraction
import Steps

Beacon :: [].{

	## A beacon blinks once in this many steps of the ride.
	beacon_period : Steps
	beacon_period = Steps.of(120)

	## Each tower's blink starts this many steps past the last one's, a number
	## that shares no factor with the period, so neighbours blink apart.
	beacon_stagger : Steps
	beacon_stagger = Steps.of(37)

	## How far into its blink the tower with key `n` is when the ride's clock
	## is 0.
	beacon_offset_for : U32 -> Steps
	beacon_offset_for = |n| beacon_stagger.times(n).wrapped_to(beacon_period)

	## How bright a beacon is `phase` steps into its blink.
	beacon_brightness : Steps -> Fraction
	beacon_brightness = |phase| {
		wrapped = phase.wrapped_to(beacon_period).to_f64()
		angle = 2.0 * F64.pi * wrapped / beacon_period.to_f64()
		Fraction.of((1.0 - angle.cos()) / 2.0)
	}
}

expect Beacon.beacon_period.to_f64() == 120.0
expect Beacon.beacon_stagger.to_f64() == 37.0

expect Beacon.beacon_offset_for(0).to_f64() == 0.0
expect Beacon.beacon_offset_for(1).to_f64() == 37.0
expect Beacon.beacon_offset_for(2).to_f64() == 74.0
expect Beacon.beacon_offset_for(3).to_f64() == 111.0
expect Beacon.beacon_offset_for(4).to_f64() == 28.0
expect Beacon.beacon_offset_for(5).to_f64() == 65.0
expect Beacon.beacon_offset_for(10).to_f64() == 10.0
expect Beacon.beacon_offset_for(60).to_f64() == 60.0
expect Beacon.beacon_offset_for(120).to_f64() == 0.0
expect
	[
		(Beacon.beacon_brightness(Steps.of(0)).to_f64(), 0.0),
		(Beacon.beacon_brightness(Steps.of(60)).to_f64(), 1.0),
		(Beacon.beacon_brightness(Steps.of(30)).to_f64(), 0.5),
		(Beacon.beacon_brightness(Steps.of(90)).to_f64(), 0.5),
		(Beacon.beacon_brightness(Steps.of(120)).to_f64(), 0.0),
		(Beacon.beacon_brightness(Steps.of(180)).to_f64(), 1.0),
		(Beacon.beacon_brightness(Steps.of(300)).to_f64(), 1.0),
		(Beacon.beacon_brightness(Steps.of(240)).to_f64(), 0.0),
	].all(|(got, want)| (got - want).abs() <= 0.0000001)
