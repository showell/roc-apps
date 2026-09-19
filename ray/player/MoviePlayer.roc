# MoviePlayer -- the whole of playing a movie on roc-ray, for any movie.
#
# ray/apps/<name>/main.roc names a movie and hands it here. Everything a
# player does lives in this file -- the painting, the keys, the camera, the
# supersampling, the screenshot -- and none of it names a movie: `program`
# TAKES one, as a value of Movie.Movie, so the app does the gluing where it can
# be read rather than by which file happened to be staged.
#
# **NOTHING HERE KNOWS WHICH MOVIE IT IS PLAYING**: it steps a model, asks for a
# frame, and fills the shapes the frame reports under a camera turned by its
# roll. A movie of a night drive would need no change here.
#
# **ONE PAINTER.** roc-ray fills the frame's polygons, triangles, discs and
# rectangles itself, under a camera turned by the roll; a shape with a gradient
# goes through one fragment shader that does Brush.shade's arithmetic on the
# scene position (BrushGlsl).
#
# There used to be three, and `R` and `A` switched between them: this one, this
# one without anti-aliasing, and the movie painting its own pixels for roc-ray
# to show as a texture. They existed to be COMPARED, and the comparison is
# settled. What went with them: a second texture, an upload every step, a
# painter in every screenshot's name, and a `pixels` method every movie would
# have had to implement.
#
# It is anti-aliased by supersampling, as roc-ray offers no multisampling: the
# frame is drawn into a render texture at twice the window's size, the camera
# zoomed to match, and drawn down onto the window with bilinear filtering,
# whose sample at each window pixel's centre falls between four texels and
# averages them.
#
# The keys are the page's: SPACE pauses and resumes, UP and DOWN step, J skips
# to the next scene, D shows the frame rate, ESCAPE quits, and P saves a
# screenshot to shots/ named by the movie's clock.
import rr.App
import rr.Assets
import rr.Camera
import rr.Capture
import rr.Color
import rr.Draw
import rr.Math
import rr.Task
import Brush
import BrushGlsl
import Movie
import Shapes

