## The skyline, drawn behind everything else: a high range to the north with
## snow on its peaks, a lower range to the west, and the rolling land in front
## of both. Each is a silhouette across the screen whose height depends only on
## the bearing it is seen at, so the skyline turns with the rider but never
## comes nearer. The rock darkens at dusk, and the snow goes blue.
import Pixels
import Angle
import Clock
import lib.DeviceMath
import Fraction
import Lens
import Float
import Paint
import Screen
import Sky
import lib.Trig
import lib.Shapes

Mountains :: [].{

	## How the skyline is seen: the rider's heading, and the camera.
	Sight : { heading : Angle.Bearing, cam_focal : Pixels }

	rock : I64
	rock = 0x5B6A8F

	rock_west : I64
	rock_west = 0x39435F

	land : I64
	land = 0x4A8F43

	## How much of its light the rock loses at full dusk.
	rock_night_dim : Fraction
	rock_night_dim = Fraction.of(0.5)

	snow_day : Sky.Rgb
	snow_day = {
		r: 238.0,
		g: 243.0,
		b: 248.0,
	}

	snow_night : Sky.Rgb
	snow_night = {
		r: 70.0,
		g: 84.0,
		b: 104.0,
	}

	## One of a colour's channels: 16 is red, 8 green and 0 blue.
	channel : I64, U8 -> F64
	channel = |color, shift| color.shr_wrap(shift).bitwise_and(255).to_f64()

	## A rock colour at `dusk`, from 0 (day) to 1 (night).
	color_at_dusk : I64, Fraction -> I64
	color_at_dusk = |color, dusk| {
		light = rock_night_dim.times(dusk).complement().to_f64()
		Sky.pack({
			r: Float.round((channel(color, 16) * light)),
			g: Float.round((channel(color, 8) * light)),
			b: Float.round((channel(color, 0) * light)),
		})
	}

	snow_color : Fraction -> I64
	snow_color = |dusk| Sky.pack(
		Sky.color_between({
			from: snow_day,
			to: snow_night,
			fraction: dusk,
		}),
	)

	west_range_bearing : Angle.Bearing
	west_range_bearing = Angle.Bearing.radians(-2.0416)

	## The north range is snowy above this height.
	snow_threshold : F64
	snow_threshold = 124.0

	## How far the snowline dips below the threshold under the highest peak.
	snow_dip : F64
	snow_dip = 10.0

	## The silhouettes are sampled every `column_step` pixels across the screen.
	column_step : F64
	column_step = 2.0

	## How far past each side of the screen the silhouettes reach, so the
	## rider's roll never shows their ends.
	roll_margin : F64
	roll_margin = 200.0

	## The rolling land: low, and all the way round.
	ground_base : Angle.Bearing -> F64
	ground_base = |bearing|
		18.0 + 12.0 * Trig.r_sin(bearing.turn_from_north().to_radians() * 0.9 + 1.9)

	north_range : Angle.Bearing -> F64
	north_range = |bearing| range_height(north, bearing)

	west_range : Angle.Bearing -> F64
	west_range = |bearing| range_height(west, bearing)

	## The height of the north range's highest peak, as its samples find it.
	snow_peak_height : F64
	snow_peak_height = {
		first = Angle.Bearing.radians(-0.5)
		north_peak_height_from({ at: first.plus(peak_sample_step), highest: north_range(first) })
	}

	## The snowline's height at `bearing`: at the threshold, dipping lower
	## under the higher peaks.
	snowline : Angle.Bearing -> F64
	snowline = |bearing| {
		above_threshold = (north_range(bearing) - snow_threshold)
		above_fraction = Fraction.clamp((above_threshold / (snow_peak_height - snow_threshold)))
		snow_threshold - (snow_dip * above_fraction.to_f64())
	}

	## The bearing seen at `x` across the screen.
	bearing_at : Mountains.Sight, F64 -> Angle.Bearing
	bearing_at = |sight, x| {
		slope = (x - Screen.center_x) / sight.cam_focal.to_f64()
		off_center = Angle.Turn.radians(Trig.r_atan(slope))
		sight.heading.plus(off_center)
	}

	## The skyline's height at `bearing`: the highest of the land and the two
	## ranges.
	horizon_crest_px : Angle.Bearing -> F64
	horizon_crest_px = |bearing| DeviceMath.real_max(
		west_range(bearing),
		DeviceMath.real_max(north_range(bearing), ground_base(bearing)),
	)

	## Whether the sun, at `clock`, has sunk behind the skyline.
	is_sun_behind_mountains : Clock -> Bool
	is_sun_behind_mountains = |clock| {
		sun_top_px = (Sky.sun_height_px(clock) + Sky.sun_radius_px)
		sun_top_px < horizon_crest_px(Sky.sun_bearing)
	}

	## The skyline, back to front: the west range, the north range, the
	## north's snow, then the land.
	draw : {
		heading : Angle.Bearing,
		dusk : Fraction,
		cam_focal : Pixels,
	} -> List(Shapes.Shape)
	draw = |{ heading, dusk, cam_focal }| {
		sight = { heading, cam_focal }
		[
			silhouette(sight, { height_at: west_range, color: color_at_dusk(rock_west, dusk) }),
			silhouette(sight, { height_at: north_range, color: color_at_dusk(rock, dusk) }),
			snow(sight, snow_color(dusk)),
			silhouette(sight, { height_at: ground_base, color: land }),
		].join()
	}
}

