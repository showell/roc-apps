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
		focal_length : Pixels,
		context : context,
	}

	from_shapes : List(Shapes.Shape) -> Picture
	from_shapes = |shapes| Picture.(shapes)

	to_shapes : Picture -> List(Shapes.Shape)
	to_shapes = |Picture.(shapes)| shapes

	## One picture of several, each painted over the ones before it.
	composite : List(Picture) -> Picture
	composite = |pictures| Picture.(pictures.join_map(Picture.to_shapes))
}
