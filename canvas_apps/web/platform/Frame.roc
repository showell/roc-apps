# Frame -- what a frame IS, declared by the platform so the compiler knows.
#
# EXPERIMENT. The shipped platform says `frame : Box(model) -> List(U32)`,
# which means ShapeWire.pack has flattened the picture before the compiler
# sees it, and generated glue can only ever produce a list-of-integers reader.
# This says the real type, so the type table carries the whole vocabulary.
#
# Structural unions throughout (`:`, not `:=`), so lib/Shapes.roc's Shape
# unifies with this one by shape rather than by name.
Frame :: [].{
	Rgba : { r : F64, g : F64, b : F64, a : F64 }

	Fill : [
		Skip,
		Flat(Frame.Rgba),
		Span({ edge : Frame.Rgba, middle : Frame.Rgba, x0 : F64, x1 : F64 }),
		Radial({ inner : Frame.Rgba, outer : Frame.Rgba, x : F64, y : F64, r0 : F64, r1 : F64 }),
		Linear({ c0 : Frame.Rgba, c1 : Frame.Rgba, o0 : F64, o1 : F64, ax : F64, ay : F64, dx : F64, dy : F64 }),
		Ellipse({ c0 : Frame.Rgba, c1 : Frame.Rgba, o0 : F64, o1 : F64, x : F64, y : F64, ia : F64, ib : F64, ic : F64, id : F64 }),
		Glow({ c0 : Frame.Rgba, c1 : Frame.Rgba, c2 : Frame.Rgba, x : F64, y : F64, r0 : F64, r1 : F64 }),
	]

	Clip : [Anywhere, Within({ x : F64, y : F64, w : F64, h : F64 })]

	Mode : [Over, Add]

	Space : [
		Screen,
		World({ target : { x : F64, y : F64 }, offset : { x : F64, y : F64 }, rotation : F64, zoom : F64 }),
	]

	Shape : [
		Poly({ pts : List(F64), fill : Frame.Fill }),
		Pieces({ tris : List(F64), fill : Frame.Fill }),
		Disc({ x : F64, y : F64, r : F64, fill : Frame.Fill, clip : Frame.Clip }),
		Rect({ x : F64, y : F64, w : F64, h : F64, fill : Frame.Fill }),
		Blend(Frame.Mode),
		View(Frame.Space),
		Image({ x : F64, y : F64, w : F64, h : F64, cols : U64, rows : U64, pixels : List(Frame.Rgba) }),
	]
}
