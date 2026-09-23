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
	## A computer seat carries its weights and the tables they make, built
	## once rather than every click.
	Seat : [Human, Computer(Agent.Knowledge), Naive]

	Model : { game : Type.Game, history : History.History(Type.Game), seats : List(FastTrack.Seat) }

	## Two bits a seat, the first seat lowest: 0 a person, 1 the computer, 2
	## the naive player (Agent.next_msg).
	seats_of : U32, List(Str) -> List(FastTrack.Seat)
	seats_of = |bits, zone_colors|
		List.map(
			[0, 1, 2, 3],
			|i|
				match U32.bitwise_and(U32.shr_zf_wrap(bits, 2 * i), 3) {
					1 => Computer(Agent.knowledge(Agent.default_weights, zone_colors))
					2 => Naive
					_ => Human
				},
		)

	seat : FastTrack.Model -> FastTrack.Seat
	seat = |model| List.get(model.seats, model.game.active_player_idx) ?? Human

	## One weight of one computer seat: `factor` 0 is danger, 1 out of the
	## pen, 2 home, 3 the cost of a fast-track hop, 4 the wait in the pen,
	## 5 the cost of a 4 played backwards, 6 to 15 the regions (Agent.tune_region)
	## (Agent.Weights). Anything else, or a seat that is not the
	## computer's, is left alone.
	tune : FastTrack.Model, U32, U32, U32 -> FastTrack.Model
	tune = |model, seat_idx, factor, value| {
		# Signed: the page's JavaScript hands a negative weight over as the
		# U32 with the same bits.
		v = if value >= 2147483648 { U32.to_i64(value) - 4294967296 } else { U32.to_i64(value) }
		retuned = List.map_with_index(
			model.seats,
			|s, i|
				match s {
					Computer(k) if i == U32.to_u64(seat_idx) => {
						w = k.weights
						weights =
							if factor == 0 {
								{ ..w, danger: v }
							} else if factor == 1 {
								{ ..w, out_of_pen: v }
							} else if factor == 2 {
								{ ..w, home: v }
							} else if factor == 3 {
								{ ..w, hop: v }
							} else if factor == 4 {
								{ ..w, pen: v }
							} else if factor == 5 {
								{ ..w, back4: v }
							} else if factor >= 6 and factor <= 15 {
								{ ..w, regions: Agent.tune_region(w.regions, factor - 6, v) }
							} else {
								w
							}
						Computer(Agent.knowledge(weights, model.game.zone_colors))
					}
					_ => s
				},
		)
		{ ..model, seats: retuned }
	}

	## The computer's seat, unless someone has won.
	agent_to_move : FastTrack.Model -> Bool
	agent_to_move = |model| seat(model) != Human and Try.is_err(Game.winner(model.game))

	## The setups `init`'s number picks, in order.
	setups : List(Setup.InitSetup)
	setups = [Normal, ForcedToReverse, Discard, Cover, BullsEye, SevenSplit]

	## `teams`: 0 each for itself, 1 partners who may move each other's
	## pieces at any time, 2 partners who may once their own are home.
	init : U64, U32, U32, U32 -> FastTrack.Model
	init = |millis, setup, seat_bits, teams| {
		team_style = if teams == 1 { Anytime } else if teams == 2 { OnceHome } else { Solo }
		game = Game.begin_game(millis, List.get(setups, U32.to_u64(setup)) ?? Normal, team_style)
		{ game, history: History.reset(game), seats: seats_of(seat_bits, game.zone_colors) }
	}

	## A person's click only in a person's seat, the tick only in the
	## computer's, and nothing once someone has won: a stale click is ignored
	## rather than played.
	update : FastTrack.Model, U32 -> FastTrack.Model
	update = |model, code| {
		msg =
			if code == Codes.agent_step {
				if agent_to_move(model) {
					kind = match seat(model) {
						Computer(k) => Computer(k)
						_ => Naive
					}
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
		init : U64, U32, U32, U32 -> Box(FastTrack.Model),
		update : Box(FastTrack.Model), U32 -> Box(FastTrack.Model),
		tune : Box(FastTrack.Model), U32, U32, U32 -> Box(FastTrack.Model),
		view : Box(FastTrack.Model) -> Box(Wire.View),
		release : Box(Wire.View) -> {},
	}
	program = {
		init: |millis, setup, seat_bits, teams| Box.box(init(millis, setup, seat_bits, teams)),
		update: |b, code| Box.box(update(Box.unbox(b), code)),
		tune: |b, seat_idx, factor, value| Box.box(tune(Box.unbox(b), seat_idx, factor, value)),
		view: |b| Box.box(view(Box.unbox(b))),
		release: |_view| {},
	}
}

# Tuning reaches the seat's tables: a dear hop makes red's own FT farther.
expect {
	model = FastTrack.tune(FastTrack.init(0, 0, 1, 0), 0, 3, 14)
	match List.first(model.seats) {
		Ok(Computer(k)) => k.weights.hop == 14 and List.get(List.first(k.steps) ?? [], 16) == Ok(32)
		_ => Bool.False
	}
}

# A negative weight arrives as the U32 with its bits: -44 is 4294967252.
expect {
	model = FastTrack.tune(FastTrack.init(0, 0, 1, 0), 0, 8, 4294967252)
	match List.first(model.seats) {
		Ok(Computer(k)) => k.weights.regions.out_safely == -44
		_ => Bool.False
	}
}
