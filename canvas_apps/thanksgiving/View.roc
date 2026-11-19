## View is the guest's eye in the backyard: lib's Eye, which measures the
## world from the eye, and where on the ground the eye stands. The backyard's
## own metres put the guest's chair at the origin, `right` across the table
## and `forward` down it, so every drawing module places its things where they
## are and asks View where they land. The cut moves the eye in one place.
import lib.Brush
import lib.Eye
import lib.Pixels
import lib.Point
import lib.Shapes

View :: { eye : Eye.Eye, stands : { right : F64, forward : F64 } }.{

	## The eye `eye`, standing at `stands` on the backyard's ground.
	standing : Eye.Eye, { right : F64, forward : F64 } -> View
	standing = |eye, stands| View.({ eye, stands })

	## The same eye, seeing a copy of the backyard's things moved by `offset`:
	## drawing a thing at its own place through this view draws it moved.
	shifted_view : View, { right : F64, forward : F64 } -> View
	shifted_view = |View.(view), offset| View.({ eye: view.eye, stands: { right: view.stands.right - offset.right, forward: view.stands.forward - offset.forward } })

	## The screen's width and height, in pixels.
	screen_width : View -> F64
	screen_width = |View.(view)| view.eye.width

	screen_height : View -> F64
	screen_height = |View.(view)| view.eye.height

	## Where a point in the backyard lands on the screen, with how many pixels
	## a metre is at its distance, or `BehindEye` when it is not in front.
	sighting : View, Eye.At -> Try({ point : Point, pixels_per_metre : F64 }, [BehindEye])
	sighting = |View.(view), at|
		match Eye.sighting(view.eye, point_from_eye(view.stands, at)) {
			Ok({ point, pixels_per_metre }) => Ok({
				point: Point.at(point.x, point.y),
				pixels_per_metre,
			})
			Err(BehindEye) => Err(BehindEye)
		}

	## A flat region of backyard points, cut to what is in front of the eye.
	## A region wholly behind the eye has nothing to draw, so it gives an empty
	## list rather than a shape.
	region_shapes : View, { corners : List(Eye.At), fill : Brush.Fill } -> List(Shapes.Shape)
	region_shapes = |View.(view), { corners, fill }| {
		on_screen = Eye.screen_corners(view.eye, corners.map(|at| point_from_eye(view.stands, at)))
		if on_screen.len() < 3 {
			[]
		} else {
			[Shapes.region_from_corners(on_screen, fill)]
		}
	}

	## A straight line `width` metres wide between two backyard points, or
	## nothing when either end is behind the eye. Its width is the near end's.
	line_shapes : View,
	{
		from : Eye.At,
		to : Eye.At,
		width : F64,
		fill : Brush.Fill,
	} -> List(Shapes.Shape)
	line_shapes = |view, { from, to, width, fill }|
		match (View.sighting(view, from), View.sighting(view, to)) {
			(Ok(start), Ok(end)) =>
				if start.point == end.point {
					[]
				} else {
					[
						Shapes.line(
							{
								from: start.point,
								to: end.point,
								width: Pixels.of(width * start.pixels_per_metre),
							},
							fill,
						),
					]
				}
			(Err(BehindEye), _) | (_, Err(BehindEye)) => []
		}
}

# A backyard point as the eye measures it: across and down the table from
# where the eye stands.
point_from_eye : { right : F64, forward : F64 }, Eye.At -> Eye.At
point_from_eye = |stands, at| {
	right: at.right - stands.right,
	forward: at.forward - stands.forward,
	height: at.height,
}
