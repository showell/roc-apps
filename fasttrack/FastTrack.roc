# FastTrack -- the game as the platform runs it, from Main.elm.
#
# The model is the game and its undo history. A click arrives as a code
# (Codes.roc); a code that decodes to nothing leaves the game as it was.
import pf.Wire
import Codes
import Game
import History
import Page
import Setup
import Type

FastTrack :: [].{
	Model : { game : Type.Game, history : History.History(Type.Game) }

	## The setups `init`'s number picks, in order.
	setups : List(Setup.InitSetup)
	setups = [Normal, ForcedToReverse, Discard, Cover, BullsEye, SevenSplit]

	init : U64, U32 -> FastTrack.Model
	init = |millis, setup| {
		game = Game.begin_game(millis, List.get(setups, U32.to_u64(setup)) ?? Normal)
		{ game, history: History.reset(game) }
	}

	update : FastTrack.Model, U32 -> FastTrack.Model
	update = |model, code|
		match Codes.decode(model.game.zone_colors, code) {
			Ok(msg) => {
				(history, game) = Game.update_game(msg, model.history, model.game)
				{ game, history }
			}
			Err(_) => model
		}

	view : FastTrack.Model -> Wire.View
	view = |model| Page.view(model.game, History.can_undo(model.history, model.game))

	program : {
		init : U64, U32 -> Box(FastTrack.Model),
		update : Box(FastTrack.Model), U32 -> Box(FastTrack.Model),
		view : Box(FastTrack.Model) -> Box(Wire.View),
		release : Box(Wire.View) -> {},
	}
	program = {
		init: |millis, setup| Box.box(init(millis, setup)),
		update: |b, code| Box.box(update(Box.unbox(b), code)),
		view: |b| Box.box(view(Box.unbox(b))),
		release: |_view| {},
	}
}
