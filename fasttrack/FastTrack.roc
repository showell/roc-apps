# FastTrack -- the game as the platform runs it, from Main.elm.
#
# The model is the game, its undo history, and who sits in each seat. A click
# arrives as a code (Codes.roc); a code that decodes to nothing leaves the
# game as it was. A computer's seat plays through the page's tick: the view
# asks for Codes.agent_step, and each one is the computer's next click. The
# computer plans its turn once (Search.best_line) and plays the plan a click
# a tick; a refilled hand, which ends a plan, gets a new one.
import pf.Wire
import Codes
import Motion
import Game
import History
import Page
import Player
import Search
import Setup
import Strategy
import Type

FastTrack :: [].{
	Seat : [Human, Computer(Strategy.Strategy)]

	## `plan` is the rest of the computer's current plan: the clicks it has
	## chosen and not yet played. `motions` are what the last click moved,
	## and `motion_id` counts the clicks that moved something.
	Model : {
		game : Type.Game,
		history : Game.Undo,
		seats : List(FastTrack.Seat),
		plan : List(Type.GameMsg),
		motion_id : U32,
		motions : List(Motion.Motion),
	}

	## Two bits a seat, the first seat lowest: 0 a person, anything else the
	## computer, playing Strategy.champion.
	seats_of : U32 -> List(FastTrack.Seat)
	seats_of = |bits|
		[0, 1, 2, 3].map(
			|i| if bits.shr_zf_wrap(2 * i).bitwise_and(3) == 0 {
				Human
			} else {
				Computer(Strategy.champion)
			},
		)

	seat : FastTrack.Model -> FastTrack.Seat
	seat = |model| model.seats.get(model.game.active_player_idx) ?? Human

	## The computer's seat, unless someone has won.
	agent_to_move : FastTrack.Model -> Bool
	agent_to_move = |model| seat(model) != Human and Game.winner(model.game).is_err()

	## The setups `init`'s number picks, in order.
	setups : List(Setup.InitSetup)
	setups = [Normal, ForcedToReverse, Discard, Cover, BullsEye, SevenSplit]

	## `teams`: 0 each for itself, 1 partners who may move each other's
	## pieces at any time, 2 partners who may once their own are home.
	init : U64, U32, U32, U32 -> FastTrack.Model
	init = |millis, setup, seat_bits, teams| {
		team_style = if teams == 1 {
			Anytime
		} else if teams == 2 {
			OnceHome
		} else {
			Solo
		}
		game = Game.begin_game(millis, setups.get(setup.to_u64()) ?? Normal, team_style)
		{
			game,
			history: History.reset(game),
			seats: seats_of(seat_bits),
			plan: [],
			motion_id: 0,
			motions: [],
		}
	}

	## The computer's next click, and the rest of its plan: a finished turn
	## is passed on; otherwise the plan in hand, or a new one. With no play at
	## all the turn is passed on too, as Arena.step does, so the page can
	## never wait on a tick that does nothing.
	next_click : FastTrack.Model,
	Strategy.Strategy -> Try(
		{ msg : Type.GameMsg, rest : List(Type.GameMsg) },
		[NoPlay],
	)
	next_click = |model, strategy|
		if Player.get_active_player(model.game).turn == TurnDone {
			Ok({ msg: RotateBoard, rest: [] })
		} else {
			plan =
				if model.plan.is_empty() {
					match Search.best_line(strategy, model.game) {
						Ok(best) => best.line.msgs
						Err(_) => []
					}
				} else {
					model.plan
				}
			match plan {
				[first, .. as rest] => Ok({ msg: first, rest })
				[] => Ok({ msg: RotateBoard, rest: [] })
			}
		}

	## A person's click only in a person's seat, the tick only in the
	## computer's, and nothing once someone has won: a stale click is ignored
	## rather than played.
	update : FastTrack.Model, U32 -> FastTrack.Model
	update = |model, code| {
		step =
			if code == Codes.agent_step and agent_to_move(model) {
				match seat(model) {
					Computer(strategy) => next_click(model, strategy).map_err(|_| Ignored)
					Human => Err(Ignored)
				}
			} else if code != Codes.agent_step and seat(model) == Human and Game.winner(model.game).is_err() {
				Codes.decode(model.game.zone_colors, code)
					.map_err(|_| Ignored)
					.map_ok(|m| { msg: m, rest: [] })
			} else {
				Err(Ignored)
			}
		match step {
			Ok(s) => {
				(history, game) = Game.update_game(s.msg, model.history, model.game)
				motions = Motion.of(model.game, s.msg, game)
				motion_id = if motions.is_empty() {
					model.motion_id
				} else {
					model.motion_id + 1
				}
				{
					..model,
					game,
					history,
					plan: s.rest,
					motion_id,
					motions,
				}
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
				clicks: if human and Game.winner(model.game).is_err() {
					TakesClicks
				} else {
					IgnoresClicks
				},
				show_undo: human and History.can_undo(model.history, model.game),
				tick: if agent_to_move(model) {
					Codes.agent_step
				} else {
					0
				},
				winner: Game.winner(model.game) ?? "",
				motion_id: model.motion_id,
				motions: model.motions.map(
					|m| {
						color: m.color,
						path: m.path.map(U64.to_u32_wrap),
						sent_home: m.sent_home,
					},
				),
			},
		)
	}

	program : {
		init : U64, U32, U32, U32 -> Box(FastTrack.Model),
		update : Box(FastTrack.Model), U32 -> Box(FastTrack.Model),
		view : Box(FastTrack.Model) -> Box(Wire.View),
		release : Box(Wire.View) -> {},
	}
	program = {
		init: |millis, setup, seat_bits, teams| Box.box(init(millis, setup, seat_bits, teams)),
		update: |b, code| Box.box(update(b.unbox(), code)),
		view: |b| Box.box(view(b.unbox())),
		release: |_view| {},
	}
}

# Four computers play a game to its end, a click a tick, taking turns in order.
expect {
	start = FastTrack.init(3, 0, 0x55, 0)
	var $m = start
	var $n = 0
	while Game.winner($m.game).is_err() and $n < 5000 {
		$m = FastTrack.update($m, Codes.agent_step)
		$n = $n + 1
	}
	Game.winner($m.game).is_ok()
}
