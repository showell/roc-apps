## A still is a small picture made of polygons, each filled with a flat
## colour or a gradient. It is drawn in its own frame, in units of its height:
## its feet at y 0, y up, and its height 1, with x across from its middle. A
## still that is wider than it is tall, such as a flying bird, has x past 1.
## The frame is a convention, not a rule: a set of poses, such as the cat's,
## shares one frame so that they line up, and a pose may reach past it.
## EmojiStills, CatStills and BirdStills hold the pictures, and StillShapes
## puts them on screen.
import Fraction
import lib.ArgbColor
import lib.RgbColor

Still :: List(Still.Polygon).{

	## The still made of `polygons`, drawn in their order. Each polygon is
	## checked once, here, and a flawed one crashes with a reason that says
	## where it is in the still's frame: a polygon of fewer than three
	## corners, a corner that repeats its neighbour (the last corner's
	## neighbour is the first, as the polygon closes by itself), colour stops
	## whose start offset is past their end offset, a linear gradient that
	## starts where it ends, or a radial one whose axes span less than
	## `min_axes_area`.
	of : List(Still.Polygon) -> Still
	of = |polygons| {
		for polygon in polygons {
			match polygon_flaw(polygon) {
				Sound => {}
				Flawed(reason) => crash "Still.of: ${reason}"
			}
		}
		Still.(polygons)
	}

	## A place in the still's frame: a corner of a polygon, or where a
	## gradient starts, ends or is centred.
	FramePoint : { x : F64, y : F64 }

	## A step across the still's frame, a direction and a length but not a
	## place: one of a radial gradient's axes, measured from its center.
	Step : { x : F64, y : F64 }

	## A gradient's two colours, and where each sits along it: the start
	## colour up to `start_offset`, the end colour from `end_offset`, and a
	## mix of the two between.
	ColorStops : {
		start_color : ArgbColor,
		end_color : ArgbColor,
		start_offset : Fraction,
		end_offset : Fraction,
	}

	## A polygon's gradient as traced, with its two colours and where each
	## sits along it. A linear one runs from `start` to `end`. A radial one
	## spreads over an ellipse about `center`, whose two axes are the steps
	## `axis_u` and `axis_v`.
	Gradient : [
		Linear(
			{
				stops : Still.ColorStops,
				start : Still.FramePoint,
				end : Still.FramePoint,
			},
		),
		Radial(
			{
				stops : Still.ColorStops,
				center : Still.FramePoint,
				axis_u : Still.Step,
				axis_v : Still.Step,
			},
		),
	]

	## How a polygon of a still is filled: with one colour, or with a gradient.
	Fill : [Flat(RgbColor), Shaded(Still.Gradient)]

	## One polygon of a still: how it is filled, and its corners.
	Polygon : { fill : Still.Fill, points : List(Still.FramePoint) }

	## The still's polygons, in the order they are drawn.
	polygons : Still -> List(Still.Polygon)
	polygons = |Still.(still_polygons)| still_polygons

	is_eq : _
}

## What is wrong with a polygon, if anything, as a reason that names where it
## is in the still's frame.
Flaw : [Sound, Flawed(Str)]

## The least area, in the still's square units, that a radial gradient's two
## axes may span. A still is never drawn under 2 pixels tall (Pipeline's
## smallest height on screen), where this area is 4 times as many square
## pixels: 0.0001, the least that Brush can invert.
min_axes_area : F64
min_axes_area = 0.000025

## A place in the still's frame, written as `(x, y)`.
place : Still.FramePoint -> Str
place = |point| "(${point.x.to_str()}, ${point.y.to_str()})"

polygon_flaw : Still.Polygon -> Flaw
polygon_flaw = |polygon|
	match polygon.points {
		[] => Flawed("a polygon has no corners, and it needs three")
		[first, .. as rest] if rest.len() < 2 =>
			Flawed("the polygon from ${place(first)} has ${(rest.len() + 1).to_str()} corners, and it needs three")
		[first, ..] => {
			next_corners = polygon.points.drop_first(1).concat([first])
			edges = polygon.points.map2(next_corners, |from, to| { from, to })
			match edges.find_first(|{ from, to }| from == to) {
				Ok({ from, .. }) =>
					Flawed("the polygon from ${place(first)} repeats its corner ${place(from)}")
				Err(NotFound) =>
					match polygon.fill {
						Flat(_) => Sound
						Shaded(gradient) => gradient_flaw(gradient)
					}
			}
		}
	}

gradient_flaw : Still.Gradient -> Flaw
gradient_flaw = |gradient|
	match gradient {
		Linear({ stops, start, end }) =>
			if start == end {
				Flawed("the linear gradient from ${place(start)} ends where it starts")
			} else {
				stops_flaw(stops, "the linear gradient from ${place(start)}")
			}
		Radial({ stops, center, axis_u, axis_v }) => {
			area = (axis_u.x * axis_v.y - axis_u.y * axis_v.x).abs()
			if area < min_axes_area {
				least = min_axes_area.to_str()
				Flawed("the radial gradient about ${place(center)} has axes that span ${area.to_str()}, under ${least}")
			} else {
				stops_flaw(stops, "the radial gradient about ${place(center)}")
			}
		}
	}

