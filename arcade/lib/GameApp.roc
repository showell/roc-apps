# GameApp -- a game on the arcade wasm platform, which is the same file every
# time.
#
# Hand-written. The platform asks for seven functions over a boxed model and
# every one of them is the same for any game: box it, step it with the tick's
# keys, pack its shapes, and say which tones went off. `program` takes a Game
# and names none, so a game's wasm app is five lines.
import Game
import Keys
import ShapeWire

GameApp :: [].{
	# Roc reads `game.frame(m)` as a method call, so each of a game's
	# functions is bound before it is used, under its own name.
	program : Game.Game(model) -> {
		init : {} -> Box(model),
		advance : Box(model), U32, U32 -> Box(model),
		render : Box(model) -> List(U32),
		sounds : Box(model) -> U32,
		width : Box(model) -> U32,
		height : Box(model) -> U32,
		fps : Box(model) -> U32,
	}
	program = |game| {
		advance = game.advance
		frame = game.frame
		sounds = game.sounds
		{
			init: |{}| Box.box(game.init),
			advance: |b, held, struck| Box.box(advance(Box.unbox(b), Keys.of(held, struck))),
			render: |b| ShapeWire.pack(frame(Box.unbox(b))),
			sounds: |b| sounds(Box.unbox(b)),
			width: |_b| F64.to_u32_wrap(game.size.width),
			height: |_b| F64.to_u32_wrap(game.size.height),
			fps: |_b| I32.to_u32_wrap(game.fps),
		}
	}
}