## A mountain range: the bearing of its middle, how far it reaches either
## side, its height there, and the two frequencies of the ridges along it.
## The ridge frequencies are cycles per radian of turn from the middle.
MountainRange : {
	center : Angle.Bearing,
	half_width : Angle.Turn,
	peak : F64,
	ridge_a : F64,
	ridge_b : F64,
}

north : MountainRange
north = {
	center: Angle.north,
	half_width: Angle.Turn.radians(0.95),
	peak: 150.0,
	ridge_a: 8.0,
	ridge_b: 21.0,
}

west : MountainRange
west = {
	center: Mountains.west_range_bearing,
	half_width: Angle.Turn.radians(0.72),
	peak: 120.0,
	ridge_a: 11.0,
	ridge_b: 27.0,
}

## A range's height at `bearing`: highest in its middle, falling to nothing at
## its ends, with two ridges along it.
range_height : MountainRange, Angle.Bearing -> F64
range_height = |range, bearing| {
	from_center = bearing.turn_from(range.center)
	fraction = from_center.ratio_to(range.half_width)
	if DeviceMath.real_abs(fraction) >= 1.0 {
		0.0
	} else {
		envelope = Trig.r_cos(fraction * Trig.pi / 2.0)
		radians = from_center.to_radians()
		first_wave = 0.24 * Trig.r_cos(radians * range.ridge_a)
		second_wave = 0.16 * Trig.r_cos(radians * range.ridge_b + 1.0)
		ridge = 0.6 + first_wave + second_wave
		range.peak * envelope * ridge
	}
}

## The north range's peak is searched for every hundredth of a radian.
peak_sample_step : Angle.Turn
peak_sample_step = Angle.Turn.radians(0.01)

## The north range's peak height between `at` and half a radian, or
## `highest` where that is higher. Each sample's bearing is the last's plus
## the step.
north_peak_height_from : { at : Angle.Bearing, highest : F64 } -> F64
north_peak_height_from = |{ at, highest }|
	if at > Angle.Bearing.radians(0.5) {
		highest
	} else {
		north_peak_height_from({
			at: at.plus(peak_sample_step),
			highest: DeviceMath.real_max(highest, Mountains.north_range(at)),
		})
	}

## The screen's horizon, where a height of zero is drawn.
horizon_y : F64
horizon_y = Screen.horizon_y

## The screen's y for a height on the skyline.
height_y : Mountains.Sight, F64 -> F64
height_y = |sight, height| horizon_y - (height * sight.cam_focal.ratio_to(Lens.focal))

