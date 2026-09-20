# GameRunner -- the whole of running a game on roc-ray, for any game.
#
# arcade/<name>/main.roc names a game and hands it here. What is in this file
# is what web/game_runner.js does on a page: the window, the clock, the keyboard,
# and the painting. Neither knows what game it is running.
#
# **THE KEYBOARD IS THE POINT OF THE SEAM.** roc-ray hands the host's own
# `Devices.Snapshot`; this converts it into a `Keys.Snapshot`, which is the
# same thing a browser's event loop builds out of keydown and keyup. So a
# game's `read_controls` -- the one function that touches the keyboard -- is
# written once and run by both.
#
# The painting is MoviePlayer's, because filling a frame's shapes is the same
# job whatever produced them: roc-ray fills the polygons, triangles, discs and
# rectangles itself, and a shape with a gradient goes through one fragment
# shader that does Brush.shade's arithmetic on the scene position (BrushGlsl).
# It is anti-aliased by supersampling, since roc-ray offers no multisampling.
#
# **THIS IS AN APP MODULE, NOT PART OF A PACKAGE.** It imports rr.App and
# rr.Draw, and a package cannot see a platform -- every roc-ray type came back
# as an unresolved type variable when this was tried as one. That is why the
# app files sit at the top of arcade/ rather than beside their game.
#
# Sound is not wired up yet. A game reports which tones a step set off and this
# ignores them for now, exactly as the page lights a widget instead of playing
# them.
import rr.App
import rr.Assets
import rr.Camera
import rr.Color
import rr.Devices
import rr.Draw
import rr.Math
import lib.Brush
import lib.BrushGlsl
import lib.Game
import lib.Keys
import lib.Shapes

GameRunner :: [].{
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

	Model(model) : { state : model, fps : Bool, target : Draw.RenderTexture, gpu : GameRunner.Gpu }

	Msg : []

	# Twice the window, drawn down with bilinear filtering.
	supersample : F32
	supersample = 2.0

	target_size : Game.Game(model) -> { width : I32, height : I32 }
	target_size = |game| {
		{
			width: F64.to_i32_wrap(game.size.width * F32.to_f64(supersample)),
			height: F64.to_i32_wrap(game.size.height * F32.to_f64(supersample)),
		}
	}

	init! : Game.Game(model) -> App.Init(GameRunner.Model(model), [TextureGenerationFailed, ResourceLimit, ShaderLoadFailed, UniformNotFound, RenderTextureLoadFailed])
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
	# arcade knows, asked of roc-ray's snapshot and written into ours. The arms
	# look tautological because the tags are spelled the same on purpose; they
	# are two different types, and this is the bridge.
	watched : List(Keys.Key)
	watched = [KeyUp, KeyDown, KeyLeft, KeyRight, KeyW, KeyA, KeyS, KeyD, KeySpace, KeyEscape, KeyEnter, KeyP, KeyR]

	snapshot_of : Devices.Snapshot -> Keys.Snapshot
	snapshot_of = |devices| {
		n = List.len(watched)
		var $keys = Keys.none
		var $i = 0
		while $i < n {
			key = List.get(watched, $i) ?? KeyUp
			$keys = if pressed_on(devices, key) {
				$keys.with_key_pressed(key)
			} else if down_on(devices, key) {
				$keys.with_key_down(key)
			} else {
				$keys
			}
			$i = $i + 1
		}
		$keys
	}

	down_on : Devices.Snapshot, Keys.Key -> Bool
	down_on = |d, key|
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
			KeyEscape => d.key_down(KeyEscape)
			KeyEnter => d.key_down(KeyEnter)
			KeyP => d.key_down(KeyP)
			KeyR => d.key_down(KeyR)
		}

	pressed_on : Devices.Snapshot, Keys.Key -> Bool
	pressed_on = |d, key|
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
			KeyEscape => d.key_pressed(KeyEscape)
			KeyEnter => d.key_pressed(KeyEnter)
			KeyP => d.key_pressed(KeyP)
			KeyR => d.key_pressed(KeyR)
		}

	update! : Game.Game(model), GameRunner.Model(model), App.Input(GameRunner.Msg), App.Io => Try(GameRunner.Model(model), [Exit(I64), ..])
	update! = |game, model, input, _io| {
		# Roc reads `game.advance(m, k)` as a method call, so the field is
		# bound first. See Game.roc.
		advance = game.advance
		devices = input.devices
		if devices.key_pressed(KeyEscape) {
			Err(Exit(0))
		} else {
			fps = if devices.key_pressed(KeyF) { !model.fps } else { model.fps }
			Ok({ ..model, state: advance(model.state, snapshot_of(devices)), fps })
		}
	}

	render! : Game.Game(model), GameRunner.Model(model), Draw.Frame => Try({}, [Exit(I64), ScopeLimit, ScopeUnavailable, ..])
	render! = |game, model, frame| {
		draw!(game, model, frame)?
		show_fps!(model.fps, frame)
		Ok({})
	}

	draw! : Game.Game(model), GameRunner.Model(model), Draw.Frame => Try({}, [ScopeLimit, ScopeUnavailable, ..])
	draw! = |game, model, frame| {
		the_frame = game.frame
		# roc-ray fills convex polygons only, so a concave one is cut here. A
		# game does not know or care; a canvas does not ask.
		shapes = Shapes.cut(the_frame(model.state))
		frame.with_render_texture!(model.target, |big| {
			big.clear!(Color.black)
			big.with_camera!(camera(game.size, 0.0, supersample), |world| {
				draw_shapes!(model.gpu, world, shapes)
				Ok({})
			})
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

	draw_shapes! : GameRunner.Gpu, Draw.Frame, List(Shapes.Shape) => {}
	draw_shapes! = |gpu, frame, shapes| {
		n = List.len(shapes)
		var $k = 0
		while $k < n {
			draw_shape!(gpu, frame, List.get(shapes, $k) ?? crash("shape out of range"))
			$k = $k + 1
		}
		{}
	}

	draw_shape! : GameRunner.Gpu, Draw.Frame, Shapes.Shape => {}
	draw_shape! = |gpu, frame, shape|
		match shape {
			Poly(p) => with_fill!(gpu, frame, p.fill, Anywhere, |f, col| f.convex_polygon!({ points: points(p.pts), style: Draw.filled(col) }))
			Pieces(p) => with_fill!(gpu, frame, p.fill, Anywhere, |f, col| draw_triangles!(f, p.tris, col))
			Disc(d) => with_fill!(gpu, frame, d.fill, d.clip, |f, col| f.circle!({ center: point(d.x, d.y), radius: F64.to_f32_wrap(d.r), style: Draw.filled(col) }))
			Rect(r) => with_fill!(gpu, frame, r.fill, Anywhere, |f, col| f.rectangle!({ x: F64.to_f32_wrap(r.x), y: F64.to_f32_wrap(r.y), width: F64.to_f32_wrap(r.w), height: F64.to_f32_wrap(r.h), style: Draw.filled(col) }))
		}

	# Draw with a flat colour directly, or through the shader: its uniforms set for
	# the fill and the geometry drawn in white, which the shader ignores.
	with_fill! : GameRunner.Gpu, Draw.Frame, Brush.Fill, Shapes.Clip, (Draw.Frame, Color.Rgba => {}) => {}
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
	set_uniforms! : GameRunner.Gpu, Brush.Fill, Shapes.Clip => {}
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
