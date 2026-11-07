## The skyline, the farthest of the ride's shapes and painted first among them,
## over the backdrop's sky, sun and grass: a high range to the north with snow on
## its peaks, a lower range to the west, and the rolling land in front of both.
## Each is a silhouette across the screen whose height depends on the bearing it
## is seen at and on the lens, so the skyline turns with the rider but never comes
## nearer. The rock darkens at dusk, and the snow goes blue.
import Pixels
import Angle
import Clock
import Fraction
import Grass
import Lens
import HexColor
import Polygon
import Screen
import Sun
import lib.RgbColor
import lib.Shapes

Mountains :: [].{

	## Whether the sun, at `clock`, has sunk behind the skyline.
	is_sun_behind_mountains : Clock -> Bool
	is_sun_behind_mountains = |clock| {
		sun_top = Sun.height_at(clock).plus(Sun.radius)
		sun_top < skyline_height(Sun.bearing)
	}

	## The skyline, back to front, for a camera facing `heading` through a lens
	## of `cam_focal`: the west range, the north range, the north's snow, then the
	## land.
	mountain_shapes :
		{ heading : Angle.Bearing, cam_focal : Pixels, .. }, Fraction -> List(Shapes.Shape)
	mountain_shapes = |aim, darkness| {
		snow_shapes =
			match snow_shape(aim, snow_color(darkness)) {
				Ok(snow) => [snow]
				Err(NoSnow) => []
			}
		[
			[
				silhouette(
					aim,
					{
						height_at: west_range_height,
						color: rock_color_at_darkness(west_rock, darkness),
						base_y: range_base_y,
					},
				),
				silhouette(
					aim,
					{
						height_at: north_range_height,
						color: rock_color_at_darkness(north_rock, darkness),
						base_y: range_base_y,
					},
				),
			],
			snow_shapes,
			[
				silhouette(
					aim,
					{
						height_at: land_height,
						color: Grass.grass_color,
						base_y: land_base_y,
					},
				),
			],
		].join()
	}
}

north_rock : RgbColor
north_rock = RgbColor.of(0x5B6A8F)

west_rock : RgbColor
west_rock = RgbColor.of(0x39435F)

## How much of its light the rock loses at full darkness.
rock_night_dim : Fraction
rock_night_dim = Fraction.of(0.5)

snow_day : RgbColor
snow_day = RgbColor.of(0xEEF3F8)

snow_night : RgbColor
snow_night = RgbColor.of(0x465468)

## A rock colour at `darkness`, from 0 (day) to 1 (night).
rock_color_at_darkness : RgbColor, Fraction -> RgbColor
rock_color_at_darkness = |color, darkness|
	HexColor.shade_color(color, rock_night_dim.times(darkness).less().to_f64())

snow_color : Fraction -> RgbColor
snow_color = |darkness| HexColor.color_between({
	from: snow_day,
	to: snow_night,
	fraction: darkness,
})

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

## The rolling land: low, and all the way round. It stands 18 pixels high on
## average and rises and falls 12 either side of that, in 0.9 of a wave all
## the way round, a little under one. The 1.9 sets where along the wave north
## falls. Each number was tuned by eye.
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
	above_fraction = Fraction.clamp(above_threshold.portion(peak_above_threshold))
	snow_threshold.minus(snow_dip.times(above_fraction.to_f64()))
}

## The bearing seen at `x` across the screen.
bearing_at : { heading : Angle.Bearing, cam_focal : Pixels, .. }, Pixels -> Angle.Bearing
bearing_at = |aim, x| aim.heading.plus(Lens.turn_at_x({ x, cam_focal: aim.cam_focal }))

## The skyline's height at `bearing`: the highest of the land and the two
## ranges.
skyline_height : Angle.Bearing -> Pixels
skyline_height = |bearing| {
	north_or_land = north_range_height(bearing).max(land_height(bearing))
	west_range_height(bearing).max(north_or_land)
}

## A mountain range: the bearing of its middle, how far it reaches either
## side, the height it never passes, and the two frequencies of the ridges
## along it, broad and fine. Each ridge frequency is how many waves would fit
## a whole turn.
MountainRange : {
	center : Angle.Bearing,
	half_width : Angle.Turn,
	height_ceiling : Pixels,
	broad_ridge_waves : F64,
	fine_ridge_waves : F64,
}

north : MountainRange
north = {
	center: Angle.north,
	half_width: Angle.Turn.radians(0.95),
	height_ceiling: Pixels.of(150.0),
	broad_ridge_waves: 8.0,
	fine_ridge_waves: 21.0,
}

