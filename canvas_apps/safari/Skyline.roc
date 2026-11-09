## The skyline, the farthest of the ride's shapes and painted first among them,
## over the backdrop's sky, sun and grass: a high range to the north with snow on
## its peaks, a lower range to the west, and the rolling land in front of both.
## Each is a silhouette across the screen whose height depends on the bearing it
## is seen at and on the lens, so the skyline turns with the rider but never comes
## nearer. The rock darkens at dusk, and the snow goes blue. It is worked out
## each frame from the clock and the camera's heading and lens.
import Pixels
import Angle
import FarHeight
import FarRise
import Fraction
import Grass
import Lens
import ColorShade
import Polygon
import Screen
import lib.RgbColor
import lib.Shapes

Skyline :: [].{

	## The rolling land: low, and all the way round. It stands 18 pixels high on
	## average and rises and falls 12 either side of that, in 0.9 of a wave all
	## the way round, a little under one. The 1.9 sets where along the wave north
	## falls. Each number was tuned by eye.
	land_height : Angle.Bearing -> FarHeight
	land_height = |bearing|
		FarHeight.of(18.0 + 12.0 * (bearing.turn_from_north().to_radians() * 0.9 + 1.9).sin())

	## The north range's height at `bearing`.
	north_range_height : Angle.Bearing -> FarHeight
	north_range_height = |bearing| range_height(north_range, bearing)

	## The west range's height at `bearing`.
	west_range_height : Angle.Bearing -> FarHeight
	west_range_height = |bearing| range_height(west_range, bearing)

	## The skyline, back to front, for a camera facing `heading` through a lens
	## of `focal_length`: the west range, the north range, the north's snow, then the
	## land. `darkness` is how far the sky has darkened, and the rock and snow
	## darken as far.
	skyline_shapes : { heading : Angle.Bearing, focal_length : Pixels, .. },
	{
		darkness : Fraction,
	} -> List(Shapes.Shape)
	skyline_shapes = |aim, { darkness }| {
		sky_columns = sky_columns_for(aim)
		snow_shapes =
			match snow_shape(
				sky_columns,
				{ focal_length: aim.focal_length, color: snow_color(darkness) },
			) {
				Ok(snow) => [snow]
				Err(NoSnow) => []
			}
		[
			[
				silhouette(
					sky_columns,
					{
						focal_length: aim.focal_length,
						height_at: |column| Skyline.west_range_height(column.bearing),
						color: rock_color_at_darkness(west_rock, darkness),
						base_y: range_base_y,
					},
				),
				silhouette(
					sky_columns,
					{
						focal_length: aim.focal_length,
						height_at: |column| column.north_height,
						color: rock_color_at_darkness(north_rock, darkness),
						base_y: range_base_y,
					},
				),
			],
			snow_shapes,
			[
				silhouette(
					sky_columns,
					{
						focal_length: aim.focal_length,
						height_at: |column| Skyline.land_height(column.bearing),
						color: Grass.grass_color,
						base_y: land_base_y,
					},
				),
			],
		].join()
	}
}

## A column of the skyline: where it is across the screen, the bearing seen
## there, and the north range's height at that bearing, which the north range's
## silhouette and its snow both need.
SkylineColumn : {
	x : Pixels,
	bearing : Angle.Bearing,
	north_height : FarHeight,
}

## The skyline's columns, every `column_step` pixels from `Screen.drawn_left` to
## `Screen.drawn_right`, for a camera facing `heading` through a lens of
## `focal_length`.
sky_columns_for : { heading : Angle.Bearing, focal_length : Pixels, .. } -> List(SkylineColumn)
sky_columns_for = |aim|
	columns({ from: Screen.drawn_left, to: Screen.drawn_right }).map(
		|x| {
			bearing = bearing_at(aim, x)
			{ x, bearing, north_height: Skyline.north_range_height(bearing) }
		},
	)

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
	ColorShade.shade_color(color, Darkened(rock_night_dim.times(darkness)))

snow_color : Fraction -> RgbColor
snow_color = |darkness| ColorShade.color_between({
	from: snow_day,
	to: snow_night,
	fraction: darkness,
})

west_range_bearing : Angle.Bearing
west_range_bearing = Angle.Bearing.radians(-2.0416)

## The north range is snowy above this height.
snow_threshold : FarHeight
snow_threshold = FarHeight.of(124.0)

## How far the snowline dips below the threshold under the highest peak.
snow_dip : FarRise
snow_dip = FarRise.of(10.0)

