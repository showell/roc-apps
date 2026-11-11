## Point is a place in a frame's own coordinates, in pixels, x across and y
## down from the top left. Either can be negative, or past the far edge, for a
## point off the screen. It is a module of its own so that Brush, which Shapes
## imports, can name it too.
import Pixels

Point := { x : Pixels, y : Pixels }.{

	## Two points are equal when both their coordinates are.
	is_eq : _

	## The point `x` pixels across and `y` pixels down.
	at : F64, F64 -> Point
	at = |x, y| { x: Pixels.of(x), y: Pixels.of(y) }
}
