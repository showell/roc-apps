## A Rendered is one object as a frame paints it: its picture and how far ahead
## of the camera it stands. Nothing here says what sort of object it is, so every
## sort meets in one list, and that list is what the depth sort orders.
import DepthSort
import Distance
import Picture

Rendered :: { depth : Distance, picture : Picture }.{

	## The rendering of `picture`, standing `depth` ahead of the camera.
	of : Distance, Picture -> Rendered
	of = |depth, picture| Rendered.({ depth, picture })

	## How far ahead of the camera it is, negative for what is behind the rider.
	depth : Rendered -> Distance
	depth = |Rendered.(rendering)| rendering.depth

	## What the frame paints.
	picture : Rendered -> Picture
	picture = |Rendered.(rendering)| rendering.picture

	## `renderings` from far to near. Two about as far away as each other keep
	## the order they came in, so that order decides which is painted over the
	## other.
	depth_sorted_renderings : List(Rendered) -> List(Rendered)
	depth_sorted_renderings = |renderings|
		DepthSort.sort_by(renderings, |rendering| rendering.depth())
}

## A rendering with one shape, which tells it from another at the same depth.
marked_rendering : F64, F64 -> Rendered
marked_rendering = |depth, mark|
	Rendered.of(
		Distance.metres(depth),
		Picture.from_shapes([
			Rect({
				x: mark,
				y: 0.0,
				width: 1.0,
				height: 1.0,
				fill: Flat({
					r: 0.0,
					g: 0.0,
					b: 0.0,
					a: 1.0,
				}),
			}),
		]),
	)

# The farthest comes first, and two at one depth stay as they came.
expect
	Rendered.depth_sorted_renderings([
		marked_rendering(10.0, 1.0),
		marked_rendering(30.0, 2.0),
		marked_rendering(10.0, 3.0),
		marked_rendering(20.0, 4.0),
	]).map(|rendering| rendering.picture().to_shapes())
		== [
			marked_rendering(30.0, 2.0),
			marked_rendering(20.0, 4.0),
			marked_rendering(10.0, 1.0),
			marked_rendering(10.0, 3.0),
		].map(|rendering| rendering.picture().to_shapes())
