## A Sprite is how one object looks in one frame: the shapes that paint it,
## in order. Outside this module a sprite is a single thing, handed along
## whole until something paints it.
import lib.Pixels
import Spot
import lib.Shapes

Sprite :: List(Shapes.Shape).{

	## What a kind of object draws its sprite from: where it stands in the
	## frame, the camera's focal length, and `context`, which is whatever else
	## that kind needs. A kind that needs nothing more takes `{}`.
	Setting(context) : {
		spot : Spot,
		focal_length : Pixels,
		context : context,
	}

	from_shapes : List(Shapes.Shape) -> Sprite
	from_shapes = |shapes| Sprite.(shapes)

	to_shapes : Sprite -> List(Shapes.Shape)
	to_shapes = |Sprite.(shapes)| shapes

	## One sprite of several, each painted over the ones before it.
	composite : List(Sprite) -> Sprite
	composite = |sprites| Sprite.(sprites.join_map(Sprite.to_shapes))
}
