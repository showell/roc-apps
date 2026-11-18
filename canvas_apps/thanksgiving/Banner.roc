## Banner draws the "Happy Thanksgiving!" banner, hanging from two cords at
## the top of the screen, given how far it has dropped in, from 0, still above
## the screen, to 1, hanging in place. Its letters are lib's Font, strokes
## rather than type, as every page but a widget's draws its words.
import lib.Brush
import lib.Font
import lib.Pixels
import lib.Point
import lib.RgbColor
import lib.Shapes

Banner :: [].{

	banner_shapes : F64, { width : F64 } -> List(Shapes.Shape)
	banner_shapes = |dropped, { width }|
		if dropped <= 0.0 {
			[]
		} else {
			middle = width / 2.0
			# It overshoots a little and settles, as cloth on a cord does.
			settle = 1.0 + 0.12 * (dropped * F64.pi).sin() * (1.0 - dropped)
			center_y = -80.0 + 150.0 * dropped * settle
			half_wide = 210.0
			half_high = 46.0
			notch = 22.0
			top = center_y - half_high
			bottom = center_y + half_high
			left = middle - half_wide
			right = middle + half_wide
			cloth = Shapes.region_from_corners(
				[
					Point.at(left, top),
					Point.at(right, top),
					Point.at(right - notch, center_y),
					Point.at(right, bottom),
					Point.at(left, bottom),
					Point.at(left + notch, center_y),
				],
				Brush.flat(RgbColor.of(0x9C2F1F)),
			)
			cords = [left + 40.0, right - 40.0].map(
				|x| Shapes.line(
					{
						from: Point.at(x, -2.0),
						to: Point.at(x, top + 2.0),
						width: Pixels.of(2.0),
					},
					Brush.flat(RgbColor.of(0x3A2A20)),
				),
			)
			trim = [top + 6.0, bottom - 6.0].map(
				|y| Shapes.line(
					{
						from: Point.at(left + 14.0, y),
						to: Point.at(right - 14.0, y),
						width: Pixels.of(2.0),
					},
					Brush.flat(RgbColor.of(0xF2C14E)),
				),
			)
			words = lettering_shapes(
				"Happy",
				{ top_center: Point.at(middle, top + 14.0), size: 28.0 },
			)
				.concat(
					lettering_shapes(
						"Thanksgiving!",
						{ top_center: Point.at(middle, top + 50.0), size: 24.0 },
					),
				)
			cords.append(cloth).concat(trim).concat(words)
		}
}

# Font's strokes are a fourteenth of the letter's height, which is thin for a
# banner, so each line is drawn three times a pixel apart, over a shadow.
lettering_shapes : Str, { top_center : Point, size : F64 } -> List(Shapes.Shape)
lettering_shapes = |words, { top_center, size }| {
	x = top_center.x.to_f64()
	y = top_center.y.to_f64()
	ink = Brush.opaque_rgba(RgbColor.of(0xFFF4DC))
	shadow = Brush.opaque_rgba(RgbColor.of(0x4A140C))
	strokes = |dx, dy, color| Font.centered_text_shapes(
		words,
		{
			top_center: Point.at(x + dx, y + dy),
			size,
			color,
		},
	)
	[
		strokes(1.5, 2.0, shadow),
		strokes(-0.8, 0.0, ink),
		strokes(0.8, 0.0, ink),
		strokes(0.0, 0.8, ink),
	].join()
}

expect Banner.banner_shapes(0.0, { width: 640.0 }) == []
expect Banner.banner_shapes(1.0, { width: 640.0 }).len() > 20
expect ["Happy", "Thanksgiving!"].all(Font.can_plot)