## The stops' flaw, if any, for the gradient named by `gradient_name`.
stops_flaw : Still.ColorStops, Str -> Flaw
stops_flaw = |stops, gradient_name|
	if stops.end_offset < stops.start_offset {
		start = stops.start_offset.to_f64().to_str()
		end = stops.end_offset.to_f64().to_str()
		Flawed("${gradient_name} has its start offset ${start} past its end offset ${end}")
	} else {
		Sound
	}

sample_stops : Still.ColorStops
sample_stops = {
	start_color: ArgbColor.of(0xFF000000),
	end_color: ArgbColor.of(0xFFFFFFFF),
	start_offset: Fraction.of(0.25),
	end_offset: Fraction.of(0.75),
}

sample_corners : List(Still.FramePoint)
sample_corners = [{ x: 0.5, y: 0.0 }, { x: 1.0, y: 0.0 }, { x: 0.5, y: 1.0 }]

## A polygon on `sample_corners` filled by a linear gradient from (0.5, 0) to
## `end`, with `stops`.
linear_polygon : Still.ColorStops, Still.FramePoint -> Still.Polygon
linear_polygon = |stops, end| {
	gradient = Linear({
		stops,
		start: { x: 0.5, y: 0.0 },
		end,
	})
	{ fill: Shaded(gradient), points: sample_corners }
}

## A polygon on `sample_corners` filled by a radial gradient about (0.5, 0.25)
## with the two axes.
radial_polygon : Still.Step, Still.Step -> Still.Polygon
radial_polygon = |axis_u, axis_v| {
	gradient = Radial({
		stops: sample_stops,
		center: { x: 0.5, y: 0.25 },
		axis_u,
		axis_v,
	})
	{ fill: Shaded(gradient), points: sample_corners }
}

## A radial polygon whose axes span `area`.
radial_of_area : F64 -> Still.Polygon
radial_of_area = |area| radial_polygon({ x: area, y: 0.0 }, { x: 0.0, y: 1.0 })

## A flat polygon on `corners`.
flat_polygon : List(Still.FramePoint) -> Still.Polygon
flat_polygon = |corners| { fill: Flat(RgbColor.of(7)), points: corners }

# Three corners are a polygon, and two or none are not.
expect polygon_flaw(flat_polygon(sample_corners)) == Sound
expect
	polygon_flaw(flat_polygon(sample_corners.take_first(2)))
		== Flawed("the polygon from (0.5, 0) has 2 corners, and it needs three")
expect polygon_flaw(flat_polygon([])) == Flawed("a polygon has no corners, and it needs three")

# A corner that repeats its neighbour is a flaw, the last beside the first
# too, and corners that differ are sound (above).
expect {
	doubled = [{ x: 0.5, y: 0.0 }, { x: 1.0, y: 0.0 }, { x: 1.0, y: 0.0 }, { x: 0.5, y: 1.0 }]
	polygon_flaw(flat_polygon(doubled)) == Flawed("the polygon from (0.5, 0) repeats its corner (1, 0)")
}
expect
	polygon_flaw(flat_polygon(sample_corners.concat([{ x: 0.5, y: 0.0 }])))
		== Flawed("the polygon from (0.5, 0) repeats its corner (0.5, 0)")

# Stops whose offsets meet are sound, and a start past the end is not.
expect stops_flaw({ ..sample_stops, end_offset: Fraction.of(0.25) }, "g") == Sound
expect {
	crossed_stops = {
		..sample_stops,
		start_offset: Fraction.of(0.75),
		end_offset: Fraction.of(0.25),
	}
	stops_flaw(crossed_stops, "g") == Flawed("g has its start offset 0.75 past its end offset 0.25")
}

# A linear gradient with any length is sound, and one with none is not.
expect polygon_flaw(linear_polygon(sample_stops, { x: 0.5, y: 1.0 })) == Sound
expect
	polygon_flaw(linear_polygon(sample_stops, { x: 0.5, y: 0.0 }))
		== Flawed("the linear gradient from (0.5, 0) ends where it starts")

# A shaded polygon's stops are checked too.
expect {
	crossed_stops = { ..sample_stops, start_offset: Fraction.whole }
	polygon_flaw(linear_polygon(crossed_stops, { x: 0.5, y: 1.0 }))
		== Flawed("the linear gradient from (0.5, 0) has its start offset 1 past its end offset 0.75")
}

# Axes that span the least area are sound, and ones just under it, or
# parallel, are not.
expect polygon_flaw(radial_of_area(min_axes_area)) == Sound
expect polygon_flaw(radial_of_area(0.00002)) != Sound
expect
	polygon_flaw(radial_polygon({ x: 0.5, y: 0.5 }, { x: 0.25, y: 0.25 }))
		== Flawed("the radial gradient about (0.5, 0.25) has axes that span 0, under 2.5e-5")
