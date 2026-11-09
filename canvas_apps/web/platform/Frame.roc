## Frame says what a frame is, so the compiler knows: the platform's `frame`
## returns a `List(Frame.Shape)`. The type table the compiler reports then
## carries every shape and fill, and `roc glue` generates the page's reader,
## roc_glue.js, from it. shapes_canvas.js paints what that reader returns.
##
## The unions are structural (`:`, not `:=`), so lib/Shapes.roc's Shape
## unifies with this one by shape rather than by name.
Frame :: [].{
	Rgba : { r : F64, g : F64, b : F64, a : F64 }

	TwoStops : { start_color : Frame.Rgba, end_color : Frame.Rgba, start_offset : F64, end_offset : F64 }

	Fill : [
		Flat(Frame.Rgba),
		Span({ edge_color : Frame.Rgba, middle_color : Frame.Rgba, left_x : F64, right_x : F64 }),
		Radial({ inner_color : Frame.Rgba, outer_color : Frame.Rgba, center : { x : F64, y : F64 }, inner_radius : F64, outer_radius : F64 }),
		Linear({ stops : Frame.TwoStops, start_point : { x : F64, y : F64 }, end_point : { x : F64, y : F64 } }),
		Ellipse({ stops : Frame.TwoStops, center : { x : F64, y : F64 }, axis_u : { x : F64, y : F64 }, axis_v : { x : F64, y : F64 } }),
		Glow({ inner_color : Frame.Rgba, middle_color : Frame.Rgba, outer_color : Frame.Rgba, middle_offset : F64, center : { x : F64, y : F64 }, inner_radius : F64, outer_radius : F64 }),
	]

	Mode : [Over, Add]

	Space : [
		Screen,
		World({ target : { x : F64, y : F64 }, offset : { x : F64, y : F64 }, rotation : F64, zoom : F64 }),
	]

	Face : [Prose, Code]

	Align : [Left, Center]

	Point : { x : F64, y : F64 }

	Shape : [
		Triangle({ first : Frame.Point, second : Frame.Point, third : Frame.Point, fill : Frame.Fill }),
		Rectangle({ top_left : Frame.Point, width : F64, height : F64, fill : Frame.Fill }),
		Disc({ center : Frame.Point, radius : F64, fill : Frame.Fill }),
		Polygon({ corners : List(Frame.Point), fill : Frame.Fill }),
		Blend(Frame.Mode),
		View(Frame.Space),
		Image({ x : F64, y : F64, width : F64, height : F64, cols : U64, rows : U64, pixels : List(Frame.Rgba) }),
		Text({ text : Str, x : F64, y : F64, size : F64, face : Frame.Face, align : Frame.Align, color : Frame.Rgba }),
	]
}
