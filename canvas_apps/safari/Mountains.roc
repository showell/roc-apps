## The skyline, in front of the sky and behind the rest of the ride: a high range
## to the north with snow on its peaks, a lower range to the west, and the rolling
## land in front of both. Each is a silhouette across the screen whose height
## depends on the bearing it is seen at and on the lens, so the skyline turns with
## the rider but never comes nearer. The rock darkens at dusk, and the snow goes
## blue.
import Pixels
import Angle
import Backdrop
import Clock
import Fraction
import Lens
import HexColor
import Polygon
import Screen
import Sun
import lib.Shapes

Mountains :: [].{

	## Whether the sun, at `clock`, has sunk behind the skyline.
	is_sun_behind_mountains : Clock -> Bool
	is_sun_behind_mountains = |clock| {
		sun_top_px = Sun.height_px(clock).plus(Sun.radius_px)
		sun_top_px < horizon_crest_px(Sun.bearing)
	}

	## The skyline, back to front: the west range, the north range, the
	## north's snow, then the land.
	mountain_shapes : {
		heading : Angle.Bearing,
		dusk : Fraction,
		cam_focal : Pixels,
	} -> List(Shapes.Shape)
	mountain_shapes = |{ heading, dusk, cam_focal }| {
		sight = { heading, cam_focal }
		[
			[
				silhouette(
					sight,
					{ height_at: west_range_height, color: color_at_dusk(rock_west, dusk) },
				),
				silhouette(
					sight,
					{ height_at: north_range_height, color: color_at_dusk(rock, dusk) },
				),
			],
			snow_shapes(sight, snow_color(dusk)),
			[silhouette(sight, { height_at: land_height, color: Backdrop.grass_color })],
		].join()
	}
}

## How the skyline is seen: the rider's heading, and the camera.
Sight : { heading : Angle.Bearing, cam_focal : Pixels }

rock : I64
rock = 0x5B6A8F

rock_west : I64
rock_west = 0x39435F

## How much of its light the rock loses at full dusk.
rock_night_dim : Fraction
rock_night_dim = Fraction.of(0.5)

snow_day : HexColor.Rgb
snow_day = {
	r: 238.0,
	g: 243.0,
	b: 248.0,
}

snow_night : HexColor.Rgb
snow_night = {
	r: 70.0,
	g: 84.0,
	b: 104.0,
}

## A rock colour at `dusk`, from 0 (day) to 1 (night).
color_at_dusk : I64, Fraction -> I64
color_at_dusk = |color, dusk|
	HexColor.shade_color(color, rock_night_dim.times(dusk).complement().to_f64())

snow_color : Fraction -> I64
snow_color = |dusk| HexColor.pack(
	HexColor.color_between({
		from: snow_day,
		to: snow_night,
		fraction: dusk,
	}),
)

west_range_bearing : Angle.Bearing
west_range_bearing = Angle.Bearing.radians(-2.0416)

## The north range is snowy above this height.
snow_threshold : Pixels
snow_threshold = Pixels.of(124.0)

## How far the snowline dips below the threshold under the highest peak.
snow_dip : Pixels
snow_dip = Pixels.of(10.0)

## The silhouettes are sampled every `column_step` pixels across the screen.
column_step : Pixels
column_step = Pixels.of(2.0)

## How far past each side of the screen the silhouettes reach, so the
## rider's roll never shows their ends.
roll_margin : Pixels
roll_margin = Pixels.of(200.0)

## The rolling land: low, and all the way round.
land_height : Angle.Bearing -> Pixels
land_height = |bearing|
	Pixels.of(18.0 + 12.0 * (bearing.turn_from_north().to_radians() * 0.9 + 1.9).sin())

north_range_height : Angle.Bearing -> Pixels
north_range_height = |bearing| range_height(north, bearing)

west_range_height : Angle.Bearing -> Pixels
west_range_height = |bearing| range_height(west, bearing)

## The height of the north range's highest peak, as its samples find it.
snow_peak_height : Pixels
snow_peak_height = {
	first = Angle.Bearing.radians(-0.5)
	var $highest = north_range_height(first)
	var $at = first.plus(peak_sample_step)
	while $at <= Angle.Bearing.radians(0.5) {
		$highest = $highest.max(north_range_height($at))
		$at = $at.plus(peak_sample_step)
	}
	$highest
}

## The snowline's height at `bearing`: at the threshold, dipping lower
## under the higher peaks.
snowline : Angle.Bearing -> Pixels
snowline = |bearing| {
	above_threshold = north_range_height(bearing).minus(snow_threshold)
	peak_above_threshold = snow_peak_height.minus(snow_threshold)
	above_fraction = Fraction.clamp(above_threshold.ratio_to(peak_above_threshold))
	snow_threshold.minus(snow_dip.times(above_fraction.to_f64()))
}

## The bearing seen at `x` across the screen.
bearing_at : Sight, Pixels -> Angle.Bearing
bearing_at = |sight, x| {
	slope = x.minus(Screen.center_x).ratio_to(sight.cam_focal)
	off_center = Angle.Turn.radians(slope.atan())
	sight.heading.plus(off_center)
}