## The columns sampled, every `column_step` pixels from `from` up to `to`.
columns : { from : F64, to : F64 } -> List(F64)
columns = |{ from, to }| columns_onto([], { at: from, to })

columns_onto : List(F64), { at : F64, to : F64 } -> List(F64)
columns_onto = |sampled, { at, to }|
	if at > to {
		sampled
	} else {
		columns_onto(sampled.append(at), { at: (at + Mountains.column_step), to })
	}

## A silhouette across the screen, its top at `height_at` each bearing, closed
## along the horizon.
silhouette : Mountains.Sight,
{
	height_at : Angle.Bearing -> F64,
	color : I64,
} -> List(Shapes.Shape)
silhouette = |sight, { height_at, color }| {
	left = (0.0 - Mountains.roll_margin)
	right = (Screen.width + Mountains.roll_margin)
	crest = columns({ from: left, to: right }).map(
		|x| { x, y: height_y(sight, height_at(Mountains.bearing_at(sight, x))) },
	)
	Paint.polygon(color, crest.concat([{ x: right, y: horizon_y }, { x: left, y: horizon_y }]))
}

## The north range's snow: along its crest where the range is above the
## snowline, then back along the snowline.
snow : Mountains.Sight, I64 -> List(Shapes.Shape)
snow = |sight, color| {
	snowy = columns({ from: 0.0, to: Screen.width }).keep_if(
		|x| {
			bearing = Mountains.bearing_at(sight, x)
			Mountains.north_range(bearing) > (Mountains.snowline(bearing) + 0.01)
		},
	)
	if snowy.len() < 2 {
		[]
	} else {
		crest = snowy.map(
			|x| { x, y: height_y(sight, Mountains.north_range(Mountains.bearing_at(sight, x))) },
		)
		snowline = snowy.fold_rev(
			[],
			|x, back| back.append({
				x,
				y: height_y(sight, Mountains.snowline(Mountains.bearing_at(sight, x))),
			}),
		)
		Paint.polygon(color, crest.concat(snowline))
	}
}

# The bearing `radians` to the right of north.
north_by : F64 -> Angle.Bearing
north_by = |radians| Angle.Bearing.radians(radians)

# The west range's middle, `radians` to its right.
west_by : F64 -> Angle.Bearing
west_by = |radians| Mountains.west_range_bearing.plus(Angle.Turn.radians(radians))

expect Mountains.rock == 5991055
expect Mountains.rock_west == 3752799
expect Mountains.land == 4886339

expect Mountains.channel(Mountains.rock, 16) == 91.0
expect Mountains.channel(Mountains.rock, 8) == 106.0
expect Mountains.channel(Mountains.rock, 0) == 143.0
expect Mountains.channel(16777215, 16) == 255.0
expect Mountains.channel(0, 0) == 0.0

expect Mountains.color_at_dusk(Mountains.rock, Fraction.zero) == 5991055
expect Mountains.color_at_dusk(Mountains.rock_west, Fraction.zero) == 3752799
expect Mountains.color_at_dusk(Mountains.land, Fraction.zero) == 4886339
expect Mountains.color_at_dusk(Mountains.rock, Fraction.whole) == 3028296
expect Mountains.color_at_dusk(Mountains.rock_west, Fraction.whole) == 1909296
expect Mountains.color_at_dusk(Mountains.land, Fraction.whole) == 2443298
expect Mountains.color_at_dusk(Mountains.rock, Fraction.of(0.5)) == 4477035

expect Mountains.snow_color(Fraction.zero) == 15660024
expect Mountains.snow_color(Fraction.whole) == 4609128
expect Mountains.snow_color(Fraction.of(0.5)) == 10134704
expect Sky.pack(Mountains.snow_day) == 15660024
expect Sky.pack(Mountains.snow_night) == 4609128

