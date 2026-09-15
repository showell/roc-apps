# Safari on roc-ray. SafariRide says what a frame shows; roc-ray draws it.
#
# Two painters, R switching between them so they can be compared on the same
# screen. Shapes, the default: roc-ray fills the frame's polygons, triangles,
# discs and rectangles itself, under a camera turned by the roll, with
# gradients flat for now. Pixels, the first iteration: Raster paints the frame
# in Roc and roc-ray shows it as one texture.
#
# The keys are the page's: SPACE pauses and resumes, UP and DOWN step, J rides
# to the next segment, D shows the frame rate, ESCAPE quits; and R.
app [Model, program] { rr: platform "roc-ray/platform/main.roc" }

import rr.App
import rr.Assets
import rr.Camera
import rr.Color
import rr.Draw
import rr.Math
import SafariRide
import Raster
import Shapes

Model : { ride : SafariRide.Model, auto : Bool, fps : Bool, pixels : Bool, screen : Assets.Texture }

Msg : []

program = { init!, update!, render! }

# J rides until the segment changes; this bounds it, as the page does.
step_guard : I64
step_guard = 200000

init! : App.Init(Model, [TextureGenerationFailed, ResourceLimit])
init! = App.init(
	App.default.with_title("Safari").with_size({ width: 960, height: 600 }),
	|_io| {
		screen = Assets.generate_color_texture!({ width: 960, height: 600, color: Color.black })?
		Ok({ ride: SafariRide.init, auto: Bool.True, fps: Bool.False, pixels: Bool.False, screen })
	},
)

update! : Model, App.Input(Msg), App.Io => Try(Model, [Exit(I64), ..])
update! = |model, input, _io| {
	keys = input.devices
	if keys.key_pressed(KeyEscape) {
		Err(Exit(0))
	} else {
		up = keys.key_pressed(KeyUp)
		down = keys.key_pressed(KeyDown)
		jump = keys.key_pressed(KeyJ)
		manual = up or down or jump
		auto = if manual { Bool.False } else if keys.key_pressed(KeySpace) { !model.auto } else { model.auto }
		ride = if jump {
			next_segment(model.ride)
		} else if up {
			SafariRide.advance(model.ride)
		} else if down {
			SafariRide.back(model.ride)
		} else if auto {
			SafariRide.advance(model.ride)
		} else {
			model.ride
		}
		pixels = if keys.key_pressed(KeyR) { !model.pixels } else { model.pixels }
		upload!(pixels and (manual or auto or pixels != model.pixels), model.screen, ride)
		fps = if keys.key_pressed(KeyD) { !model.fps } else { model.fps }
		Ok({ ride, auto, fps, pixels, screen: model.screen })
	}
}

render! : Model, Draw.Frame => Try({}, [Exit(I64), ScopeLimit, ScopeUnavailable, ..])
render! = |model, frame| {
	draw!(model, frame)?
	show_fps!(model.fps, frame)
	Ok({})
}

draw! : Model, Draw.Frame => Try({}, [ScopeLimit, ScopeUnavailable, ..])
draw! = |model, frame|
	if model.pixels {
		frame.texture!({ texture: model.screen, source: Math.rect(0, 0, 960, 600), dest: Math.rect(0, 0, 960, 600), origin: Math.zero, rotation: 0, tint: Color.white })
		Ok({})
	} else {
		m = model.ride
		shapes = Shapes.frame(SafariRide.commands(m), SafariRide.sky_top(m), SafariRide.sky_horizon(m), SafariRide.sun(m))
		# The canvas turns the frame by minus the roll about the screen's centre;
		# a Camera2D turns the world by its rotation, in degrees.
		camera = Camera.new({ target: { x: 480, y: 300 }, offset: { x: 480, y: 300 }, rotation: F64.to_f32_wrap(0.0 - SafariRide.roll(m) * 57.29577951308232), zoom: 1 })
		frame.clear!(Color.black)
		frame.with_camera!(camera, |world| {
			draw_shapes!(world, shapes)
			Ok({})
		})
	}

