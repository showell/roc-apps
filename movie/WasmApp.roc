# WasmApp -- a movie on the wasm platform, which is the same file every time.
#
# Hand-written. The platform asks for twelve functions over a boxed model, and
# eleven of them are the same for any movie: box it, step it, pack its shapes,
# answer how big it is and how fast it runs. **THREE MOVIES HAD THAT FILE
# BYTE FOR BYTE**, differing only in the name they imported, which is one file
# too many to keep in step by hand.
#
# So this is what MoviePlayer is to roc-ray: `program` takes a Movie and names
# none. An app that needs more than the default says so by name --
#
#     program = { ..WasmApp.program(SafariMovie.movie), scene: my_scene }
#
# -- which is how Safari keeps its route segment and its timing probes.
import Movie
import ShapeWire

WasmApp :: [].{
	# Roc reads `movie.frame(m)` as a method call, so each of a movie's
	# functions is bound before it is used. See Movie.roc.
	program : Movie.Movie(model) -> {
		init : {} -> Box(model),
		advance : Box(model) -> Box(model),
		back : Box(model) -> Box(model),
		render : Box(model) -> List(U32),
		probe_frame : Box(model) -> U32,
		probe_expand : Box(model) -> U32,
		clock : Box(model) -> U32,
		scene : Box(model) -> U32,
		roll : Box(model) -> F32,
		width : Box(model) -> U32,
		height : Box(model) -> U32,
		fps : Box(model) -> U32,
	}
	program = |movie| {
		step = movie.advance
		unstep = movie.back
		shapes_of = movie.frame
		roll_of = movie.roll
		tick_of = movie.clock
		{
			init: |{}| Box.box(movie.init),
			advance: |b| Box.box(step(Box.unbox(b))),
			back: |b| Box.box(unstep(Box.unbox(b))),
			# **THE WHOLE FRAME, BACKDROP AND ALL.** What went over this wire
			# used to be draw commands, with the page painting the sky and the
			# sun itself from six more exports; a page cannot do that for a
			# movie it has never heard of, so the frame arrives as shapes and
			# the page paints what it is given.
			render: |b| ShapeWire.pack(shapes_of(Box.unbox(b))),
			# What the Node smoke run times. A movie whose frame is not
			# expanded from commands has one number to give, twice.
			probe_frame: |b| U64.to_u32_wrap(List.len(shapes_of(Box.unbox(b)))),
			probe_expand: |b| U64.to_u32_wrap(List.len(shapes_of(Box.unbox(b)))),
			clock: |b| F64.to_u32_wrap(tick_of(Box.unbox(b))),
			# Which scene it is in. What a scene IS, is the movie's business,
			# and a movie with one scene is in it.
			scene: |_b| 0,
			roll: |b| F64.to_f32_wrap(roll_of(Box.unbox(b))),
			width: |_b| F64.to_u32_wrap(movie.size.width),
			height: |_b| F64.to_u32_wrap(movie.size.height),
			fps: |_b| I32.to_u32_wrap(movie.fps),
		}
	}
}
