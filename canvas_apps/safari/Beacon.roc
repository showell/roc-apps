## Beacon is the light on top of a radio tower, as the scene draws it: a
## magenta disc 3 m in radius, seen through as far as it is dim. A beacon
## blinks by the ride's clock, each segment's a little apart from the last, and
## a tower halfway along a segment blinks opposite the one at its end. Whatever
## holds a beacon says where its middle is on screen and how many pixels a
## metre spans there. A beacon is worked out each frame from the clock and the
## tower it tops.
import Clock
import Distance
import lib.Point
import lib.Fraction
import lib.Pixels
import Route
import Steps
import lib.Brush
import lib.RgbColor
import lib.Shapes

## A tower's beacon at one moment of its blink, by how bright it is.
Beacon :: Fraction.{

	## Where on its segment a tower stands: past the segment's end, or halfway
	## along it.
	TowerPlace : [AtEnd, Midway]

	## Which tower a beacon tops: the segment it stands on, and its place
	## there. Towers aren't kept, so this pair is all that tells one from
	## another.
	TowerKey : { segment : Route.SegmentIndex, place : Beacon.TowerPlace }

	## The beacon of `tower`, as it shines at `clock`.
	at : Beacon.TowerKey, Clock -> Beacon
	at = |tower, clock| Beacon.(beacon_brightness(Beacon.blink_phase(tower, clock)))

	## The phase of the beacon of `tower` at `clock`: the steps since the
	## ride's start, plus the beacon's head start. Each whole `beacon_period`
	## on is the same point of the blink, counted from where it starts dark.
	blink_phase : Beacon.TowerKey, Clock -> Steps
	blink_phase = |tower, clock|
		clock.steps_since(Clock.start).plus(head_start(tower))

	## A beacon blinks once in this many steps of the ride.
	beacon_period : Steps
	beacon_period = Steps.of(120)

	## How bright the beacon is.
	brightness : Beacon -> Fraction
	brightness = |Beacon.(fraction)| fraction

	## The beacon's disc, centred on `center` where a metre across spans
	## `metre_on_screen`, unless it is too dim or too small to draw.
	disc : Beacon,
	{
		center : Point.Point,
		metre_on_screen : Pixels,
	} -> Try(Shapes.Shape, [TooDim, TooSmall])
	disc = |Beacon.(fraction), { center, metre_on_screen }|
		if fraction < dimmest_beacon {
			Err(TooDim)
		} else {
			radius = metre_on_screen.times(beacon_radius.to_metres())
			if radius < smallest_beacon_radius {
				Err(TooSmall)
			} else {
				Ok(beacon_disc({ center, radius_on_screen: radius, brightness: fraction }))
			}
		}
}

## How far into its blink the beacon of the tower at `place` on the segment at
## `segment` is when the ride starts. Each segment's beacon starts a stagger
## further into its blink than the last one's, so neighbouring segments'
## beacons blink apart, and the tower halfway along starts half a blink on
## from the one at the end, so the two blink opposite each other.
head_start : Beacon.TowerKey -> Steps
head_start = |{ segment, place }| {
	at_end = beacon_stagger.times(segment.to_u32()).wrapped_to(Beacon.beacon_period)
	match place {
		AtEnd => at_end
		Midway => at_end.plus(half_period).wrapped_to(Beacon.beacon_period)
	}
}

## Each segment's beacon starts this many steps further into its blink than the
## last one's. The number shares no factor with the period, so the first
## period's worth of segments' beacons all start at different points of the
## blink.
beacon_stagger : Steps
beacon_stagger = Steps.of(37)