west : MountainRange
west = {
	center: west_range_bearing,
	half_width: Angle.Turn.radians(0.72),
	height_ceiling: Pixels.of(120.0),
	broad_ridge_waves: 11.0,
	fine_ridge_waves: 27.0,
}

## A range's height at `bearing`: under an envelope that is highest in its
## middle and falls to nothing at its ends, with two ridges along it. The ridge
## line sits at 0.6 of the envelope, and the broad ridges rise and fall 0.24
## either side of it and the fine ones 0.16, so the three add up to the whole
## envelope at most. The fine ridges start a radian along, so the two don't peak
## together in the middle. The shares were tuned by eye.
range_height : MountainRange, Angle.Bearing -> Pixels
range_height = |range, bearing| {
	from_center = bearing.turn_from(range.center)
	fraction = from_center.portion(range.half_width)
	if fraction.abs() >= 1.0 {
		Pixels.zero
	} else {
		envelope = (fraction * F64.pi / 2.0).cos()
		radians = from_center.to_radians()
		first_wave = 0.24 * (radians * range.broad_ridge_waves).cos()
		second_wave = 0.16 * (radians * range.fine_ridge_waves + 1.0).cos()
		ridge = 0.6 + first_wave + second_wave
		range.height_ceiling.times(envelope).times(ridge)
	}
}

## The north range's peak is searched for every hundredth of a radian.
peak_sample_step : Angle.Turn
peak_sample_step = Angle.Turn.radians(0.01)

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

## The ranges are seen only above the grass, so they stop where it begins.
range_base_y : Pixels
range_base_y = Grass.grass_top_y

## The land is in front of the ranges and closes along the horizon. The grass
## begins a pixel above the horizon so that no seam shows under the roll, and
## the land reaches that same pixel past the ranges' foot, for the same reason.
land_base_y : Pixels
land_base_y = Screen.horizon_y

## A silhouette across the screen, its top at `height_at` each bearing but never
## below `base_y`, closed along `base_y`.
silhouette :
	{ heading : Angle.Bearing, cam_focal : Pixels, .. },
	{
		height_at : Angle.Bearing -> Pixels,
		color : RgbColor,
		base_y : Pixels,
	} -> Shapes.Shape
silhouette = |aim, { height_at, color, base_y }| {
	left = Screen.roll_margin.opposite()
	right = Screen.width.plus(Screen.roll_margin)
	crest = columns({ from: left, to: right }).map(
		|x| {
			height = height_at(bearing_at(aim, x))
			top_y = Lens.y_for_height({ height, cam_focal: aim.cam_focal })
			{
				x,
				y: if top_y > base_y {
					base_y
				} else {
					top_y
				},
			}
		},
	)
	Polygon.flat_polygon(crest.concat([{ x: right, y: base_y }, { x: left, y: base_y }]), color)
}

## Snow thinner than this, between the range's crest and the snowline, isn't
## drawn.
thinnest_snow : Pixels
thinnest_snow = Pixels.of(0.01)

## The north range's snow: along its crest where the range is above the
## snowline, then back along the snowline, unless fewer than two columns of
## the screen show snow.
snow_shape :
	{ heading : Angle.Bearing, cam_focal : Pixels, .. }, RgbColor -> Try(Shapes.Shape, [NoSnow])
snow_shape = |aim, color| {
	snowy = columns({ from: Pixels.zero, to: Screen.width }).keep_if(
		|x| {
			bearing = bearing_at(aim, x)
			north_range_height(bearing) > snowline(bearing).plus(thinnest_snow)
		},
	)
	if snowy.len() < 2 {
		Err(NoSnow)
	} else {
		crest = snowy.map(
			|x| {
				height = north_range_height(bearing_at(aim, x))
				{ x, y: Lens.y_for_height({ height, cam_focal: aim.cam_focal }) }
			},
		)
		snowline_points = snowy.fold_rev(
			[],
			|x, back| {
				height = snowline(bearing_at(aim, x))
				back.append({ x, y: Lens.y_for_height({ height, cam_focal: aim.cam_focal }) })
			},
		)
		Ok(Polygon.flat_polygon(crest.concat(snowline_points), color))
	}
}

# The bearing `radians` to the right of north.
north_by : F64 -> Angle.Bearing
north_by = |radians| Angle.Bearing.radians(radians)

# The west range's middle, `radians` to its right.
west_by : F64 -> Angle.Bearing
west_by = |radians| west_range_bearing.plus(Angle.Turn.radians(radians))

