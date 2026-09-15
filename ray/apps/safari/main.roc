# Safari on roc-ray, painted in Roc: SafariRide says what a frame shows, Raster
# paints it into pixels, and roc-ray shows the pixels as one texture. This is
# the first iteration, roc-ray as a framebuffer and nothing more.
#
# The keys are the page's: SPACE pauses and resumes, UP and DOWN step, J rides
# to the next segment, D shows the frame rate, ESCAPE quits.
app [Model, program] { rr: platform "roc-ray/platform/main.roc" }

import rr.App
import rr.Assets
import rr.Color
import rr.Draw
import rr.Math
import SafariRide
import Raster

Model : { ride : SafariRide.Model, auto : Bool, fps : Bool, screen : Assets.Texture }

Msg : []

program = { init!, update!, render! }

# J rides until the segment changes; this bounds it, as the page does.
step_guard : I64
step_guard = 200000

init! : App.Init(Model, [TextureGenerationFailed, ResourceLimit, PixelCountMismatch])
init! = App.init(
	App.default.with_title("Safari").with_size({ width: 960, height: 600 }),
	|_io| {
		screen = Assets.generate_color_texture!({ width: 960, height: 600, color: Color.black })?
		ride = SafariRide.init
		Assets.update_texture!(screen, pixels_of(ride))?
		Ok({ ride, auto: Bool.True, fps: Bool.False, screen })
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
		upload!(manual or auto, model.screen, ride)
		fps = if keys.key_pressed(KeyD) { !model.fps } else { model.fps }
		Ok({ ride, auto, fps, screen: model.screen })
	}
}

render! : Model, Draw.Frame => Try({}, [Exit(I64), ..])
render! = |model, frame| {
	frame.texture!({ texture: model.screen, source: Math.rect(0, 0, 960, 600), dest: Math.rect(0, 0, 960, 600), origin: Math.zero, rotation: 0, tint: Color.white })
	show_fps!(model.fps, frame)
	Ok({})
}

# The frame SafariRide describes, painted and handed to the screen texture.
upload! : Bool, Assets.Texture, SafariRide.Model => {}
upload! = |moved, screen, ride|
	if moved {
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
