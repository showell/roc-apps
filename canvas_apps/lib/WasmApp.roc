# WasmApp -- a game on canvas_apps wasm platform, which is the same file every
# time.
#
# Hand-written. The platform asks for eleven functions over a boxed model and
# every one of them is the same for any game: box it, step it with the tick's
# keys, answer its shapes, and say which tones went off. `program` takes a
# CanvasApp and names none, so an app's wasm file only names its app.
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
		dt = 1.0 / game.fps.to_f32()
		model_at_next_step = game.model_at_next_step
		frame_of = game.frame_shapes
		sounds = game.sounds
		{
			init: |{}| Box.box(game.init),
			model_at_next_step: |b, held, struck, buttons, clicks, x, y, wheel|
				Box.box(model_at_next_step(Box.unbox(b), Input.of(held, struck, Mouse.of(buttons, clicks, x, y, wheel)), dt)),
			frame_shapes: |b| frame_of(Box.unbox(b)),
			# **THE HOST HANDS THE FRAME BACK AND ROC DROPS IT.** Releasing a
			# List(Shape) means decrementing each element's inner lists, which
			# needs the tag union's layout. Roc already has that layout; the
			# host does not and should not. So the host does not free the
			# frame, it returns it.
			release: |_frame| {},
			sounds: |b| sounds(Box.unbox(b)),
			tone_count: |_b| game.tones.len().to_u32_wrap(),
			# A tone is a pitch and a length, which is all either runner needs
			# to make the sound the game says it made.
			tone_freq: |_b, i| tone_at(game.tones, i).freq.to_u32_wrap(),
			tone_ms: |_b, i| tone_at(game.tones, i).ms.to_u32_wrap(),
			width: |_b| game.size.width.to_u32_wrap(),
			height: |_b| game.size.height.to_u32_wrap(),
			fps: |_b| game.fps.to_u32_wrap(),
		}
	}

	tone_at : List({ freq : I32, ms : I32 }), U32 -> { freq : I32, ms : I32 }
	tone_at = |tones, i| tones.get(i.to_u64()) ?? { freq: 0, ms: 0 }
}
