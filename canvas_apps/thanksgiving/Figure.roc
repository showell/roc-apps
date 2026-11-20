## Figure is how the movie's flat figures are drawn: a robot, the dancer, the
## drum major's drumstick. A figure is laid out in metres from its feet,
## across from its middle and up from the ground, and a Place says where its
## feet are on the screen and how many pixels a metre is there, so the same
## figure serves near and far.
import lib.Brush
import lib.CurvedShapes
import lib.Pixels
import lib.Point
import lib.Shapes

Figure :: [].{

	## Where the screen is for one figure: its feet, and pixels a metre.
	Place : {
		x : F64,
		y : F64,
		scale : F64,
	}

	## A spot on the figure, in metres from its feet.
	Spot : { across : F64, up : F64 }

	screen_point : Figure.Place, Figure.Spot -> Point
	screen_point = |place, spot| Point.at(
		place.x + spot.across * place.scale,
		place.y - spot.up * place.scale,
	)

	## A straight bar `width` metres wide.
	bar : Figure.Place,
	{
		from : Figure.Spot,
		to : Figure.Spot,
		width : F64,
		fill : Brush.Fill,
	} -> Shapes.Shape
	bar = |place, { from, to, width, fill }|
		Shapes.line(
			{
				from: screen_point(place, from),
				to: screen_point(place, to),
				width: Pixels.of(width * place.scale),
			},
			fill,
		)

	## A round dot `radius` metres across.
	dot : Figure.Place,
	{
		at : Figure.Spot,
		radius : F64,
		fill : Brush.Fill,
	} -> Shapes.Shape
	dot = |place, { at, radius, fill }| Disc({
		center: screen_point(place, at),
		radius: Pixels.of(radius * place.scale),
		fill,
	})

	## A rounded box, `left` and `bottom` its lower left corner in metres.
	box : Figure.Place,
	{
		left : F64,
		bottom : F64,
		width : F64,
		height : F64,
		corner : F64,
		fill : Brush.Fill,
	} -> Shapes.Shape
	box = |
		place,
		{
			left,
			bottom,
			width,
			height,
			corner,
			fill,
		},
	|
		CurvedShapes.rounded_rect(
			{
				top_left: screen_point(place, { across: left, up: bottom + height }),
				width: Pixels.of(width * place.scale),
				height: Pixels.of(height * place.scale),
				corner_radius: Pixels.of(corner * place.scale),
				corner_steps: 3,
			},
			fill,
		)

	## The far end of a bone `length` metres long from `start`, at `angle`
	## radians from straight down, positive to the screen's right.
	bone_end : Figure.Spot, { angle : F64, length : F64 } -> Figure.Spot
	bone_end = |start, { angle, length }| {
		across: start.across + angle.sin() * length,
		up: start.up - angle.cos() * length,
	}
}