MoviePlayer :: [].{
	Gpu : {
		shader : Draw.Shader,
		mode : Draw.F32Uniform,
		clip : Draw.Vec4Uniform,
		color_a : Draw.Vec4Uniform,
		color_b : Draw.Vec4Uniform,
		color_c : Draw.Vec4Uniform,
		geom_a : Draw.Vec4Uniform,
		geom_b : Draw.Vec4Uniform,
		geom_c : Draw.Vec4Uniform,
	}

	Model(model) : { state : model, auto : Bool, fps : Bool, target : Draw.RenderTexture, gpu : MoviePlayer.Gpu }

	# The supersampled frame: twice the window's size each way, four samples a pixel.
	supersample : F32
	supersample = 2

	# The render texture the frame is drawn into, at the supersampled size.
	target_size : Movie.Movie(model) -> { width : I32, height : I32 }
	target_size = |movie| {
		width: F64.to_i32_wrap(movie.size.width * F32.to_f64(supersample)),
		height: F64.to_i32_wrap(movie.size.height * F32.to_f64(supersample)),
	}

	Msg : [ShotSaved(Try({}, Capture.ScreenshotError))]



	init! : Movie.Movie(model) -> App.Init(MoviePlayer.Model(model), [TextureGenerationFailed, ResourceLimit, ShaderLoadFailed, UniformNotFound, RenderTextureLoadFailed])
	init! = |movie| App.init(
		# **THE MOVIE SETS THE RATE.** raylib's default is 240 frames a second,
		# which played every movie here four times too fast against the page.
		App.default.with_title(movie.title).with_size({ width: F64.to_i32_wrap(movie.size.width), height: F64.to_i32_wrap(movie.size.height) }).with_frame_pacing(Capped(movie.fps)).with_output_dir("shots"),
		|_io| {
			target = Draw.RenderTexture.load!(target_size(movie))?
			Assets.set_texture_filter!(target.texture(), Bilinear)
			shader = Draw.Shader.from_source!({ vertex_source: BrushGlsl.vertex, fragment_source: BrushGlsl.fragment })?
			gpu = {
				shader,
				mode: shader.uniform_f32!("mode")?,
				clip: shader.uniform_vec4!("clip")?,
				color_a: shader.uniform_vec4!("colorA")?,
				color_b: shader.uniform_vec4!("colorB")?,
				color_c: shader.uniform_vec4!("colorC")?,
				geom_a: shader.uniform_vec4!("geomA")?,
				geom_b: shader.uniform_vec4!("geomB")?,
				geom_c: shader.uniform_vec4!("geomC")?,
			}
			Ok({ state: movie.init, auto: Bool.True, fps: Bool.False, target, gpu })
		},
	)

	update! : Movie.Movie(model), MoviePlayer.Model(model), App.Input(MoviePlayer.Msg), App.Io => Try(MoviePlayer.Model(model), [Exit(I64), ..])
	update! = |movie, model, input, io| {
		# Roc reads `movie.advance(m)` as a method call, so a movie's own
		# functions are bound before they are used. See Movie.roc.
		skip = movie.skip
		advance = movie.advance
		back = movie.back
		clock = movie.clock
		keys = input.devices
		if keys.key_pressed(KeyEscape) {
			Err(Exit(0))
		} else {
			up = keys.key_pressed(KeyUp)
			down = keys.key_pressed(KeyDown)
			jump = keys.key_pressed(KeyJ)
			manual = up or down or jump
			auto = if manual { Bool.False } else if keys.key_pressed(KeySpace) { !model.auto } else { model.auto }
			state = if jump {
				skip(model.state)
			} else if up {
				advance(model.state)
			} else if down {
				back(model.state)
			} else if auto {
				advance(model.state)
			} else {
				model.state
			}
			if keys.key_pressed(KeyP) {
				name = "${movie.stem}-${U32.to_str(F64.to_u32_wrap(clock(state)))}.png"
				Task.spawn!(input, || ShotSaved(io.capture().screenshot!(name)))
			}
			fps = if keys.key_pressed(KeyD) { !model.fps } else { model.fps }
			Ok({ ..model, state, auto, fps })
		}
	}

	render! : Movie.Movie(model), MoviePlayer.Model(model), Draw.Frame => Try({}, [Exit(I64), ScopeLimit, ScopeUnavailable, ..])
	render! = |movie, model, frame| {
		draw!(movie, model, frame)?
		show_fps!(model.fps, frame)
		Ok({})
	}

	draw! : Movie.Movie(model), MoviePlayer.Model(model), Draw.Frame => Try({}, [ScopeLimit, ScopeUnavailable, ..])
	draw! = |movie, model, frame| {
		the_frame = movie.frame
		f = the_frame(model.state)
		# roc-ray fills convex polygons only, so a concave one is cut here.
		# A movie does not know or care; a canvas does not ask.
		shapes = Shapes.cut(f.shapes)
		roll = F64.to_f32_wrap(0.0 - f.roll * 57.29577951308232)
		frame.with_render_texture!(model.target, |big| {
			big.clear!(Color.black)
			big.with_camera!(camera(movie.size, roll, supersample), |world| {
				draw_shapes!(model.gpu, world, shapes)
				Ok({})
			})
		})?
		frame.texture!({ texture: model.target.texture(), source: model.target.source(), dest: Math.rect(0, 0, F64.to_f32_wrap(movie.size.width), F64.to_f32_wrap(movie.size.height)), origin: Math.zero, rotation: 0, tint: Color.white })
		Ok({})
	}

	# The canvas turns the frame by minus the roll about the screen's centre; a
	# Camera2D turns the world by its rotation, in degrees, about its target, and
	# puts the target at its offset. `zoom` scales the frame onto a target that
	# many times the window's size.
	unclipped : Shapes.Clip -> Bool
	unclipped = |clip|
		match clip {
			Anywhere => Bool.True
			Within(_) => Bool.False
		}

	camera : { width : F64, height : F64 }, F32, F32 -> Camera.Camera2D
	camera = |size, rotation, zoom| {
		mid_x = F64.to_f32_wrap(size.width / 2.0)
		mid_y = F64.to_f32_wrap(size.height / 2.0)
		Camera.new({ target: { x: mid_x, y: mid_y }, offset: { x: mid_x * zoom, y: mid_y * zoom }, rotation, zoom })
	}

	draw_shapes! : MoviePlayer.Gpu, Draw.Frame, List(Shapes.Shape) => {}
	draw_shapes! = |gpu, frame, shapes| {
		n = List.len(shapes)
		var $k = 0
		while $k < n {
			draw_shape!(gpu, frame, List.get(shapes, $k) ?? crash("shape out of range"))
			$k = $k + 1
		}
		{}
	}

	draw_shape! : MoviePlayer.Gpu, Draw.Frame, Shapes.Shape => {}
	draw_shape! = |gpu, frame, shape|
		match shape {
			Poly(p) => with_fill!(gpu, frame, p.fill, Anywhere, |f, col| f.convex_polygon!({ points: points(p.pts), style: Draw.filled(col) }))
			Pieces(p) => with_fill!(gpu, frame, p.fill, Anywhere, |f, col| draw_triangles!(f, p.tris, col))
			Disc(d) => with_fill!(gpu, frame, d.fill, d.clip, |f, col| f.circle!({ center: point(d.x, d.y), radius: F64.to_f32_wrap(d.r), style: Draw.filled(col) }))
			Rect(r) => with_fill!(gpu, frame, r.fill, Anywhere, |f, col| f.rectangle!({ x: F64.to_f32_wrap(r.x), y: F64.to_f32_wrap(r.y), width: F64.to_f32_wrap(r.w), height: F64.to_f32_wrap(r.h), style: Draw.filled(col) }))
		}

	# Draw with a flat colour directly, or through the shader: its uniforms set for
	# the fill and the geometry drawn in white, which the shader ignores.
	with_fill! : MoviePlayer.Gpu, Draw.Frame, Brush.Fill, Shapes.Clip, (Draw.Frame, Color.Rgba => {}) => {}
	with_fill! = |gpu, frame, fill, clip, draw_it!|
		match fill {
			Skip => {}
			Flat(col) if unclipped(clip) => draw_it!(frame, color_of(col))
			_ => {
				scope = frame.with_shader!(gpu.shader, |shaded| {
					set_uniforms!(gpu, fill, clip)
					draw_it!(shaded, Color.white)
					Ok({})
				})
				match scope {
					Ok({}) => {}
					Err(_) => crash("the player: a shader scope was refused")
				}
			}
		}

	# The fill, into the uniforms BrushGlsl reads: which shading, where it may
	# paint, and the colours and geometry that shading wants.
	set_uniforms! : MoviePlayer.Gpu, Brush.Fill, Shapes.Clip => {}
	set_uniforms! = |gpu, fill, clip| {
		# A zero width is "no clip"; the shader keeps every fragment.
		gpu.clip.set!(
			match clip {
				Anywhere => vec(0.0, 0.0, 0.0, 0.0)
				Within(r) => vec(r.x, r.y, r.w, r.h)
			},
		)
		gpu.mode.set!(F64.to_f32_wrap(BrushGlsl.mode_of(fill)))
		match fill {
			Skip => {}
			Flat(c) => gpu.color_a.set!(rgba_vec(c))
			Span(p) => {
				gpu.color_a.set!(rgba_vec(p.edge))
				gpu.color_b.set!(rgba_vec(p.middle))
				gpu.geom_a.set!(vec(p.x0, p.x1, 0.0, 0.0))
			}
			Radial(p) => {
				gpu.color_a.set!(rgba_vec(p.inner))
				gpu.color_b.set!(rgba_vec(p.outer))
				gpu.geom_a.set!(vec(p.x, p.y, p.r0, p.r1))
			}
			Linear(p) => {
				gpu.color_a.set!(rgba_vec(p.c0))
				gpu.color_b.set!(rgba_vec(p.c1))
				gpu.geom_a.set!(vec(p.o0, p.o1, 0.0, 0.0))
				gpu.geom_b.set!(vec(p.ax, p.ay, p.dx, p.dy))
			}
			Ellipse(p) => {
				gpu.color_a.set!(rgba_vec(p.c0))
				gpu.color_b.set!(rgba_vec(p.c1))
				gpu.geom_a.set!(vec(p.o0, p.o1, 0.0, 0.0))
				gpu.geom_b.set!(vec(p.x, p.y, 0.0, 0.0))
				gpu.geom_c.set!(vec(p.ia, p.ib, p.ic, p.id))
			}
			Glow(p) => {
				gpu.color_a.set!(rgba_vec(p.c0))
				gpu.color_b.set!(rgba_vec(p.c1))
				gpu.color_c.set!(rgba_vec(p.c2))
				gpu.geom_a.set!(vec(p.x, p.y, p.r0, p.r1))
			}
		}
	}

	rgba_vec : Brush.Rgba -> Draw.Vec4
	rgba_vec = |c| vec(c.r / 255.0, c.g / 255.0, c.b / 255.0, c.a)

	vec : F64, F64, F64, F64 -> Draw.Vec4
	vec = |x, y, z, w| { x: F64.to_f32_wrap(x), y: F64.to_f32_wrap(y), z: F64.to_f32_wrap(z), w: F64.to_f32_wrap(w) }

	color_of : Brush.Rgba -> Color.Rgba
	color_of = |c| Color.rgba(byte(c.r), byte(c.g), byte(c.b), byte(c.a * 255.0))

	byte : F64 -> U8
	byte = |v| {
		n = F64.to_i64_wrap(v + 0.5)
		I64.to_u8_wrap(if n < 0 { 0 } else if n > 255 { 255 } else { n })
	}

	draw_triangles! : Draw.Frame, List(F64), Color.Rgba => {}
	draw_triangles! = |frame, tris, col| {
		m = List.len(tris) // 6
		var $k = 0
		while $k < m {
			b = 6 * $k
			frame.triangle!({ a: point(at(tris, b), at(tris, b + 1)), b: point(at(tris, b + 2), at(tris, b + 3)), c: point(at(tris, b + 4), at(tris, b + 5)), style: Draw.filled(col) })
			$k = $k + 1
		}
		{}
	}

	at : List(F64), U64 -> F64
	at = |xs, i| List.get(xs, i) ?? 0.0

	point : F64, F64 -> { x : F32, y : F32 }
	point = |x, y| { x: F64.to_f32_wrap(x), y: F64.to_f32_wrap(y) }

	points : List(F64) -> List({ x : F32, y : F32 })
	points = |xs| {
		n = List.len(xs) // 2
		var $out = List.with_capacity(n)
		var $k = 0
		while $k < n {
			$out = List.append($out, point(at(xs, 2 * $k), at(xs, 2 * $k + 1)))
			$k = $k + 1
		}
		$out
	}

	show_fps! : Bool, Draw.Frame => {}
	show_fps! = |shown, frame|
		if shown {
			frame.fps!({ pos: { x: 8, y: 8 }, size: 20, color: Color.white })
		} else {
			{}
		}


	# **THE PLAYER IS A FUNCTION OF THE MOVIE IT PLAYS.** An app names its
	# movie and hands it over; nothing here is found by name.
	program = |movie| {
		init!: init!(movie),
		update!: |model, input, io| update!(movie, model, input, io),
		render!: |model, frame| render!(movie, model, frame),
	}
}