draw_shapes! : Draw.Frame, List(Shapes.Shape) => {}
draw_shapes! = |frame, shapes| {
	n = List.len(shapes)
	var $k = 0
	while $k < n {
		draw_shape!(frame, List.get(shapes, $k) ?? crash("shape out of range"))
		$k = $k + 1
	}
	{}
}

draw_shape! : Draw.Frame, Shapes.Shape => {}
draw_shape! = |frame, shape|
	match shape {
		Convex(p) => frame.convex_polygon!({ points: points(p.pts), style: Draw.filled(color(p.color)) })
		Triangle(t) => frame.triangle!({ a: point(t.ax, t.ay), b: point(t.bx, t.by), c: point(t.cx, t.cy), style: Draw.filled(color(t.color)) })
		Disc(d) => frame.circle!({ center: point(d.x, d.y), radius: F64.to_f32_wrap(d.r), style: Draw.filled(color(d.color)) })
		Glow(g) => frame.circle_gradient!({ center: point(g.x, g.y), radius: F64.to_f32_wrap(g.r), color_inner: color(g.inner), color_outer: color(g.outer) })
		Rect(r) => frame.rectangle!({ x: F64.to_f32_wrap(r.x), y: F64.to_f32_wrap(r.y), width: F64.to_f32_wrap(r.w), height: F64.to_f32_wrap(r.h), style: Draw.filled(color(r.color)) })
		RectV(r) => frame.rectangle_gradient_v!({ x: F64.to_f32_wrap(r.x), y: F64.to_f32_wrap(r.y), width: F64.to_f32_wrap(r.w), height: F64.to_f32_wrap(r.h), color_top: color(r.top), color_bottom: color(r.bottom) })
	}

point : F64, F64 -> { x : F32, y : F32 }
point = |x, y| { x: F64.to_f32_wrap(x), y: F64.to_f32_wrap(y) }

points : List(F64) -> List({ x : F32, y : F32 })
points = |xs| {
	n = List.len(xs) // 2
	var $out = List.with_capacity(n)
	var $k = 0
	while $k < n {
		$out = List.append($out, point(List.get(xs, 2 * $k) ?? 0.0, List.get(xs, 2 * $k + 1) ?? 0.0))
		$k = $k + 1
	}
	$out
}

color : Shapes.Rgba8 -> Color.Rgba
color = |c| Color.rgba(c.r, c.g, c.b, c.a)

# The frame SafariRide describes, painted by Raster and handed to the screen
# texture, when the pixel painter is showing and the frame moved.
upload! : Bool, Assets.Texture, SafariRide.Model => {}
upload! = |needed, screen, ride|
	if needed {
		match Assets.update_texture!(screen, pixels_of(ride)) {
			Ok({}) => {}
			Err(_) => crash("safari: a frame did not fit the screen texture")
		}
	} else {
		{}
	}

show_fps! : Bool, Draw.Frame => {}
show_fps! = |shown, frame|
	if shown {
		frame.fps!({ pos: { x: 8, y: 8 }, size: 20, color: Color.white })
	} else {
		{}
	}

pixels_of : SafariRide.Model -> List(Color.Rgba)
pixels_of = |m| {
	scene = { commands: SafariRide.commands(m), roll: SafariRide.roll(m), sky_top: SafariRide.sky_top(m), sky_horizon: SafariRide.sky_horizon(m), sun: SafariRide.sun(m) }
	List.map(Raster.paint(scene), rgba)
}

rgba : U32 -> Color.Rgba
rgba = |p| Color.rgba(U32.to_u8_wrap(U32.shr_wrap(p, 16)), U32.to_u8_wrap(U32.shr_wrap(p, 8)), U32.to_u8_wrap(p), 255)

next_segment : SafariRide.Model -> SafariRide.Model
next_segment = |m| {
	from = m.ride.rider.segment
	var $m = SafariRide.advance(m)
	var $guard = 0
	while $m.ride.rider.segment == from and $guard < step_guard {
		$m = SafariRide.advance($m)
		$guard = $guard + 1
	}
	$m
}
