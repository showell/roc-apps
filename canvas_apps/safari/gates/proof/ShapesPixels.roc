## ShapesPixels paints a frame's shapes into exact pixels with ScanlineFill.
## (See SafariFrame for more context.) Its twin is web/shapes_canvas.js, which
## paints the same shapes onto the browser's canvas in the game. SafariFrame
## paints every proof frame through this module, and ShapesFrame paints each
## one a second time with its polygons cut into triangles.
##
## It paints only what Safari's ride draws: polygons, discs and rectangles, each
## laid over what is there. Any other shape crashes, naming what it got.
import lib.Shapes
import ScanlineFill
import ScreenRoll

ShapesPixels :: [].{

	## The shapes, in order, painted onto `pixels`.
	pixels_with_shapes : List(U32), { roll : ScreenRoll, shapes : List(Shapes.Shape) } -> List(U32)
	pixels_with_shapes = |pixels, { roll, shapes }| {
		var $px = pixels
		for shape in shapes {
			$px = pixels_with_shape($px, { roll, shape })
		}
		$px
	}
}

pixels_with_shape : List(U32), { roll : ScreenRoll, shape : Shapes.Shape } -> List(U32)
pixels_with_shape = |pixels, { roll, shape }|
	match shape {
		Poly(p) => ScanlineFill.polygon_pixels(
			pixels,
			{ roll, coordinates: p.coordinates, fill: p.fill },
		)
		Disc(d) => ScanlineFill.disc_pixels(
			pixels,
			{
				roll,
				center: ScreenRoll.ScenePoint.({ x: d.x, y: d.y }),
				radius: d.radius,
				fill: d.fill,
			},
		)
		# A canvas traces a rectangle as the path round its four corners, so it
		# fills as that polygon does.
		Rect(r) => ScanlineFill.polygon_pixels(
			pixels,
			{
				roll,
				coordinates: [
					r.x,
					r.y,
					r.x + r.width,
					r.y,
					r.x + r.width,
					r.y + r.height,
					r.x,
					r.y + r.height,
				],
				fill: r.fill,
			},
		)
		# ScanlineFill lays every pixel over what is there, so Over is the mode
		# it is always in, and Add is light it can't paint.
		Blend(Over) => pixels
		Blend(Add) => crash "ShapesPixels: a shape lit in Add mode"
		Image(_) => crash "ShapesPixels: an image among the ride's shapes"
		Text(_) => crash "ShapesPixels: a line of type among the ride's shapes"
		# The roll is the caller's, so the game's lean mark never reaches here.
		View(_) => crash "ShapesPixels: a view mark among the ride's shapes"
	}
