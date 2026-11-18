## Dishes draws the three dishes the robots bring: a turkey on a platter, a
## bowl of mashed potatoes, and a pumpkin pie. Each is drawn from the middle
## of its base on the screen, at a size of pixels a metre, tipped by `tilt`
## radians about that point, so the same drawing serves a dish held up, a dish
## wobbling, and a dish set on the table.
import lib.Brush
import lib.Pixels
import lib.Point
import lib.RgbColor
import lib.Shapes

Dishes :: [].{

	Dish : [Turkey, Potatoes, Pie]

	dish_shapes : Dishes.Dish,
	{
		base : Point,
		pixels_per_metre : F64,
		tilt : F64,
	} -> List(Shapes.Shape)
	dish_shapes = |dish, { base, pixels_per_metre, tilt }| {
		place = {
			x: base.x.to_f64(),
			y: base.y.to_f64(),
			scale: pixels_per_metre * oversize,
			cosine: tilt.cos(),
			sine: tilt.sin(),
		}
		match dish {
			Turkey => turkey_shapes(place)
			Potatoes => potato_shapes(place)
			Pie => pie_shapes(place)
		}
	}
}

# A dish is drawn bigger than life, because a pie at its true size halfway
# down the table is a few pixels across.
oversize : F64
oversize = 1.7

# Where a dish is on the screen, and how it is tipped.
Place : {
	x : F64,
	y : F64,
	scale : F64,
	cosine : F64,
	sine : F64,
}

# A point on the dish, `across` and `up` metres from the middle of its base.
screen_point : Place, { across : F64, up : F64 } -> Point
screen_point = |place, { across, up }| {
	turned_across = across * place.cosine - up * place.sine
	turned_up = across * place.sine + up * place.cosine
	Point.at(place.x + turned_across * place.scale, place.y - turned_up * place.scale)
}

# An oval, or the part of one between two angles, as a region.
Oval : {
	across : F64,
	up : F64,
	wide : F64,
	high : F64,
}

oval_shape : Place, { oval : Oval, fill : Brush.Fill } -> Shapes.Shape
oval_shape = |place, { oval, fill }| arc_shape(
	place,
	{
		oval,
		from: 0.0,
		to: F64.tau,
		fill,
	},
)

arc_shape : Place,
{
	oval : Oval,
	from : F64,
	to : F64,
	fill : Brush.Fill,
} -> Shapes.Shape
arc_shape = |place, { oval, from, to, fill }| {
	sides : U64
	sides = 20
	var $corners = List.with_capacity(sides + 1)
	for k in 0..=sides {
		angle = from + (to - from) * k.to_f64() / sides.to_f64()
		$corners = $corners.append(
			screen_point(
				place,
				{
					across: oval.across + oval.wide * angle.cos(),
					up: oval.up + oval.high * angle.sin(),
				},
			),
		)
	}
	Shapes.region_from_corners($corners, fill)
}

flat : I64 -> Brush.Fill
flat = |hex| Flat(Brush.opaque_rgba(RgbColor.of(hex)))

turkey_shapes : Place -> List(Shapes.Shape)
turkey_shapes = |place| [
	oval_shape(
		place,
		{
			oval: {
				across: 0.0,
				up: 0.015,
				wide: 0.22,
				high: 0.04,
			},
			fill: flat(0xA9B0B8),
		},
	),
	oval_shape(
		place,
		{
			oval: {
				across: 0.0,
				up: 0.02,
				wide: 0.2,
				high: 0.03,
			},
			fill: flat(0xE4E7EB),
		},
	),
	Disc({
		center: screen_point(place, { across: -0.16, up: 0.03 }),
		radius: Pixels.of(0.025 * place.scale),
		fill: flat(0x5E8F3A),
	}),
	Disc({
		center: screen_point(place, { across: 0.16, up: 0.03 }),
		radius: Pixels.of(0.025 * place.scale),
		fill: flat(0x5E8F3A),
	}),
	oval_shape(
		place,
		{
			oval: {
				across: -0.11,
				up: 0.05,
				wide: 0.06,
				high: 0.035,
			},
			fill: flat(0x8A431C),
		},
	),
	oval_shape(
		place,
		{
			oval: {
				across: 0.11,
				up: 0.05,
				wide: 0.06,
				high: 0.035,
			},
			fill: flat(0x8A431C),
		},
	),
	Disc({
		center: screen_point(place, { across: -0.17, up: 0.065 }),
		radius: Pixels.of(0.016 * place.scale),
		fill: flat(0xF4EAD2),
	}),
	Disc({
		center: screen_point(place, { across: 0.17, up: 0.065 }),
		radius: Pixels.of(0.016 * place.scale),
		fill: flat(0xF4EAD2),
	}),
	oval_shape(
		place,
		{
			oval: {
				across: 0.0,
				up: 0.075,
				wide: 0.13,
				high: 0.075,
			},
			fill: flat(0x9C4F22),
		},
	),
	oval_shape(
		place,
		{
			oval: {
				across: -0.03,
				up: 0.1,
				wide: 0.06,
				high: 0.03,
			},
			fill: flat(0xC7743A),
		},
	),
]