## The skyline's height at `bearing`: the highest of the land and the two
## ranges.
horizon_crest_px : Angle.Bearing -> Pixels
horizon_crest_px = |bearing| {
	north_or_land = north_range_height(bearing).max(land_height(bearing))
	west_range_height(bearing).max(north_or_land)
}

## A mountain range: the bearing of its middle, how far it reaches either
## side, the height it never passes, and the two frequencies of the ridges
## along it. Each ridge frequency is how many waves would fit a whole turn.
MountainRange : {
	center : Angle.Bearing,
	half_width : Angle.Turn,
	height_ceiling : Pixels,
	ridge_a : F64,
	ridge_b : F64,
}

north : MountainRange
north = {
	center: Angle.north,
	half_width: Angle.Turn.radians(0.95),
	height_ceiling: Pixels.of(150.0),
	ridge_a: 8.0,
	ridge_b: 21.0,
}

west : MountainRange
west = {
	center: west_range_bearing,
	half_width: Angle.Turn.radians(0.72),
	height_ceiling: Pixels.of(120.0),
	ridge_a: 11.0,
	ridge_b: 27.0,
}

## A range's height at `bearing`: under an envelope that is highest in its
## middle and falls to nothing at its ends, with two ridges along it.
range_height : MountainRange, Angle.Bearing -> Pixels
range_height = |range, bearing| {
	from_center = bearing.turn_from(range.center)
	fraction = from_center.ratio_to(range.half_width)
	if fraction.abs() >= 1.0 {
		Pixels.zero
	} else {
		envelope = (fraction * F64.pi / 2.0).cos()
		radians = from_center.to_radians()
		first_wave = 0.24 * (radians * range.ridge_a).cos()
		second_wave = 0.16 * (radians * range.ridge_b + 1.0).cos()
		ridge = 0.6 + first_wave + second_wave
		range.height_ceiling.times(envelope).times(ridge)
	}
}

## The north range's peak is searched for every hundredth of a radian.
peak_sample_step : Angle.Turn
peak_sample_step = Angle.Turn.radians(0.01)

## The screen's horizon, where a height of zero is drawn.
horizon_y : Pixels
horizon_y = Screen.horizon_y

## The screen's y for a height on the skyline.
height_y : Sight, Pixels -> Pixels
height_y = |sight, height| {
	scale = sight.cam_focal.ratio_to(Lens.resting_focal)
	horizon_y.minus(height.times(scale))
}

## The columns sampled, every `column_step` pixels from `from` up to `to`.
columns : { from : Pixels, to : Pixels } -> List(Pixels)
columns = |{ from, to }| {
	var $sampled = []
	var $at = from
	while $at <= to {
		$sampled = $sampled.append($at)
		$at = $at.plus(column_step)
	}
	$sampled
}

## A silhouette across the screen, its top at `height_at` each bearing, closed
## along the horizon.
silhouette : Sight, { height_at : Angle.Bearing -> Pixels, color : I64 } -> Shapes.Shape
silhouette = |sight, { height_at, color }| {
	left = roll_margin.opposite()
	right = Screen.width.plus(roll_margin)
	crest = columns({ from: left, to: right }).map(
		|x| { x, y: height_y(sight, height_at(bearing_at(sight, x))) },
	)
	Polygon.flat_polygon(
		color,
		crest.concat([{ x: right, y: horizon_y }, { x: left, y: horizon_y }]),
	)
}

## Snow thinner than this, between the range's crest and the snowline, isn't
## drawn.
thinnest_snow : Pixels
thinnest_snow = Pixels.of(0.01)

## The north range's snow: along its crest where the range is above the
## snowline, then back along the snowline.
snow_shapes : Sight, I64 -> List(Shapes.Shape)
snow_shapes = |sight, color| {
	snowy = columns({ from: Pixels.zero, to: Screen.width }).keep_if(
		|x| {
			bearing = bearing_at(sight, x)
			north_range_height(bearing) > snowline(bearing).plus(thinnest_snow)
		},
	)
	if snowy.len() < 2 {
		[]
	} else {
		crest = snowy.map(|x| { x, y: height_y(sight, north_range_height(bearing_at(sight, x))) })
		snowline_points = snowy.fold_rev(
			[],
			|x, back| back.append({ x, y: height_y(sight, snowline(bearing_at(sight, x))) }),
		)
		[Polygon.flat_polygon(color, crest.concat(snowline_points))]
	}
}

# The bearing `radians` to the right of north.
north_by : F64 -> Angle.Bearing
north_by = |radians| Angle.Bearing.radians(radians)

# The west range's middle, `radians` to its right.
west_by : F64 -> Angle.Bearing
west_by = |radians| west_range_bearing.plus(Angle.Turn.radians(radians))

expect rock == 0x5B6A8F
expect rock_west == 0x39435F

sight_at_rest : Sight
sight_at_rest = { heading: Angle.north, cam_focal: Lens.resting_focal }

