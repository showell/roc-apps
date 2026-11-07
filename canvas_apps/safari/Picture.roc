## A Picture is how one object looks in one frame: the shapes that paint it,
## in order. Outside this module a picture is a single thing, handed along
## whole until something paints it.
import Pixels
import Spot
import lib.Shapes

Picture :: List(Shapes.Shape).{

	## What a kind of object draws its picture from: where it stands in the
	## frame, the camera's focal length, and `context`, which is whatever else
	## that kind needs. A kind that needs nothing more takes `{}`.
	Setting(context) : {
		spot : Spot,
		cam_focal : Pixels,
		context : context,
	}

	from_shapes : List(Shapes.Shape) -> Picture
	from_shapes = |shapes| Picture.(shapes)

	to_shapes : Picture -> List(Shapes.Shape)
	to_shapes = |Picture.(shapes)| shapes
}

sample_shape : Shapes.Shape
sample_shape = Rect({
	x: 1.0,
	y: 2.0,
	width: 3.0,
	height: 4.0,
	fill: Flat({
		r: 0.0,
		g: 0.0,
		b: 0.0,
		a: 1.0,
	}),
})

expect Picture.from_shapes([]).to_shapes() == []
expect Picture.from_shapes([sample_shape, View(Screen)]).to_shapes() == [sample_shape, View(Screen)]