## The silhouettes are sampled every `column_step` pixels across the screen.
column_step : Pixels
column_step = Pixels.of(2.0)

## The height of the north range's highest peak, as its samples across the
## whole range find it.
snow_peak_height : FarHeight
snow_peak_height = {
	first = north_range.center.plus(Angle.straight_ahead.minus(north_range.half_width))
	last = north_range.center.plus(north_range.half_width)
	var $highest = Skyline.north_range_height(first)
	var $at = first.plus(peak_sample_step)
	while $at <= last {
		$highest = $highest.max(Skyline.north_range_height($at))
		$at = $at.plus(peak_sample_step)
	}
	$highest
}

## The snowline's height where the north range stands `north_height` high: at
## the threshold, dipping lower under the higher peaks.
snowline_under : FarHeight -> FarHeight
snowline_under = |north_height| {
	above_threshold = north_height.minus(snow_threshold)
	peak_above_threshold = snow_peak_height.minus(snow_threshold)
	above_fraction = Fraction.clamp(above_threshold.ratio_to(peak_above_threshold))
	snow_threshold.lowered_by(snow_dip.scaled_by(above_fraction))
}

## The bearing seen at `x` across the screen.
bearing_at : { heading : Angle.Bearing, focal_length : Pixels, .. }, Pixels -> Angle.Bearing
bearing_at = |aim, x| aim.heading.plus(Lens.turn_at_x({ x, focal_length: aim.focal_length }))

## A mountain range: the bearing of its middle, how far it reaches either
## side, how far above the horizon it reaches at most, and the two frequencies of the ridges
## along it, broad and fine. Each ridge frequency is how many waves would fit
## a whole turn.
MountainRange : {
	center : Angle.Bearing,
	half_width : Angle.Turn,
	height_ceiling : FarRise,
	broad_ridge_waves : F64,
	fine_ridge_waves : F64,
}

north_range : MountainRange
north_range = {
	center: Angle.north,
	half_width: Angle.Turn.radians(0.95),
	height_ceiling: FarRise.of(150.0),
	broad_ridge_waves: 8.0,
	fine_ridge_waves: 21.0,
}

west_range : MountainRange
west_range = {
	center: west_range_bearing,
	half_width: Angle.Turn.radians(0.72),
	height_ceiling: FarRise.of(120.0),
	broad_ridge_waves: 11.0,
	fine_ridge_waves: 27.0,
}

