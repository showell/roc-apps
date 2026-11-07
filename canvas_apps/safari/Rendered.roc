## A Rendered is one object as a frame paints it: its picture and how far ahead
## of the camera it stands. Nothing here says what sort of object it is, so every
## sort meets in one list, and that list is what the depth sort orders.
import Distance
import Picture

Rendered := {
	## How far ahead of the camera it is, negative for what is behind the rider.
	depth : Distance,
	picture : Picture,
}