aim_at_rest : { heading : Angle.Bearing, cam_focal : Pixels }
aim_at_rest = { heading: Angle.north, cam_focal: Lens.resting_focal }

expect rock_color_at_darkness(north_rock, Fraction.zero) == RgbColor.of(0x5B6A8F)
expect rock_color_at_darkness(west_rock, Fraction.zero) == RgbColor.of(0x39435F)
expect rock_color_at_darkness(north_rock, Fraction.whole) == RgbColor.of(0x2E3548)
expect rock_color_at_darkness(west_rock, Fraction.whole) == RgbColor.of(0x1D2230)
expect rock_color_at_darkness(north_rock, Fraction.of(0.5)) == RgbColor.of(0x44506B)

expect snow_color(Fraction.zero) == RgbColor.of(0xEEF3F8)
expect snow_color(Fraction.whole) == RgbColor.of(0x465468)
expect snow_color(Fraction.of(0.5)) == RgbColor.of(0x9AA4B0)

## A color's brightness: the sum of its three channels.
brightness : RgbColor -> I64
brightness = |color| HexColor.red_of(color) + HexColor.green_of(color) + HexColor.blue_of(color)

# The snow stays brighter than the rock it lies on, by day and at dusk.
expect
	[Fraction.zero, Fraction.whole].all(
		|darkness| {
			rock = rock_color_at_darkness(north_rock, darkness)
			brightness(snow_color(darkness)) > brightness(rock)
		},
	)

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
	].all(|bearing| west_range_height(bearing) == Pixels.zero)

expect north_range_height(north_by(0.0)) > Pixels.zero
expect north_range_height(north_by(0.94)) > Pixels.zero
expect north_range_height(north_by(0.0)) > snow_threshold
expect !(north_range_height(north_by(0.9)) > snow_threshold)
expect west_range_height(west_range_bearing) > Pixels.zero

expect snowline(north_by(0.9)) == snow_threshold
expect snowline(north_by(2.0)) == snow_threshold

expect snowline(north_by(0.0)) < snow_threshold
expect snowline(north_by(0.0)) > snow_threshold.minus(snow_dip)
expect snowline(north_by(0.5)) <= snow_threshold
expect snowline(north_by(0.5)) >= snow_threshold.minus(snow_dip)

expect snow_peak_height > snow_threshold

# The y of each corner of a silhouette.
corner_ys : Shapes.Shape -> List(F64)
corner_ys = |shape|
	match shape {
		Poly(p) =>
			p.coordinates.fold(
				{ ys: [], is_y: False },
				|walk, n| {
					ys: if walk.is_y {
						walk.ys.append(n)
					} else {
						walk.ys
					},
					is_y: !walk.is_y,
				},
			).ys
		_ => crash "Mountains: a silhouette is a polygon"
	}

lowest_y : Shapes.Shape -> F64
lowest_y = |shape| corner_ys(shape).fold(-F64.infinity, |low, y| low.max(y))

highest_y : Shapes.Shape -> F64
highest_y = |shape| corner_ys(shape).fold(F64.infinity, |high, y| high.min(y))

range_silhouette : { heading : Angle.Bearing, cam_focal : Pixels } -> Shapes.Shape
range_silhouette = |aim| silhouette(
	aim,
	{
		height_at: north_range_height,
		color: north_rock,
		base_y: range_base_y,
	},
)

land_silhouette : { heading : Angle.Bearing, cam_focal : Pixels } -> Shapes.Shape
land_silhouette = |aim| silhouette(
	aim,
	{
		height_at: land_height,
		color: Grass.grass_color,
		base_y: land_base_y,
	},
)

# Facing south, the north range is out of sight: it lies flat along its base,
# never below it.
expect {
	south = range_silhouette({ ..aim_at_rest, heading: north_by(3.0) })
	lowest_y(south) == range_base_y.to_f64() and highest_y(south) == range_base_y.to_f64()
}

# Facing north, it stands above its base, and still closes along it.
expect {
	north_view = range_silhouette(aim_at_rest)
	lowest_y(north_view) == range_base_y.to_f64() and highest_y(north_view) < range_base_y.to_f64()
}

# The land closes along its own base, below the ranges'.
expect lowest_y(land_silhouette(aim_at_rest)) == land_base_y.to_f64()
expect highest_y(land_silhouette(aim_at_rest)) < range_base_y.to_f64()

expect !Mountains.is_sun_behind_mountains(Clock.at_step(0))
expect Mountains.is_sun_behind_mountains(Clock.at_step(6000))