## A range's height at `bearing`: under an envelope that is highest in its
## middle and falls to nothing at its ends, with two ridges along it. The ridge
## line sits at 0.6 of the envelope, and the broad ridges rise and fall 0.24
## either side of it and the fine ones 0.16, so the three add up to the whole
## envelope at most. The fine ridges start a radian along, so the two don't peak
## together in the middle. The shares were tuned by eye.
range_height : MountainRange, Angle.Bearing -> FarHeight
range_height = |range, bearing| {
	from_center = bearing.turn_from(range.center)
	fraction = from_center.ratio_to(range.half_width)
	if fraction.abs() >= 1.0 {
		FarHeight.zero
	} else {
		envelope = (fraction * F64.pi / 2.0).cos()
		radians = from_center.to_radians()
		first_wave = 0.24 * (radians * range.broad_ridge_waves).cos()
		second_wave = 0.16 * (radians * range.fine_ridge_waves + 1.0).cos()
		ridge = 0.6 + first_wave + second_wave
		FarHeight.zero.plus(range.height_ceiling.times(envelope).times(ridge))
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

## A silhouette across the screen, its top at `height_at` each of `sky_columns`
## through a lens of `focal_length`, but never below `base_y`, closed along
## `base_y`.
silhouette :
	List(SkylineColumn),
	{
		focal_length : Pixels,
		height_at : SkylineColumn -> FarHeight,
		color : RgbColor,
		base_y : Pixels,
	} -> Shapes.Shape
silhouette = |sky_columns, { focal_length, height_at, color, base_y }| {
	left = Screen.drawn_left
	right = Screen.drawn_right
	crest = sky_columns.map(
		|column| {
			top_y = Lens.y_for_height({ height: height_at(column), focal_length })
			{
				x: column.x,
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
thinnest_snow : FarRise
thinnest_snow = FarRise.of(0.01)

## The north range's snow: along its crest where the range is above the
## snowline, then back along the snowline, unless fewer than two of
## `sky_columns` on the screen itself show snow.
snow_shape :
	List(SkylineColumn), { focal_length : Pixels, color : RgbColor } -> Try(Shapes.Shape, [NoSnow])
snow_shape = |sky_columns, { focal_length, color }| {
	snowy =
		sky_columns
			.keep_if(|column| column.x >= Pixels.zero and column.x <= Screen.width)
			.map(
				|column| {
					x: column.x,
					north_height: column.north_height,
					snowline_height: snowline_under(column.north_height),
				},
			)
			.keep_if(|column| column.north_height > column.snowline_height.plus(thinnest_snow))
	if snowy.len() < 2 {
		Err(NoSnow)
	} else {
		crest = snowy.map(
			|column| {
				height = column.north_height
				{ x: column.x, y: Lens.y_for_height({ height, focal_length }) }
			},
		)
		snowline_points = snowy.fold_rev(
			[],
			|column, back| {
				height = column.snowline_height
				back.append({ x: column.x, y: Lens.y_for_height({ height, focal_length }) })
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

aim_at_rest : { heading : Angle.Bearing, focal_length : Pixels }
aim_at_rest = { heading: Angle.north, focal_length: Lens.resting_focal_length }

expect rock_color_at_darkness(north_rock, Fraction.zero) == RgbColor.of(0x5B6A8F)
expect rock_color_at_darkness(west_rock, Fraction.zero) == RgbColor.of(0x39435F)
expect rock_color_at_darkness(north_rock, Fraction.whole) == RgbColor.of(0x2E3548)
expect rock_color_at_darkness(west_rock, Fraction.whole) == RgbColor.of(0x1D2230)
expect rock_color_at_darkness(north_rock, Fraction.of(0.5)) == RgbColor.of(0x44506B)

expect snow_color(Fraction.zero) == RgbColor.of(0xEEF3F8)
expect snow_color(Fraction.whole) == RgbColor.of(0x465468)
expect snow_color(Fraction.of(0.5)) == RgbColor.of(0x9AA4B0)

## A color's brightness: the sum of its three channels, widened first because
## the sum can pass a channel's 255.
brightness : RgbColor -> I64
brightness = |color| color.red().to_i64() + color.green().to_i64() + color.blue().to_i64()

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
		|radians| Skyline.north_range_height(north_by(radians)) == FarHeight.zero,
	)
expect
	[
		west_by(0.8),
		west_by(-0.8),
		north_by(0.0),
		north_by(1.5),
	].all(|bearing| Skyline.west_range_height(bearing) == FarHeight.zero)

expect Skyline.north_range_height(north_by(0.0)) > FarHeight.zero
expect Skyline.north_range_height(north_by(0.94)) > FarHeight.zero
expect Skyline.north_range_height(north_by(0.0)) > snow_threshold
expect !(Skyline.north_range_height(north_by(0.9)) > snow_threshold)
expect Skyline.west_range_height(west_range_bearing) > FarHeight.zero

expect snowline_under(Skyline.north_range_height(north_by(0.9))) == snow_threshold
expect snowline_under(Skyline.north_range_height(north_by(2.0))) == snow_threshold

expect snowline_under(Skyline.north_range_height(north_by(0.0))) < snow_threshold
expect {
	deepest_snowline = snow_threshold.lowered_by(snow_dip)
	snowline_under(Skyline.north_range_height(north_by(0.0))) > deepest_snowline
}
expect snowline_under(Skyline.north_range_height(north_by(0.5))) <= snow_threshold
expect {
	deepest_snowline = snow_threshold.lowered_by(snow_dip)
	snowline_under(Skyline.north_range_height(north_by(0.5))) >= deepest_snowline
}

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
		_ => crash "Skyline: a silhouette is a polygon"
	}

lowest_y : Shapes.Shape -> F64
lowest_y = |shape| corner_ys(shape).fold(-F64.infinity, |low, y| low.max(y))

highest_y : Shapes.Shape -> F64
highest_y = |shape| corner_ys(shape).fold(F64.infinity, |high, y| high.min(y))

range_silhouette : { heading : Angle.Bearing, focal_length : Pixels } -> Shapes.Shape
range_silhouette = |aim| silhouette(
	sky_columns_for(aim),
	{
		focal_length: aim.focal_length,
		height_at: |column| column.north_height,
		color: north_rock,
		base_y: range_base_y,
	},
)

land_silhouette : { heading : Angle.Bearing, focal_length : Pixels } -> Shapes.Shape
land_silhouette = |aim| silhouette(
	sky_columns_for(aim),
	{
		focal_length: aim.focal_length,
		height_at: |column| Skyline.land_height(column.bearing),
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
