## WasmApp turns a CanvasApp into what the canvas apps' wasm platform asks
## for, which is the same for every app. The platform asks for eleven
## functions over a boxed model: box it, step it with the tick's keys, answer
## its shapes, and say which tones went off. `program` takes a CanvasApp and
## names none, so an app's wasm file only names its app.
import CanvasApp
import Input
import Mouse
import Shapes

WasmApp :: [].{
	# Roc reads `game.frame_shapes(m)` as a method call, so each of a game's
	# functions is bound before it is used, under its own name.
	#
	# The seven numbers a tick carries are one Input.Snapshot, flattened: the
	# wasm edge has no records, so the runner packs and this unpacks.
	program : CanvasApp.CanvasApp(model) -> {
		init : {} -> Box(model),
		model_at_next_step : Box(model), U32, U32, U32, U32, F32, F32, F32 -> Box(model),
		frame_shapes : Box(model) -> List(Shapes.Shape),
		release : List(Shapes.Shape) -> {},
		sounds : Box(model) -> U32,
		tone_count : Box(model) -> U32,
		tone_freq : Box(model), U32 -> U32,
		tone_ms : Box(model), U32 -> U32,
		width : Box(model) -> U32,
		height : Box(model) -> U32,
		fps : Box(model) -> U32,
	}
	program = |game| {
		# The step a tick covers, which is the rate the game asked to be run at.
		seconds_a_step = 1.0 / game.frames_a_second.to_f32()
		model_at_next_step = game.model_at_next_step
		frame_shapes = game.frame_shapes
		sounds = game.sounds
		{
			init: |{}| Box.box(game.init),
			model_at_next_step: |boxed_model, key_held, key_struck, button_held, button_struck, x, y, wheel|
				Box.box(model_at_next_step(Box.unbox(boxed_model), Input.of({ held: key_held, struck: key_struck, mouse: Mouse.of({ held: button_held, struck: button_struck, at: { x, y }, wheel }) }), seconds_a_step)),
			frame_shapes: |boxed_model| frame_shapes(Box.unbox(boxed_model)),
			# The host hands the frame back and Roc drops it. Releasing a
			# List(Shape) means decrementing each element's inner lists, which
			# needs the tag union's layout. Roc has that layout and the host
			# doesn't, so the host returns the frame rather than freeing it.
			release: |_frame| {},
			sounds: |boxed_model| sounds(Box.unbox(boxed_model)),
			tone_count: |_boxed_model| game.tones.len().to_u32_try() ?? crash "WasmApp.program: more tones than a U32 can count",
			tone_freq: |_boxed_model, i| tone_at(game.tones, i).hertz,
			tone_ms: |_boxed_model, i| tone_at(game.tones, i).milliseconds,
			width: |_boxed_model| game.size.width.to_u32_try() ?? crash "WasmApp.program: a width outside a U32's range",
			height: |_boxed_model| game.size.height.to_u32_try() ?? crash "WasmApp.program: a height outside a U32's range",
			fps: |_boxed_model| game.frames_a_second,
		}
	}
}

# The host asks only for a tone below the count it was given, so one past the
# end is a bug on the host's side.
tone_at : List(CanvasApp.Tone), U32 -> CanvasApp.Tone
tone_at = |tones, i| tones.get(i.to_u64()) ?? crash "WasmApp.tone_at: the host asked for a tone past the end of the app's tones"
