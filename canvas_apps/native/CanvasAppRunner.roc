# CanvasAppRunner -- the whole of running a game on roc-ray, for any game.
#
# canvas_apps/<name>_native.roc names a game and hands it here. What is in this file
# is what web/canvas_app_runner.js does on a page: the window, the clock, the keyboard,
# and the painting. Neither knows what game it is running.
#
# **THE KEYBOARD IS THE POINT OF THE SEAM.** roc-ray hands the host's own
# `Devices.Snapshot`; this converts it into an `Input.Snapshot`, which is the
# same thing a browser's event loop builds out of keydown and keyup. So a
# game's `read_controls` -- the one function that touches the keyboard -- is
# written once and run by both.
#
# The painting is the canvas apps' own: roc-ray fills the polygons, triangles, discs and
# rectangles itself, and a shape with a gradient goes through one fragment
# shader that does Brush.shade's arithmetic on the scene position (BrushGlsl).
# It is anti-aliased by supersampling, since roc-ray offers no multisampling.
#
# **THIS IS AN APP MODULE, NOT PART OF A PACKAGE.** It imports rr.App and
# rr.Draw, and a package cannot see a platform -- every roc-ray type came back
# as an unresolved type variable when this was tried as one. That is why the
# app files sit at the top of canvas_apps/ rather than beside their game.
#
# Sound is not wired up yet. A game reports which tones a step set off and this
# ignores them for now, exactly as the page lights a widget instead of playing
# them.
import rr.App
import rr.Assets
import rr.Camera
import rr.Color
import rr.Devices
import rr.Mouse as HostMouse
import rr.Draw
import rr.Math
import lib.Brush
import lib.BrushGlsl
import lib.CanvasApp
import lib.Input
import lib.Keys
import lib.Mouse
import lib.Shapes

