# CanvasAppRunner runs any canvas app on roc-ray.
#
# An app's main.roc names its CanvasApp value and hands it here. What is in this
# file is what web/canvas_app_runner.js does on a page: the window, the clock,
# the keyboard, and the painting. Neither knows which app it is running.
#
# The keyboard is where the two ends meet. roc-ray hands the host's own
# `Devices.Snapshot`; this converts it into an `Input.Snapshot`, which is the
# same thing a browser's event loop builds out of keydown and keyup. So an
# app's `read_controls` -- the one function that touches the keyboard -- is
# written once and run by both.
#
# The painting is the canvas apps' own: roc-ray fills the polygons, triangles,
# discs and rectangles itself, and a shape with a gradient goes through one
# fragment shader that does Brush.shade's arithmetic on the scene position
# (BrushGlsl). It is anti-aliased by supersampling, since roc-ray offers no
# multisampling.
#
# It is a module of the `native` package, which declares roc-ray in its own
# header (native/main.roc); that declaration is what lets it import rr.App.
#
# Sound is not played here: an app reports which tones a step set off and this
# ignores them, where the page plays them.
import rr.App
import rr.Assets
import rr.Camera
import rr.Color
import rr.Devices
import rr.Mouse as HostMouse
import rr.Draw
import rr.Math
import rr.Shader
import lib.Brush
import lib.BrushGlsl
import lib.CanvasApp
import lib.ConvexCut
import lib.Font
import lib.Input
import lib.Keys
import lib.Mouse
import lib.Shapes

