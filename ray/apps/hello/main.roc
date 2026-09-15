# The smallest roc-ray app: a window at Safari's size with a disc that pulses,
# closing on Escape. It proves a build of the platform end to end, on this box
# and on the Windows runner. ray/build.sh rewrites the platform reference.
app [Model, program] { rr: platform "roc-ray/platform/main.roc" }

import rr.App
import rr.Color
import rr.Draw

Model : { elapsed : F32 }

Msg : []

program = { init!, update!, render! }

init! : App.Init(Model, [])
init! = App.init(
	App.default.with_title("roc-apps on roc-ray").with_size({ width: 960, height: 600 }),
	|_io| Ok({ elapsed: 0 }),
)

update! : Model, App.Input(Msg), App.Io => Try(Model, [Exit(I64), ..])
update! = |model, input, _io|
	if input.devices.key_pressed(KeyEscape) {
		Err(Exit(0))
	} else {
		Ok({ elapsed: model.elapsed + input.time.elapsed_seconds })
	}

render! : Model, Draw.Frame => Try({}, [Exit(I64), ..])
render! = |model, frame| {
	frame.clear!(Color.from_hex_rgb(0x4a8f43))
	frame.circle!({ center: { x: 480, y: 300 }, radius: 60 + 20 * F32.sin(model.elapsed * 2), style: Draw.filled(Color.from_hex_rgb(0xffc980)) })
	Ok({})
}
