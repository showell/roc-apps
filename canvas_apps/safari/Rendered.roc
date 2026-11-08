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

	## `renderings` from far to near, sorted by `DepthSort.sort_by`.
	depth_sorted_renderings : List(Rendered) -> List(Rendered)
	depth_sorted_renderings = |renderings|
		DepthSort.sort_by(renderings, |rendering| rendering.depth())
}