expect Mountains.snow_color(Fraction.whole) > Mountains.color_at_dusk(
	Mountains.rock,
	Fraction.whole,
)
expect Mountains.snow_color(Fraction.zero) > Mountains.color_at_dusk(Mountains.rock, Fraction.zero)

expect [0.95, 1.0, 2.0, -0.95, -3.0].all(|radians| Mountains.north_range(north_by(radians)) == 0.0)
expect
	[
		west_by(0.8),
		west_by(-0.8),
		north_by(0.0),
		north_by(1.5),
	].all(|sight| Mountains.west_range(sight) == 0.0)

expect Mountains.north_range(north_by(0.0)) > 0.0
expect Mountains.north_range(north_by(0.94)) > 0.0
expect Mountains.north_range(north_by(0.0)) > Mountains.snow_threshold
expect !(Mountains.north_range(north_by(0.9)) > Mountains.snow_threshold)
expect Mountains.west_range(Mountains.west_range_bearing) > 0.0

expect Mountains.west_range_bearing.to_radians() == -2.0416
expect Mountains.snow_threshold == 124.0
expect Mountains.snow_dip == 10.0
expect Mountains.column_step == 2.0
expect Mountains.roll_margin == 200.0
expect Mountains.rock_night_dim.to_f64() == 0.5

expect Mountains.snowline(north_by(0.9)) == 124.0
expect Mountains.snowline(north_by(2.0)) == 124.0

expect Mountains.snowline(north_by(0.0)) < Mountains.snow_threshold
expect Mountains.snowline(north_by(0.0)) > Mountains.snow_threshold - Mountains.snow_dip
expect Mountains.snowline(north_by(0.5)) <= Mountains.snow_threshold
expect Mountains.snowline(north_by(0.5)) >= Mountains.snow_threshold - Mountains.snow_dip

expect Mountains.snow_peak_height > Mountains.snow_threshold
expect Mountains.snow_peak_height < 150.0

# The bearing seen at `x` across a 960-pixel screen.
seen_bearing : {
	heading : F64,
	cam_focal : Pixels,
	x : F64,
} -> F64
seen_bearing = |{ heading, cam_focal, x }|
	Mountains.bearing_at({ heading: north_by(heading), cam_focal }, x).to_radians()

expect
	seen_bearing({
		heading: 0.0,
		cam_focal: Pixels.of(500.0),
		x: 480.0,
	})
		== 0.0
expect
	seen_bearing({
		heading: 1.25,
		cam_focal: Pixels.of(500.0),
		x: 480.0,
	})
		== 1.25
expect
	seen_bearing({
		heading: 1.25,
		cam_focal: Pixels.of(100.0),
		x: 480.0,
	})
		== 1.25

# Bearings grow across the screen, and a shorter focal length spreads them.
expect
	seen_bearing({
		heading: 0.0,
		cam_focal: Pixels.of(500.0),
		x: 0.0,
	})
		< seen_bearing({
			heading: 0.0,
			cam_focal: Pixels.of(500.0),
			x: 480.0,
		})
expect
	seen_bearing({
		heading: 0.0,
		cam_focal: Pixels.of(500.0),
		x: 480.0,
	})
		< seen_bearing({
			heading: 0.0,
			cam_focal: Pixels.of(500.0),
			x: 960.0,
		})
expect
	seen_bearing({
		heading: 0.0,
		cam_focal: Pixels.of(100.0),
		x: 960.0,
	})
		> seen_bearing({
			heading: 0.0,
			cam_focal: Pixels.of(500.0),
			x: 960.0,
		})

expect Mountains.horizon_crest_px(north_by(0.0)) >= Mountains.ground_base(north_by(0.0))
expect Mountains.horizon_crest_px(north_by(2.0)) >= Mountains.ground_base(north_by(2.0))
expect Mountains.horizon_crest_px(north_by(0.0)) >= Mountains.north_range(north_by(0.0))
expect !Mountains.is_sun_behind_mountains(Clock.at_step(0))
expect Mountains.is_sun_behind_mountains(Clock.at_step(6000))
