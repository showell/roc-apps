# GameApp -- a game on the arcade wasm platform, which is the same file every
# time.
#
# Hand-written. The platform asks for seven functions over a boxed model and
# every one of them is the same for any game: box it, step it with the tick's
# keys, pack its shapes, and say which tones went off. `program` takes a Game
# and names none, so a game's wasm app is five lines.
import Game
import Input
import Mouse
import ShapeWire

GameApp :: [].{
	# Roc reads `game.frame(m)` as a method call, so each of a game's
	# functions is bound before it is used, under its own name.
	#
	# The eight numbers a tick carries are one Input.Snapshot, flattened: the
	# wasm edge has no records, so the runner packs and this unpacks.
	program : Game.Game(model) -> {
		init : {} -> Box(model),
		advance : Box(model), U32, U32, U32, U32, F32, F32, F32 -> Box(model),
		render : Box(model) -> List(U32),
		sounds : Box(model) -> U32,
		tone_count : Box(model) -> U32,
		width : Box(model) -> U32,
		height : Box(model) -> U32,
		fps : Box(model) -> U32,
	}
	program = |game| {
		# The step a tick covers, which is the rate the game asked to be run at.
		dt = 1.0 / I32.to_f32(game.fps)
		advance = game.advance
		frame = game.frame
		sounds = game.sounds
		{
			init: |{}| Box.box(game.init),
			advance: |b, held, struck, buttons, clicks, x, y, wheel|
				Box.box(advance(Box.unbox(b), Input.of(held, struck, Mouse.of(buttons, clicks, x, y, wheel)), dt)),
			render: |b| ShapeWire.pack(frame(Box.unbox(b))),
			sounds: |b| sounds(Box.unbox(b)),
			tone_count: |_b| U64.to_u32_wrap(List.len(game.tones)),
			width: |_b| F64.to_u32_wrap(game.size.width),
			height: |_b| F64.to_u32_wrap(game.size.height),
			fps: |_b| I32.to_u32_wrap(game.fps),
		}
	}
}