potato_shapes : Place -> List(Shapes.Shape)
potato_shapes = |place| [
	arc_shape(
		place,
		{
			oval: {
				across: 0.0,
				up: 0.08,
				wide: 0.12,
				high: 0.08,
			},
			from: F64.pi,
			to: F64.tau,
			fill: flat(0x3F78B5),
		},
	),
	oval_shape(
		place,
		{
			oval: {
				across: 0.0,
				up: 0.08,
				wide: 0.12,
				high: 0.022,
			},
			fill: flat(0x2F5F99),
		},
	),
	oval_shape(
		place,
		{
			oval: {
				across: 0.0,
				up: 0.09,
				wide: 0.1,
				high: 0.045,
			},
			fill: flat(0xF4E7C0),
		},
	),
	oval_shape(
		place,
		{
			oval: {
				across: -0.03,
				up: 0.105,
				wide: 0.04,
				high: 0.02,
			},
			fill: flat(0xFFF6DC),
		},
	),
	Shapes.rounded_rect(
		{
			top_left: screen_point(place, { across: 0.0, up: 0.14 }),
			width: Pixels.of(0.035 * place.scale),
			height: Pixels.of(0.025 * place.scale),
			corner_radius: Pixels.of(0.006 * place.scale),
			corner_steps: 2,
		},
		flat(0xF7D35A),
	),
]

pie_shapes : Place -> List(Shapes.Shape)
pie_shapes = |place| [
	Shapes.region_from_corners(
		[
			screen_point(place, { across: -0.13, up: 0.0 }),
			screen_point(place, { across: 0.13, up: 0.0 }),
			screen_point(place, { across: 0.15, up: 0.04 }),
			screen_point(place, { across: -0.15, up: 0.04 }),
		],
		flat(0x9FA3AD),
	),
	oval_shape(
		place,
		{
			oval: {
				across: 0.0,
				up: 0.04,
				wide: 0.15,
				high: 0.03,
			},
			fill: flat(0xD9A056),
		},
	),
	oval_shape(
		place,
		{
			oval: {
				across: 0.0,
				up: 0.043,
				wide: 0.125,
				high: 0.021,
			},
			fill: flat(0xC2642B),
		},
	),
	Disc({
		center: screen_point(place, { across: 0.0, up: 0.055 }),
		radius: Pixels.of(0.025 * place.scale),
		fill: flat(0xFFF8EC),
	}),
]

# Each dish is drawn, and a tipped dish moves its corners but not its base.
expect {
	base = Point.at(200.0, 300.0)
	upright = Dishes.dish_shapes(Pie, { base, pixels_per_metre: 100.0, tilt: 0.0 })
	tipped = Dishes.dish_shapes(Pie, { base, pixels_per_metre: 100.0, tilt: 0.3 })
	upright.len() == 4 and tipped.len() == 4 and upright != tipped
}
expect Dishes.dish_shapes(
	Turkey,
	{
		base: Point.at(0.0, 0.0),
		pixels_per_metre: 50.0,
		tilt: 0.0,
	},
).len() == 10
expect Dishes.dish_shapes(
	Potatoes,
	{
		base: Point.at(0.0, 0.0),
		pixels_per_metre: 50.0,
		tilt: 0.0,
	},
).len() == 5
