## ShapesPixels paints a frame's shapes into exact pixels with ScanlineFill.
## (See SafariFrame for more context.) Its twin is web/shapes_canvas.js, which
## paints the same shapes onto the browser's canvas in the game. SafariFrame
## paints every proof frame through this module, and ShapesFrame paints each
## one a second time with its polygons cut into triangles.
##
## It paints only what Safari's ride draws: triangles, quads, discs and
## polygons, each laid over what is there, or added to it after a `Blend(Add)`
## mark until a `Blend(Over)`. Any other shape crashes, naming what it got.
import game.Angle
import lib.Brush
import lib.Pixels
import lib.Point
import lib.Shapes
import PixelGrid
import ScanlineFill
import ScreenRoll

ShapesPixels :: [].{

	## The shapes, in order, painted onto `pixels`. A list starts in `Over`
	## mode, as a canvas does.
	pixels_with_shapes : List(U32), { roll : ScreenRoll, shapes : List(Shapes.Shape) } -> List(U32)
	pixels_with_shapes = |pixels, { roll, shapes }| {
		var $px = pixels
		var $mode = Over
		for shape in shapes {
			match shape {
				Blend(mode) => {
					$mode = mode
				}
				_ => {
					$px = pixels_with_shape($px, { roll, shape, mode: $mode })
				}
			}
		}
		$px
	}
}

pixels_with_shape : List(U32),
{
	roll : ScreenRoll,
	shape : Shapes.Shape,
	mode : Shapes.Mode,
} -> List(U32)
pixels_with_shape = |pixels, { roll, shape, mode }|
	match shape {
		# A canvas traces a triangle as the path round its three corners, so it
		# fills as that polygon does.
		Triangle(t) => ScanlineFill.polygon_pixels(
			pixels,
			{
				roll,
				corners: [t.first, t.second, t.third],
				fill: t.fill,
				mode,
			},
		)
		# A quad, likewise, as the path round its four corners.
		Quad(q) => ScanlineFill.polygon_pixels(
			pixels,
			{
				roll,
				corners: [q.first, q.second, q.third, q.fourth],
				fill: q.fill,
				mode,
			},
		)
		Polygon(p) => ScanlineFill.polygon_pixels(
			pixels,
			{
				roll,
				corners: p.corners,
				fill: p.fill,
				mode,
			},
		)
		Disc(d) => ScanlineFill.disc_pixels(
			pixels,
			{
				roll,
				center: ScreenRoll.ScenePoint.({ x: d.center.x.to_f64(), y: d.center.y.to_f64() }),
				radius: d.radius.to_f64(),
				fill: d.fill,
				mode,
			},
		)
		# `pixels_with_shapes` keeps the mode a mark sets, so no mark reaches here.
		Blend(_) => crash "ShapesPixels: a blend mark is the list's to keep"
		Image(_) => crash "ShapesPixels: an image among the ride's shapes"
		Text(_) => crash "ShapesPixels: a line of type among the ride's shapes"
		# The roll is the caller's, so the game's lean mark never reaches here.
		View(_) => crash "ShapesPixels: a view mark among the ride's shapes"
	}

## A row of four pixels, under no roll.
four_pixel_row : ScreenRoll
four_pixel_row = ScreenRoll.of({
	roll: Angle.upright,
	width: PixelGrid.Coordinate.from_i64(4),
	height: PixelGrid.Coordinate.from_i64(1),
})

## A disc in `fill` over the middle of pixels `x - 1` and `x`.
disc_at : F64, Brush.Rgba -> Shapes.Shape
disc_at = |x, fill| Disc({
	center: Point.at(x, 0.5),
	radius: Pixels.of(0.9),
	fill: Flat(fill),
})

## A dim orange light, at half its strength.
half_orange_light : Brush.Rgba
half_orange_light = {
	r: 128.0,
	g: 64.0,
	b: 32.0,
	a: 0.5,
}

opaque_red : Brush.Rgba
opaque_red = {
	r: 255.0,
	g: 0.0,
	b: 0.0,
	a: 1.0,
}

# After `Blend(Add)` a shape adds its light to what is there, and after
# `Blend(Over)` it paints over it again: the first two pixels take the added
# light, the second and third the red painted over, and the last neither.
expect {
	lit = Shapes.added_light_shapes([disc_at(1.0, half_orange_light)])
	shapes = lit.append(disc_at(2.0, opaque_red))
	blue_row = [0x204060, 0x204060, 0x204060, 0x204060]
	painted = ShapesPixels.pixels_with_shapes(blue_row, { roll: four_pixel_row, shapes })
	painted == [0x606070, 0xFF0000, 0xFF0000, 0x204060]
}
