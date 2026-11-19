## WidthShading makes the fill that rounds a flat region: its colour darker at
## its left and right edges and lighter in the middle, a `Brush.Fill` `Span`
## across the x the region covers. A region too narrow to show it, or shaded
## with no strength, gets the flat colour instead.
import Brush
import ColorShade
import Fraction
import Pixels
import Point
import RgbColor

WidthShading :: [].{

	## How a fill is shaded across a width: its colour, darker at the edges and
	## lighter in the middle by `strength`.
	WidthShade : { color : RgbColor, strength : Fraction }

	## The span of x a region covers. Either end is negative for a region off
	## the left of the screen.
	XSpan : { min_x : Pixels, max_x : Pixels }

	## The fill of a region spanning `span`, shaded across its width, or a flat
	## one where it has no strength or is too narrow to shade.
	width_shade : WidthShading.XSpan, WidthShading.WidthShade -> Brush.Fill
	width_shade = |span, { color, strength }|
		if strength <= Fraction.zero or is_too_narrow_to_shade(span) {
			Brush.flat(color)
		} else {
			Span({
				edge_color: Brush.opaque_rgba(width_shade_edge(color, strength)),
				middle_color: Brush.opaque_rgba(width_shade_middle(color, strength)),
				left_x: span.min_x,
				right_x: span.max_x,
			})
		}

	## The fill of the region with these corners, shaded across its width as
	## `width_shade` shades it. A region has a corner, so none crashes.
	corners_shade : List(Point), WidthShading.WidthShade -> Brush.Fill
	corners_shade = |corners, width_shading| WidthShading.width_shade(
		x_span(corners),
		width_shading,
	)
}

shade_edge_darken : Fraction
shade_edge_darken = Fraction.of(0.4)

shade_middle_lift : Fraction
shade_middle_lift = Fraction.of(0.25)

## A width-shaded fill's colour at its edges.
width_shade_edge : RgbColor, Fraction -> RgbColor
width_shade_edge = |color, strength|
	ColorShade.shade_color(color, Darkened(shade_edge_darken.times(strength)))

## A width-shaded fill's colour in its middle.
width_shade_middle : RgbColor, Fraction -> RgbColor
width_shade_middle = |color, strength|
	ColorShade.shade_color(color, Lightened(shade_middle_lift.times(strength)))

narrowest_shaded_width : Pixels
narrowest_shaded_width = Pixels.of(1.0)

is_too_narrow_to_shade : WidthShading.XSpan -> Bool
is_too_narrow_to_shade = |span| span.max_x.minus(span.min_x) < narrowest_shaded_width

## The span of x over a region's corners. It has at least one corner.
x_span : List(Point) -> WidthShading.XSpan
x_span = |corners|
	match corners.map(|corner| corner.x) {
		[first, .. as rest] => {
			min_x: rest.fold(
				first,
				|least, x|
					if x < least {
						x
					} else {
						least
					},
			),
			max_x: rest.fold(
				first,
				|most, x|
					if x > most {
						x
					} else {
						most
					},
			),
		}
		[] => crash "WidthShading.x_span: a region has a corner"
	}

sample_color : RgbColor
sample_color = RgbColor.of(0x804020)

expect width_shade_edge(sample_color, Fraction.whole) == RgbColor.of(0x4D2613)
expect width_shade_middle(sample_color, Fraction.whole) == RgbColor.of(0xA05028)
expect width_shade_edge(sample_color, Fraction.of(0.5)) == RgbColor.of(0x66331A)
expect width_shade_middle(sample_color, Fraction.of(0.5)) == RgbColor.of(0x904824)
expect width_shade_edge(sample_color, Fraction.zero) == sample_color
expect width_shade_middle(sample_color, Fraction.zero) == sample_color

# A lift past 255 holds at white.
expect width_shade_middle(RgbColor.of(0xFAFAFA), Fraction.whole) == RgbColor.of(0xFFFFFF)

expect is_too_narrow_to_shade({ min_x: Pixels.of(10.0), max_x: Pixels.of(10.5) })
expect !is_too_narrow_to_shade({ min_x: Pixels.of(10.0), max_x: Pixels.of(11.0) })
expect !is_too_narrow_to_shade({ min_x: Pixels.of(10.0), max_x: Pixels.of(30.0) })

expect x_span(wide_corners) == { min_x: Pixels.of(10.0), max_x: Pixels.of(30.0) }
expect x_span([Point.at(5.0, 99.0)]) == { min_x: Pixels.of(5.0), max_x: Pixels.of(5.0) }

wide_corners : List(Point)
wide_corners = [
	Point.at(10.0, 1.0),
	Point.at(30.0, 2.0),
	Point.at(20.0, 3.0),
]

narrow_corners : List(Point)
narrow_corners = [
	Point.at(10.0, 1.0),
	Point.at(10.5, 2.0),
	Point.at(10.2, 3.0),
]

expect
	WidthShading.corners_shade(wide_corners, { color: sample_color, strength: Fraction.whole })
		== Span({
			edge_color: Brush.opaque_rgba(RgbColor.of(0x4D2613)),
			middle_color: Brush.opaque_rgba(RgbColor.of(0xA05028)),
			left_x: Pixels.of(10.0),
			right_x: Pixels.of(30.0),
		})

# No strength, or too narrow a region, is a flat fill.
expect WidthShading.corners_shade(
	wide_corners,
	{ color: sample_color, strength: Fraction.zero },
) == Brush.flat(sample_color)
expect WidthShading.corners_shade(
	narrow_corners,
	{ color: sample_color, strength: Fraction.whole },
) == Brush.flat(sample_color)
