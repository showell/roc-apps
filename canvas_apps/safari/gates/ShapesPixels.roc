## ShapesPixels paints a frame's shapes into exact pixels with ScanlineFill.
## (See SafariFrame for more context.) Its twin is web/shapes_canvas.js, which
## paints the same shapes onto the browser's canvas in the game. SafariFrame
## paints every proof frame through this module, and ShapesFrame paints each
## one a second time with its polygons cut into triangles.
##
## It paints only what Safari's ride draws: polygons, triangle pieces and
## unclipped flat discs, each laid over what is there. Any other shape
## crashes, naming what it got.
import lib.Brush
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
		Pieces(p) => pixels_with_pieces(pixels, { roll, tris: p.tris, fill: p.fill })
		Disc(d) => {
			color = match d.fill {
				Flat(flat) => flat
				Skip | Span(_) | Radial(_) | Linear(_) | Ellipse(_) | Glow(_) =>
					crash "ShapesPixels: a disc with a gradient"
			}
			match d.clip {
				Anywhere =>
					ScanlineFill.disc_pixels(
						pixels,
						{
							roll,
							center: ScreenRoll.ScenePoint.({ x: d.x, y: d.y }),
							radius: d.r,
							color,
						},
					)
				Within(_) => crash "ShapesPixels: a disc clipped to a rectangle"
			}
		}
		Rect(_) => crash "ShapesPixels: a rectangle among the ride's shapes"
		# ScanlineFill lays every pixel over what is there, so Over is the mode
		# it is always in, and Add is light it can't paint.
		Blend(Over) => pixels
		Blend(Add) => crash "ShapesPixels: a shape lit in Add mode"
		Image(_) => crash "ShapesPixels: an image among the ride's shapes"
		Text(_) => crash "ShapesPixels: a line of type among the ride's shapes"
		# The roll is the caller's, so the game's lean mark never reaches here.
		View(_) => crash "ShapesPixels: a view mark among the ride's shapes"
	}

## The triangles, six numbers each, all filled with one brush.
pixels_with_pieces : List(U32),
{
	roll : ScreenRoll,
	tris : List(F64),
	fill : Brush.Fill,
} -> List(U32)
pixels_with_pieces = |pixels, { roll, tris, fill }| {
	var $px = pixels
	for k in 0..<(tris.len() // 6) {
		$px = ScanlineFill.polygon_pixels(
			$px,
			{
				roll,
				coordinates: tris.sublist({ start: 6 * k, len: 6 }),
				fill,
			},
		)
	}
	$px
}
