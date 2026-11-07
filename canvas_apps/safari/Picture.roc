## A Picture is how one object looks in one frame: the shapes that paint it,
## in order. Outside this module a picture is a single thing, handed along
## whole, and the painter is the one reader of its shapes.
import lib.Shapes

Picture :: List(Shapes.Shape).{

	from_shapes : List(Shapes.Shape) -> Picture
	from_shapes = |shapes| Picture.(shapes)

	to_shapes : Picture -> List(Shapes.Shape)
	to_shapes = |Picture.(shapes)| shapes
}

sample_shape : Shapes.Shape
sample_shape = Rect({
	x: 1.0,
	y: 2.0,
	w: 3.0,
	h: 4.0,
	fill: Skip,
})

expect Picture.from_shapes([]).to_shapes() == []
expect Picture.from_shapes([sample_shape, View(Screen)]).to_shapes() == [sample_shape, View(Screen)]
