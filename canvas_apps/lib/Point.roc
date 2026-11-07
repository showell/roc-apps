## Point is a place in a frame's own coordinates, x across and y down, for the
## modules that build shapes and the brushes that fill them. It is a module of
## its own so that Brush, which Shapes imports, can name it too.
Point :: [].{
	Point : { x : F64, y : F64 }
}