half_period : Steps
half_period = Steps.of(Beacon.beacon_period.to_u32() // 2)

## How bright a beacon is `phase` steps into its blink.
beacon_brightness : Steps -> Fraction
beacon_brightness = |phase| {
	wrapped = phase.wrapped_to(Beacon.beacon_period).to_f64()
	angle = 2.0 * F64.pi * wrapped / Beacon.beacon_period.to_f64()
	Fraction.of((1.0 - angle.cos()) / 2.0)
}

beacon_radius : Distance
beacon_radius = Distance.metres(3.0)

beacon_color : RgbColor
beacon_color = RgbColor.of(0xFF2FE6)

## The dimmest beacon that is drawn. A dimmer one would tint the sky by less
## than one part in fifty, too little to see; the figure was chosen by eye.
dimmest_beacon : Fraction
dimmest_beacon = Fraction.of(0.02)

## The smallest beacon radius that is drawn. A disc under a pixel across
## covers no pixel whole, so a far beacon is left out rather than drawn as a
## speck.
smallest_beacon_radius : Pixels
smallest_beacon_radius = Pixels.of(0.5)

## A beacon's disc, seen through as far as `brightness` says.
beacon_disc : {
	center : Point.Point,
	radius_on_screen : Pixels,
	brightness : Fraction,
} -> Shapes.Shape
beacon_disc = |{ center, radius_on_screen, brightness }| {
	opaque = Brush.opaque_rgba(beacon_color)
	Disc({
		center,
		radius: radius_on_screen,
		fill: Flat({ ..opaque, a: brightness.to_f64() }),
	})
}

## How far into its blink the beacon past the end of the segment numbered `n`
## is when the ride starts.
segment_head_start : U32 -> F64
segment_head_start = |n| {
	segment = Route.SegmentIndex.number(n)
	head_start({ segment, place: AtEnd }).to_f64()
}

## How far into its blink the beacon halfway along the segment numbered `n` is
## when the ride starts.
midway_head_start : U32 -> F64
midway_head_start = |n| {
	segment = Route.SegmentIndex.number(n)
	head_start({ segment, place: Midway }).to_f64()
}

expect segment_head_start(0) == 0.0
expect segment_head_start(1) == 37.0
expect segment_head_start(2) == 74.0
expect segment_head_start(3) == 111.0
expect segment_head_start(4) == 28.0
expect segment_head_start(5) == 65.0
expect segment_head_start(10) == 10.0
expect segment_head_start(60) == 60.0
expect segment_head_start(120) == 0.0

# The midway beacon starts half a blink further on than the one at the end,
# wrapped to the blink, and half a blink on from that is back where the one at
# the end started.
expect
	[
		(midway_head_start(0), 60.0),
		(midway_head_start(1), 97.0),
		(midway_head_start(2), 14.0),
		(midway_head_start(3), 51.0),
		(midway_head_start(60), 0.0),
	].all(|(got, want)| got == want)
expect
	[0, 1, 2, 3, 59, 60, 119].all(
		|n| {
			midway = head_start({ segment: Route.SegmentIndex.number(n), place: Midway })
			back_again = midway.plus(half_period).wrapped_to(Beacon.beacon_period)
			back_again.to_f64() == segment_head_start(n)
		},
	)
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

## How bright the first segment's beacon at `place` is at `step` of the ride.
first_brightness_at : Beacon.TowerPlace, U32 -> F64
first_brightness_at = |place, step| {
	beacon = Beacon.at({ segment: Route.SegmentIndex.first, place }, Clock.at_step(step))
	beacon.brightness().to_f64()
}

# A beacon blinks: dark at the start of its blink, full halfway, half a quarter
# of the way either side, and dark again a whole blink on. The midway beacon
# is full where the one at the end is dark, and dark where it is full.
expect
	[
		(first_brightness_at(AtEnd, 0), 0.0),
		(first_brightness_at(AtEnd, 30), 0.5),
		(first_brightness_at(AtEnd, 60), 1.0),
		(first_brightness_at(AtEnd, 90), 0.5),
		(first_brightness_at(AtEnd, 120), 0.0),
		(first_brightness_at(Midway, 0), 1.0),
		(first_brightness_at(Midway, 30), 0.5),
		(first_brightness_at(Midway, 60), 0.0),
		(first_brightness_at(Midway, 120), 1.0),
	].all(|(got, want)| (got - want).abs() <= 0.0000001)

# The phase counts from the tower's own head start: the second segment's beacon
# at the end starts 37 steps in, its midway beacon half a blink further, and
# each comes back to 0 at a whole blink.
expect
	[
		(Route.SegmentIndex.number(1), AtEnd, 0, 37.0),
		(Route.SegmentIndex.number(1), AtEnd, 83, 0.0),
		(Route.SegmentIndex.number(1), Midway, 0, 97.0),
		(Route.SegmentIndex.number(1), Midway, 23, 0.0),
		(Route.SegmentIndex.first, AtEnd, 5400, 0.0),
		(Route.SegmentIndex.first, AtEnd, 5519, 119.0),
	].all(
		|(segment, place, step, want)| {
			phase = Beacon.blink_phase({ segment, place }, Clock.at_step(step))
			phase.wrapped_to(Beacon.beacon_period).to_f64() == want
		},
	)

## The disc of a beacon at `brightness`, centred at (10, 20) where a metre
## spans `metre` pixels.
disc_of : F64, F64 -> Try(Shapes.Shape, [TooDim, TooSmall])
disc_of = |brightness, metre|
	Beacon.(Fraction.of(brightness)).disc({
		center: Point.at(10.0, 20.0),
		metre_on_screen: Pixels.of(metre),
	})

# A lit beacon's disc is 3 m in radius, magenta, and seen through as
# far as it is dim.
expect
	disc_of(0.25, 10.0)
		== Ok(
			Disc({
				center: Point.at(10.0, 20.0),
				radius: Pixels.of(30.0),
				fill: Flat(Brush.with_alpha(beacon_color, 0.25)),
			}),
		)

# A beacon dimmer than one part in fifty is not drawn, and one just bright
# enough is.
expect disc_of(0.0, 10.0) == Err(TooDim)
expect disc_of(0.019, 10.0) == Err(TooDim)
expect disc_of(0.02, 10.0).is_ok()

# A beacon under a pixel across is not drawn, and one just over is.
expect disc_of(1.0, 0.16) == Err(TooSmall)
expect disc_of(1.0, 0.17).is_ok()

# Too dim is told before too small.
expect disc_of(0.0, 0.16) == Err(TooDim)

# The first segment's beacon, at the start of the ride, is too dark to draw.
expect
	Beacon.at({ segment: Route.SegmentIndex.first, place: AtEnd }, Clock.start).disc({
		center: Point.at(10.0, 20.0),
		metre_on_screen: Pixels.of(10.0),
	})
		== Err(TooDim)