CanvasAppRunner :: [].{

	## `BrushGlsl.Uniforms` in roc-ray's 32-bit types, as the shader takes them.
	BrushUniforms : {
		mode : F32,
		color_a : Math.Vec4,
		color_b : Math.Vec4,
		color_c : Math.Vec4,
		geom_a : Math.Vec4,
		geom_b : Math.Vec4,
		geom_c : Math.Vec4,
	}

	Model(model) : { state : model, fps : Bool, target : Draw.RenderTexture, shader : Shader(CanvasAppRunner.BrushUniforms) }

	Msg : []

	# Twice the window, drawn down with bilinear filtering.
	supersample : F32
	supersample = 2.0

	target_size : CanvasApp.CanvasApp(model) -> { width : I32, height : I32 }
	target_size = |game| {
		{
			width: F64.to_i32_wrap(game.size.width * F32.to_f64(supersample)),
			height: F64.to_i32_wrap(game.size.height * F32.to_f64(supersample)),
		}
	}

	init! : CanvasApp.CanvasApp(model) -> App.Init(CanvasAppRunner.Model(model), _)
	init! = |game| App.init(
		# The game sets the frame rate, as it does on a page: the rules are a
		# function of the ticks and the keys, not of how long a frame took.
		App.default.with_title(game.title).with_size({ width: F64.to_i32_wrap(game.size.width), height: F64.to_i32_wrap(game.size.height) }).with_frame_pacing(Capped(game.fps.to_i32_try() ?? crash "CanvasAppRunner: an fps too large for roc-ray's frame pacing")),
		|_io| {
			target = Draw.RenderTexture.load!(target_size(game))?
			Assets.set_texture_filter!(target.texture(), Bilinear)
			shader = Shader.from_source!({ vertex_source: BrushGlsl.vertex, fragment_source: BrushGlsl.fragment }, blank_uniforms)?
			Ok({ state: game.init, fps: Bool.False, target, shader })
		},
	)

	# This is the one place the host's keyboard becomes the game's: every key
	# the canvas apps know, asked of roc-ray's snapshot and written into ours. The arms
	# look tautological because the tags are spelled the same on purpose; they
	# are two different types, and this is the bridge.
	watched_keys : List(Keys.Key)
	watched_keys = [KeyUp, KeyDown, KeyLeft, KeyRight, KeyW, KeyA, KeyS, KeyD, KeySpace, KeyEnter, KeyP, KeyR, KeyQ, KeyE, KeyC, KeyJ, Key1, Key2, Key3, Key4]

	input_of : Devices.Snapshot -> Input.Snapshot
	input_of = |devices| {
		n = List.len(watched_keys)
		var $keys = Input.none
		var $i = 0
		while $i < n {
			key = List.get(watched_keys, $i) ?? KeyUp
			$keys = if host_key_pressed(devices, key) {
				$keys.with_key_pressed(key)
			} else if host_key_down(devices, key) {
				$keys.with_key_down(key)
			} else {
				$keys
			}
			$i = $i + 1
		}
		pointer = devices.mouse
		at = pointer.position()
		$keys.with_mouse(
			Mouse.of({ held: held_buttons(pointer), struck: struck_buttons(pointer), at: { x: at.x, y: at.y }, wheel: pointer.wheel_delta().y }),
		)
	}

	## The three buttons a page can report, as our bits. roc-ray names seven
	## and we name three, and the two Button types share their spellings, so
	## the bridge says each case outright rather than matching either.
	held_buttons : HostMouse.Snapshot -> U32
	held_buttons = |m|
		some(m.button_down(Left), m.button_down(Right), m.button_down(Middle))

	struck_buttons : HostMouse.Snapshot -> U32
	struck_buttons = |m|
		some(m.button_pressed(Left), m.button_pressed(Right), m.button_pressed(Middle))

	some : Bool, Bool, Bool -> U32
	some = |left, right, middle| {
		var $bits = 0
		$bits = if left {
			U32.bitwise_or($bits, Mouse.bit(Left))
		} else {
			$bits
		}
		$bits = if right {
			U32.bitwise_or($bits, Mouse.bit(Right))
		} else {
			$bits
		}
		if middle {
			U32.bitwise_or($bits, Mouse.bit(Middle))
		} else {
			$bits
		}
	}

	host_key_down : Devices.Snapshot, Keys.Key -> Bool
	host_key_down = |d, key|
		match key {
			KeyUp => d.key_down(KeyUp)
			KeyDown => d.key_down(KeyDown)
			KeyLeft => d.key_down(KeyLeft)
			KeyRight => d.key_down(KeyRight)
			KeyW => d.key_down(KeyW)
			KeyA => d.key_down(KeyA)
			KeyS => d.key_down(KeyS)
			KeyD => d.key_down(KeyD)
			KeySpace => d.key_down(KeySpace)
			KeyEnter => d.key_down(KeyEnter)
			KeyP => d.key_down(KeyP)
			KeyR => d.key_down(KeyR)
			KeyQ => d.key_down(KeyQ)
			KeyE => d.key_down(KeyE)
			KeyC => d.key_down(KeyC)
			KeyJ => d.key_down(KeyJ)
			Key1 => d.key_down(Key1)
			Key2 => d.key_down(Key2)
			Key3 => d.key_down(Key3)
			Key4 => d.key_down(Key4)
		}

	host_key_pressed : Devices.Snapshot, Keys.Key -> Bool
	host_key_pressed = |d, key|
		match key {
			KeyUp => d.key_pressed(KeyUp)
			KeyDown => d.key_pressed(KeyDown)
			KeyLeft => d.key_pressed(KeyLeft)
			KeyRight => d.key_pressed(KeyRight)
			KeyW => d.key_pressed(KeyW)
			KeyA => d.key_pressed(KeyA)
			KeyS => d.key_pressed(KeyS)
			KeyD => d.key_pressed(KeyD)
			KeySpace => d.key_pressed(KeySpace)
			KeyEnter => d.key_pressed(KeyEnter)
			KeyP => d.key_pressed(KeyP)
			KeyR => d.key_pressed(KeyR)
			KeyQ => d.key_pressed(KeyQ)
			KeyE => d.key_pressed(KeyE)
			KeyC => d.key_pressed(KeyC)
			KeyJ => d.key_pressed(KeyJ)
			Key1 => d.key_pressed(Key1)
			Key2 => d.key_pressed(Key2)
			Key3 => d.key_pressed(Key3)
			Key4 => d.key_pressed(Key4)
		}

	update! : CanvasApp.CanvasApp(model), CanvasAppRunner.Model(model), App.Input(CanvasAppRunner.Msg), App.Io => Try(CanvasAppRunner.Model(model), [Exit(I64)])
	update! = |game, model, input, _io| {
		# Roc reads `game.model_at_next_step(m, k)` as a method call, so the field is
		# bound first. See CanvasApp.roc.
		model_at_next_step = game.model_at_next_step
		keys = input_of(input.devices)
		# Escape and F are the RUNNER's, read straight off roc-ray's own
		# snapshot: they never enter a game's Input.Snapshot, so no game can
		# bind a key that would behave differently on a page.
		if input.devices.key_pressed(KeyEscape) {
			Err(Exit(0))
		} else {
			# The step is the rate the game asked for, not however long the
			# last frame happened to take, so a rally is the same rally
			# whatever the machine is doing.
			dt = 1.0 / game.fps.to_f32()
			fps = if input.devices.key_pressed(KeyF) {
				!model.fps
			} else {
				model.fps
			}
			Ok({ ..model, state: model_at_next_step(model.state, keys, dt), fps })
		}
	}

	render! : CanvasApp.CanvasApp(model), CanvasAppRunner.Model(model), Draw.Frame => Try({}, [Exit(I64), ScopeLimit, ScopeUnavailable])
	render! = |game, model, frame| {
		draw!(game, model, frame)?
		show_fps!(model.fps, frame)
		Ok({})
	}

	draw! : CanvasApp.CanvasApp(model), CanvasAppRunner.Model(model), Draw.Frame => Try({}, [ScopeLimit, ScopeUnavailable])
	draw! = |game, model, frame| {
		the_frame = game.frame_shapes
		# roc-ray fills convex polygons only, so a concave one is cut here. A
		# game does not know or care; a canvas does not ask.
		shapes = ConvexCut.cut_shapes(the_frame(model.state))
		frame.with_render_texture!(
			model.target,
			|big| {
				big.clear!(Color.black)
				draw_runs!(model.shader, game.size, big, shapes)
				Ok({})
			},
		)?
		frame.texture!({ texture: model.target.texture(), source: model.target.source(), dest: Math.rect(0, 0, F64.to_f32_wrap(game.size.width), F64.to_f32_wrap(game.size.height)), origin: Math.zero, rotation: 0, tint: Color.white })
		Ok({})
	}

	camera : { width : F64, height : F64 }, F32, F32 -> Camera.Camera2D
	camera = |size, rotation, zoom| {
		mid_x = F64.to_f32_wrap(size.width / 2.0)
		mid_y = F64.to_f32_wrap(size.height / 2.0)
		Camera.new({ target: { x: mid_x, y: mid_y }, offset: { x: mid_x * zoom, y: mid_y * zoom }, rotation, zoom })
	}

	# The two kinds of mark are handled together. A blend says how the shapes after it
	# combine and a view says where they are, and raylib takes each as a scope
	# rather than a flag. So the frame is walked once and cut into runs: the
	# shapes between two marks share a space and a mode and are drawn inside
	# both scopes. A frame starts on the screen, painting over.
	#
	# Walking once is what keeps the two ends agreeing. A canvas holds its
	# transform and its composite operation independently, so a view mark
	# there does not disturb the blend; cutting the frame twice here, once per
	# mark, would have reset the mode at every view boundary and lit a glow on
	# a page that was flat natively.
	draw_runs! : Shader(CanvasAppRunner.BrushUniforms), { width : F64, height : F64 }, Draw.Frame, List(ConvexCut.CutShape) => {}
	draw_runs! = |shader, size, frame, shapes| {
		n = List.len(shapes)
		var $run = List.with_capacity(n)
		var $space = Screen
		var $mode = Over
		var $k = 0
		while $k < n {
			match List.get(shapes, $k) ?? crash ("shape out of range") {
				Uncut(Blend(next)) => {
					draw_run!(shader, size, frame, $run, $space, $mode)
					$run = List.with_capacity(n - $k)
					$mode = next
				}
				Uncut(View(next)) => {
					draw_run!(shader, size, frame, $run, $space, $mode)
					$run = List.with_capacity(n - $k)
					$space = next
				}
				shape => {
					$run = List.append($run, shape)
				}
			}
			$k = $k + 1
		}
		draw_run!(shader, size, frame, $run, $space, $mode)
	}

	draw_run! : Shader(CanvasAppRunner.BrushUniforms), { width : F64, height : F64 }, Draw.Frame, List(ConvexCut.CutShape), Shapes.Space, Shapes.Mode => {}
	draw_run! = |shader, size, frame, run, space, mode|
		if List.is_empty(run) {
			{}
		} else {
			scope = frame.with_camera!(
				staged(size, space),
				|seen| {
					draw_under!(shader, seen, run, mode)
					Ok({})
				},
			)
			match scope {
				Ok({}) => {}
				Err(_) => crash ("the runner: a camera scope was refused")
			}
		}

	draw_under! : Shader(CanvasAppRunner.BrushUniforms), Draw.Frame, List(ConvexCut.CutShape), Shapes.Mode => {}
	draw_under! = |shader, frame, run, mode|
		match mode {
			Over => draw_all!(shader, frame, run)
			Add => {
				scope = frame.with_blend_mode!(
					Draw.additive_blend,
					|lit| {
						draw_all!(shader, lit, run)
						Ok({})
					},
				)
				match scope {
					Ok({}) => {}
					Err(_) => crash ("the runner: a blend scope was refused")
				}
			}
		}

	# The game's camera, combined with the scaling the whole frame is drawn at.
	# Every frame here is painted into a texture at twice the window and scaled back
	# down, which is a camera of its own, and raylib's camera scopes do not
	# nest. Both are similarity transforms, so their composition is one
	# camera: scaling the offset and the zoom is the whole of it.
	staged : { width : F64, height : F64 }, Shapes.Space -> Camera.Camera2D
	staged = |size, space|
		match space {
			Screen => camera(size, 0.0, supersample)
			World(c) =>
				Camera.new({
					target: { x: F64.to_f32_wrap(c.target.x), y: F64.to_f32_wrap(c.target.y) },
					offset: { x: F64.to_f32_wrap(c.offset.x) * supersample, y: F64.to_f32_wrap(c.offset.y) * supersample },
					rotation: F64.to_f32_wrap(c.rotation),
					zoom: F64.to_f32_wrap(c.zoom) * supersample,
				})
		}

	draw_all! : Shader(CanvasAppRunner.BrushUniforms), Draw.Frame, List(ConvexCut.CutShape) => {}
	draw_all! = |shader, frame, shapes| {
		n = List.len(shapes)
		var $k = 0
		while $k < n {
			draw_shape!(shader, frame, List.get(shapes, $k) ?? crash ("shape out of range"))
			$k = $k + 1
		}
		{}
	}

	draw_shape! : Shader(CanvasAppRunner.BrushUniforms), Draw.Frame, ConvexCut.CutShape => {}
	draw_shape! = |shader, frame, cut_shape|
		match cut_shape {
			Triangles(t) => with_fill!(shader, frame, t.fill, |f, col| draw_triangles!(f, t.triangle_coordinates, col))
			Uncut(shape) =>
				match shape {
					Poly(p) => with_fill!(shader, frame, p.fill, |f, col| f.convex_polygon!({ points: points(p.coordinates), style: Draw.filled(col) }))
					Disc(d) => with_fill!(shader, frame, d.fill, |f, col| f.circle!({ center: point(d.x, d.y), radius: F64.to_f32_wrap(d.radius), style: Draw.filled(col) }))
					Rect(r) => with_fill!(shader, frame, r.fill, |f, col| f.rectangle!({ x: F64.to_f32_wrap(r.x), y: F64.to_f32_wrap(r.y), width: F64.to_f32_wrap(r.width), height: F64.to_f32_wrap(r.height), style: Draw.filled(col) }))
					# **roc-ray IS HANDED THE RECTANGLES**, as it is handed triangles
					# for a concave polygon: each painter gets a frame in the form it
					# can paint. A canvas has `putImageData`; here a texture would be
					# a GPU resource created and dropped every frame, since `render!`
					# cannot keep one.
					Image(i) => draw_pixels!(frame, i)
					# roc-ray is handed no typeface, so a line of type arrives as
					# strokes, each a quad and so convex already.
					Text(line) => draw_all!(shader, frame, Font.plotted_shapes(line).map(|stroke| Uncut(stroke)))
					# Runs are split before this, so a mark never reaches here.
					Blend(_) => {}
					View(_) => {}
				}
		}

	draw_pixels! : Draw.Frame, { x : F64, y : F64, width : F64, height : F64, cols : U64, rows : U64, pixels : List(Brush.Rgba) } => {}
	draw_pixels! = |frame, image| {
		n = image.cols * image.rows
		var $k = 0
		while $k < n {
			col = $k % image.cols
			row = $k // image.cols
			# Each cell edge to edge rather than a width times an index, so
			# neighbours meet exactly and no seam shows through.
			x0 = image.x + image.width * span(col) / span(image.cols)
			x1 = image.x + image.width * span(col + 1) / span(image.cols)
			y0 = image.y + image.height * span(row) / span(image.rows)
			y1 = image.y + image.height * span(row + 1) / span(image.rows)
			colour = List.get(image.pixels, $k) ?? { r: 0.0, g: 0.0, b: 0.0, a: 0.0 }
			if colour.a > 0.0 {
				frame.rectangle!({ x: F64.to_f32_wrap(x0), y: F64.to_f32_wrap(y0), width: F64.to_f32_wrap(x1 - x0), height: F64.to_f32_wrap(y1 - y0), style: Draw.filled(color_of(colour)) })
			} else {
				{}
			}
			$k = $k + 1
		}
		{}
	}

	span : U64 -> F64
	span = |n| I64.to_f64(U64.to_i64_wrap(n))

	# Draw with a flat colour directly, or through the shader: its uniforms
	# made from the fill, and the geometry drawn in white, which the shader
	# ignores.
	with_fill! : Shader(CanvasAppRunner.BrushUniforms), Draw.Frame, Brush.Fill, (Draw.Frame, Color.Rgba => {}) => {}
	with_fill! = |shader, frame, fill, draw_it!|
		match fill {
			Flat(col) => draw_it!(frame, color_of(col))
			_ => {
				scope = frame.with_shader!(
					shader.with_uniforms(uniforms_of(fill)),
					|shaded| {
						draw_it!(shaded, Color.white)
						Ok({})
					},
				)
				match scope {
					Ok({}) => {}
					Err(_) => crash "the player: a shader scope was refused"
				}
			}
		}

	# The fill as the uniforms BrushGlsl lays out, in roc-ray's 32-bit vectors.
	uniforms_of : Brush.Fill -> CanvasAppRunner.BrushUniforms
	uniforms_of = |fill| {
		u = BrushGlsl.uniforms(fill)
		{
			mode: F64.to_f32_wrap(u.mode),
			color_a: vec(u.color_a),
			color_b: vec(u.color_b),
			color_c: vec(u.color_c),
			geom_a: vec(u.geom_a),
			geom_b: vec(u.geom_b),
			geom_c: vec(u.geom_c),
		}
	}

	# Every uniform zero, which the shader starts with before the first
	# gradient sets its own.
	blank_uniforms : CanvasAppRunner.BrushUniforms
	blank_uniforms = {
		mode: 0.0,
		color_a: zero_vec,
		color_b: zero_vec,
		color_c: zero_vec,
		geom_a: zero_vec,
		geom_b: zero_vec,
		geom_c: zero_vec,
	}

	zero_vec : Math.Vec4
	zero_vec = vec({ x: 0.0, y: 0.0, z: 0.0, w: 0.0 })

	vec : BrushGlsl.Quad -> Math.Vec4
	vec = |q| Math.vec4(F64.to_f32_wrap(q.x), F64.to_f32_wrap(q.y), F64.to_f32_wrap(q.z), F64.to_f32_wrap(q.w))

	color_of : Brush.Rgba -> Color.Rgba
	color_of = |c| Color.rgba(byte(c.r), byte(c.g), byte(c.b), byte(c.a * 255.0))

	byte : F64 -> U8
	byte = |v| {
		n = F64.to_i64_wrap(v + 0.5)
		I64.to_u8_wrap(
			if n < 0 {
				0
			} else if n > 255 {
				255
			} else {
				n
			},
		)
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

	# An app names its game and hands it over; nothing here is found by name.
	program = |game| {
		init!: init!(game),
		update!: |model, input, io| update!(game, model, input, io),
		render!: |model, frame| render!(game, model, frame),
	}
}
