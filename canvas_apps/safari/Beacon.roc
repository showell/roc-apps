## Beacon is the light on top of a radio tower: how it blinks and how it looks.
## A beacon blinks by the ride's clock, each a little apart from the last, and
## lit, it is a magenta disc 3 m in radius, seen through as far as it is dim. A
## beacon is known by its head start: how far into its blink it is when the
## ride starts. Whatever holds it says where its middle is on screen and how
## many pixels a metre spans there.
import Clock
import Distance
import Fraction
import Pixels
import Route
import Screen
import Steps
import lib.Brush
import lib.RgbColor
import lib.Shapes

## A tower's beacon, by how far into its blink it is when the ride starts.
Beacon :: Steps.{

	## The beacon of the tower past the end of the segment at `index`. Each
	## segment's beacon starts a stagger further into its blink than the last
	## one's, so neighbouring segments' beacons blink apart.
	of_segment : Route.SegmentIndex -> Beacon
	of_segment = |index| {
		head_start = beacon_stagger.times(index.to_u32())
		Beacon.(head_start.wrapped_to(Beacon.beacon_period))
	}

	## A beacon blinks once in this many steps of the ride.
	beacon_period : Steps
	beacon_period = Steps.of(120)

	## `beacon` as it shines at `clock`.
	lit_at : Beacon, Clock -> Beacon.LitBeacon
	lit_at = |Beacon.(head_start), clock| {
		phase = clock.steps_since(Clock.start).plus(head_start)
		Beacon.LitBeacon.(beacon_brightness(phase))
	}

	## The beacon that blinks exactly opposite `beacon`, half a blink ahead of
	## it.
	opposite : Beacon -> Beacon
	opposite = |Beacon.(head_start)| {
		half_a_blink_on = head_start.plus(half_period)
		Beacon.(half_a_blink_on.wrapped_to(Beacon.beacon_period))
	}

	## A beacon at one moment of its blink, by how bright it is.
	LitBeacon :: Fraction.{

		## How bright the beacon is.
		brightness : Beacon.LitBeacon -> Fraction
		brightness = |Beacon.LitBeacon.(fraction)| fraction

		## The beacon's disc, centred on `center` where a metre across spans
		## `metre_on_screen`, unless it is too dim or too small to draw.
		disc : Beacon.LitBeacon,
		{
			center : Screen.Point,
			metre_on_screen : Pixels,
		} -> Try(Shapes.Shape, [TooDim, TooSmall])
		disc = |Beacon.LitBeacon.(fraction), { center, metre_on_screen }|
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
	center : Screen.Point,
	radius_on_screen : Pixels,
	brightness : Fraction,
} -> Shapes.Shape
beacon_disc = |{ center, radius_on_screen, brightness }| {
	opaque = Brush.opaque_rgba(beacon_color)
	Disc({
		x: center.x.to_f64(),
		y: center.y.to_f64(),
		radius: radius_on_screen.to_f64(),
		fill: Flat({ ..opaque, a: brightness.to_f64() }),
	})
}

## How far into its blink the beacon of the segment numbered `n` is when the
## ride starts.
segment_head_start : U32 -> F64
segment_head_start = |n| {
	Beacon.(head_start) = Beacon.of_segment(Route.SegmentIndex.number(n))
	head_start.to_f64()
}

## How far into its blink the beacon opposite the segment numbered `n`'s is
## when the ride starts.
opposite_head_start : U32 -> F64
opposite_head_start = |n| {
	Beacon.(head_start) = Beacon.of_segment(Route.SegmentIndex.number(n)).opposite()
	head_start.to_f64()
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

# The opposite beacon starts half a blink further on, wrapped to the blink, and
# the beacon opposite that is the one it started from.
expect
	[
		(opposite_head_start(0), 60.0),
		(opposite_head_start(1), 97.0),
		(opposite_head_start(2), 14.0),
		(opposite_head_start(3), 51.0),
		(opposite_head_start(60), 0.0),
	].all(|(got, want)| got == want)
expect
	[0, 1, 2, 3, 59, 60, 119].all(
		|n| {
			beacon = Beacon.of_segment(Route.SegmentIndex.number(n))
			Beacon.(back_again) = beacon.opposite().opposite()
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

first_beacon : Beacon
first_beacon = Beacon.of_segment(Route.SegmentIndex.first)

## How bright `beacon` is at `step` of the ride.
brightness_at_step : Beacon, U32 -> F64
brightness_at_step = |beacon, step| beacon.lit_at(Clock.at_step(step)).brightness().to_f64()

first_brightness_at : U32 -> F64
first_brightness_at = |step| brightness_at_step(first_beacon, step)

opposite_brightness_at : U32 -> F64
opposite_brightness_at = |step| brightness_at_step(first_beacon.opposite(), step)

# A beacon blinks: dark at the start of its blink, full halfway, half a quarter
# of the way either side, and dark again a whole blink on. The beacon opposite
# it is full where it is dark, and dark where it is full.
expect
	[
		(first_brightness_at(0), 0.0),
		(first_brightness_at(30), 0.5),
		(first_brightness_at(60), 1.0),
		(first_brightness_at(90), 0.5),
		(first_brightness_at(120), 0.0),
		(opposite_brightness_at(0), 1.0),
		(opposite_brightness_at(30), 0.5),
		(opposite_brightness_at(60), 0.0),
		(opposite_brightness_at(120), 1.0),
	].all(|(got, want)| (got - want).abs() <= 0.0000001)

## The disc of a beacon at `brightness`, centred at (10, 20) where a metre
## spans `metre` pixels.
disc_of : F64, F64 -> Try(Shapes.Shape, [TooDim, TooSmall])
disc_of = |brightness, metre|
	Beacon.LitBeacon.(Fraction.of(brightness)).disc({
		center: Screen.point(10.0, 20.0),
		metre_on_screen: Pixels.of(metre),
	})

# A lit beacon's disc is 3 m in radius, magenta, and seen through as
# far as it is dim.
expect
	disc_of(0.25, 10.0)
		== Ok(
			Disc({
				x: 10.0,
				y: 20.0,
				radius: 30.0,
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
	first_beacon.lit_at(Clock.start).disc({
		center: Screen.point(10.0, 20.0),
		metre_on_screen: Pixels.of(10.0),
	})
		== Err(TooDim)
