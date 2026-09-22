# FastTrack -- the game as the platform runs it, from Main.elm.
#
# The model is the game, its undo history, and who sits in each seat. A click
# arrives as a code (Codes.roc); a code that decodes to nothing leaves the
# game as it was. A computer's seat plays through the page's tick: the view
# asks for Codes.agent_step, and each one is the computer's next click.
import pf.Wire
import Agent
import Codes
import Game
import History
import Page
import Setup
import Type

FastTrack :: [].{
	Seat : [Human, Computer, Naive]

	Model : { game : Type.Game, history : History.History(Type.Game), seats : List(FastTrack.Seat) }

	## Two bits a seat, the first seat lowest: 0 a person, 1 the computer, 2
	## the naive player (Agent.next_msg).
	seats_of : U32 -> List(FastTrack.Seat)
	seats_of = |bits|
		List.map(
			[0, 1, 2, 3],
			|i|
				match U32.bitwise_and(U32.shr_zf_wrap(bits, 2 * i), 3) {
					1 => Computer
					2 => Naive
					_ => Human
				},
		)

	seat : FastTrack.Model -> FastTrack.Seat
	seat = |model| List.get(model.seats, model.game.active_player_idx) ?? Human

	## The computer's seat, unless someone has won.
	agent_to_move : FastTrack.Model -> Bool
	agent_to_move = |model| seat(model) != Human and Try.is_err(Game.winner(model.game))

	## The setups `init`'s number picks, in order.
	setups : List(Setup.InitSetup)
	setups = [Normal, ForcedToReverse, Discard, Cover, BullsEye, SevenSplit]

	init : U64, U32, U32 -> FastTrack.Model
	init = |millis, setup, seat_bits| {
		game = Game.begin_game(millis, List.get(setups, U32.to_u64(setup)) ?? Normal)
		{ game, history: History.reset(game), seats: seats_of(seat_bits) }
	}

	## A person's click only in a person's seat, the tick only in the
	## computer's, and nothing once someone has won: a stale click is ignored
	## rather than played.
	update : FastTrack.Model, U32 -> FastTrack.Model
	update = |model, code| {
		msg =
			if code == Codes.agent_step {
				if agent_to_move(model) {
					kind = if seat(model) == Naive { Naive } else { Computer }
					Try.map_err(Agent.next_msg(kind, model.game), |_| Ignored)
				} else {
					Err(Ignored)
				}
			} else if seat(model) == Human and Try.is_err(Game.winner(model.game)) {
				Try.map_err(Codes.decode(model.game.zone_colors, code), |_| Ignored)
			} else {
				Err(Ignored)
			}
		match msg {
			Ok(m) => {
				(history, game) = Game.update_game(m, model.history, model.game)
				{ ..model, game, history }
			}
			Err(_) => model
		}
	}

	view : FastTrack.Model -> Wire.View
	view = |model| {
		human = seat(model) == Human
		Page.view(
			model.game,
			{
				interactive: human and Try.is_err(Game.winner(model.game)),
				show_undo: human and History.can_undo(model.history, model.game),
				tick: if agent_to_move(model) { Codes.agent_step } else { 0 },
				winner: Game.winner(model.game) ?? "",
			},
		)
	}

	program : {
		init : U64, U32, U32 -> Box(FastTrack.Model),
		update : Box(FastTrack.Model), U32 -> Box(FastTrack.Model),
		view : Box(FastTrack.Model) -> Box(Wire.View),
		release : Box(Wire.View) -> {},
	}
	program = {
		init: |millis, setup, seat_bits| Box.box(init(millis, setup, seat_bits)),
		update: |b, code| Box.box(update(Box.unbox(b), code)),
		view: |b| Box.box(view(Box.unbox(b))),
		release: |_view| {},
	}
}