expect height_y(sight_at_rest, Pixels.of(100.0)) == Pixels.of(200.0)
expect height_y(sight_at_rest, Pixels.zero) == Pixels.of(300.0)
expect height_y(sight_at_rest, Pixels.of(-40.0)) == Pixels.of(340.0)
expect
	height_y({ ..sight_at_rest, cam_focal: Lens.resting_focal.times(0.5) }, Pixels.of(100.0))
		== Pixels.of(250.0)

expect color_at_dusk(rock, Fraction.zero) == 0x5B6A8F
expect color_at_dusk(rock_west, Fraction.zero) == 0x39435F
expect color_at_dusk(rock, Fraction.whole) == 0x2E3548
expect color_at_dusk(rock_west, Fraction.whole) == 0x1D2230
expect color_at_dusk(rock, Fraction.of(0.5)) == 0x44506B

expect snow_color(Fraction.zero) == 0xEEF3F8
expect snow_color(Fraction.whole) == 0x465468
expect snow_color(Fraction.of(0.5)) == 0x9AA4B0
expect HexColor.pack(snow_day) == 0xEEF3F8
expect HexColor.pack(snow_night) == 0x465468

expect snow_color(Fraction.whole) > color_at_dusk(rock, Fraction.whole)
expect snow_color(Fraction.zero) > color_at_dusk(rock, Fraction.zero)

expect
	[0.95, 1.0, 2.0, -0.95, -3.0].all(
		|radians| north_range_height(north_by(radians)) == Pixels.zero,
	)
expect
	[
		west_by(0.8),
		west_by(-0.8),
		north_by(0.0),
		north_by(1.5),
	].all(|sight| west_range_height(sight) == Pixels.zero)

expect north_range_height(north_by(0.0)) > Pixels.zero
expect north_range_height(north_by(0.94)) > Pixels.zero
expect north_range_height(north_by(0.0)) > snow_threshold
expect !(north_range_height(north_by(0.9)) > snow_threshold)
expect west_range_height(west_range_bearing) > Pixels.zero

expect west_range_bearing.to_radians() == -2.0416
expect snow_threshold.to_f64() == 124.0
expect snow_dip.to_f64() == 10.0
expect column_step.to_f64() == 2.0
expect roll_margin.to_f64() == 200.0
expect rock_night_dim.to_f64() == 0.5

expect snowline(north_by(0.9)).to_f64() == 124.0
expect snowline(north_by(2.0)).to_f64() == 124.0

expect snowline(north_by(0.0)) < snow_threshold
expect snowline(north_by(0.0)) > snow_threshold.minus(snow_dip)
expect snowline(north_by(0.5)) <= snow_threshold
expect snowline(north_by(0.5)) >= snow_threshold.minus(snow_dip)

expect snow_peak_height > snow_threshold
expect snow_peak_height < Pixels.of(150.0)

# The bearing seen at `x` across a 960-pixel screen.
seen_bearing : {
	heading : F64,
	cam_focal : Pixels,
	x : Pixels,
} -> F64
seen_bearing = |{ heading, cam_focal, x }|
	bearing_at({ heading: north_by(heading), cam_focal }, x).to_radians()

expect
	seen_bearing({
		heading: 0.0,
		cam_focal: Pixels.of(500.0),
		x: Pixels.of(480.0),
	})
		== 0.0
expect
	seen_bearing({
		heading: 1.25,
		cam_focal: Pixels.of(500.0),
		x: Pixels.of(480.0),
	})
		== 1.25
expect
	seen_bearing({
		heading: 1.25,
		cam_focal: Pixels.of(100.0),
		x: Pixels.of(480.0),
	})
		== 1.25

# Bearings grow across the screen, and a shorter focal length spreads them.
expect
	seen_bearing({
		heading: 0.0,
		cam_focal: Pixels.of(500.0),
		x: Pixels.of(0.0),
	})
		< seen_bearing({
			heading: 0.0,
			cam_focal: Pixels.of(500.0),
			x: Pixels.of(480.0),
		})
expect
	seen_bearing({
		heading: 0.0,
		cam_focal: Pixels.of(500.0),
		x: Pixels.of(480.0),
	})
		< seen_bearing({
			heading: 0.0,
			cam_focal: Pixels.of(500.0),
			x: Pixels.of(960.0),
		})
expect
	seen_bearing({
		heading: 0.0,
		cam_focal: Pixels.of(100.0),
		x: Pixels.of(960.0),
	})
		> seen_bearing({
			heading: 0.0,
			cam_focal: Pixels.of(500.0),
			x: Pixels.of(960.0),
		})

expect horizon_crest_px(north_by(0.0)) >= land_height(north_by(0.0))
expect horizon_crest_px(north_by(2.0)) >= land_height(north_by(2.0))
expect horizon_crest_px(north_by(0.0)) >= north_range_height(north_by(0.0))
expect !Mountains.is_sun_behind_mountains(Clock.at_step(0))
expect Mountains.is_sun_behind_mountains(Clock.at_step(6000))
