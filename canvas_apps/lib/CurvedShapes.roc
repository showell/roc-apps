## CurvedShapes builds the round things a frame draws out of straight-edged
## shapes, so no painter has to learn a curve or a stroke: a ring is a band of
## quads, and a rounded rectangle is a polygon whose corners step round each
## quarter turn. The shapes are `Shapes`' own.
import Brush
import Pixels
import Point
import Shapes

CurvedShapes :: [].{

	## A circle's outline, `line_width` wide around the rim, as `sides` sectors
	## of the band between two circles. Neighbouring sectors share their edge
	## exactly, so the band has no gap at a corner. A disc under a smaller disc
	## makes a ring too, but only on a background of a known flat color. Fewer
	## than three sides enclose nothing, and crash.
	ring_shapes : {
		center : Point,
		radius : Pixels,
		line_width : Pixels,
		sides : U64,
	},
	Brush.Fill -> List(Shapes.Shape)
	ring_shapes = |{ center, radius, line_width, sides }, fill|
		if sides < 3 {
			crash "CurvedShapes.ring_shapes: a ring needs at least three sides"
		} else {
			inner_radius = radius.to_f64() - line_width.to_f64() / 2.0
			outer_radius = radius.to_f64() + line_width.to_f64() / 2.0
			cx = center.x.to_f64()
			cy = center.y.to_f64()
			# The last side ends at angle 0 itself, not at a whole turn, so it
			# meets the first side's corners exactly.
			rim_point = |rim_radius, side| {
				angle = F64.tau * (side % sides).to_f64() / sides.to_f64()
				Point.at(cx + rim_radius * angle.cos(), cy + rim_radius * angle.sin())
			}
			var $out = List.with_capacity(sides)
			for k in 0..<sides {
				sector = Quad({
					first: rim_point(outer_radius, k),
					second: rim_point(outer_radius, k + 1),
					third: rim_point(inner_radius, k + 1),
					fourth: rim_point(inner_radius, k),
					fill,
				})
				$out = $out.append(sector)
			}
			$out
		}

	## A rectangle whose corners are rounded by `corner_radius`, each corner drawn in
	## `corner_steps` steps. A radius of zero or no steps gives the plain box, and a
	## radius too big for the box is held to half its shorter side.
	rounded_rect : {
		top_left : Point,
		width : Pixels,
		height : Pixels,
		corner_radius : Pixels,
		corner_steps : U64,
	},
	Brush.Fill -> Shapes.Shape
	rounded_rect = |box, fill| {
		x = box.top_left.x.to_f64()
		y = box.top_left.y.to_f64()
		width = box.width.to_f64()
		height = box.height.to_f64()
		corner_steps = box.corner_steps
		radius = F64.min(box.corner_radius.to_f64(), (width / 2.0).min(height / 2.0))
		if radius <= 0.0 or corner_steps == 0 {
			Shapes.rectangle({
				top_left: box.top_left,
				width: box.width,
				height: box.height,
				fill,
			})
		} else {
			var $corners = List.with_capacity(4 * (corner_steps + 1))
			# Clockwise from the top-left corner, each swept from its own start angle.
			$corners = quarter_turn_corners(
				$corners,
				{
					center: { x: x + radius, y: y + radius },
					radius,
					start_angle: half_pi * 2.0,
					steps: corner_steps,
				},
			)
			$corners = quarter_turn_corners(
				$corners,
				{
					center: { x: x + width - radius, y: y + radius },
					radius,
					start_angle: -half_pi,
					steps: corner_steps,
				},
			)
			$corners = quarter_turn_corners(
				$corners,
				{
					center: { x: x + width - radius, y: y + height - radius },
					radius,
					start_angle: 0.0,
					steps: corner_steps,
				},
			)
			$corners = quarter_turn_corners(
				$corners,
				{
					center: { x: x + radius, y: y + height - radius },
					radius,
					start_angle: half_pi,
					steps: corner_steps,
				},
			)
			Polygon({ corners: $corners, fill })
		}
	}
}

half_pi : F64
half_pi = F64.pi / 2.0

## The corners of a quarter turn about `center`, starting at `start_angle`,
## onto `corners`.
quarter_turn_corners : List(Point),
{
	center : { x : F64, y : F64 },
	radius : F64,
	start_angle : F64,
	steps : U64,
} -> List(Point)
quarter_turn_corners = |corners, { center, radius, start_angle, steps }| {
	var $out = corners
	for k in 0..=steps {
		angle = start_angle + half_pi * k.to_f64() / steps.to_f64()
		$out = $out.append(Point.at(center.x + radius * angle.cos(), center.y + radius * angle.sin()))
	}
	$out
}

## The fill the shapes below are drawn in.
ink : Brush.Fill
ink = Flat({
	r: 32.0,
	g: 32.0,
	b: 32.0,
	a: 1.0,
})

# The fewest sides a ring may have make three sectors.
expect CurvedShapes.ring_shapes(
	{
		center: Point.at(0.0, 0.0),
		radius: Pixels.of(5.0),
		line_width: Pixels.of(1.0),
		sides: 3,
	},
	ink,
).len() == 3

## A ring sector's corners: outer start, outer end, inner end, inner start.
sector_corners : Shapes.Shape -> List(Point)
sector_corners = |shape|
	match shape {
		Quad(quad) => [quad.first, quad.second, quad.third, quad.fourth]
		Triangle(_) | Disc(_) | Polygon(_) | Blend(_) | View(_) | Image(_) | Text(_) => crash "CurvedShapes: a ring's sectors are all quads"
	}

# Each sector starts where the one before it ends, outer corner and inner
# corner, all the way round to the first again. Its inner corners sit nearer
# the center than its outer ones, by the line's width.
expect {
	sectors = CurvedShapes.ring_shapes(
		{
			center: Point.at(3.0, 4.0),
			radius: Pixels.of(10.0),
			line_width: Pixels.of(2.0),
			sides: 7,
		},
		ink,
	).map(sector_corners)
	first = sectors.first() ?? crash "CurvedShapes: a ring of seven sides has sectors"
	following = sectors.drop_first(1).append(first)
	shared = List.map2(
		sectors,
		following,
		|sector, next| sector.get(1) == next.get(0) and sector.get(2) == next.get(3),
	)
	outer = first.get(0) ?? crash "CurvedShapes: a sector has an outer start corner"
	inner = first.get(3) ?? crash "CurvedShapes: a sector has an inner start corner"
	sectors.len() == 7 and shared.all(|same| same) and outer.x - inner.x == Pixels.of(2.0)
}