CanvasAppRunner :: [].{
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

	Model(model) : { state : model, fps : Bool, target : Draw.RenderTexture, gpu : CanvasAppRunner.Gpu }

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

	init! : CanvasApp.CanvasApp(model) -> App.Init(CanvasAppRunner.Model(model), [TextureGenerationFailed, ResourceLimit, ShaderLoadFailed, UniformNotFound, RenderTextureLoadFailed])
	init! = |game| App.init(
		# **THE GAME SETS THE RATE**, as it does on a page: the rules are a
		# function of the ticks and the keys, not of how long a frame took.
		App.default.with_title(game.title).with_size({ width: F64.to_i32_wrap(game.size.width), height: F64.to_i32_wrap(game.size.height) }).with_frame_pacing(Capped(game.fps)),
		|_io| {
			target = Draw.RenderTexture.load!(target_size(game))?
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
			Ok({ state: game.init, fps: Bool.False, target, gpu })
		},
	)

	# **THE ONE PLACE THE HOST'S KEYBOARD BECOMES THE GAME'S.** Every key the
	# canvas_apps knows, asked of roc-ray's snapshot and written into ours. The arms
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
			Mouse.of(held_buttons(pointer), struck_buttons(pointer), at.x, at.y, pointer.wheel_delta().y),
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
		$bits = if left { U32.bitwise_or($bits, Mouse.bit(Left)) } else { $bits }
		$bits = if right { U32.bitwise_or($bits, Mouse.bit(Right)) } else { $bits }
		if middle { U32.bitwise_or($bits, Mouse.bit(Middle)) } else { $bits }
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

	update! : CanvasApp.CanvasApp(model), CanvasAppRunner.Model(model), App.Input(CanvasAppRunner.Msg), App.Io => Try(CanvasAppRunner.Model(model), [Exit(I64), ..])
	update! = |game, model, input, _io| {
		# Roc reads `game.advance(m, k)` as a method call, so the field is
		# bound first. See CanvasApp.roc.
		advance = game.advance
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
			dt = 1.0 / I32.to_f32(game.fps)
			fps = if input.devices.key_pressed(KeyF) { !model.fps } else { model.fps }
			Ok({ ..model, state: advance(model.state, keys, dt), fps })
		}
	}

	render! : CanvasApp.CanvasApp(model), CanvasAppRunner.Model(model), Draw.Frame => Try({}, [Exit(I64), ScopeLimit, ScopeUnavailable, ..])
	render! = |game, model, frame| {
		draw!(game, model, frame)?
		show_fps!(model.fps, frame)
		Ok({})
	}

	draw! : CanvasApp.CanvasApp(model), CanvasAppRunner.Model(model), Draw.Frame => Try({}, [ScopeLimit, ScopeUnavailable, ..])
	draw! = |game, model, frame| {
		the_frame = game.frame
		# roc-ray fills convex polygons only, so a concave one is cut here. A
		# game does not know or care; a canvas does not ask.
		shapes = Shapes.cut(the_frame(model.state))
		frame.with_render_texture!(model.target, |big| {
			big.clear!(Color.black)
			draw_runs!(model.gpu, game.size, big, shapes)
			Ok({})
		})?
		frame.texture!({ texture: model.target.texture(), source: model.target.source(), dest: Math.rect(0, 0, F64.to_f32_wrap(game.size.width), F64.to_f32_wrap(game.size.height)), origin: Math.zero, rotation: 0, tint: Color.white })
		Ok({})
	}

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

	# **THE TWO MARKS ARE ONE PROBLEM.** A blend says how the shapes after it
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
	draw_runs! : CanvasAppRunner.Gpu, { width : F64, height : F64 }, Draw.Frame, List(Shapes.Shape) => {}
	draw_runs! = |gpu, size, frame, shapes| {
		n = List.len(shapes)
		var $run = List.with_capacity(n)
		var $space = Screen
		var $mode = Over
		var $k = 0
		while $k < n {
			match List.get(shapes, $k) ?? crash("shape out of range") {
				Blend(next) => {
					draw_run!(gpu, size, frame, $run, $space, $mode)
					$run = List.with_capacity(n - $k)
					$mode = next
				}
				View(next) => {
					draw_run!(gpu, size, frame, $run, $space, $mode)
					$run = List.with_capacity(n - $k)
					$space = next
				}
				shape => {
					$run = List.append($run, shape)
				}
			}
			$k = $k + 1
		}
		draw_run!(gpu, size, frame, $run, $space, $mode)
	}

	draw_run! : CanvasAppRunner.Gpu, { width : F64, height : F64 }, Draw.Frame, List(Shapes.Shape), Shapes.Space, Shapes.Mode => {}
	draw_run! = |gpu, size, frame, run, space, mode|
		if List.is_empty(run) {
			{}
		} else {
			scope = frame.with_camera!(staged(size, space), |seen| {
				draw_under!(gpu, seen, run, mode)
				Ok({})
			})
			match scope {
				Ok({}) => {}
				Err(_) => crash("the runner: a camera scope was refused")
			}
		}

	draw_under! : CanvasAppRunner.Gpu, Draw.Frame, List(Shapes.Shape), Shapes.Mode => {}
	draw_under! = |gpu, frame, run, mode|
		match mode {
			Over => draw_all!(gpu, frame, run)
			Add => {
				scope = frame.with_blend_mode!(Draw.additive_blend, |lit| {
					draw_all!(gpu, lit, run)
					Ok({})
				})
				match scope {
					Ok({}) => {}
					Err(_) => crash("the runner: a blend scope was refused")
				}
			}
		}

	# **THE GAME'S LENS, THROUGH THE ONE THE WHOLE FRAME IS DRAWN AT.** Every
	# frame here is painted into a texture at twice the window and scaled back
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

	draw_all! : CanvasAppRunner.Gpu, Draw.Frame, List(Shapes.Shape) => {}
	draw_all! = |gpu, frame, shapes| {
		n = List.len(shapes)
		var $k = 0
		while $k < n {
			draw_shape!(gpu, frame, List.get(shapes, $k) ?? crash("shape out of range"))
			$k = $k + 1
		}
		{}
	}

	draw_shape! : CanvasAppRunner.Gpu, Draw.Frame, Shapes.Shape => {}
	draw_shape! = |gpu, frame, shape|
		match shape {
			Poly(p) => with_fill!(gpu, frame, p.fill, Anywhere, |f, col| f.convex_polygon!({ points: points(p.pts), style: Draw.filled(col) }))
			Pieces(p) => with_fill!(gpu, frame, p.fill, Anywhere, |f, col| draw_triangles!(f, p.tris, col))
			Disc(d) => with_fill!(gpu, frame, d.fill, d.clip, |f, col| f.circle!({ center: point(d.x, d.y), radius: F64.to_f32_wrap(d.r), style: Draw.filled(col) }))
			Rect(r) => with_fill!(gpu, frame, r.fill, Anywhere, |f, col| f.rectangle!({ x: F64.to_f32_wrap(r.x), y: F64.to_f32_wrap(r.y), width: F64.to_f32_wrap(r.w), height: F64.to_f32_wrap(r.h), style: Draw.filled(col) }))
			# **roc-ray IS HANDED THE RECTANGLES**, as it is handed triangles
			# for a concave polygon: each painter gets a frame in the form it
			# can paint. A canvas has `putImageData`; here a texture would be
			# a GPU resource created and dropped every frame, since `render!`
			# cannot keep one.
			Image(i) => draw_pixels!(frame, i)
			# Runs are split before this, so a mark never reaches here.
			Blend(_) => {}
			View(_) => {}
		}

	draw_pixels! : Draw.Frame, { x : F64, y : F64, w : F64, h : F64, cols : U64, rows : U64, pixels : List(Brush.Rgba) } => {}
	draw_pixels! = |frame, image| {
		n = image.cols * image.rows
		var $k = 0
		while $k < n {
			col = $k % image.cols
			row = $k // image.cols
			# Each cell edge to edge rather than a width times an index, so
			# neighbours meet exactly and no seam shows through.
			x0 = image.x + image.w * span(col) / span(image.cols)
			x1 = image.x + image.w * span(col + 1) / span(image.cols)
			y0 = image.y + image.h * span(row) / span(image.rows)
			y1 = image.y + image.h * span(row + 1) / span(image.rows)
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

	# Draw with a flat colour directly, or through the shader: its uniforms set for
	# the fill and the geometry drawn in white, which the shader ignores.
	with_fill! : CanvasAppRunner.Gpu, Draw.Frame, Brush.Fill, Shapes.Clip, (Draw.Frame, Color.Rgba => {}) => {}
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
	set_uniforms! : CanvasAppRunner.Gpu, Brush.Fill, Shapes.Clip => {}
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

	# **THE RUNNER IS A FUNCTION OF THE GAME IT RUNS.** An app names its game
	# and hands it over; nothing here is found by name.
	program = |game| {
		init!: init!(game),
		update!: |model, input, io| update!(game, model, input, io),
		render!: |model, frame| render!(game, model, frame),
	}
}
