## A Rendered is one object as a frame paints it: its sprite and how far ahead
## of the camera it stands. Nothing here says what sort of object it is, so every
## sort meets in one list, and that list is what the depth sort orders.
import DepthSort
import Distance
import Sprite

Rendered :: { depth : Distance, sprite : Sprite }.{

	## The rendering of `sprite`, standing `depth` ahead of the camera.
	of : Distance, Sprite -> Rendered
	of = |depth, sprite| Rendered.({ depth, sprite })

	## How far ahead of the camera it is, negative for what is behind the rider.
	depth : Rendered -> Distance
	depth = |Rendered.(rendering)| rendering.depth

	## What the frame paints.
	sprite : Rendered -> Sprite
	sprite = |Rendered.(rendering)| rendering.sprite

	## `renderings` from far to near, sorted by `DepthSort.sort_by`.
	depth_sorted_renderings : List(Rendered) -> List(Rendered)
	depth_sorted_renderings = |renderings|
		DepthSort.sort_by(renderings, |rendering| rendering.depth())
}
